//
//  LicodeServer.h
//  ECIExample
//
//  Created by Alvaro Gil on 9/4/15.
//  Copyright (c) 2015 Alvaro Gil. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LicodeServer : NSObject

+ (instancetype)sharedInstance;

- (void)obtainMultiVideoConferenceToken:(NSString *)username
                             completion:(void(^)(BOOL result, NSString *token))completion;

@end
