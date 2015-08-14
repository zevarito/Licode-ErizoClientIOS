//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import <Foundation/Foundation.h>

#import "ECClient.h"
#import "ECSignalingChannel.h"
#import "ECStream.h"

@class ECRoom;
@class Client;

///-----------------------------------
/// @name Protocols
///-----------------------------------

@protocol ECRoomDelegate

- (void)room:(ECRoom *)room didPublishStreamId:(NSString *)streamId;
- (void)room:(ECRoom *)room didStartRecordingStreamId:(NSString *)streamId
                                      withRecordingId:(NSString *)recordingId;

@end

///-----------------------------------
/// @name Interface Declaration
///-----------------------------------

@interface ECRoom : NSObject <ECSignalingChannelRoomDelegate, ECClientDelegate>

///-----------------------------------
/// @name Initializers
///-----------------------------------

/**
 Create a ECRoom instance with a given *Licode* token and ECRoomDelegate.
 
 Encoded token sample:
 
    {
        @"tokenId":@"559ee50ec55db4935dd0d865",
        @"host":@"example.com:443",
        @"secure":@TRUE,
        @"signature":@"MDA3MDQxZTZkMWZlOWIwNTA0NmYzZjU1NmIzODQyNWUzNzIyZTJhOA=="
    }
 
 @param encodedToken Base64 encoded string.
 @param delegate ECRoomDelegate instance for this room.
 
 @return instancetype
 
 */
- (instancetype)initWithEncodedToken:(NSString *)encodedToken delegate:(id<ECRoomDelegate>)delegate;

/**
 Create an ECRoom with the given ECRoomDelegate.
 
 Notice that if initialize ECRoom like this, you will never be able to
 publish/subscribe streams without first call *createSignalingChannelWithEncodedToken*
 method.
 
 @see createSignalingChannelWithEncodedToken method.
 
 @param roomDelegate ECRoomDelegate instance for this room.
 
 @return instancetype
 */
- (instancetype)initWithDelegate:(id<ECRoomDelegate>)roomDelegate;

///-----------------------------------
/// @name Properties
///-----------------------------------

@property (weak, nonatomic) id <ECRoomDelegate> delegate;
@property BOOL recordEnabled;
@property BOOL isConnected;
@property NSDictionary *licodeConfig;
@property NSString *publishStreamId;
@property ECStream *publishStream;

///-----------------------------------
/// @name Public Methods
///-----------------------------------

- (void)createSignalingChannelWithEncodedToken:(NSString *)encodedToken;
- (void)publish:(ECStream *)stream withOptions:(NSDictionary *)options;

@end
