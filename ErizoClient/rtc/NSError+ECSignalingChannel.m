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

+ (instancetype)ECSignalingChannelErrorCodeSubscribeWith:(NSString *)streamId withMessage:(NSString * _Nullable)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage streamId:streamId code:ECSignalingChannelErrorCodeSubscribe];
}

+ (instancetype)ECSignalingChannelErrorCodeUnsubscribeWith:(NSString *)streamId withMessage:(NSString * _Nullable)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage streamId:streamId code:ECSignalingChannelErrorCodeUnsubscribe];
}

+ (instancetype)ECSignalingChannelErrorCodeSendTokenWithMessage:(NSString *)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage code:ECSignalingChannelErrorCodeSendToken];
}

+ (instancetype)ECSignalingChannelErrorCodeWebsocketWithMessage:(NSString *)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage code:ECSignalingChannelErrorCodeWebsocket];
}

#pragma mark - Private Methods

+ (NSError *)ECSignalingChannelErrorWithErrorString:(NSString *)errorMessage code:(NSInteger)code {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage streamId:nil code:code];
}

+ (NSError *)ECSignalingChannelErrorWithErrorString:(NSString *)errorMessage streamId:(NSString *)streamId code:(NSInteger)code {
    NSMutableDictionary * userInfo = [@{NSLocalizedDescriptionKey: errorMessage} mutableCopy];
    if (streamId) {
        [userInfo setObject:streamId forKey:@"streamId"];
    }
    NSError *error = [NSError errorWithDomain:ECSignalingChannelErrorDomain
                                         code:code
                                     userInfo:[userInfo copy]];
    return error;
}

@end
