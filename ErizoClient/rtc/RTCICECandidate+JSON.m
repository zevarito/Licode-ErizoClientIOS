//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import "RTCIceCandidate+JSON.h"

static NSString const *kRTCIceCandidateTypeKey = @"type";
static NSString const *kRTCIceCandidateTypeValue = @"candidate";
static NSString const *kRTCIceCandidateMidKey = @"sdpMid";
static NSString const *kRTCIceCandidateMLineIndexKey = @"sdpMLineIndex";
static NSString const *kRTCIceCandidateSdpKey = @"candidate";

@implementation RTCIceCandidate (JSON)

+ (RTCIceCandidate *)candidateFromJSONDictionary:(NSDictionary *)dictionary {

    NSDictionary *candidate = dictionary[kRTCIceCandidateSdpKey];
    if (!candidate) {
        candidate = dictionary;
    }

    NSString *mid = candidate[kRTCIceCandidateMidKey];
    NSString *sdp = candidate[kRTCIceCandidateSdpKey];
    NSNumber *num = candidate[kRTCIceCandidateMLineIndexKey];
    NSInteger mLineIndex = [num integerValue];

    return [[RTCIceCandidate alloc] initWithSdp:sdp
                                  sdpMLineIndex:(int)mLineIndex
                                         sdpMid:mid];
}

- (NSData *)JSONData {
    NSDictionary *json = @{
                           kRTCIceCandidateTypeKey : kRTCIceCandidateTypeValue,
                           kRTCIceCandidateTypeValue: @{
                                   kRTCIceCandidateMLineIndexKey : @(self.sdpMLineIndex),
                                   kRTCIceCandidateMidKey : self.sdpMid,
                                   kRTCIceCandidateSdpKey : [NSString stringWithFormat:@"a=%@", self.sdp]
                                   }
                           };
    NSError *error = nil;
    NSData *data =
    [NSJSONSerialization dataWithJSONObject:json
                                    options:NSJSONWritingPrettyPrinted
                                      error:&error];
    if (error) {
        NSLog(@"Error serializing JSON: %@", error);
        return nil;
    }
    return data;
}

@end

