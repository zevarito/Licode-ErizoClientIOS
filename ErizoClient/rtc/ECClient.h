//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

@import WebRTC;
#import <Foundation/Foundation.h>
#import "Logger.h"
#import "ECSignalingChannel.h"

typedef RTCSessionDescription * (^SDPHackCallback)(RTCSessionDescription *description);

static SDPHackCallback sdpHackCallback;
static NSString *preferredVideoCodec;
static NSString *defaultVideoCodec = @"VP8";
static NSString *const kECAppClientErrorDomain = @"ECAppClient";
static NSInteger const kECAppClientErrorCreateSDP = -3;
static NSInteger const kECAppClientErrorSetSDP = -4;
static int const kKbpsMultiplier = 1000;
/// @deprecated
static NSMutableArray *sdpReplacements __deprecated_msg("will be removed");

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
- (void)appClient:(ECClient *)client didChangeConnectionState:(RTCIceConnectionState)state;
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

/// ECClientDelegate instance.
@property (strong, nonatomic) id<ECClientDelegate> delegate;
/// Server configuration for this client.
@property (nonatomic, readonly) NSDictionary *serverConfiguration;
/// Local Stream assigned to this client.
@property (strong, nonatomic) RTCMediaStream *localStream;
/// Max bitrate allowed for this client to use.
@property NSNumber *maxBitrate;
/// Should bitrate be limited to `maxBitrate` value?
@property BOOL limitBitrate;

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

/// @deprecated
+ (void)replaceSDPLine:(NSString *)line withNewLine:(NSString *)newLine
                    __deprecated_msg("will be removed");
+ (void)setPreferredVideoCodec:(NSString *)codec;
+ (NSString *)getPreferredVideoCodec;
+ (void)hackSDPWithBlock:(SDPHackCallback)callback;

@end
