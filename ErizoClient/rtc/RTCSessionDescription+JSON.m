//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

@import WebRTC;
#import "RTCSessionDescription+JSON.h"
#import "Logger.h"

static NSString const *kRTCSessionDescriptionTypeKey = @"type";
static NSString const *kRTCSessionDescriptionSdpKey = @"sdp";

@implementation RTCSessionDescription (JSON)

+ (RTCSessionDescription *)descriptionFromJSONDictionary:(NSDictionary *)dictionary {
    NSString *typeString = dictionary[kRTCSessionDescriptionTypeKey];
    RTCSdpType type = [RTCSessionDescription typeForString:typeString];
    NSString *sdp = dictionary[kRTCSessionDescriptionSdpKey];
    return [[RTCSessionDescription alloc] initWithType:type sdp:sdp];
}

- (NSData *)JSONData {
    NSString *type = [RTCSessionDescription stringForType:self.type];
    NSDictionary *json = @{
                           kRTCSessionDescriptionTypeKey : type,
                           kRTCSessionDescriptionSdpKey : self.sdp
                           };
    return [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
}

@end


