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
NSString * const ECSignalingChannelErrorUserInfoKeyStreamId = @"streamId";

@implementation NSError (ECSignalingChannel)

+ (instancetype)ECSignalingChannelErrorCodeConnectWithMessage:(NSString *)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage code:ECSignalingChannelErrorCodeConnect];
}

+ (instancetype)ECSignalingChannelErrorCodePublishWithStreamId:(NSString *)streamId withMessage:(NSString * _Nullable)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage code:ECSignalingChannelErrorCodePublish];
}

+ (instancetype)ECSignalingChannelErrorCodeUnpublishWithStreamId:(NSString *)streamId withMessage:(NSString * _Nullable)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage code:ECSignalingChannelErrorCodeUnpublish];
}

+ (instancetype)ECSignalingChannelErrorCodeSubscribeWithStreamId:(NSString *)streamId withMessage:(NSString * _Nullable)errorMessage {
    return [NSError ECSignalingChannelErrorWithErrorString:errorMessage streamId:streamId code:ECSignalingChannelErrorCodeSubscribe];
}

+ (instancetype)ECSignalingChannelErrorCodeUnsubscribeWithStreamId:(NSString *)streamId withMessage:(NSString * _Nullable)errorMessage {
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
        [userInfo setObject:streamId forKey:ECSignalingChannelErrorUserInfoKeyStreamId];
    }
    NSError *error = [NSError errorWithDomain:ECSignalingChannelErrorDomain
                                         code:code
                                     userInfo:[userInfo copy]];
    return error;
}

@end
