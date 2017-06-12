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
#import "Logger.h"

#define ASSERT_STREAM_ID_STRING(streamId) { \
NSAssert([streamId isKindOfClass:[NSString class]], @"streamId needs to be a string");\
}

@interface ECSignalingChannel () <SocketIODelegate>
@end

@implementation ECSignalingChannel {
    SocketIO *socketIO;
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
        outMessagesQueues = [NSMutableDictionary dictionary];
        streamSignalingDelegates = [[NSMutableDictionary alloc] init];
        [self decodeToken:token];
    }
    return self;
}

- (void)connect {
    L_INFO(@"Opening Websocket Connection...");
    NSString *urlString = [NSString stringWithFormat:@"http://%@",
                            [decodedToken objectForKey:@"host"]];
    NSURL *url = [NSURL URLWithString:urlString];
    BOOL secure = [(NSNumber *)[decodedToken objectForKey:@"secure"] boolValue];
    socketIO = [[SocketIO alloc] initWithDelegate:self];
    socketIO.useSecure = secure;
    socketIO.returnAllDataFromAck = TRUE;
    [socketIO connectToHost:[url host] onPort:[[url port] integerValue]];
}

- (void)disconnect {
    [socketIO disconnect];
    outMessagesQueues = [NSMutableDictionary dictionary];
    streamSignalingDelegates = [[NSMutableDictionary alloc] init];
    [_roomDelegate signalingChannel:self didDisconnectOfRoom:roomMetadata];
}

- (void)enqueueSignalingMessage:(ECSignalingMessage *)message {
    NSString *key =  [self keyForDelegateWithStreamId:message.streamId peerSocketId:message.peerSocketId];

    if (message.type == kECSignalingMessageTypeAnswer ||
        message.type == kECSignalingMessageTypeOffer) {
        [[outMessagesQueues objectForKey:key] insertObject:message atIndex:0];
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
    
    [socketIO sendEvent:@"signaling_message"
               withData:[[NSArray alloc] initWithObjects:data, @"null", nil]];
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
    
    NSArray *dataToSend = [[NSArray alloc] initWithObjects: attributes, @"null", nil];
    [socketIO sendEvent:@"publish" withData:dataToSend
         andAcknowledge:[self onPublishCallback:delegate]];
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
signalingChannelDelegate:(id<ECSignalingChannelDelegate>)delegate {
    ASSERT_STREAM_ID_STRING(streamId);
    
    // Long values may came when dictionary created from json.
    streamId = [NSString stringWithFormat:@"%@", streamId];
    
    NSDictionary *attributes = @{
                                 //@"browser": @"chorme-stable",
                                 @"streamId": streamId,
                                 };
    NSArray *dataToSend = [[NSArray alloc] initWithObjects: attributes, @"null", nil];
    [socketIO sendEvent:@"subscribe" withData:dataToSend
         andAcknowledge:[self onSubscribeMCUCallback:streamId signalingChannelDelegate:delegate]];
}

- (void)unsubscribe:(NSString *)streamId {
    ASSERT_STREAM_ID_STRING(streamId);
    [socketIO sendEvent:@"unsubscribe" withData:streamId andAcknowledge:[self onUnSubscribeCallback:streamId]];
}


- (void)startRecording:(NSString *)streamId {
    ASSERT_STREAM_ID_STRING(streamId);
    [socketIO sendEvent:@"startRecorder" withData:@{@"to": streamId}
         andAcknowledge:[self onStartRecordingCallback:streamId]];
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
	
	[socketIO sendEvent:@"sendDataStream"
			   withData:[[NSArray alloc] initWithObjects: data, nil]];
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
	
	[socketIO sendEvent:@"updateStreamAttributes"
			   withData:[[NSArray alloc] initWithObjects: data, nil]];
}

#
# pragma mark - SockeIODelegate
#

- (void)socketIODidConnect:(SocketIO *)socket {
    L_INFO(@"Websocket Connection success!");

    isConnected = [socketIO isConnected];
    [socketIO sendEvent:@"token" withData:decodedToken
         andAcknowledge:[self onSendTokenCallback]];
}

- (void)socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error {
    L_ERROR(@"Websocket disconnectedWithError code: %li, domain: \"%@\"", (long)error.code, error.domain);
}

- (void)socketIO:(SocketIO *)socket didReceiveMessage:(SocketIOPacket *)packet {
    L_DEBUG(@"Websocket didReceiveMessage \"%@\"", packet.data);
}

- (void)socketIO:(SocketIO *)socket didReceiveJSON:(SocketIOPacket *)packet {
    L_DEBUG(@"Websocket didReceiveJSON \"%@\"", packet.data);
}

- (void)socketIO:(SocketIO *)socket didSendMessage:(SocketIOPacket *)packet {
    L_DEBUG(@"Websocket didSendMessage \"%@\"", packet.data);
}

- (void)socketIO:(SocketIO *)socket onError:(NSError *)error {
    L_ERROR(@"Websocket onError code: %li, domain: \"%@\"", (long)error.code, error.domain);
    [_roomDelegate signalingChannel:self didError:[error localizedDescription]];
}

- (void)socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet {
    L_DEBUG(@"Websocket didReceiveEvent \"%@\"", packet.data);
    
    ECSignalingEvent *event = [[ECSignalingEvent alloc] initWithName:packet.name
                                                             message:[packet.args objectAtIndex:0]];

    if ([event.name isEqualToString:kEventOnAddStream]) {
        [_roomDelegate signalingChannel:self didStreamAddedWithId:event.streamId event:event];
        return;
    }

    if ([event.name isEqualToString:kEventOnRemoveStream]) {
        [_roomDelegate signalingChannel:self didRemovedStreamId:event.streamId];
        return;
    }

    if ([event.name isEqualToString:kEventSignalingMessageErizo] ||
         [event.name isEqualToString:kEventSignalingMessagePeer]) {

        ECSignalingMessage *message = [ECSignalingMessage messageFromDictionary:event.message];
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

        if ([packet.name isEqualToString:kEventSignalingMessagePeer] &&
            message.peerSocketId && message.type == kECSignalingMessageTypeOffer) {
            // FIXME: Looks like in P2P mode subscribe callback isn't called after attempt
            // to subscribe a stream, that's why sometimes signalingDelegate couldn't not yet exits
            [signalingDelegate signalingChannelDidOpenChannel:self];
            [signalingDelegate signalingChannel:self
                       readyToSubscribeStreamId:message.streamId
                                   peerSocketId:message.peerSocketId];
        }

        return;
    }
    
    // On publish_me event for p2p rooms
    if ([event.name isEqualToString:kEventPublishMe]) {
        [_roomDelegate signalingChannel:self
       didRequestPublishP2PStreamWithId:event.streamId
                           peerSocketId:event.peerSocketId];
        return;
    }

	if ([event.name isEqualToString:kEventOnDataStream]) {
		if([_roomDelegate respondsToSelector:@selector(signalingChannel:fromStreamId:receivedDataStream:)]) {
			[_roomDelegate signalingChannel:self
                               fromStreamId:event.streamId
                         receivedDataStream:event.dataStream];
		}
		return;
	}
	if ([event.name isEqualToString:kEventOnUpdateAttributeStream]) {
		if([_roomDelegate respondsToSelector:@selector(signalingChannel:fromStreamId:updateStreamAttributes:)]) {
			[_roomDelegate signalingChannel:self
                               fromStreamId:event.streamId
                     updateStreamAttributes:event.updatedAttributes];
		}
		return;
	}
	
    L_WARNING(@"SignalingChannel: Erizo event couldn't be processed: %@", packet.data);
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
            L_ERROR(@"SignalingChannel couldn't subscribe streamId: %@", streamId);
        }
    };
    return _cb;
}

