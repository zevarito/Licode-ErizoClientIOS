//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import <Foundation/Foundation.h>

@class RTCSessionDescription;

@interface SDPUtils : NSObject

// Updates the original SDP description to instead prefer the specified video
// codec. We do this by placing the specified codec at the beginning of the
// codec list if it exists in the sdp.
+ (RTCSessionDescription *)
descriptionForDescription:(RTCSessionDescription *)description
preferredVideoCodec:(NSString *)codec;

@end