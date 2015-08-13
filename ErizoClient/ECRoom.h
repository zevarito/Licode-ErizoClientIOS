//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import <Foundation/Foundation.h>
#import "ECClient.h"
#import "ECStream.h"

@class ECRoom;
@class Client;

///-----------------------------------
/// @name Protocols
///-----------------------------------

@protocol RoomDelegate <NSObject>

- (void)appClient:(Client *)client didReceiveLocalVideoTrack:(RTCVideoTrack *)localVideoTrack;
- (void)didStreamAddedWithId:(NSString *)streamId;
- (void)didStartRecordingStreamId:(NSString *)streamId withRecordingId:(NSString *)recordingId;

@end

///-----------------------------------
/// @name Interface Declaration
///-----------------------------------

@interface ECRoom : NSObject

///-----------------------------------
/// @name Initializers
///-----------------------------------

/**
 Create a *ECRoom* instance with a given *Licode* token.
 
 Encoded token sample:
 
    {
        @"tokenId":@"559ee50ec55db4935dd0d865",
        @"host":@"example.com:443",
        @"secure":@TRUE,
        @"signature":@"MDA3MDQxZTZkMWZlOWIwNTA0NmYzZjU1NmIzODQyNWUzNzIyZTJhOA=="
    }
 
 @param encodedToken Base64 encoded string.
 */
- (instancetype)initWithEncodedToken:(NSString *)encodedToken delegate:(id<RoomDelegate>)delegate;
- (instancetype)initWithDelegate: (id<RoomDelegate>)roomDelegate;

///-----------------------------------
/// @name Properties
///-----------------------------------

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
