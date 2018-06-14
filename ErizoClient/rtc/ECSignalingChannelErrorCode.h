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
    ECSignalingChannelConnectError = 0,
    ECSignalingChannelPublishError = 1,
    ECSignalingChannelUnpublishError = 2,
    ECSignalingChannelSubscribeError = 3,
    ECSignalingChannelUnsubscribeError = 4,
    ECSignalingChannelSendTokenError = 5,
    ECSignalingChannelWebsocketError = 6,
};

#endif /* ECSignalingChannelErrorCode_h */
