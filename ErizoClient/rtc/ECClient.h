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
#import "ECClientDelegate.h"
#import "ECClientState.h"

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
 Returns *ECClientState* stringified.
 
 @param state ECClientState.
 
 @return NSString*
 */
extern NSString* clientStateToString(ECClientState state);

@class ECClient;

///-----------------------------------
/// @name ECClient Interface
///-----------------------------------

@interface ECClient : NSObject <ECSignalingChannelDelegate>

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
/// Peer socket id assigned by Licode for signaling P2P connections.
@property NSString *peerSocketId;
/// The streamId
@property NSString *streamId;

///-----------------------------------
/// @name Initializers
///-----------------------------------

- (instancetype)initWithDelegate:(id<ECClientDelegate>)delegate;
- (instancetype)initWithDelegate:(id<ECClientDelegate>)delegate
                  andPeerFactory:(RTCPeerConnectionFactory *)peerFactory;
- (instancetype)initWithDelegate:(id<ECClientDelegate>)delegate
                     peerFactory:(RTCPeerConnectionFactory *)peerFactory
                    peerSocketId:(NSString *)peerSocketId;
- (instancetype)initWithDelegate:(id<ECClientDelegate>)delegate
                     peerFactory:(RTCPeerConnectionFactory *)peerFactory
                        streamId:(NSString *)streamId
                    peerSocketId:(NSString *)peerSocketId;
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
