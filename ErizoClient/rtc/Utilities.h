//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Utilities)

// Creates a dictionary with the keys and values in the JSON object.
+ (NSDictionary *)dictionaryWithJSONString:(NSString *)jsonString;
+ (NSDictionary *)dictionaryWithJSONData:(NSData *)jsonData;

@end

@interface NSURLConnection (ECUtilities)

// Issues an asynchronous request that calls back on main queue.
+ (void)sendAsyncRequest:(NSURLRequest *)request
       completionHandler:(void (^)(NSURLResponse *response,
                                   NSData *data,
                                   NSError *error))completionHandler;

// Posts data to the specified URL.
+ (void)sendAsyncPostToURL:(NSURL *)url
                  withData:(NSData *)data
         completionHandler:(void (^)(BOOL succeeded,
                                     NSData *data))completionHandler;

@end