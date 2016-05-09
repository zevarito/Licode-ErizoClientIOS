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

static NSMutableArray *sdpReplacements;
static NSString *preferredVideoCodec;
static NSString *defaultVideoCodec = @"VP8";

/**
 @enum ClientState
 */
typedef NS_ENUM(NSInteger, ECClientState) {
    /// Disconnected
    ECClientStateDisconnected,
    /// Ready to signaling
    ECClientStateReady,
    /// Signaling proccess
    ECClientStateConnecting,
    /// Signlaning done
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

/**
 @protocol ECClientDelegate
 
 Classes that implement this protocol will be called for RTC Client
 event notification.
 
 */
@protocol ECClientDelegate <NSObject>

- (void)appClient:(ECClient *)client didChangeState:(ECClientState)state;
- (void)appClient:(ECClient *)client didChangeConnectionState:(RTCICEConnectionState)state;
- (void)appClient:(ECClient *)client didReceiveRemoteStream:(RTCMediaStream *)stream withStreamId:(NSString *)streamId;
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

@property (strong, nonatomic) id<ECClientDelegate> delegate;
@property (nonatomic, readonly) NSDictionary *serverConfiguration;
@property (strong, nonatomic) RTCMediaStream *localStream;

///-----------------------------------
/// @name Initializers
///-----------------------------------

- (instancetype)initWithDelegate:(id<ECClientDelegate>)delegate;
- (instancetype)initWithDelegate:(id<ECClientDelegate>)delegate
                  andPeerFactory:(RTCPeerConnectionFactory *)peerFactory;

///-----------------------------------
/// @name Instance Methods
///-----------------------------------

- (void)disconnect;

///-----------------------------------
/// @name Class Methods
///-----------------------------------
+ (void)replaceSDPLine:(NSString *)line withNewLine:(NSString *)newLine;
+ (void)setPreferredVideoCodec:(NSString *)codec;
+ (NSString *)getPreferredVideoCodec;

@end