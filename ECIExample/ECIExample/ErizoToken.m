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
        NSString *pListPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
        plistDictionary = [NSDictionary dictionaryWithContentsOfFile:pListPath];
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

- (void)obtainWithCompletionHandler:(void (^)(BOOL result, NSString *token))completion {
    
   
    [NSURLConnection sendAsynchronousRequest:[self buildRequest] queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (!connectionError) {
                                   NSString *token = [self parseResponse:data];
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

- (NSString *)parseResponse:(NSData *)data {
    
    NSError *jsonParseError = nil;
    NSDictionary *object = [NSJSONSerialization
                 JSONObjectWithData:data
                 options:0
                 error:&jsonParseError];
    
    if (!jsonParseError) {
        NSLog(@"JSON parsed: %@", object);
        
        NSString *tokenNamespace = [plistDictionary objectForKey:@"Erizo Token JSON Namespace"];
        NSString *tokenField = [plistDictionary objectForKey:@"Erizo Token JSON Field"];
        
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

- (NSMutableURLRequest *)buildRequest {
    
    NSURL *url = [NSURL URLWithString:[plistDictionary objectForKey:@"Erizo Token URL"]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
    
    NSDictionary * postData = [plistDictionary objectForKey:@"Erizo Token POST JSON"];
    if ([postData count] > 0) {
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSData * data = [NSJSONSerialization dataWithJSONObject:postData
                                                        options:NSJSONWritingPrettyPrinted error:nil];
        request.HTTPBody = data;
    }
    
    request.HTTPMethod = [plistDictionary objectForKey:@"Erizo Token Method"];
    
    return request;
}

@end
