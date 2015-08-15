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
 
 Inmediatly attempt to acceess local audio/video.
 You can pass *nil* to *mediaConstraints* and default media
 constraints will be used.
 
 @param mediaConstraints RTCMediaConstraints that apply to this stream.
 
 @return instancetype
 */
- (instancetype)initWithLocalStreamAndMediaConstraints:(RTCMediaConstraints *)mediaConstraints;

/**
 Creates an instance of ECStream capturing audio/video data
 from host device.
 
 By default RTCMediaConstraints will be used.
 
 @see initLocalStreamWithMediaConstraints:
 
 @return instancetype
 */
- (instancetype)initWithLocalStream;

///-----------------------------------
/// @name Properties
///-----------------------------------

/// RTCMediaStream object that represent the stream a/v data.
@property (readonly) RTCMediaStream *stream;

@end
