//
//  LicodeServer.m
//  ECIExample
//
//  Created by Alvaro Gil on 9/4/15.
//  Copyright (c) 2015 Alvaro Gil. All rights reserved.
//

#import "LicodeServer.h"

static NSString *kLicodeServerURLString = @"https://chotis2.dit.upm.es/token";

@implementation LicodeServer

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)obtainMultiVideoConferenceToken:(NSString *)username completion:(void (^)(BOOL, NSString *))completion {
    NSDictionary *postData = @{
                               @"role": @"presenter",
                               @"roomId":@"52820ce37fe4cd3764000001",
                               @"username":username
                               };
    NSMutableURLRequest *request = [self buildRequest:kLicodeServerURLString method:@"POST" postData:postData];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
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
    NSString* token = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return token;
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

