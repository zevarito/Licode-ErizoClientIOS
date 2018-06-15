//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import "NSError+ECSignalingChannel.h"
#import "ECSignalingChannelErrorCode.h"

NSString * const ECSignalingChannelErrorDomain = @"ECSignalingChannelErrorDomain";

@implementation NSError (ECSignalingChannel)

+ (instancetype)ECSignalingChannelErrorCodeConnectWithMessage:(NSString *)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage code:ECSignalingChannelErrorCodeConnect];
}

+ (instancetype)ECSignalingChannelErrorCodePublishWithMessage:(NSString *)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage code:ECSignalingChannelErrorCodePublish];
}

+ (instancetype)ECSignalingChannelErrorCodeUnpublishWithMessage:(NSString *)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage code:ECSignalingChannelErrorCodeUnpublish];
}

+ (instancetype)ECSignalingChannelErrorCodeSubscribeWith:(NSString *)streamId withMessage:(NSString *)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage code:ECSignalingChannelErrorCodeSubscribe];
}

+ (instancetype)ECSignalingChannelErrorCodeUnsubscribeWith:(NSString *)streamId withMessage:(NSString *)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage code:ECSignalingChannelErrorCodeUnsubscribe];
}

+ (instancetype)ECSignalingChannelErrorCodeSendTokenWithMessage:(NSString *)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage code:ECSignalingChannelErrorCodeSendToken];
}

+ (instancetype)ECSignalingChannelErrorCodeWebsocketWithMessage:(NSString *)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage code:ECSignalingChannelErrorCodeWebsocket];
}

#pragma mark - Private Methods

+ (NSError *)ECSignalingChannelErrorWithErrorString:(NSString *)errorMessage code:(NSInteger)code {
    NSDictionary * userInfo = @{NSLocalizedDescriptionKey: errorMessage};
    NSError *error = [NSError errorWithDomain:ECSignalingChannelErrorDomain
                                         code:code
                                     userInfo:userInfo];
    return error;
}

@end
