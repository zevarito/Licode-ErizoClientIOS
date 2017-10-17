//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

@import WebRTC;
#import "ECSignalingMessage.h"
#import "ECSignalingEvent.h"
#import "ECClientDelegate.h"

@class ECSignalingChannel;

///-----------------------------------
/// @protocol ECSignalingChannelDelegate
///-----------------------------------

@protocol ECSignalingChannelDelegate <NSObject>

@property NSString *streamId;
@property NSString *peerSocketId;

/**
 Event fired when Erizo server has validated our token.
 
 @param signalingChannel ECSignalingChannel the channel that emit the message.
 */
- (void)signalingChannelDidOpenChannel:(ECSignalingChannel *)signalingChannel;

/**
 Event fired each time ECSignalingChannel has received a new ECSignalingMessage.
 
 @param channel ECSignalingChannel the channel that emit the message.
 @param message ECSignalingMessage received by channel.
 */
- (void)signalingChannel:(ECSignalingChannel *)channel didReceiveMessage:(ECSignalingMessage *)message;

/**
 Event fired when Erizo is ready to receive a publishing stream.

 @param signalingChannel ECSignalingChannel the channel that emit the message.
 @param peerSocketId Id of the socket in a p2p publishing without MCU. Pass nil if
        you are not setting a P2P room.
 */
- (void)signalingChannel:(ECSignalingChannel *)signalingChannel
  readyToPublishStreamId:(NSString *)streamId
            peerSocketId:(NSString *)peerSocketId;

/**
 Event fired when Erizo failed to publishing stream.
 
 @param signalingChannel ECSignalingChannel the channel that emit the message.
 */
- (void)signalingChannelPublishFailed:(ECSignalingChannel *)signalingChannel;

/**
 Event fired each time ECSignalingChannel has received a confirmation from the server
 to subscribe a stream.
 This event is fired to let Client know that it can start signaling to subscribe the stream.
 
 @param channel ECSignalingChannel the channel that emit the message.
 @param streamId Id of the stream that will be subscribed.
 @param peerSocketId pass nil if is MCU being used.
 */
- (void)signalingChannel:(ECSignalingChannel *)channel
readyToSubscribeStreamId:(NSString *)streamId
            peerSocketId:(NSString *)peerSocketId;

@end

///-----------------------------------
/// @protocol ECSignalingChannelRoomDelegate
///-----------------------------------

@protocol ECSignalingChannelRoomDelegate <NSObject>

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
 Event fired as soon as rtc channels were disconnected and websocket
 connection is about to be closed.
 
 @param channel ECSignalingChannel the channel that emit the message.
 @param roomMeta Metadata associated to the room that the client just connect.
 */
- (void)signalingChannel:(ECSignalingChannel *)channel didDisconnectOfRoom:(NSDictionary *)roomMeta;

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
 @param recordingDate NSDate when the server start to recording the stream.
 */
- (void)signalingChannel:(ECSignalingChannel *)channel didStartRecordingStreamId:(NSString *)streamId
                                                                 withRecordingId:(NSString *)recordingId
                                                                       recordingDate:(NSDate *)recordingDate;
/**
 Event fired when a recording of a stream has failed.
 
 @param channel ECSignalingChannel the channel that emit the message.
 @param streamId NSString id of the stream being recorded.
 @param errorMsg Error string sent from the server.
 */
- (void)signalingChannel:(ECSignalingChannel *)channel didFailStartRecordingStreamId:(NSString *)streamId
            withErrorMsg:(NSString *)errorMsg;

/**
 Event fired when a new StreamId has been added to a room.
 
 @param channel ECSignalingChannel the channel that emit the message.
 @param streamId NSString added to the room.
 @param event Event name and data carried
 */
- (void)signalingChannel:(ECSignalingChannel *)channel
    didStreamAddedWithId:(NSString *)streamId
                   event:(ECSignalingEvent *)event;

/**
 Event fired when a StreamId has been removed from a room, not necessary this
 stream has been consumed.
 
 @param channel ECSignalingChannel the channel that emit the message.
 @param streamId NSString of the removed stream.
 */
