//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import <Foundation/Foundation.h>

#import "ECSignalingMessage.h"
#import "ECSignalingChannel.h"
#import "ECSignalingEvent.h"
#import "RTCSessionDescription+JSON.h"
#import "Logger.h"
#import "NSError+ECSignalingChannel.h"
@import SocketIO;

#define ASSERT_STREAM_ID_STRING(streamId) { \
NSAssert([streamId isKindOfClass:[NSString class]], @"streamId needs to be a string");\
}

typedef void(^SocketIOCallback)(NSArray* data);

@interface ECSignalingChannel ()
@end

@implementation ECSignalingChannel {
    SocketIOClient *socketIO;
    BOOL isConnected;
    NSString *encodedToken;
    NSDictionary *decodedToken;
    NSMutableDictionary *outMessagesQueues;
    NSMutableDictionary *streamSignalingDelegates;
    NSDictionary *roomMetadata;
}

- (instancetype)initWithEncodedToken:(NSString *)token
                        roomDelegate:(id<ECSignalingChannelRoomDelegate>)roomDelegate
                      clientDelegate:(id<ECClientDelegate>)clientDelegate {
    if (self = [super init]) {
        _roomDelegate = roomDelegate;
        encodedToken = token;
        [self decodeToken:token];
    }
    return self;
}

- (void)connect {
    L_INFO(@"Opening Websocket Connection...");
    outMessagesQueues = [NSMutableDictionary dictionary];
    streamSignalingDelegates = [[NSMutableDictionary alloc] init];
    BOOL secure = [(NSNumber *)[decodedToken objectForKey:@"secure"] boolValue];
    NSString *urlString = [NSString stringWithFormat:@"http://%@",
                           [decodedToken objectForKey:@"host"]];
    NSURL *url = [NSURL URLWithString:urlString];

    socketIO = [[SocketIOClient alloc] initWithSocketURL:url
                                                  config:@{
                                                           @"log":@YES,
                                                           @"forcePolling": @NO,
                                                           @"forceWebsockets": @YES,
                                                           @"secure": [NSNumber numberWithBool:secure],
                                                           @"reconnects": @NO,
                                                         }];

    [socketIO on:@"connect" callback:^(NSArray* data, SocketAckEmitter* ack) {
        L_INFO(@"Websocket Connection success!");
        [[socketIO emitWithAck:@"token" with:@[decodedToken]] timingOutAfter:0 callback:^(NSArray* data) {
            [self onSendTokenCallback](data);
        }];
    }];
    [socketIO on:@"disconnect" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull emitter) {
        L_WARNING(@"Websocket disconnected: %@", data);
        outMessagesQueues = [NSMutableDictionary dictionary];
        streamSignalingDelegates = [[NSMutableDictionary alloc] init];
        [_roomDelegate signalingChannel:self didDisconnectOfRoom:roomMetadata];
        [socketIO removeAllHandlers];
        socketIO = nil;
    }];
    [socketIO on:@"error" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull emitter) {
        L_ERROR(@"Websocket error: %@", data);
        NSString *dataString = [NSString stringWithFormat:@"%@", data];
        NSError *error = [NSError ECSignalingChannelWebsocketErrorWithMessage:dataString];
        [self.roomDelegate signalingChannel:self didError:error];
    }];
    [socketIO on:@"reconnect" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull emitter) {
        // TODO
    }];
    [socketIO on:@"reconnectAttempt" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull emitter) {
        // TODO
    }];
    [socketIO on:@"statusChange" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull emitter) {
    }];
    [socketIO on:kEventPublishMe callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull emitter) {
        [self onSocketPublishMe:[data objectAtIndex:0]];
    }];
    [socketIO on:kEventOnAddStream callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull emitter) {
        [self onSocketAddStream:[data objectAtIndex:0]];
    }];
    [socketIO on:kEventOnRemoveStream callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull emitter) {
        [self onSocketRemoveStream:[data objectAtIndex:0]];
    }];
    [socketIO on:kEventSignalingMessageErizo callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull emitter) {
        [self onSocketSignalingMessage:[data objectAtIndex:0] type:kEventSignalingMessageErizo];
    }];
    [socketIO on:kEventSignalingMessagePeer callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull emitter) {
        [self onSocketSignalingMessage:[data objectAtIndex:0] type:kEventSignalingMessagePeer];
    }];
    [socketIO on:kEventOnDataStream callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull emitter) {
        [self onSocketDataStream:[data objectAtIndex:0]];
    }];
    [socketIO on:kEventOnUpdateAttributeStream callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull emitter) {
        [self onUpdateAttributeStream:[data objectAtIndex:0]];
    }];

    [socketIO connect];
}

