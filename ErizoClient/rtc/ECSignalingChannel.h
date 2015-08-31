//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import "SocketIO.h"
#import "SocketIOPacket.h"
#import "ECSignalingMessage.h"

@class ECSignalingChannel;

///-----------------------------------
/// @protocol ECSignalingChannelDelegate
///-----------------------------------

@protocol ECSignalingChannelDelegate

/**
 Event fired when Erizo server has validated our token.
 
 @param signalingChannel ECSignalingChannel the channel that emit the message.
 */
- (void)signalingChannelDidOpenChannel:(ECSignalingChannel *)signalingChannel;

/**
 Event fired when Erizo server send to us configuration like Stun/Turn servers, Video BW limits etc.
 
 @param channel ECSignalingChannel the channel that emit the message.
 @param serverConfiguration NSDictionary * dictionary representing Erizo configuration.
 */
- (void)signalingChannel:(ECSignalingChannel *)channel didReceiveServerConfiguration:(NSDictionary *)serverConfiguration;

/**
 Event fired each time ECSignalingChannel has received a new ECSignalingMessage.
 
 @param channel ECSignalingChannel the channel that emit the message.
 @param message ECSignalingMessage received by channel.
 */
- (void)signalingChannel:(ECSignalingChannel *)channel didReceiveMessage:(ECSignalingMessage *)message;

/**
 Event fired when Erizo is ready to receive a publishing stream.

 @param signalingChannel ECSignalingChannel the channel that emit the message.
 */
- (void)signalingChannel:(ECSignalingChannel *)signalingChannel readyToPublishStreamId:(NSString *)streamId;

/**
 Event fired each time ECSignalingChannel has received a confirmation from the server
 to subscribe a stream.
 This event is fired to let Client know that it can start signaling to subscribe the stream.
 
 @param channel ECSignalingChannel the channel that emit the message.
 @param streamId Id of the stream that will be subscribed.
 */
- (void)signalingChannel:(ECSignalingChannel *)channel readyToSubscribeStreamId:(NSString *)streamId;
@end

///-----------------------------------
/// @protocol ECSignalingChannelRoomDelegate
///-----------------------------------

@protocol ECSignalingChannelRoomDelegate

/**
 This event is fired when a token was not successfuly used.
 
 @param channel ECSignalingChannel the channel that emit the message.
 @param reason String of error returned by the server.
 */
- (void)signalingChannel:(ECSignalingChannel *)channel didError:(NSString *)reason;

/**
 Event fired as soon a client connect to a room.

 @param channel ECSignalingChannel the channel that emit the message.
 @param roomMeta Metadata associated to the room that the client just connect.
 */
- (void)signalingChannel:(ECSignalingChannel *)channel didConnectToRoom:(NSDictionary *)roomMeta;

/**
 Event fired when a new stream id has been created and server is ready
 to start publishing it.
 
 @param channel ECSignalingChannel the channel that emit the message.
 @param streamId NSString id of the stream that will be published.
 */
- (void)signalingChannel:(ECSignalingChannel *)channel didReceiveStreamIdReadyToPublish:(NSString *)streamId;

/**
 Event fired when a recording of a stream has started.
 
 @param channel ECSignalingChannel the channel that emit the message.
 @param streamId NSString id of the stream being recorded.
 @param recordingId NSString id of the recording id on Erizo server.
 */
- (void)signalingChannel:(ECSignalingChannel *)channel didStartRecordingStreamId:(NSString *)streamId
                                                                 withRecordingId:(NSString *)recordingId;

/**
 Event fired when a new StreamId has been added to a room.
 
 @param channel ECSignalingChannel the channel that emit the message.
 @param streamId NSString added to the room.
 */
- (void)signalingChannel:(ECSignalingChannel *)channel didStreamAddedWithId:(NSString *)streamId;

/**
 Event fired when a StreamId has been removed from a room.
 
 @param channel ECSignalingChannel the channel that emit the message.
 @param streamId NSString of the removed stream.
 */
- (void)signalingChannel:(ECSignalingChannel *)channel didStreamRemovedWithId:(NSString *)streamId;

@end

/**
 @interface ECSignalingChannel
 
 */
@interface ECSignalingChannel : NSObject

///-----------------------------------
/// @name Initializers
///-----------------------------------

/**
 Creates an instance of ECSignalingChannel.
 
 @param token NString * representing the encoded token to access a room.
 @param signalingDelegate ECSignalingChannelDelegate instance that will receive
        events related to RTC peer negotiation.
 @param roomDelegate ECSignalingChannelRoomDelegate instance that will receive
        events related to stream addition, recording started, etc.
 
 @return instancetype
 */
- (instancetype)initWithEncodedToken:(NSString *)token
                   signalingDelegate:(id<ECSignalingChannelDelegate>)signalingDelegate
                        roomDelegate:(id<ECSignalingChannelRoomDelegate>)roomDelegate;

///-----------------------------------
/// @name Properties
///-----------------------------------

/// ECSignalingChannelDelegate reference
@property (weak, nonatomic) id<ECSignalingChannelDelegate> signalingDelegate;

/// ECSignalingChannelRoomDelegate reference
@property (weak, nonatomic) id<ECSignalingChannelRoomDelegate> roomDelegate;


///-----------------------------------
/// @name Public Methods
///-----------------------------------

- (void)connect;
- (void)disconnect;
- (void)enqueueSignalingMessage:(ECSignalingMessage *)message;
- (void)sendSignalingMessage:(ECSignalingMessage *)message;
- (void)drainMessageQueue;
- (void)publish:(NSDictionary *)attributes;
- (void)subscribe:(NSString *)streamId;
- (void)unsubscribe:(NSString *)streamId;
- (void)startRecording:(NSString *)streamId;
    
@end
