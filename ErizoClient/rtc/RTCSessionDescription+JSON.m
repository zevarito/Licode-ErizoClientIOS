//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import "RTCSessionDescription+JSON.h"

static NSString const *kRTCSessionDescriptionTypeKey = @"type";
static NSString const *kRTCSessionDescriptionSdpKey = @"sdp";

@implementation RTCSessionDescription (JSON)

+ (RTCSessionDescription *)descriptionFromJSONDictionary:
(NSDictionary *)dictionary {
    NSString *type = dictionary[kRTCSessionDescriptionTypeKey];
    NSString *sdp = dictionary[kRTCSessionDescriptionSdpKey];
    return [[RTCSessionDescription alloc] initWithType:type sdp:sdp];
}

- (NSData *)JSONData {
    NSDictionary *json = @{
                           kRTCSessionDescriptionTypeKey : self.type,
                           kRTCSessionDescriptionSdpKey : self.description
                           };
    return [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
}

@end