- (void)disconnect {
    [socketIO disconnect];
}

- (void)enqueueSignalingMessage:(ECSignalingMessage *)message {
    NSString *key =  [self keyForDelegateWithStreamId:message.streamId peerSocketId:message.peerSocketId];

    if (message.type == kECSignalingMessageTypeAnswer ||
        message.type == kECSignalingMessageTypeOffer) {
        [[outMessagesQueues objectForKey:key] insertObject:message atIndex:0];
    } else if (message.type == kECSignalingMessageTypeCandidate) {
        [self sendSignalingMessage:message];
    } else {
        [[outMessagesQueues objectForKey:key] addObject:message];
    }
}

- (void)sendSignalingMessage:(ECSignalingMessage *)message {
    
    if (!message.streamId || [message.streamId isEqualToString:@""]) {
        L_WARNING(@"Sending orphan signaling message, lack streamId");
    }
    
    NSError *error;
    NSDictionary *messageDictionary = [NSJSONSerialization
                                       JSONObjectWithData:[message JSONData]
                                       options:NSJSONReadingMutableContainers error:&error];
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    [data setObject:message.streamId forKey:kEventKeyStreamId];
    if (message.peerSocketId) {
        [data setObject:message.peerSocketId forKey:kEventKeyPeerSocketId];
    }
    [data setObject:messageDictionary forKey:@"msg"];
    
    L_INFO(@"Send signaling message: %@", data);
    
    [socketIO emit:@"signaling_message"
              with:[[NSArray alloc] initWithObjects:data, @"null", nil]];
}

- (void)drainMessageQueueForStreamId:(NSString *)streamId peerSocketId:(NSString *)peerSocketId {
    ASSERT_STREAM_ID_STRING(streamId);
    NSString *key =  [self keyForDelegateWithStreamId:streamId peerSocketId:peerSocketId];

    for (ECSignalingMessage *message in [outMessagesQueues objectForKey:key]) {
        [self sendSignalingMessage:message];
    }
    [[outMessagesQueues objectForKey:key] removeAllObjects];
}

- (void)publish:(NSDictionary*)options signalingChannelDelegate:(id<ECSignalingChannelDelegate>)delegate {
    
    NSMutableDictionary *attributes = [options mutableCopy];
    
    if (!options[@"state"]) {
        attributes[@"state"] = @"erizo";
    }
    
    SocketIOCallback callback = [self onPublishCallback:delegate];
    [[socketIO emitWithAck:@"publish" with:@[attributes, [NSNull null]]] timingOutAfter:10
                                                                               callback:callback];
}

- (void)unpublish:(NSString *)streamId signalingChannelDelegate:(id<ECSignalingChannelDelegate>)delegate {
    SocketIOCallback callback = [self onUnPublishCallback:streamId];
    [[socketIO emitWithAck:@"unpublish" with:@[[self longStreamId:streamId]]] timingOutAfter:10
                                                                                    callback:callback];
}

