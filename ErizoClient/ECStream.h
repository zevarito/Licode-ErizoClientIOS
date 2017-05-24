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

static NSString * const kLicodeAudioLabel = @"LCMSa0";
static NSString * const kLicodeVideoLabel = @"LCMSv0";

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

 Notice that the constraints passed to this initializer will also be set as defaul
 constraint properties for defaultAudioConstraints and defaultVideoConstraints.

 @param videoConstraints RTCMediaConstraints that apply to this stream.
 @param audioConstraints RTCMediaConstraints that apply to this stream.

 @return instancetype
 */
- (instancetype)initWithLocalStreamVideoConstraints:(RTCMediaConstraints *)videoConstraints
                                   audioConstraints:(RTCMediaConstraints *)audioConstraints;

/**
 Creates an instance of ECStream capturing audio/video data
 from host device with defaultVideoConstraints and defaultAudioConstraints.

 Historically this method used mediaConstraints property which will be deprecated
 soon, this method offers backward compatibility still using them, but they are
 only applied as video constraints at is was before. Better start to use
 defaultVideoConstraints and defaultAudioConstraints.

 @see initWithLocalStreamVideoConstraints:audioConstraints:

 @return instancetype
 */
- (instancetype)initLocalStream;

/**
 Creates an instance of ECStream with a given media stream object
 and stream id.

 @param mediaStream The media stream with audio/video.
 @param streamId Erizo stream id for this stream object.
 @param signalingChannel Signaling channel used by ECRoom that handles the stream.

 @return instancetype
 */
- (instancetype)initWithRTCMediaStream:(RTCMediaStream *)mediaStream
                          withStreamId:(NSString *)streamId
                      signalingChannel:(ECSignalingChannel *)signalingChannel;

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
- (NSDictionary *)getAttributes;

/**
 Set attributes of the stream

 Notice that this method will replace the whole dictionary.
 */
- (void)setAttributes:(NSDictionary *)attributes;

/**
 Send data stream on channel
 
 data Dictionary.
 */
- (BOOL)sendData:(NSDictionary *)data;

///-----------------------------------
/// @name Properties
///-----------------------------------

/// RTCMediaStream object that represent the stream a/v data.
@property RTCMediaStream *mediaStream;

/// Erizo stream id.
@property (readonly) NSString *streamId;

/// Erizo stream attributes for the stream being pubished.
@property (strong, nonatomic, readonly) NSDictionary *streamAttributes;

/// Erizo stream options.
@property (strong, nonatomic) NSDictionary *streamOptions;

/// Factory instance used to access local media. It is very important
/// use the same factory at the moment of create a peer connection to
/// publish the local stream. So it needs to be accesible.
@property (readonly) RTCPeerConnectionFactory *peerFactory;

/// ECSignalingChannel instance assigned by ECRoom at the moment
@property (weak, readonly) ECSignalingChannel *signalingChannel;

@property (readonly) BOOL isLocal;

/// Default video contraints.
@property (readonly) RTCMediaConstraints *defaultVideoConstraints;

/// Default audio contraints.
@property (readonly) RTCMediaConstraints *defaultAudioConstraints;

@end
