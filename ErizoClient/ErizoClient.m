//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import "ErizoClient.h"
#import "RTC/ECClient.h"
#import "RTCPeerConnectionFactory.h"
#import "RTCLogging.h"

@implementation ErizoClient

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
#ifdef DEBUG
        RTCSetMinDebugLogLevel(kRTCLoggingSeverityInfo);
#endif
        [RTCPeerConnectionFactory initializeSSL];
        [ECClient setPreferredVideoCodec:@"VP8"];
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

@end
