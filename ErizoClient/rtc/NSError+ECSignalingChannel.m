//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import "NSError+ECSignalingChannel.h"

NSString * const ECSignalingChannelErrorDomain = @"ECSignalingChannelErrorDomain";

@implementation NSError (ECSignalingChannel)

+ (instancetype)ECSignalingChannelConnectErrorWithMessage:(NSString *)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage code:0];
}

+ (instancetype)ECSignalingChannelPublishErrorWithMessage:(NSString *)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage code:0];
}

+ (instancetype)ECSignalingChannelUnpublishErrorWithMessage:(NSString *)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage code:0];
}

+ (instancetype)ECSignalingChannelSubscribeErrorWith:(NSString *)streamId withMessage:(NSString *)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage code:0];
}

+ (instancetype)ECSignalingChannelUnsubscribeErrorWith:(NSString *)streamId withMessage:(NSString *)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage code:0];
}

+ (instancetype)ECSignalingChannelSendTokenErrorWithMessage:(NSString *)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage code:0];
}

+ (instancetype)ECSignalingChannelWebsocketErrorWithMessage:(NSString *)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage code:0];
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
