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
    NSString *_websocketToken;
    NSDictionary *tokenDictionary;
    id<ECSignalingChannelDelegate> delegate;
    BOOL isConnected;
    NSString *streamId;
    NSMutableArray *outMessagesQueue;
}

- (instancetype)initWithToken:(NSDictionary *)token delegate:(id)signalingDelegate {
    self = [super init];
    tokenDictionary = token;
    delegate = signalingDelegate;
    outMessagesQueue = [NSMutableArray array];
    return self;
}

- (void)disconnect {
    [socketIO disconnect];
}

- (void)enqueueSignalingMessage:(ECSignalingMessage*)message {
    if (message.type == kECSignalingMessageTypeAnswer ||
            message.type == kECSignalingMessageTypeOffer) {
        [outMessagesQueue insertObject:message atIndex:0];
    } else {
        [outMessagesQueue addObject:message];
    }
}

- (void)sendSignalingMessage:(ECSignalingMessage*)message {
    NSError *error;
    NSDictionary *messageDictionary = [NSJSONSerialization
                                       JSONObjectWithData:[message JSONData]
                                       options:NSJSONReadingMutableContainers error:&error];
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    [data setObject:streamId forKey:@"streamId"];
    [data setObject:messageDictionary forKey:@"msg"];
    
    L_INFO(@"Send signaling message: %@", data);
    
    [socketIO sendEvent:@"signaling_message"
               withData:[[NSArray alloc] initWithObjects: data, @"null", nil]];
}

- (void) drainMessageQueue {
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

- (void)startRecording {
    [socketIO sendEvent:@"startRecorder" withData:@{@"to": streamId} andAcknowledge:[self onStartRecordingCallback]];
}

# pragma mark - SockeIODelegate

- (void) socketIODidConnect:(SocketIO *)socket {
    L_INFO(@"Websocket Connection success!");
    
    isConnected = [socketIO isConnected];
    [socketIO sendEvent:@"token" withData:tokenDictionary
        andAcknowledge:[self onSendTokenCallback]];
}

- (void) socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error {
    L_ERROR(@"🚾 disconnectedWithError code: %li, domain: \"%@\"", (long)error.code, error.domain);
}

- (void) socketIO:(SocketIO *)socket didReceiveMessage:(SocketIOPacket *)packet {
    L_DEBUG(@"🚾 didReceiveMessage \"%@\"", packet.data);
}

- (void) socketIO:(SocketIO *)socket didReceiveJSON:(SocketIOPacket *)packet {
    L_DEBUG(@"🚾 didReceiveJSONe \"%@\"", packet.data);
}

- (void) socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet {
    L_DEBUG(@"🚾 didReceiveEvent \"%@\"", packet.data);
    NSDictionary *msg = [(NSDictionary*)[packet.args objectAtIndex:0] objectForKey:@"mess"];
    
    if (!msg) {
        L_WARNING(@"Discarding Licode Event: %@", packet.data);
        
        if ([packet.name isEqualToString:@"onAddStream"]) {
            NSString *sId = [NSString stringWithFormat:@"%@",[[packet.args objectAtIndex:0]objectForKey:@"id"]];

            [delegate didStreamAddedWithId:sId];
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
    [delegate didReceiveMessage:message];
}

- (void) socketIO:(SocketIO *)socket didSendMessage:(SocketIOPacket *)packet {
    L_DEBUG(@"🚾 didSendMessage \"%@\"", packet.data);
}

- (void) socketIO:(SocketIO *)socket onError:(NSError *)error {
    L_ERROR(@"🚾 onError code: %li, domain: \"%@\"", (long)error.code, error.domain);
}

# pragma mark - Callback blocks

- (SocketIOCallback) onPublishCallback {
    
    SocketIOCallback _cb = ^(id argsData) {
        NSArray *response = argsData;
        L_INFO(@"🚾Publish callback: %@", response);
        streamId = [(NSNumber*)[response objectAtIndex:0]stringValue];
        [delegate didReceiveStreamIdReadyToPublish];
    };
    return _cb;
}

- (SocketIOCallback) onSendTokenCallback {
    SocketIOCallback _cb = ^(id argsData) {
        NSArray *response = argsData;
        L_INFO(@"Licode server configuration received: %@", response);
        if ([(NSString *)[response objectAtIndex:0] isEqualToString:@"success"]) {
            [delegate didOpenChannel:self];
            [delegate didReceiveServerConfiguration:[response objectAtIndex:1]];
        }
    };
    return _cb;
}


- (SocketIOCallback) onStartRecordingCallback {
    SocketIOCallback _cb = ^(id argsData) {
        NSArray *response = argsData;
        L_INFO(@"🚾Record callback: %@", response);
        NSString  *recordingId = [(NSNumber*)[response objectAtIndex:0]stringValue];
        [delegate didStartRecordingStreamId:streamId withRecordingId:recordingId];
    };
    return _cb;
}

#pragma mark - Private

- (void)open {
    
    L_INFO(@"Opening Websocket Connection...");
    
    socketIO = [[SocketIO alloc] initWithDelegate:self];
    socketIO.useSecure = (BOOL)[tokenDictionary objectForKey:@"secure"];
    socketIO.returnAllDataFromAck = TRUE;
    int port = socketIO.useSecure ? 443 : 80;
    [socketIO connectToHost:[tokenDictionary objectForKey:@"host"]
                     onPort:port];
}

@end