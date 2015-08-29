//
//  ErizoToken.h
//  ECIExample
//
//  Created by Alvaro Gil on 8/29/15.
//  Copyright (c) 2015 Alvaro Gil. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ErizoToken : NSObject

+ (instancetype)sharedInstance;
- (void)obtainWithCompletionHandler:(void(^)(BOOL result, NSString *token))completion;

@end
