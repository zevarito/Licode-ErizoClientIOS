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
#import "ECClient.h"
#import "Logger.h"

#define ASSERT_STREAM_ID(streamId) { \
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
                        roomDelegate:(id<ECSignalingChannelRoomDelegate>)roomDelegate {
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
    socketIO = [[SocketIO alloc] initWithDelegate:self];
    socketIO.useSecure = (BOOL)[decodedToken objectForKey:@"secure"];
    socketIO.returnAllDataFromAck = TRUE;
    int port = socketIO.useSecure ? 443 : 80;
    [socketIO connectToHost:[decodedToken objectForKey:@"host"] onPort:port];
}

- (void)disconnect {
    [socketIO disconnect];
    outMessagesQueues = [NSMutableDictionary dictionary];
}

- (void)enqueueSignalingMessage:(ECSignalingMessage *)message {
    if (message.type == kECSignalingMessageTypeAnswer ||
            message.type == kECSignalingMessageTypeOffer) {
        [[outMessagesQueues objectForKey:message.streamId] insertObject:message atIndex:0];
    } else {
        [[outMessagesQueues objectForKey:message.streamId] addObject:message];
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
    
    [data setObject:message.streamId forKey:@"streamId"];
    [data setObject:messageDictionary forKey:@"msg"];
    
    L_INFO(@"Send signaling message: %@", data);
    
    [socketIO sendEvent:@"signaling_message"
               withData:[[NSArray alloc] initWithObjects: data, @"null", nil]];
}

- (void)drainMessageQueueForStreamId:(NSString *)streamId {
    ASSERT_STREAM_ID(streamId);
    for (ECSignalingMessage *message in [outMessagesQueues objectForKey:streamId]) {
        [self sendSignalingMessage:message];
    }
    [[outMessagesQueues objectForKey:streamId] removeAllObjects];
}

- (void)publish:(NSDictionary*)options
            signalingChannelDelegate:(id<ECSignalingChannelDelegate>)delegate {
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	[attributes setObject:@"erizo" forKey:@"state"];
	[attributes setObject:[options objectForKey:@"audio"] forKey:@"audio"];
	[attributes setObject:[options objectForKey:@"video"] forKey:@"video"];
	[attributes setObject:[options objectForKey:@"data"] forKey:@"data"];
	id object = [options objectForKey:@"customAttributes"];
	if(object) {
		[attributes setObject:object forKey:@"attributes"];
	}
    
    NSArray *dataToSend = [[NSArray alloc] initWithObjects: attributes, @"null", nil];
    [socketIO sendEvent:@"publish" withData:dataToSend
         andAcknowledge:[self onPublishCallback:delegate]];
}

- (void)subscribe:(NSString *)streamId
            signalingChannelDelegate:(id<ECSignalingChannelDelegate>)delegate {
    ASSERT_STREAM_ID(streamId);
    
    // Long values may came when dictionary created from json.
    streamId = [NSString stringWithFormat:@"%@", streamId];
    
    NSDictionary *attributes = @{
                    //@"browser": @"chorme-stable",
                    @"streamId": streamId,
                    };
    NSArray *dataToSend = [[NSArray alloc] initWithObjects: attributes, @"null", nil];
    [socketIO sendEvent:@"subscribe" withData:dataToSend
         andAcknowledge:[self onSubscribeCallback:streamId signalingChannelDelegate:delegate]];
}

- (void)unsubscribe:(NSString *)streamId {
    ASSERT_STREAM_ID(streamId);
    [socketIO sendEvent:@"unsubscribe" withData:streamId andAcknowledge:[self onUnSubscribeCallback:streamId]];
}


- (void)startRecording:(NSString *)streamId {
    ASSERT_STREAM_ID(streamId);
    [socketIO sendEvent:@"startRecorder" withData:@{@"to": streamId}
         andAcknowledge:[self onStartRecordingCallback:streamId]];
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
}

- (void)socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet {
    L_DEBUG(@"Websocket didReceiveEvent \"%@\"", packet.data);
    
    // On Add Stream Event
    if ([packet.name isEqualToString:kEventOnAddStream]) {
        NSString *sId = [[[packet.args objectAtIndex:0] objectForKey:@"id"] stringValue];
        [_roomDelegate signalingChannel:self didStreamAddedWithId:sId];
        return;
    }
    
    // On Remove Stream Event
    if ([packet.name isEqualToString:kEventOnRemoveStream]) {
        NSString *sId = [[[packet.args objectAtIndex:0] objectForKey:@"id"] stringValue];
        [_roomDelegate signalingChannel:self didStreamRemovedWithId:sId];
        return;
    }
    
    // On Signaling Erizo Message Event
    if ([packet.name isEqualToString:kEventSignalingMessage]) {
        
        NSDictionary *msg = [packet.args objectAtIndex:0];
        
        ECSignalingMessage *message = [ECSignalingMessage messageFromDictionary:msg];
        [[self signalingDelegateForStreamId:message.streamId] signalingChannel:self didReceiveMessage:message];
        
        return;
    }
    
    L_WARNING(@"SignalingChannel: Erizo event couldn't be processed: %@", packet.data);
}

#
# pragma mark - Callback blocks
#

- (SocketIOCallback)onSubscribeCallback:(NSString *)streamId
            signalingChannelDelegate:(id<ECSignalingChannelDelegate>)signalingDelegate {
    SocketIOCallback _cb = ^(id argsData) {
        ASSERT_STREAM_ID(streamId);
        L_INFO(@"SignalingChannel Subscribe callback: %@", argsData);
        if ((bool)[argsData objectAtIndex:0]) {
            // Keep track of an unique delegate for this stream id.
            [self setSignalingDelegateForStreamId:signalingDelegate streamId:streamId];
            
            // Notify signalingDelegate that can start peer negotiation for streamId.
            [signalingDelegate signalingChannelDidOpenChannel:self];
            [signalingDelegate signalingChannel:self didReceiveServerConfiguration:roomMetadata];
            [signalingDelegate signalingChannel:self readyToSubscribeStreamId:streamId];
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
        NSString *streamId = [(NSNumber*)[argsData objectAtIndex:0] stringValue];
        
        // Keep track of an unique delegate for this stream id.
        [self setSignalingDelegateForStreamId:signalingDelegate streamId:streamId];
    
        // Notify room and signaling delegates
        [signalingDelegate signalingChannelDidOpenChannel:self];
        [signalingDelegate signalingChannel:self didReceiveServerConfiguration:roomMetadata];
        [signalingDelegate signalingChannel:self readyToPublishStreamId:streamId];
        [_roomDelegate signalingChannel:self didReceiveStreamIdReadyToPublish:streamId];
    };
    return _cb;
}

- (SocketIOCallback)onUnSubscribeCallback:(NSString *)streamId {
    SocketIOCallback _cb = ^(id argsData) {
        ASSERT_STREAM_ID(streamId);
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
        ASSERT_STREAM_ID(streamId);
        NSArray *response = argsData;
        L_INFO(@"SignalingChannel onStartRecordingCallback: %@", response);
        NSString  *recordingId = [(NSNumber*)[response objectAtIndex:0]stringValue];
        [_roomDelegate signalingChannel:self didStartRecordingStreamId:streamId withRecordingId:recordingId];
    };
    return _cb;
}

#
# pragma mark - Private
#

- (void)decodeToken:(NSString *)token {
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:token options:0];
    NSError *jsonParseError = nil;
    decodedToken = [NSJSONSerialization
                   JSONObjectWithData:decodedData
                   options:0
                   error:&jsonParseError];
}

- (void)removeSignalingDelegateForStreamId:(NSString *)streamId {
    ASSERT_STREAM_ID(streamId);
    [streamSignalingDelegates setValue:nil forKey:streamId];
}

- (void)setSignalingDelegateForStreamId:(id<ECSignalingChannelDelegate>)delegate streamId:(NSString *)streamId {
    ASSERT_STREAM_ID(streamId);
    [streamSignalingDelegates setValue:delegate forKey:streamId];
    
    [outMessagesQueues setValue:[NSMutableArray array] forKey:streamId];
}

- (id<ECSignalingChannelDelegate>)signalingDelegateForStreamId:(NSString *)streamId {
    ASSERT_STREAM_ID(streamId);
    id delegate = [streamSignalingDelegates objectForKey:streamId];
    
    if (!delegate) {
        NSException *exception = [NSException
                        exceptionWithName:@"MissingSignalingDelegate"
                        reason:[NSString stringWithFormat:@"Delegate for streamId %@ not present.", streamId]
                        userInfo:nil];
        @throw exception;
    } else {
        return delegate;
    }
}

@end