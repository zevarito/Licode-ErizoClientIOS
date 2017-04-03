//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

@import WebRTC;
#import <Foundation/Foundation.h>
#import "ECClient.h"
#import "ECSignalingChannel.h"
#import "ECStream.h"
#import "ECRoomStatsProtocol.h"

@class ECRoom;
@class Client;

/**
 @enum ECRoomStatus
 */
typedef NS_ENUM(NSInteger, ECRoomStatus) {
    ECRoomStatusReady,
    ECRoomStatusConnected,
    ECRoomStatusDisconnected,
    ECRoomStatusError
};

/**
 @enum ECRoomErrorStatus
 */
typedef NS_ENUM(NSInteger, ECRoomErrorStatus) {
    ECRoomUnknownError,
    ECRoomClientFailedSDP,
    ECRoomConnectionError
};

///-----------------------------------
/// @name Protocols
///-----------------------------------

/**
 ECRoomDelegate
 
 Will fire events related with ECRoom state change.
 */
@protocol ECRoomDelegate <NSObject>

/**
 Fired when server sent the streamId of the subscribed stream.
 
 @param room Instance of the room where event happen.
 @param stream The subscribed Stream object.
 
 */
- (void)room:(ECRoom *)room didSubscribeStream:(ECStream *)stream;

/**
 Fired when server has succesfully unsubscribed a stream.
 
 @param room Instance of the room where event happen.
 @param stream The unSubscribed Stream object.
 
 */
- (void)room:(ECRoom *)room didUnSubscribeStream:(NSString *)streamId;

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
 @param recordingDate moment when the server started to record the stream.
 
 */
- (void)room:(ECRoom *)room didStartRecordingStreamId:(NSString *)streamId
                                      withRecordingId:(NSString *)recordingId
                                        recordingDate:(NSDate *)recordingDate;
/**
 Fired when server failed to start recording the stream.
 
 @param room Instance of the room where event happen.
 @param streamId String representing the Id of the stream being recorded.
 @param errorMsg The error message sent by the server.
 
 */
- (void)room:(ECRoom *)room didFailStartRecordingStreamId:(NSString *)streamId
                                             withErrorMsg:(NSString *)errorMsg;

/**
 Fired when signaling channel connected with Erizo Room.
 
 @param room Instance of the room where event happen.
 
 */
- (void)room:(ECRoom *)room didConnect:(NSDictionary *)roomMetadata;

/**
 Fired each time there is an error with the room
 
 @param room Instance of the room where event happen.
 @param error Status constant
 @param reason Text explaining the error. (Not always available)
 
 */
- (void)room:(ECRoom *)room didError:(ECRoomErrorStatus)status reason:(NSString *)reason;

/**
 Fired each time the room changed his state.
 
 @param room Instance of the room where event happen.
 @param status ECRoomStatus value.
 
 */
- (void)room:(ECRoom *)room didChangeStatus:(ECRoomStatus)status;

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

/**
 Event fired once a new stream has been added to the room.
 
 It is up to you to subscribe that stream or not.
 It is worth to notice that your published stream will not be notified
 by this method, use ECRoomDelegate:didPublishStreamId: instead.
 
 @param room Instance of the room where event happen.
 @param sreamId The stream id of the added stream.
 
 */
- (void)room:(ECRoom *)room didAddedStreamId:(NSString *)streamId;

/**
 Fired when a stream in a room has been removed, not necessary the
 stream was being consumed.
 
 @param room Instance of the room where event happen.
 @param stream The id of the removed stream.
 
 */
- (void)room:(ECRoom *)room didRemovedStreamId:(NSString *)streamId;

/**
 Fired when a data stream is received.
 
 @param room Instance of the room where event happen.
 @param stream The id received from.
 @param data stream message received.
 
 */
- (void)room:(ECRoom *)room fromStreamId:(NSString *)streamId receivedDataStream:(NSDictionary *)dataStream;

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
 @param factory RTCPeerConnectionFactory instance for this room.
 
 @return instancetype
 
 */
- (instancetype)initWithEncodedToken:(NSString *)encodedToken delegate:(id<ECRoomDelegate>)delegate
                      andPeerFactory:(RTCPeerConnectionFactory *)factory;

/**
 Create an ECRoom with the given ECRoomDelegate.
 
 Notice that if initialize ECRoom like this, you will never be able to
 publish/subscribe streams without first call method createSignalingChannelWithEncodedToken:
 method.
 @see createSignalingChannelWithEncodedToken:
 
 @param roomDelegate ECRoomDelegate instance for this room.
 @param factory RTCPeerConnectionFactory instance for this room.
 
 @return instancetype
 */
- (instancetype)initWithDelegate:(id<ECRoomDelegate>)roomDelegate
                  andPeerFactory:(RTCPeerConnectionFactory *)factory;

///-----------------------------------
/// @name Properties
///-----------------------------------

/// ECRoomDelegate were this room will invoke methods as events.
@property (weak, nonatomic, readonly) id <ECRoomDelegate> delegate;

/// ECRoomStatsDelegate delegate to receive stats.
/// Notice that you should also set *publishingStats* to YES.
@property (weak, nonatomic) id <ECRoomStatsDelegate> statsDelegate;

/// The status of this Room.
@property (nonatomic, readonly) ECRoomStatus status;

/// Contents full responde after signalling channel connect the server.
@property NSDictionary *roomMetadata;

/// The Erizo room id for this room instance.
@property NSString *roomId;

/// NSString stream id of the stream being published
@property (readonly) NSString *publishStreamId;

/// ECStream referencing the stream being published.
@property (weak, readonly) ECStream *publishStream;

/// BOOL set/get enable recording of the stream being published.
@property BOOL recordEnabled;

/// BOOL is P2P kind of room.
@property (readonly) BOOL peerToPeerRoom;

/// RTC Factory shared by streams of this room.
@property RTCPeerConnectionFactory *peerFactory;

/// BOOL enable/disable log publishing stats.
/// Stats are collected each 2 seconds max, having this flag on produces
/// console output, take a look to ECRoomStatsDelegate to being able
/// to receive events when stats are collected.
@property BOOL publishingStats;

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
            state: p2p // pass this key/value if you want to start a p2p stream.
        }
 
 Notice that starting a p2p streams requiere `recordEnabled` flag to be set FALSE.

 */
- (void)publish:(ECStream *)stream withOptions:(NSDictionary *)options;

/**
 Subscribe to a remote stream.
 
 @param streamId The id of the stream you want to subscribe
 
 You should be connected to the room before subscribing to a stream.
 To know how to get streams ids take a look at the following methods:
 @see ECRoomDelegate:didReceiveStreamsList
 @see ECRoomDelegate:didAddedStream

 */
- (void)subscribe:(NSString *)streamId;

/**
 Unsubscribe from a remote stream.
 
 @param streamId The id of the stream you want to unsubscribe.
 @see ECRoomDelegate:didUnSubscribeStream
 */
- (void)unsubscribe:(NSString *)streamId;

/**
 Leave the room.
 
 RTC and WS connections will be closed.
 */
- (void)leave;

/**
 Send data stream on channel
 
 data Dictionary.
 */
- (BOOL)sendData:(NSDictionary *)data;

@end
