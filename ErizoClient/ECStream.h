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
#import "RTCMediaConstraints.h"
#import "RTCMediaStream.h"

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
 Creates an instance of ECStream capturing audio/video data
 from host device.
 
 Inmediatly attempts to acceess local audio/video.
 You can pass *nil* to *mediaConstraints* and default media
 constraints will be used.
 
 @param mediaConstraints RTCMediaConstraints that apply to this stream.
 
 @return instancetype
 */
- (instancetype)initWithLocalStreamWithMediaConstraints:(RTCMediaConstraints *)mediaConstraints;

/**
 Creates an instance of ECStream capturing audio/video data
 from host device with default RTCMediaConstraints.

 @see initLocalStreamWithMediaConstraints:
 
 @return instancetype
 */
- (instancetype)initLocalStream;

/**
 Creates an instance of ECStream with a given media stream object
 and stream id.
 
 @param mediaStream The media stream with audio/video.
 @param streamId Erizo stream id for this stream object.
 
 @return instancetype
 */
- (instancetype)initWithRTCMediaStream:(RTCMediaStream *)mediaStream
                          withStreamId:(NSString *)streamId;

/**
 Attempt to switch between FRONT/REAR camera for the local stream
 being capturated.
 
 @returns Boolean value.
 */
- (BOOL)switchCamera;

/**
 Indicates if the stream has audio activated.
 
 @returns Boolean value.
 */
- (BOOL)hasAudio;

/**
 Indicates if the stream has video activated.
 
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

///-----------------------------------
/// @name Properties
///-----------------------------------

/// RTCMediaStream object that represent the stream a/v data.
@property RTCMediaStream *mediaStream;

/// Erizo stream id.
@property (readonly) NSString *streamId;

/// Factory instance used to access local media. It is very important
/// use the same factory at the moment of create a peer connection to
/// publish the local stream. So it needs to be accesible.
@property (readonly) RTCPeerConnectionFactory *peerFactory;

/// Stream media constraints
@property (readonly) RTCMediaConstraints *mediaConstraints;

@end
