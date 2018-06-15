//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import <Foundation/Foundation.h>
#import "ECStream.h"

FOUNDATION_EXPORT NSString * const ECSignalingChannelErrorDomain;
FOUNDATION_EXPORT NSString * const ECSignalingChannelErrorUserInfoKeyStreamId;

NS_ASSUME_NONNULL_BEGIN

@interface NSError (ECSignalingChannel)

+ (instancetype)ECSignalingChannelErrorCodeConnectWithMessage:(NSString *)errorMessage;
+ (instancetype)ECSignalingChannelErrorCodePublishWith:(NSString *)streamId withMessage:(NSString * _Nullable)errorMessage;
+ (instancetype)ECSignalingChannelErrorCodeUnpublishWith:(NSString *)streamId withMessage:(NSString * _Nullable)errorMessage;
+ (instancetype)ECSignalingChannelErrorCodeSubscribeWith:(NSString *)streamId withMessage:(NSString * _Nullable)errorMessage;
+ (instancetype)ECSignalingChannelErrorCodeUnsubscribeWith:(NSString *)streamId withMessage:(NSString * _Nullable)errorMessage;
+ (instancetype)ECSignalingChannelErrorCodeSendTokenWithMessage:(NSString *)errorMessage;
+ (instancetype)ECSignalingChannelErrorCodeWebsocketWithMessage:(NSString *)errorMessage;

@end

NS_ASSUME_NONNULL_END
