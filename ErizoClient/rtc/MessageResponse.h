//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ECMessageResultType) {
    kECMessageResultTypeUnknown,
    kECMessageResultTypeSuccess,
    kECMessageResultTypeInvalidRoom,
    kECMessageResultTypeInvalidClient
};

@interface MessageResponse : NSObject

@property(nonatomic, readonly) ECMessageResultType result;

+ (MessageResponse *)responseFromJSONData:(NSData *)data;

@end
