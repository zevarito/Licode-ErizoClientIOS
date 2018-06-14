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

NS_ASSUME_NONNULL_BEGIN

@interface NSError (ECSignalingChannel)

+ (instancetype)ECSignalingChannelConnectErrorWithMessage:(NSString *)errorMessage;
+ (instancetype)ECSignalingChannelPublishErrorWithMessage:(NSString *)errorMessage;
+ (instancetype)ECSignalingChannelUnpublishErrorWithMessage:(NSString *)errorMessage;
+ (instancetype)ECSignalingChannelSubscribeErrorWith:(NSString *)streamId withMessage:(NSString *)errorMessage;
+ (instancetype)ECSignalingChannelUnsubscribeErrorWith:(NSString *)streamId withMessage:(NSString *)errorMessage;
+ (instancetype)ECSignalingChannelSendTokenErrorWithMessage:(NSString *)errorMessage;
+ (instancetype)ECSignalingChannelWebsocketErrorWithMessage:(NSString *)errorMessage;

@end

NS_ASSUME_NONNULL_END
