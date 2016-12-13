//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

@import WebRTC;
#import "ErizoClient.h"
#import "rtc/ECClient.h"

@implementation ErizoClient

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
#ifdef DEBUG
        RTCSetMinDebugLogLevel(RTCLoggingSeverityInfo);
#endif
        RTCInitializeSSL();
        [ECClient setPreferredVideoCodec:@"VP8"];
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

@end
