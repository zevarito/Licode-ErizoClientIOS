//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import <Foundation/Foundation.h>

#import "Logger.h"
#import "RTCPeerConnectionFactory.h"
#import "RTCVideoTrack.h"
#import "ECSignalingChannel.h"

/**
 @enum ClientState
 */
typedef NS_ENUM(NSInteger, ECClientState) {
    ECClientStateDisconnected,
    ECClientStateReady,
    ECClientStateConnecting,
    ECClientStateConnected,
};

/**
 Returns *ECClientState* stringified.
 
 @param state ECClientState.
 
 @return NSString*
 */
extern NSString* clientStateToString(ECClientState state);

@class ECClient;

///-----------------------------------
/// @protocol ECClientDelegate Protocol
///-----------------------------------

@protocol ECClientDelegate <NSObject>

- (void)appClient:(ECClient *)client didChangeState:(ECClientState)state;
- (void)appClient:(ECClient *)client didChangeConnectionState:(RTCICEConnectionState)state;
- (void)appClient:(ECClient *)client didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack;
- (void)appClient:(ECClient *)client didError:(NSError *)error;
- (RTCMediaStream *)streamToPublishByAppClient:(ECClient *)client;

@end

///-----------------------------------
/// @name ECClient Interface
///-----------------------------------

@interface ECClient : NSObject

///-----------------------------------
/// @name Properties
///-----------------------------------

@property (weak, nonatomic) id<ECClientDelegate> delegate;
@property (nonatomic, readonly) NSDictionary *serverConfiguration;
@property (strong, nonatomic) RTCMediaStream *localStream;

///-----------------------------------
/// @name Initializers
///-----------------------------------

- (instancetype)initWithDelegate:(id<ECClientDelegate>)delegate;

///-----------------------------------
/// @name Instance Methods
///-----------------------------------

- (void)disconnect;
- (void)setRemoteSessionDescription:(NSDictionary*)descriptionMessage;

@end