//
//  LicodeServer.m
//  ECIExample
//
//  Created by Alvaro Gil on 9/4/15.
//  Copyright (c) 2015 Alvaro Gil. All rights reserved.
//

#import "LicodeServer.h"

static const NSString *kLicodeServerURLString = @"https://chotis2.dit.upm.es/token";

@implementation LicodeServer

- (void)obtainMultiVideoConferenceToken:(NSString *)username {
    NSDictionary *postData = @{
                               role: "presenter"
                               roomId: "52820ce37fe4cd3764000001"
                               username: username
                               };
    NSMutableURLRequest *request = [self buildRequest:kLicodeServerURLString method:@"POST" postData:postData];
}

# pragma mark - Private

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
