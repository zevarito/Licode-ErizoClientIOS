//
//  Nuve.m
//  ECIExampleLicode
//
//  Created by Alvaro Gil on 3/6/17.
//  Copyright © 2017 Alvaro Gil. All rights reserved.
//

#import "Nuve.h"
#include <stdlib.h>
#include <CommonCrypto/CommonHMAC.h>

static NSString *kNuveHost          = nil;
static NSString *kNuveServiceId     = nil;
static NSString *kNuveServiceKey    = nil;

@implementation Nuve

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        NSAssert(kNuveHost, @"kNuvehost cannot be nil!");
        NSAssert(kNuveServiceId, @"kNuveServiceId cannot be nil!");
        NSAssert(kNuveServiceKey, @"kNuveServiceKey cannot be nil!");
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)listRoomsWithCompletion:(NuveListRoomsCallback)completion {
    NSString *endpoint = @"/rooms";
    NSString *authorizationHeader = [self authorizationHeaderForUserName:nil
                                                                    role:nil];

    [self performRequest:endpoint method:@"GET" postData:nil authorization:authorizationHeader
              completion:^(BOOL success, id data) {
                  if (success) {
                      completion(YES, data);
                  } else {
                      completion(NO, nil);
                  }
              }];
}

- (void)createRoom:(NSString *)roomName
          roomType:(RoomType)roomType
           options:(NSDictionary *)options
        completion:(NuveCreateRoomCallback)completion {
    NSAssert(roomName, @"You should provide a name for this room!");

    NSString *endpoint = @"/rooms";
    NSMutableDictionary *postData = [NSMutableDictionary dictionaryWithObject:roomName
                                                                       forKey:@"name"];
    if (options)
        [postData addEntriesFromDictionary:options];

    if (roomType == RoomTypeP2P)
        [postData setValue:@TRUE forKey:@"p2p"];

    NSString *authorizationHeader = [self authorizationHeaderForUserName:nil
                                                                    role:nil];

    [self performRequest:endpoint method:@"POST" postData:postData authorization:authorizationHeader
              completion:^(BOOL success, id data) {
        if (success) {
            NSString *roomId = [data objectForKey:@"_id"];
            BOOL p2p = [[data objectForKey:@"p2p"] boolValue];
            completion(YES, roomId, p2p);
        } else {
            completion(NO, nil, NO);
        }
    }];
}

- (void)createTokenForRoomId:(NSString *)roomId
                    username:(NSString *)username
                        role:(NSString *)role
                  completion:(NuveCreateTokenCallback)completion {
    NSAssert(roomId, @"You should provide a roomId!");
    NSAssert(username, @"You should provide username!");
    NSAssert(role, @"You should provide a role!");

    NSString *endpoint = [NSString stringWithFormat:@"/rooms/%@/tokens", roomId];
    NSString *authorizationHeader = [self authorizationHeaderForUserName:username
                                                                role:role];
    [self performRequest:endpoint method:@"POST" postData:nil authorization:authorizationHeader
              completion:^(BOOL success, id data) {
        if (success) {
            completion(YES, data);
        } else {
            completion(NO, nil);
        }
    }];
}

- (void)createTokenForTheFirstAvailableRoom:(NSString *)roomName
                                   roomType:(RoomType)roomType
                                   username:(NSString *)username
                                     create:(BOOL)create
                                 completion:(NuveCreateTokenCallback)completion {
    [[Nuve sharedInstance] listRoomsWithCompletion:^(BOOL success, NSArray *rooms) {
        if (success) {
            for (NSDictionary *room in rooms) {
                BOOL isP2P = [[room objectForKey:@"p2p"] boolValue];
                NSString *name = roomName ? [room objectForKey:@"name"] : nil;

                if (name == roomName && ((isP2P && roomType == RoomTypeP2P) ||
                                         (!isP2P && roomType == RoomTypeMCU))) {
                    [self createTokenForRoomId:[room objectForKey:@"_id"]
                                      username:username
                                          role:kLicodePresenterRole
                                    completion:completion];
                    return;
                }
            }
            if (create) {
                [self createRoomAndCreateToken:roomName
                                      roomType:roomType
                                      username:username
                                    completion:completion];
            } else {
                completion(false, nil);
            }
        } else {
            completion(false, nil);
        }
    }];
}

