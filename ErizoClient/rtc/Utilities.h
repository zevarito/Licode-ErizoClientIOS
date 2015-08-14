//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Utilities)

+ (NSDictionary *)dictionaryWithJSONString:(NSString *)jsonString;
+ (NSDictionary *)dictionaryWithJSONData:(NSData *)jsonData;

@end