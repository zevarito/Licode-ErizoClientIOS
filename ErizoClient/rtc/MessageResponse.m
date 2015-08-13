//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import "MessageResponse+Internal.h"

#import "Utilities.h"

static NSString const *kECMessageResultKey = @"result";

@implementation MessageResponse

@synthesize result = _result;

+ (MessageResponse *)responseFromJSONData:(NSData *)data {
    NSDictionary *responseJSON = [NSDictionary dictionaryWithJSONData:data];
    if (!responseJSON) {
        return nil;
    }
    MessageResponse *response = [[MessageResponse alloc] init];
    response.result =
    [[self class] resultTypeFromString:responseJSON[kECMessageResultKey]];
    return response;
}

#pragma mark - Private

+ (ECMessageResultType)resultTypeFromString:(NSString *)resultString {
    ECMessageResultType result = kECMessageResultTypeUnknown;
    if ([resultString isEqualToString:@"SUCCESS"]) {
        result = kECMessageResultTypeSuccess;
    } else if ([resultString isEqualToString:@"INVALID_CLIENT"]) {
        result = kECMessageResultTypeInvalidClient;
    } else if ([resultString isEqualToString:@"INVALID_ROOM"]) {
        result = kECMessageResultTypeInvalidRoom;
    }
    return result;
}

@end

