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
 
 Notice that if you don't not pass the `factory` from the room ECRoom instance that
 will be used to publish, it might not work. See ECRoom:peerFactory:
 
 @param mediaConstraints RTCMediaConstraints that apply to this stream.
 @param factory Shared factory from the ECRoom instance that you will use to publish.
 
 @return instancetype
 */
- (instancetype)initWithLocalStreamWithMediaConstraints:(RTCMediaConstraints *)mediaConstraints
                                 peerConnectionFactory:(RTCPeerConnectionFactory *)factory;

/**
 Creates an instance of ECStream capturing audio/video data
 from host device with default RTCMediaConstraints.

 @param factory Shared factory from the ECRoom instance that you will use to publish.
 
 @see initLocalStreamWithMediaConstraints:
 
 @return instancetype
 */
- (instancetype)initLocalStreamWithPeerConnectionFactory:(RTCPeerConnectionFactory *)factory;

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

///-----------------------------------
/// @name Properties
///-----------------------------------

/// RTCMediaStream object that represent the stream a/v data.
@property RTCMediaStream *mediaStream;
/// Erizo stream id.
@property (readonly) NSString *streamId;

@end
