//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#ifndef ECSignalingChannelErrorCode_h
#define ECSignalingChannelErrorCode_h

typedef NS_ENUM(NSUInteger, ECSignalingChannelErrorCode) {
    ECSignalingChannelErrorCodeConnect = 0,
    ECSignalingChannelErrorCodePublish = 1,
    ECSignalingChannelErrorCodeUnpublish = 2,
    ECSignalingChannelErrorCodeSubscribe = 3,
    ECSignalingChannelErrorCodeUnsubscribe = 4,
    ECSignalingChannelErrorCodeSendToken = 5,
    ECSignalingChannelErrorCodeWebsocket = 6,
};

#endif /* ECSignalingChannelErrorCode_h */
