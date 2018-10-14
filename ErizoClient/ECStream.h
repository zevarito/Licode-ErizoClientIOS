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
#import "ECSignalingMessage.h"

static NSString * _Nonnull const kLicodeAudioLabel = @"LCMSa0";
static NSString * _Nonnull const kLicodeVideoLabel = @"LCMSv0";

/// Video option
static NSString * _Nonnull const kStreamOptionVideo         = @"video";
/// Audio option
static NSString * _Nonnull const kStreamOptionAudio         = @"audio";
/// Data option
static NSString * _Nonnull const kStreamOptionData          = @"data";
/// Label option, added in v6
static NSString * _Nonnull const kStreamOptionLabel         = @"label";
/// minVideoBW
static NSString * _Nonnull const kStreamOptionMinVideoBW    = @"minVideoBW";
/// maxVideoBW
static NSString * _Nonnull const kStreamOptionMaxVideoBW    = @"maxVideoBW";
/// maxAudioBW
static NSString * _Nonnull const kStreamOptionMaxAudioBW    = @"maxAudioBW";

/**
 @interface ECStream

 Represents a wrapper around an audio/video RTC stream that can be used to
 access local media and publish it in a ECRoom, or receive video from.
 */
@interface ECStream: NSObject

///-----------------------------------
/// @name Initializers
///-----------------------------------

/**
 Creates an instace of ECStream capturing audio/video from the host device
 with given Audio and Video contraints.

 Notice that the constraints passed to this initializer will also be set as default
 constraint properties for defaultAudioConstraints and defaultVideoConstraints.

 @param videoConstraints RTCMediaConstraints that apply to this stream.
 @param audioConstraints RTCMediaConstraints that apply to this stream.

 @see initLocalStream:
 @see initLocalStreamWithOptions:attributes:videoConstraints:audioConstraints:

 @return instancetype
 */
- (instancetype _Nonnull)initLocalStreamVideoConstraints:(nullable RTCMediaConstraints *)videoConstraints
                                        audioConstraints:(nullable RTCMediaConstraints *)audioConstraints;

/**
 Creates an instace of ECStream capturing audio/video from the host device
 providing options, attributes and Audio and Video contraints.

 Notice that the constraints passed to this initializer will also be set as default
 constraint properties for defaultAudioConstraints and defaultVideoConstraints.

 @param options dictionary. @see kStreamOption for options keys.
 @param attributes dictionary. @see setAttributes.
 @param videoConstraints RTCMediaConstraints that apply to this stream.
 @param audioConstraints RTCMediaConstraints that apply to this stream.

 @see initLocalStream:
 @see initLocalStreamVideoConstraints:audioConstraints:

 @return instancetype
 */
- (instancetype _Nonnull)initLocalStreamWithOptions:(nullable NSDictionary *)options
                                         attributes:(nullable NSDictionary *)attributes
                                   videoConstraints:(nullable RTCMediaConstraints *)videoConstraints
                                   audioConstraints:(nullable RTCMediaConstraints *)audioConstraints;
/**
 Creates an instace of ECStream capturing audio/video from the host device
 providing options, attributes.

 @param options dictionary. @see kStreamOption for options keys.
 @param attributes dictionary. @see setAttributes.

 @see initLocalStream:
 @see initLocalStreamVideoConstraints:audioConstraints:
 @see initLocalStreamWithOptions:attributes:videoConstraints:audioConstraints:

 @return instancetype
 */
- (instancetype _Nonnull)initLocalStreamWithOptions:(nullable NSDictionary *)options
                                         attributes:(nullable NSDictionary *)attributes;

/**
 Creates an instance of ECStream capturing audio/video data
 from host device with defaultVideoConstraints and defaultAudioConstraints.

 @see initWithLocalStreamVideoConstraints:audioConstraints:
 @see initLocalStreamWithOptions:attributes:videoConstraints:audioConstraints:

 @return instancetype
 */
- (instancetype _Nonnull)initLocalStream;

/**
 Creates an instance of ECStream with a given stream id and signaling channel.

 @param streamId Erizo stream id for this stream object.
 @param attributes Stream attributes. Attributes will not be sent to the server.
 @param signalingChannel Signaling channel used by ECRoom that handles the stream.
 
 @return instancetype
 */
- (instancetype _Nonnull)initWithStreamId:(nonnull NSString *)streamId
                      attributes:(nullable NSDictionary *)attributes
                signalingChannel:(nonnull ECSignalingChannel *)signalingChannel;

/**
 Attempt to switch between FRONT/REAR camera for the local stream
 being capturated.

 @returns Boolean value.
 */
- (BOOL)switchCamera;

/**
 Indicates if the media stream has audio tracks.

 If you want to know if the stream was initializated requesting
 audio look into streamOptions dictionary.

 @returns Boolean value.
 */
- (BOOL)hasAudio;

/**
 Indicates if the media stream has video tracks.

 If you want to know if the stream was initializated requesting
 video look into streamOptions dictionary.

 @returns Boolean value.
 */
- (BOOL)hasVideo;

/**
 Indicates if the stream has data activated.

 @returns Boolean value.
 */
- (BOOL)hasData;

/**
 Mute Audio tracks for this stream.
 */
- (void)mute;

/**
 Unmute Audio tracks for this stream.
 */
- (void)unmute;

/**
 Generates the video tracks for the stream
 */
- (void)generateVideoTracks;

/**
 Generates the audio tracks for the stream
 */
- (void)generateAudioTracks;

/**
 Get attributes of the stream
 */
- (NSDictionary *_Nonnull)getAttributes;

/**
 Set attributes of the stream

 Notice that this method will replace the whole dictionary.

 If the stream doesn't belong to a connected room, the attributes
 will be marked as dirty and they will be sent to the server
 once the stream gets a functional signaling channel.

 If the stream is a remote stream it will not submit attributes.
 */
- (void)setAttributes:(NSDictionary *_Nonnull)attributes;

/**
 Send data stream on channel

 data Dictionary.
 */
- (BOOL)sendData:(NSDictionary *_Nonnull)data;

/**
 Enable or disable slide show on remote stream
 
 true - enable, false - disable.
 */
- (BOOL)enableSlideShow:(BOOL)enable;

///-----------------------------------
/// @name Properties
///-----------------------------------

/// RTCMediaStream object that represent the stream a/v data.
@property RTCMediaStream * _Nullable mediaStream;

/// Erizo stream id.
@property NSString * _Nullable streamId;

/// Erizo stream attributes for the stream being pubished.
@property (strong, nonatomic, readonly) NSDictionary * _Nonnull streamAttributes;

/// Indicates attributes hasn't been sent to Erizo yet.
@property (readonly) BOOL dirtyAttributes;

/// Erizo stream options.
@property (strong, nonatomic) NSMutableDictionary * _Nonnull streamOptions;

/// Factory instance used to access local media.
@property (strong, nonatomic) RTCPeerConnectionFactory * _Nonnull peerFactory;

/// ECSignalingChannel instance assigned by ECRoom at the moment
@property (weak) ECSignalingChannel * _Nullable signalingChannel;

@property (readonly) BOOL isLocal;

/// Default video contraints.
@property (readonly) RTCMediaConstraints * _Nullable defaultVideoConstraints;

/// Default audio contraints.
@property (readonly) RTCMediaConstraints * _Nullable defaultAudioConstraints;

@end
