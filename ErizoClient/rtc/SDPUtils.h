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

/// Updates the original SDP description to instead prefer the specified video
/// codec. We do this by placing the specified codec at the beginning of the
/// codec list if it exists in the sdp.
+ (RTCSessionDescription *)descriptionForDescription:(RTCSessionDescription *)description
                                 preferredVideoCodec:(NSString *)codec;

/// Appends an SDP line after a regex matching existing line.
+ (RTCSessionDescription *)descriptionForDescription:(RTCSessionDescription *)description
                                        appendingLine:(NSString *)line
                                        afterRegexString:(NSString *)regexStr;

/// If `b=` is not defined adds `b=AS:{bandwidthLimit}` for the given media type.
+ (RTCSessionDescription *)descriptionForDescription:(RTCSessionDescription *)description
                                       bandwidthLimit:(NSInteger)bandwidthLimit
                                         forMediaType:(NSString *)mediaType;

/// Replace a matching SDP string regex template with a given new line string.
+ (RTCSessionDescription *)descriptionForDescription:(RTCSessionDescription *)description
                                  matchingPatternStr:(NSString *)matchingPatternStr
                                     replaceWithLine:(NSString *)replacementLine;

+ (RTCSessionDescription *)descriptionForDescription:(RTCSessionDescription *)description
                                       codecMimeType:(const NSString *)codec
                                          fmtpString:(NSString *)fmtpString
                                    preserveExistent:(BOOL)preserveExistent;
@end
