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

@interface ECStream: NSObject

///-----------------------------------
/// @name Initializers
///-----------------------------------

/**
 Creates an instance of ECStream capturing audio/video data
 from host device.
 
 You can pass *nil* to *mediaConstraints* and default media
 constraints will be used.
 
 @param mediaConstraints RTCMediaConstraints that apply to this stream.
 
 @return instancetype
 */
- (instancetype)initWithLocalStream:(RTCMediaConstraints *)mediaConstraints;

///-----------------------------------
/// @name Properties
///-----------------------------------

/// @return RTCMediaStream object that represent the stream a/v data.
@property RTCMediaStream *stream;

///-----------------------------------
/// @name Instance Methods
///-----------------------------------

- (RTCMediaStream *)createLocalStream:(RTCMediaConstraints *)mediaConstraints;

@end
