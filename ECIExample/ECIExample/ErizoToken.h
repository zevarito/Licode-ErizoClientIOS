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

- (void)obtainWithStringURL:(NSString *)url
              requestMethod:(NSString *)method
      responseJSONNamespace:(NSString *)responseNamespace
          responseJSONField:(NSString *)responseField
                   postData:(NSDictionary *)postData
                 completion:(void(^)(BOOL result, NSString *token))completion;

@end