- (void)publishToPeerID:(NSString *)peerSocketId signalingChannelDelegate:(id<ECSignalingChannelDelegate>)delegate {
    L_INFO(@"Publishing streamId: %@ to peerSocket: %@", delegate.streamId, delegate.peerSocketId);

    // Keep track of an unique delegate for this stream id.
    [self setSignalingDelegate:delegate];

    // Notify room and signaling delegates
    [delegate signalingChannelDidOpenChannel:self];
    [delegate signalingChannel:self readyToPublishStreamId:delegate.streamId peerSocketId:delegate.peerSocketId];
    [_roomDelegate signalingChannel:self didReceiveStreamIdReadyToPublish:delegate.streamId];
}

- (void)subscribe:(NSString *)streamId
    streamOptions:(NSDictionary *)streamOptions
signalingChannelDelegate:(id<ECSignalingChannelDelegate>)delegate {
    ASSERT_STREAM_ID_STRING(streamId);

    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:streamOptions];
    [attributes setValuesForKeysWithDictionary:@{
                                                 //@"browser": @"chorme-stable",
                                                 @"streamId": [self longStreamId:streamId],
                                                 }];
    NSArray *dataToSend = [[NSArray alloc] initWithObjects: attributes, @"null", nil];
    SocketIOCallback callback = [self onSubscribeMCUCallback:streamId signalingChannelDelegate:delegate];
    [[socketIO emitWithAck:@"subscribe" with:dataToSend] timingOutAfter:0
                                                             callback:callback];
}

- (void)unsubscribe:(NSString *)streamId {
    ASSERT_STREAM_ID_STRING(streamId);

    SocketIOCallback callback = [self onUnSubscribeCallback:streamId];
    [[socketIO emitWithAck:@"unsubscribe" with:@[[self longStreamId:streamId]]] timingOutAfter:0
                                                                                      callback:callback];
}


- (void)startRecording:(NSString *)streamId {
    ASSERT_STREAM_ID_STRING(streamId);
    NSNumber *longStreamId = [self longStreamId:streamId];
    SocketIOCallback callback = [self onStartRecordingCallback:streamId];
    [[socketIO emitWithAck:@"startRecorder" with:@[@{@"to":longStreamId}]] timingOutAfter:0
                                                                                 callback:callback];
}

- (void)sendDataStream:(ECSignalingMessage *)message {

	if (!message.streamId || [message.streamId isEqualToString:@""]) {
		L_WARNING(@"Sending orphan signaling message, lack streamId");
	}

	NSError *error;
	NSDictionary *messageDictionary = [NSJSONSerialization JSONObjectWithData:[message JSONData]
                                                                          options:NSJSONReadingMutableContainers
                                                                            error:&error];
	NSMutableDictionary *data = [NSMutableDictionary dictionary];

	[data setObject:@([message.streamId longLongValue]) forKey:@"id"];
	[data setObject:messageDictionary forKey:@"msg"];

	L_INFO(@"Send event message data stream: %@", data);
    [socketIO emit:@"sendDataStream" with:[[NSArray alloc] initWithObjects: data, nil]];
}

- (void)updateStreamAttributes:(ECSignalingMessage *)message {
	
	if (!message.streamId || [message.streamId isEqualToString:@""]) {
		L_WARNING(@"Sending orphan signaling message, lack streamId");
	}
	
	NSError *error;
	NSDictionary *messageDictionary = [NSJSONSerialization
									   JSONObjectWithData:[message JSONData]
									              options:NSJSONReadingMutableContainers error:&error];
	
	NSMutableDictionary *data = [NSMutableDictionary dictionary];
	
	[data setObject:@([message.streamId longLongValue]) forKey:@"id"];
	[data setObject:messageDictionary forKey:@"attrs"];
	
	L_INFO(@"Update attribute stream: %@", data);
	
	[socketIO emit:@"updateStreamAttributes"
              with:[[NSArray alloc] initWithObjects: data, nil]];
}

#
# pragma mark - ECLicodeProtocol
#

- (void)onSocketPublishMe:(NSDictionary *)msg {
    ECSignalingMessage *message = [ECSignalingMessage messageFromDictionary:msg];
    [_roomDelegate signalingChannel:self
   didRequestPublishP2PStreamWithId:message.streamId
                       peerSocketId:message.peerSocketId];
}

