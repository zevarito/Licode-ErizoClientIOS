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
#import "Logger.h"

@interface ECSignalingChannel () <SocketIODelegate>
@end

@implementation ECSignalingChannel {
    SocketIO *socketIO;
    NSString *encodedToken;
    NSDictionary *decodedToken;
    BOOL isConnected;
    NSString *currentStreamId;
    NSMutableArray *outMessagesQueue;
}

- (instancetype)initWithEncodedToken:(NSString *)token
                   signalingDelegate:(id<ECSignalingChannelDelegate>)signalingDelegate
                        roomDelegate:(id<ECSignalingChannelRoomDelegate>)roomDelegate {
    if (self = [super init]) {
        _signalingDelegate = signalingDelegate;
        _roomDelegate = roomDelegate;
        encodedToken = token;
        outMessagesQueue = [NSMutableArray array];
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
    [socketIO connectToHost:[decodedToken objectForKey:@"host"]
                     onPort:port];
}

- (void)disconnect {
    [socketIO disconnect];
    outMessagesQueue = [NSMutableArray array];
}

- (void)enqueueSignalingMessage:(ECSignalingMessage *)message {
    if (message.type == kECSignalingMessageTypeAnswer ||
            message.type == kECSignalingMessageTypeOffer) {
        [outMessagesQueue insertObject:message atIndex:0];
    } else {
        [outMessagesQueue addObject:message];
    }
}

- (void)sendSignalingMessage:(ECSignalingMessage *)message {
    NSError *error;
    NSDictionary *messageDictionary = [NSJSONSerialization
                                       JSONObjectWithData:[message JSONData]
                                       options:NSJSONReadingMutableContainers error:&error];
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    [data setObject:currentStreamId forKey:@"streamId"];
    [data setObject:messageDictionary forKey:@"msg"];
    
    L_INFO(@"Send signaling message: %@", data);
    
    [socketIO sendEvent:@"signaling_message"
               withData:[[NSArray alloc] initWithObjects: data, @"null", nil]];
}

- (void)drainMessageQueue {
    for (ECSignalingMessage *message in outMessagesQueue) {
        [self sendSignalingMessage:message];
    }
    [outMessagesQueue removeAllObjects];
}

- (void)publish:(NSDictionary*)options {
    NSDictionary *attributes = @{
                    @"state": @"erizo",
                    @"audio": [options objectForKey:@"audio"],
                    @"video": [options objectForKey:@"video"],
                    @"data": [options objectForKey:@"data"],
                    };
    
    NSArray *dataToSend = [[NSArray alloc] initWithObjects: attributes, @"null", nil];
    [socketIO sendEvent:@"publish" withData:dataToSend andAcknowledge:[self onPublishCallback]];
}

- (void)subscribe:(NSString *)streamId {
    currentStreamId = streamId;
    
    NSDictionary *attributes = @{
                    //@"browser": @"chorme-stable",
                    @"streamId": currentStreamId,
                    };
    NSArray *dataToSend = [[NSArray alloc] initWithObjects: attributes, @"null", nil];
    [socketIO sendEvent:@"subscribe" withData:dataToSend andAcknowledge:[self onSubscribeCallback:streamId]];
}

- (void)unsubscribe:(NSString *)streamId {
    [socketIO sendEvent:@"unsubscribe" withData:streamId andAcknowledge:[self onUnSubscribeCallback:streamId]];
}


- (void)startRecording:(NSString *)streamId {
    [socketIO sendEvent:@"startRecorder" withData:@{@"to": streamId} andAcknowledge:[self onStartRecordingCallback]];
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
    L_DEBUG(@"Websocket didReceiveJSONe \"%@\"", packet.data);
}

- (void)socketIO:(SocketIO *)socket didSendMessage:(SocketIOPacket *)packet {
    L_DEBUG(@"Websocket didSendMessage \"%@\"", packet.data);
}

- (void)socketIO:(SocketIO *)socket onError:(NSError *)error {
    L_ERROR(@"Websocket onError code: %li, domain: \"%@\"", (long)error.code, error.domain);
}

- (void)socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet {
    L_DEBUG(@"Websocket didReceiveEvent \"%@\"", packet.data);
    NSDictionary *msg = [(NSDictionary*)[packet.args objectAtIndex:0] objectForKey:@"mess"];
    
    if (!msg) {
        if ([packet.name isEqualToString:@"onAddStream"]) {
            NSString *sId = [NSString stringWithFormat:@"%@",[[packet.args objectAtIndex:0]objectForKey:@"id"]];
            [_roomDelegate signalingChannel:self didStreamAddedWithId:sId];
        }
        return;
    }
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:msg
                                                       options:(NSJSONWritingOptions) NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                 encoding:NSUTF8StringEncoding];
    ECSignalingMessage *message = [ECSignalingMessage messageFromJSONString:jsonString];
    [_signalingDelegate signalingChannel:self didReceiveMessage:message];
}

