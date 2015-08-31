//
//  ErizoToken.m
//  ECIExample
//
//  Created by Alvaro Gil on 8/29/15.
//  Copyright (c) 2015 Alvaro Gil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ErizoToken.h"

@implementation ErizoToken {
    NSDictionary *plistDictionary;
}

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)obtainWithStringURL:(NSString *)url requestMethod:(NSString *)method
      responseJSONNamespace:(NSString *)responseNamespace
          responseJSONField:(NSString *)responseField
                   postData:(NSDictionary *)postData
                 completion:(void (^)(BOOL, NSString *))completion {
    
    NSMutableURLRequest *request = [self buildRequest:url
                                               method:method
                                               postData:postData];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (!connectionError) {
                                   NSString *token = [self parseResponse:data
                                                          tokenNamespace:responseNamespace
                                                              tokenField:responseField
                                                       autoConsumeArrays:TRUE];
                                   if (token) {
                                       NSLog(@"Erizo Token: %@", token);
                                       completion(TRUE, token);
                                   } else {
                                       completion(FALSE, nil);
                                   }
                               } else {
                                   completion(FALSE, nil);
                               }
    }];
}

# pragma mark - Private

- (NSString *)parseResponse:(NSData *)data tokenNamespace:(NSString *)tokenNamespace
                 tokenField:(NSString *)tokenField autoConsumeArrays:(BOOL)consumeArrays {
    
    NSError *jsonParseError = nil;
    id object = [NSJSONSerialization
                 JSONObjectWithData:data
                 options:0
                 error:&jsonParseError];
    
    if (!jsonParseError) {
        NSLog(@"JSON parsed: %@", object);
        
        if (consumeArrays && [object isKindOfClass:[NSArray class]]) {
            NSLog(@"Autoconsumed array response when parsing token!");
            object = [object objectAtIndex:0];
        }
        
        if ([tokenNamespace isEqualToString:@""]) {
            return [object objectForKey:tokenField];
        } else {
            return [[object objectForKey:tokenNamespace] objectForKey:tokenField];
        }
    } else {
        NSLog(@"Error parsing JSON data %@", data);
        return nil;
    }
}

- (NSMutableURLRequest *)buildRequest:(NSString *)urlString method:(NSString *)method postData:(NSDictionary *)postData {
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
    
    if ([postData count] > 0) {
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSData * data = [NSJSONSerialization dataWithJSONObject:postData
                                                        options:NSJSONWritingPrettyPrinted error:nil];
        request.HTTPBody = data;
    }
    
    request.HTTPMethod = method;
    
    return request;
}

@end