- (void)onSocketAddStream:(NSDictionary *)msg {
    ECSignalingEvent *event = [[ECSignalingEvent alloc] initWithName:kEventOnAddStream
                                                             message:msg];
    NSString *sId = [NSString stringWithFormat:@"%@", [msg objectForKey:@"id"]];
    [_roomDelegate signalingChannel:self didStreamAddedWithId:sId event:event];
}

- (void)onSocketRemoveStream:(NSDictionary *)msg {
    NSString *sId = [NSString stringWithFormat:@"%@", [msg objectForKey:@"id"]];
    [_roomDelegate signalingChannel:self didRemovedStreamId:sId];
}

- (void)onSocketDataStream:(NSDictionary *)msg {
    NSDictionary *dataStream = [msg objectForKey:@"msg"];
    NSString *sId = [NSString stringWithFormat:@"%@", [msg objectForKey:@"id"]];
    if([_roomDelegate respondsToSelector:@selector(signalingChannel:fromStreamId:receivedDataStream:)]) {
        [_roomDelegate signalingChannel:self fromStreamId:sId receivedDataStream:dataStream];
    }
}

- (void)onUpdateAttributeStream:(NSDictionary *)msg {
    //ECSignalingEvent *event = [[ECSignalingEvent alloc] initWithName:kEventOnAddStream
    //                                                         message:msg];
    NSDictionary *attributes = [msg objectForKey:kEventKeyUpdatedAttributes];
    NSString *sId = [NSString stringWithFormat:@"%@", [msg objectForKey:@"id"]];
    if([_roomDelegate respondsToSelector:@selector(signalingChannel:fromStreamId:updateStreamAttributes:)]) {
        [_roomDelegate signalingChannel:self fromStreamId:sId updateStreamAttributes:attributes];
    }
}

- (void)onSocketSignalingMessage:(NSDictionary *)msg type:(NSString *)type {
    ECSignalingMessage *message = [ECSignalingMessage messageFromDictionary:msg];
    NSString *key = [self keyForDelegateWithStreamId:message.streamId
                                        peerSocketId:message.peerSocketId];

    id<ECSignalingChannelDelegate> signalingDelegate = [self signalingDelegateForKey:key];
    if (!signalingDelegate) {
        signalingDelegate = [_roomDelegate clientDelegateRequiredForSignalingChannel:self];
        [signalingDelegate setStreamId:message.streamId];
        [signalingDelegate setPeerSocketId:message.peerSocketId];
        [self setSignalingDelegate:signalingDelegate];
    }

    [signalingDelegate signalingChannel:self didReceiveMessage:message];
    
    if ([type isEqualToString:kEventSignalingMessagePeer] &&
        message.peerSocketId && message.type == kECSignalingMessageTypeOffer) {
        // FIXME: Looks like in P2P mode subscribe callback isn't called after attempt
        // to subscribe a stream, that's why sometimes signalingDelegate couldn't not yet exits
        [signalingDelegate signalingChannelDidOpenChannel:self];
        [signalingDelegate signalingChannel:self
                   readyToSubscribeStreamId:message.streamId
                               peerSocketId:message.peerSocketId];
    }
}

#
# pragma mark - Callback blocks
#

- (SocketIOCallback)onSubscribeMCUCallback:(NSString *)streamId signalingChannelDelegate:(id<ECSignalingChannelDelegate>)signalingDelegate {
    SocketIOCallback _cb = ^(id argsData) {
        ASSERT_STREAM_ID_STRING(streamId);
        L_INFO(@"SignalingChannel Subscribe callback: %@", argsData);
        if ((bool)[argsData objectAtIndex:0]) {
            // Keep track of an unique delegate for this stream id and peer socket if p2p.
            signalingDelegate.streamId = streamId;
            [self setSignalingDelegate:signalingDelegate];
            
            // Notify signalingDelegate that can start peer negotiation for streamId.
            [signalingDelegate signalingChannelDidOpenChannel:self];
            [signalingDelegate signalingChannel:self readyToSubscribeStreamId:streamId peerSocketId:nil];
        } else {
            NSError *error = [NSError ECSignalingChannelSubscribeErrorWithStreamId:streamId withMessage:nil];
            [self.roomDelegate signalingChannel:self didError:error];
        }
    };
    return _cb;
}

