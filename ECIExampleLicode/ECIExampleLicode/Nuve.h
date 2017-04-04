//
//  Nuve.h
//  ECIExampleLicode
//
//  Created by Alvaro Gil on 3/6/17.
//  Copyright © 2017 Alvaro Gil. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, RoomType) {
    RoomTypeP2P,
    RoomTypeMCU,
};

typedef void(^NuveHTTPCallback)(BOOL success, id data);
typedef void(^NuveCreateRoomCallback)(BOOL success, NSString *roomId, BOOL p2p);
typedef void(^NuveCreateTokenCallback)(BOOL success, NSString *token);
typedef void(^NuveListRoomsCallback)(BOOL success, NSArray *rooms);

static NSString *const kLicodePresenterRole = @"presenter";

@interface Nuve : NSObject

+ (instancetype)sharedInstance;

- (void)listRoomsWithCompletion:(NuveListRoomsCallback)completion;

- (void)createRoom:(NSString *)roomName
          roomType:(RoomType)roomType
           options:(NSDictionary *)options
        completion:(NuveCreateRoomCallback)completion;

- (void)createTokenForRoomId:(NSString *)roomId
                    username:(NSString *)username
                        role:(NSString *)role
                  completion:(NuveCreateTokenCallback)completion;

- (void)createTokenForTheFirstAvailableRoom:(NSString *)roomName
                                   roomType:(RoomType)roomType
                                   username:(NSString *)username
                                     create:(BOOL)create
                                 completion:(NuveCreateTokenCallback)completion;

- (void)createRoomAndCreateToken:(NSString *)roomName
                        roomType:(RoomType)roomType
                        username:(NSString *)username
                      completion:(NuveCreateTokenCallback)completion;

@end