- (void)signalingChannel:(ECSignalingChannel *)channel didRemovedStreamId:(NSString *)streamId;

/**
 Event fired when a StreamId previously subscribed has been unsubscribed.
 
 @param channel ECSignalingChannel the channel that emit the message.
 @param streamId NSString of the unsubscribed stream.
 */
- (void)signalingChannel:(ECSignalingChannel *)channel didUnsubscribeStreamWithId:(NSString *)streamId;

/**
 Event fired when a published stream is being unpublished.

 @param channel ECSignalingChannel the channel that emit the message.
 @param streamId NSString of the stream being unpublished
 */
- (void)signalingChannel:(ECSignalingChannel *)channel didUnpublishStreamWithId:(NSString *)streamId;

/**
 Event fired when some peer request to subscribe to a given stream.

 @param channel ECSignalingChannel the channel that emit the message.
 @param streamId NSString of the unsubscribed stream.
 @param peerSocketId String that identifies the peer connection for the stream.

 */
- (void)signalingChannel:(ECSignalingChannel *)channel didRequestPublishP2PStreamWithId:(NSString *)streamId
                                                                        peerSocketId:(NSString *)peerSocketId;

/**
 Method called when the signaling channels needs a new client to operate a connection.

 @param channel ECSignalingChannel the channel that emit the message.

 @returns ECClientDelegate instance.
 */
- (id<ECSignalingChannelDelegate>)clientDelegateRequiredForSignalingChannel:(ECSignalingChannel *)channel;

/**
 Event fired when data stream received.
 
 @param channel ECSignalingChannel the channel that emit the message.
 @param streamId NSString id of the stream received from.
 @param dataStream NSDictionary having message and timestamp.
 */
- (void)signalingChannel:(ECSignalingChannel *)channel
            fromStreamId:(NSString *)streamId
	  receivedDataStream:(NSDictionary *)dataStream;

/**
 Event fired when stream atrribute updated.
 
 @param channel ECSignalingChannel the channel that emit the message.
 @param streamId NSString id of the stream received from.
 @param attributes NSDictionary having custom attribute.
 */
- (void)signalingChannel:(ECSignalingChannel *)channel
            fromStreamId:(NSString *)streamId
   updateStreamAttributes:(NSDictionary *)attributes;

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
 
 @param token The encoded token to access a room.
 @param roomDelegate ECSignalingChannelRoomDelegate instance that will receive
        events related to stream addition, recording started, etc.
 
 @return instancetype
 */
- (instancetype)initWithEncodedToken:(NSString *)token
                        roomDelegate:(id<ECSignalingChannelRoomDelegate>)roomDelegate
                      clientDelegate:(id<ECClientDelegate>)clientDelegate;

///-----------------------------------
/// @name Properties
///-----------------------------------

/// ECSignalingChannelRoomDelegate reference
@property (weak, nonatomic) id<ECSignalingChannelRoomDelegate> roomDelegate;


///-----------------------------------
/// @name Public Methods
///-----------------------------------

- (void)connect;
- (void)disconnect;
- (void)enqueueSignalingMessage:(ECSignalingMessage *)message;
- (void)sendSignalingMessage:(ECSignalingMessage *)message;
- (void)drainMessageQueueForStreamId:(NSString *)streamId
                        peerSocketId:(NSString *)peerSocketId;
- (void)publish:(NSDictionary *)options
            signalingChannelDelegate:(id<ECSignalingChannelDelegate>)delegate;
- (void)unpublish:(NSString *)streamId
            signalingChannelDelegate:(id<ECSignalingChannelDelegate>)delegate;
- (void)publishToPeerID:(NSString *)peerSocketId
            signalingChannelDelegate:(id<ECSignalingChannelDelegate>)delegate;
- (void)subscribe:(NSString *)streamId
    streamOptions:(NSDictionary *)streamOptions
signalingChannelDelegate:(id<ECSignalingChannelDelegate>)delegate;
- (void)unsubscribe:(NSString *)streamId;
- (void)startRecording:(NSString *)streamId;
    
- (void)sendDataStream:(ECSignalingMessage *)message;
- (void)updateStreamAttributes:(ECSignalingMessage *)message;

@end