- (SocketIOCallback)onPublishCallback:(id<ECSignalingChannelDelegate>)signalingDelegate {
    SocketIOCallback _cb = ^(id argsData) {
        L_INFO(@"SignalingChannel Publish callback: %@", argsData);

        NSString *ackString = [NSString stringWithFormat:@"%@", [argsData objectAtIndex:0]];
        if ([[NSString stringWithFormat:@"NO ACK"] isEqualToString:ackString]) {
            NSString *errorString = @"No ACK received when publishing stream!";
            L_ERROR(errorString);
            NSError *error = [NSError ECSignalingChannelPublishErrorWithStreamId:signalingDelegate.streamId withMessage:errorString];
            [self.roomDelegate signalingChannel:self didError:error];
            return;
        }

        // Get streamId for the stream to publish.
		id object = [argsData objectAtIndex:0];
		if(!object || object == [NSNull null]) {
            NSError *error = [NSError ECSignalingChannelPublishErrorWithStreamId:signalingDelegate.streamId withMessage:[argsData objectAtIndex:1]];
            [self.roomDelegate signalingChannel:self didError:error];
			return;
		}
        NSString *streamId = [(NSNumber*)[argsData objectAtIndex:0] stringValue];
        
        // Client delegate should know about the stream id.
        signalingDelegate.streamId = streamId;
        
        // Keep track of an unique delegate for this stream id.
        [self setSignalingDelegate:signalingDelegate];
        
        // Notify room and signaling delegates
        [signalingDelegate signalingChannelDidOpenChannel:self];
        [signalingDelegate signalingChannel:self readyToPublishStreamId:streamId peerSocketId:nil];
        [_roomDelegate signalingChannel:self didReceiveStreamIdReadyToPublish:streamId];
    };
    return _cb;
}

- (SocketIOCallback)onUnPublishCallback:(NSString *)streamId {
    SocketIOCallback _cb = ^(id argsData) {
        ASSERT_STREAM_ID_STRING(streamId);
        NSArray *response = argsData;
        L_INFO(@"SignalingChannel Unpublish callback: %@", response);
        if ((BOOL)[response objectAtIndex:0]) {
            [_roomDelegate signalingChannel:self didUnpublishStreamWithId:streamId];
        } else {
            NSError *error = [NSError ECSignalingChannelUnpublishErrorWithStreamId:streamId withMessage:nil];
            [self.roomDelegate signalingChannel:self didError:error];
        }
    };
    return _cb;
}

- (SocketIOCallback)onUnSubscribeCallback:(NSString *)streamId {
    SocketIOCallback _cb = ^(id argsData) {
        ASSERT_STREAM_ID_STRING(streamId);
        NSArray *response = argsData;
        L_INFO(@"SignalingChannel Unsubscribe callback: %@", response);
        if ((BOOL)[response objectAtIndex:0]) {
            [_roomDelegate signalingChannel:self didUnsubscribeStreamWithId:streamId];
        } else {
            NSError *error = [NSError ECSignalingChannelUnsubscribeErrorWithStreamId:streamId withMessage:nil];
            [self.roomDelegate signalingChannel:self didError:error];
        }
    };
    return _cb;
}

