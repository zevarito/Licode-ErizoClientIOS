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

+ (instancetype)ECSignalingChannelConnectErrorWithMessage:(NSString *)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage code:ECSignalingChannelConnectError];
}

+ (instancetype)ECSignalingChannelPublishErrorWithMessage:(NSString *)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage code:ECSignalingChannelPublishError];
}

+ (instancetype)ECSignalingChannelUnpublishErrorWithMessage:(NSString *)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage code:ECSignalingChannelUnpublishError];
}

+ (instancetype)ECSignalingChannelSubscribeErrorWith:(NSString *)streamId withMessage:(NSString *)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage code:ECSignalingChannelSubscribeError];
}

+ (instancetype)ECSignalingChannelUnsubscribeErrorWith:(NSString *)streamId withMessage:(NSString *)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage code:ECSignalingChannelUnsubscribeError];
}

+ (instancetype)ECSignalingChannelSendTokenErrorWithMessage:(NSString *)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage code:ECSignalingChannelSendTokenError];
}

+ (instancetype)ECSignalingChannelWebsocketErrorWithMessage:(NSString *)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage code:ECSignalingChannelWebsocketError];
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
