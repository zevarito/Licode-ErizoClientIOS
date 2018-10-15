//
//  LicodeServer.m
//  ECIExample
//
//  Created by Alvaro Gil on 9/4/15.
//  Copyright (c) 2015 Alvaro Gil. All rights reserved.
//

#import "LicodeServer.h"
#import "Logger.h"

@interface NSURLRequest (DummyInterface)
	+(void)setAllowsAnyHTTPSCertificate:(BOOL) allow forHost:(NSString*) host;
@end

static NSString *kLicodeServerURLString = @"https://chotis2.dit.upm.es/token";
static NSString *kLicodeRoomId = @"57ced7acb831f12276f1afcc";
static NSString *kLicodeServerTokenJSONNameSpace = @"";
static NSString *kLicodeServerTokenJSONField = @"";

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
							   @"mediaConfiguration": @"default",
							   @"role": @"presenter",
							   @"room": @"basicExampleRoom",
							   @"type": @"erizo",
							   @"username": username
							   };
	NSMutableURLRequest *request = [self buildRequest:kLicodeServerURLString method:@"POST" postData:postData];
	
    NSURL* url = [NSURL URLWithString:kLicodeServerURLString];
	[NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:[url host]];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
								if (!connectionError) {
									NSString *token = nil;

									if (kLicodeServerTokenJSONField.length) {
										token = [self parseResponse:data
													tokenNamespace:kLicodeServerTokenJSONNameSpace
													tokenField:kLicodeServerTokenJSONField
													autoConsumeArrays:TRUE];
									} else {
									   token = [self parseResponse:data];
									}

								   if (token) {
									   L_INFO(@"Erizo Token: %@", token);
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

- (NSString *)parseResponse:(NSData *)data tokenNamespace:(NSString *)tokenNamespace
				 tokenField:(NSString *)tokenField autoConsumeArrays:(BOOL)consumeArrays {
	NSError *jsonParseError = nil;
	id object = [NSJSONSerialization
				 JSONObjectWithData:data
				 options:0
				 error:&jsonParseError];
	
	if (!jsonParseError) {
		L_INFO(@"JSON parsed: %@", object);
		
		if (consumeArrays && [object isKindOfClass:[NSArray class]]) {
			L_INFO(@"Autoconsumed array response when parsing token!");
			object = [object objectAtIndex:0];
		} else if (consumeArrays && [object isKindOfClass:[NSDictionary class]]) {
			L_INFO(@"Autoconsumed array response when parsing token!");
			object = [object objectForKey:@"token"];
			return object;
		}
		
		if ([tokenNamespace isEqualToString:@""]) {
			return [object objectForKey:tokenField];
		} else {
			return [[object objectForKey:tokenNamespace] objectForKey:tokenField];
		}
	} else {
		L_ERROR(@"Error parsing JSON data %@", data);
		return nil;
	}
}


@end