- (SocketIOCallback)onSendTokenCallback {
    SocketIOCallback _cb = ^(id argsData) {
        NSArray *response = argsData;
        L_INFO(@"SignalingChannel: onSendTokenCallback: %@", response);
        
        // Get message and status
        NSString *status = (NSString *)[response objectAtIndex:0];
        NSString *message = (NSString *)[response objectAtIndex:1];
        
        // If success store room metadata and notify connection.
        if ([status isEqualToString:@"success"]) {
            roomMetadata = [[response objectAtIndex:1] mutableCopy];
            [roomMetadata setValue:[[roomMetadata objectForKey:@"streams"] mutableCopy] forKey:@"streams"];
            // Convert stream ids to strings just in case they were parsed as longs.
            for (int i=0; i<[[roomMetadata objectForKey:@"streams"] count]; i++) {
                NSDictionary *stream = [[roomMetadata objectForKey:@"streams"][i] mutableCopy];
                NSString *sId = [NSString stringWithFormat:@"%@", [stream objectForKey:@"id"]];
                [stream setValue:sId forKey:@"id"];
                [roomMetadata objectForKey:@"streams"][i] = stream;
            }
            [_roomDelegate signalingChannel:self didConnectToRoom:roomMetadata];
        } else {
            NSError *error = [NSError ECSignalingChannelSendTokenErrorWithMessage:message];
            [self.roomDelegate signalingChannel:self didError:error];
        }
    };
    return _cb;
}

- (SocketIOCallback)onStartRecordingCallback:(NSString *)streamId {
    SocketIOCallback _cb = ^(id argsData) {
        ASSERT_STREAM_ID_STRING(streamId);
        NSArray *response = argsData;
        L_INFO(@"SignalingChannel onStartRecordingCallback: %@", response);
        
        NSString  *recordingId;
        NSString  *errorStr;
        NSTimeInterval timestamp;
        NSDate *recordingDate = [NSDate date];
        
        if ([[response objectAtIndex:0] isKindOfClass:[NSNull class]]) {
            errorStr = [response objectAtIndex:1];
        } else if ([[response objectAtIndex:0] isKindOfClass:[NSDictionary class]]) {
            recordingId = [[response objectAtIndex:0] objectForKey:@"id"];
            timestamp = [(NSNumber*)[[response objectAtIndex:0] objectForKey:@"timestamp"] integerValue];
            recordingDate = [NSDate dateWithTimeIntervalSince1970:timestamp/1000];
        } else {
            recordingId = [[response objectAtIndex:0] stringValue];
        }
        
        if (!errorStr) {
            [_roomDelegate signalingChannel:self didStartRecordingStreamId:streamId
                            withRecordingId:recordingId
                              recordingDate:recordingDate];
        } else {
            [_roomDelegate signalingChannel:self didFailStartRecordingStreamId:streamId
                               withErrorMsg:errorStr];
        }
    };
    return _cb;
}

#
# pragma mark - Private
#

- (NSNumber *)longStreamId:(NSString *)streamId {
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    return [f numberFromString:streamId];
}

- (void)decodeToken:(NSString *)token {
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:token options:0];
	if(!decodedData) {
		return;
	}
    NSError *jsonParseError = nil;
    decodedToken = [NSJSONSerialization
                    JSONObjectWithData:decodedData
                    options:0
                    error:&jsonParseError];
}

- (void)removeSignalingDelegateForKey:(NSString *)key {
    [streamSignalingDelegates setValue:nil forKey:key];
}

- (void)setSignalingDelegate:(id<ECSignalingChannelDelegate>)delegate {
    [streamSignalingDelegates setValue:delegate forKey:[self keyFromDelegate:delegate]];
    [outMessagesQueues setValue:[NSMutableArray array] forKey:[self keyFromDelegate:delegate]];
}

- (NSString *)keyFromDelegate:(id<ECSignalingChannelDelegate>)delegate {
    return [self keyForDelegateWithStreamId:delegate.streamId peerSocketId:delegate.peerSocketId];
}

- (NSString *)keyForDelegateWithStreamId:(NSString *)streamId peerSocketId:(NSString *)peerSocketId {
    return [NSString stringWithFormat:@"%@-%@", streamId, peerSocketId];
}

- (id<ECSignalingChannelDelegate>)signalingDelegateForKey:(NSString *)key {
    return [streamSignalingDelegates objectForKey:key];
}

@end