- (void)createRoomAndCreateToken:(NSString *)roomName
                        roomType:(RoomType)roomType
                        username:(NSString *)username
                      completion:(NuveCreateTokenCallback)completion {
    [[Nuve sharedInstance] createRoom:roomName
                             roomType:roomType
                              options:@{}
                           completion:^(BOOL success, NSString *roomId, BOOL p2p) {
                               [[Nuve sharedInstance] createTokenForRoomId:roomId
                                                                  username:username
                                                                      role:kLicodePresenterRole
                                                                completion:completion];
                           }];
}


# pragma Mark - Private


- (void)performRequest:(NSString *)path
                method:(NSString *)method
              postData:(NSDictionary *)postData
         authorization:(NSString *)authorization
            completion:(NuveHTTPCallback)completion {

    NSURL *url = [NSURL URLWithString:[kNuveHost stringByAppendingString:path]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    if ([postData count] > 0) {
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSData * data = [NSJSONSerialization dataWithJSONObject:postData
                                                        options:NSJSONWritingPrettyPrinted error:nil];
        request.HTTPBody = data;
    }

    request.HTTPMethod = method;

    [request addValue:authorization forHTTPHeaderField:@"Authorization"];

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                               if (!connectionError && httpResponse.statusCode >= 200 && httpResponse.statusCode <= 400) {
                                   completion(YES, [self parseResponse:data]);
                               } else {
                                   completion(NO, [self parseResponse:data]);
                               }
                           }];
}

- (id)parseResponse:(NSData *)data {
    NSString *parsedData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *firstCharacter = [parsedData substringWithRange:NSMakeRange(0, 1)];
    if ([firstCharacter isEqualToString:@"{"] || [firstCharacter isEqualToString:@"["]) {
        NSData *jsonData = [parsedData dataUsingEncoding:NSUnicodeStringEncoding];
        NSError *error;
        if (!error) {
            return [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
        } else {
            return nil;
        }
    } else {
        return parsedData;
    }
}

- (NSString *)signatureFor:(NSString *)stringToSign {
    return [self hmacsha1:stringToSign key:kNuveServiceKey];
}

- (NSString *)authorizationHeaderForUserName:(NSString *)username role:(NSString *)role {
    NSString *mAuth = @"MAuth realm=http://marte3.dit.upm.es,mauth_signature_method=HMAC_SHA1";

    NSInteger timestamp = [[NSDate date] timeIntervalSince1970];
    NSNumber *cNounce = [NSNumber numberWithInt:arc4random_uniform(99999)];

    NSString *timestampStr = [NSString stringWithFormat:@"%lu", (long)timestamp];
    NSString *cNounceStr = [NSString stringWithFormat:@"%@", cNounce];

    NSString *stringToSign = [NSString stringWithFormat:@"%@,%@",
                              timestampStr, cNounceStr];

    if (username && role) {
        NSString *userAndRole = [NSString stringWithFormat:@",%@,%@", username, role];
        stringToSign = [stringToSign stringByAppendingString:userAndRole];
    }

    NSString *signature = [self signatureFor:stringToSign];

    NSString *authorizationHeaderValue;

    if (username && role) {
        authorizationHeaderValue = [NSString stringWithFormat:@"%@,mauth_username=%@,mauth_role=%@,mauth_serviceid=%@,mauth_cnonce=%@,mauth_timestamp=%@,mauth_signature=%@", mAuth, username, role, kNuveServiceId, cNounceStr, timestampStr, signature];
    } else {
        authorizationHeaderValue = [NSString stringWithFormat:@"%@,mauth_serviceid=%@,mauth_cnonce=%@,mauth_timestamp=%@,mauth_signature=%@",
         mAuth, kNuveServiceId, cNounceStr, timestampStr, signature];
    }

    return authorizationHeaderValue;
}

- (NSString *)hmacsha1:(NSString *)text key:(NSString *)key {
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    NSData *textData = [text dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *hMacOut = [NSMutableData dataWithLength:CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, [keyData bytes], [keyData length], [textData bytes], [textData length], hMacOut.mutableBytes);

    NSString *hexString = @"";
    uint8_t *dataPointer = (uint8_t *)(hMacOut.bytes);
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        hexString = [hexString stringByAppendingFormat:@"%02x", dataPointer[i]];
    }

    NSString *base64EncodedResult = [[hexString dataUsingEncoding:NSUTF8StringEncoding]
                                        base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];

    return base64EncodedResult;
}

@end