#
# pragma mark - Callback blocks
#

- (SocketIOCallback)onSubscribeCallback:(NSString *)streamId {
    SocketIOCallback _cb = ^(id argsData) {
        NSArray *response = argsData;
        L_INFO(@"SignalingChannel Subscribe callback: %@", response);
        if ((bool)[response objectAtIndex:0]) {
            [_signalingDelegate signalingChannel:self readyToSubscribeStreamId:streamId];
        }
    };
    return _cb;
}

- (SocketIOCallback)onUnSubscribeCallback:(NSString *)streamId {
    SocketIOCallback _cb = ^(id argsData) {
        NSArray *response = argsData;
        L_INFO(@"SignalingChannel Unsubscribe callback: %@", response);
        if ((BOOL)[response objectAtIndex:0]) {
            [_roomDelegate signalingChannel:self didStreamRemovedWithId:streamId];
        } else {
            L_ERROR(@"signalingChannel Couldn't unsubscribe stream id: %@", streamId);
        }
    };
    return _cb;
}

- (SocketIOCallback)onPublishCallback {
    SocketIOCallback _cb = ^(id argsData) {
        NSArray *response = argsData;
        L_INFO(@"SignalingChannel Publish callback: %@", response);
        currentStreamId = [(NSNumber*)[response objectAtIndex:0]stringValue];
        [_signalingDelegate signalingChannel:self readyToPublishStreamId:currentStreamId];
        [_roomDelegate signalingChannel:self didReceiveStreamIdReadyToPublish:currentStreamId];
    };
    return _cb;
}

- (SocketIOCallback)onSendTokenCallback {
    SocketIOCallback _cb = ^(id argsData) {
        NSArray *response = argsData;
        L_INFO(@"SignalingChannel: onSendTokenCallback: %@", response);
        NSString *status = (NSString *)[response objectAtIndex:0];
        NSString *message = (NSString *)[response objectAtIndex:1];
        if ([status isEqualToString:@"success"]) {
            [_signalingDelegate signalingChannelDidOpenChannel:self];
            NSDictionary *roomMeta = [response objectAtIndex:1];
            [_signalingDelegate signalingChannel:self didReceiveServerConfiguration:roomMeta];
            [_roomDelegate signalingChannel:self didConnectToRoom:roomMeta];
        } else {
            [_roomDelegate signalingChannel:self didError:message];
        }
    };
    return _cb;
}

- (SocketIOCallback)onStartRecordingCallback {
    SocketIOCallback _cb = ^(id argsData) {
        NSArray *response = argsData;
        L_INFO(@"SignalingChannel onStartRecordingCallback: %@", response);
        NSString  *recordingId = [(NSNumber*)[response objectAtIndex:0]stringValue];
        [_roomDelegate signalingChannel:self didStartRecordingStreamId:currentStreamId withRecordingId:recordingId];
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

@end