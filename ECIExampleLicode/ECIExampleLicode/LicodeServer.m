//
//  LicodeServer.m
//  ECIExample
//
//  Created by Alvaro Gil on 9/4/15.
//  Copyright (c) 2015 Alvaro Gil. All rights reserved.
//

#import "LicodeServer.h"

@interface NSURLRequest (DummyInterface)
	+(void)setAllowsAnyHTTPSCertificate:(BOOL) allow forHost:(NSString*) host;
@end

//static NSString *kLicodeServerURLString = @"https://demowebrtc.claryicon.com:3004/api/rooms/570fb06865c8b4270ca45f13?userName=user&userRole=presenter";
//static NSString *kLicodeServerURLString = @"https://chotis2.dit.upm.es/token";
//static NSString *kLicodeServerTokenJSONNameSpace = @"data";
//static NSString *kLicodeServerTokenJSONField = @"token";

static NSString *kLicodeServerURLString = @"https://chotis2.dit.upm.es/token";
//static NSString *kLicodeServerURLString = @"https://192.168.1.4:3004/createToken";
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
							   @"role": @"presenter",
							   @"roomId":@"56bb46efc61d88361edb4dc6",
//							   @"roomId":@"573de5361549c12fa0a673f3",
							   @"username":username
							   };
	NSMutableURLRequest *request = [self buildRequest:kLicodeServerURLString method:@"POST" postData:postData];
	
    //NSDictionary *postData = @{
    //                           @"role": @"presenter",
    //                           @"roomId":@"52820ce37fe4cd3764000001",
    //                           @"username":username
    //                           };
    //NSMutableURLRequest *request = [self buildRequest:kLicodeServerURLString method:@"GET" postData:nil];
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


@end

