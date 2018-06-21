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

+ (instancetype)ECSignalingChannelConnectErrorWithMessage:(NSString *)errorMessage;
+ (instancetype)ECSignalingChannelPublishErrorWithStreamId:(NSString *)streamId withMessage:(NSString * _Nullable)errorMessage;
+ (instancetype)ECSignalingChannelUnpublishErrorWithStreamId:(NSString *)streamId withMessage:(NSString * _Nullable)errorMessage;
+ (instancetype)ECSignalingChannelSubscribeErrorWithStreamId:(NSString *)streamId withMessage:(NSString * _Nullable)errorMessage;
+ (instancetype)ECSignalingChannelUnsubscribeErrorWithStreamId:(NSString *)streamId withMessage:(NSString * _Nullable)errorMessage;
+ (instancetype)ECSignalingChannelSendTokenErrorWithMessage:(NSString *)errorMessage;
+ (instancetype)ECSignalingChannelWebsocketErrorWithMessage:(NSString *)errorMessage;

@end

NS_ASSUME_NONNULL_END