- (SocketIOCallback)onPublishCallback:(id<ECSignalingChannelDelegate>)signalingDelegate {
    SocketIOCallback _cb = ^(id argsData) {
        L_INFO(@"SignalingChannel Publish callback: %@", argsData);
        
        // Get streamId for the stream to publish.
		id object = [argsData objectAtIndex:0];
		if(!object || object == [NSNull null]) {
			if([signalingDelegate respondsToSelector:@selector(signalingChannelPublishFailed:)]) {
				[signalingDelegate signalingChannelPublishFailed:self];
			}
			if([_roomDelegate respondsToSelector:@selector(signalingChannel:didError:)]) {
				[_roomDelegate signalingChannel:self
                                       didError:[NSString stringWithFormat:@"%@", [argsData objectAtIndex:1]]];
			}
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

- (SocketIOCallback)onUnSubscribeCallback:(NSString *)streamId {
    SocketIOCallback _cb = ^(id argsData) {
        ASSERT_STREAM_ID_STRING(streamId);
        NSArray *response = argsData;
        L_INFO(@"SignalingChannel Unsubscribe callback: %@", response);
        if ((BOOL)[response objectAtIndex:0]) {
            [_roomDelegate signalingChannel:self didUnsubscribeStreamWithId:streamId];
        } else {
            L_ERROR(@"signalingChannel Couldn't unsubscribe stream id: %@", streamId);
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
            [_roomDelegate signalingChannel:self didError:message];
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
            errorStr = [(NSNumber*)[response objectAtIndex:1] stringValue];
        }
        
        if ([[response objectAtIndex:0] isKindOfClass:[NSDictionary class]]) {
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
