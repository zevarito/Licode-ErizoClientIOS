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

/**
 ECRoomDelegate
 
 Will fire events related with ECRoom state change.
 */
@protocol ECRoomDelegate

/**
 Fired when server sent the streamId of the subscribed stream.
 
 @param room Instance of the room where event happen.
 @param stream The subscribed Stream object.
 
 */
- (void)room:(ECRoom *)room didSubscribeStream:(ECStream *)stream;

/**
 Fired when server sent the streamId of the published stream.
 
 @param room Instance of the room where event happen.
 @param didPublishStreamId String representing the Id of the stream being published.
 
 */
- (void)room:(ECRoom *)room didPublishStreamId:(NSString *)streamId;

/**
 Fired when server sent the recordingId of a stream being published and
 recorded.
 
 @param room Instance of the room where event happen.
 @param streamId String representing the Id of the stream being recorded.
 @param recordingId String representing the Id of the recording of the stream.
 
 */
- (void)room:(ECRoom *)room didStartRecordingStreamId:(NSString *)streamId
                                      withRecordingId:(NSString *)recordingId;

/**
 Fired when RTC client get ready to start signaling Erizo.
 
 @param room Instance of the room where event happen.
 @param client Instance of the client linked with this room.
 
 */
- (void)room:(ECRoom *)room didGetReady:(ECClient *)client;


/**
 Event fired as soon a client connect to a room.
 
 @param room Instance of the room where event happen.
 @param list The list of streams id that are publishing into the room.
 
 
     list = (
        {
            audio = true;
            data = 0;
            id = 268365939846262340;
            video = true;
        }
     );
 */
- (void)room:(ECRoom *)room didReceiveStreamsList:(NSArray *)list;

@end

///-----------------------------------
/// @name Interface Declaration
///-----------------------------------

/*
 Interface responsable of publshing/consuming streams in a given ECRoom.
 */
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
 publish/subscribe streams without first call method createSignalingChannelWithEncodedToken:
 method.
 @see createSignalingChannelWithEncodedToken:
 
 @param roomDelegate ECRoomDelegate instance for this room.
 
 @return instancetype
 */
- (instancetype)initWithDelegate:(id<ECRoomDelegate>)roomDelegate;

///-----------------------------------
/// @name Properties
///-----------------------------------

/// The Erizo room id for this room instance.
@property NSString *roomId;

/// ECRoomDelegate were this room will invoke methods as events.
@property (weak, nonatomic, readonly) id <ECRoomDelegate> delegate;

/// NSString stream id of the stream being published
@property (readonly) NSString *publishStreamId;

/// ECStream referencing the stream being published.
@property (weak, nonatomic, readonly) ECStream *publishStream;

/// BOOL set/get enable recording of the stream being published.
@property BOOL recordEnabled;

///-----------------------------------
/// @name Public Methods
///-----------------------------------

/**
 Creates a ECSignalingChannel instance using the given token.
 
 This method is **required** if you have instantiated ECRoom class without
 provided a token.
 
 @param encodedToken The auth token for room access. See initWithEncodedToken:
    for token composition details.
 
 @see initWithDelegate:
 */
- (void)createSignalingChannelWithEncodedToken:(NSString *)encodedToken;

/**
 Publishes a given ECStream with given options.
 
 @param stream The stream from where we will be publishing.
 @param options Dictionary with publishing options
 
        {
            data: BOOL // weather or not data should be enabled for this room.
        }
 
 */
- (void)publish:(ECStream *)stream withOptions:(NSDictionary *)options;
- (void)subscribe:(NSString *)streamId;

@end
