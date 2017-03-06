//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

@import WebRTC;
#import "ECClientState.h"

@class ECClient;

///-----------------------------------
/// @protocol ECClientDelegate Protocol
///-----------------------------------

/**
 @protocol ECClientDelegate

 Classes that implement this protocol will be called for RTC Client
 event notification.

 */
@protocol ECClientDelegate <NSObject>

- (void)appClient:(ECClient *)client didChangeState:(ECClientState)state;
- (void)appClient:(ECClient *)client didChangeConnectionState:(RTCIceConnectionState)state;
- (void)appClient:(ECClient *)client didReceiveRemoteStream:(RTCMediaStream *)stream withStreamId:(NSString *)streamId;
- (void)appClient:(ECClient *)client didError:(NSError *)error;
- (RTCMediaStream *)streamToPublishByAppClient:(ECClient *)client;
- (NSDictionary *)appClientRequestICEServers:(ECClient *)client;

@end
