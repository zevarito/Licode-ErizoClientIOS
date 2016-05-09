//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import "ECRoom.h"
#import "ECStream.h"
#import "ECCLient.h"
#import "ECClient+Internal.h"
#import "ECSignalingChannel.h"

#import "RTCAVFoundationVideoSource.h"
#import "RTCMediaConstraints.h"
#import "RTCMediaStream.h"

#import "Logger.h"

@implementation ECRoom {
    ECSignalingChannel *signalingChannel;
    ECClient *publishClient;
    ECClient *subscribeClient;
}

- (instancetype)init {
    if (self = [super init]) {
        _recordEnabled = NO;
        if (_peerFactory) {
            _peerFactory = [[RTCPeerConnectionFactory alloc] init];
        }
        self.status = ECRoomStatusReady;
    }
    return self;
}

- (instancetype)initWithDelegate:(id<ECRoomDelegate>)roomDelegate
                  andPeerFactory:(nullable RTCPeerConnectionFactory *)factory {
    if (self = [self init]) {
        _delegate = roomDelegate;
        _peerFactory = factory;
        self.status = ECRoomStatusReady;
    }
    return self;
}

- (instancetype)initWithEncodedToken:(NSString *)encodedToken
                            delegate:(id<ECRoomDelegate>)delegate
                      andPeerFactory:(RTCPeerConnectionFactory *)factory {
    if (self = [self initWithDelegate:delegate andPeerFactory:factory]) {
        [self createSignalingChannelWithEncodedToken:encodedToken];
    }
    return self;
}

- (void)setStatus:(ECRoomStatus)status {
    _status = status;
    if ([self.delegate respondsToSelector:@selector(room:didChangeStatus:)]) {
        [self.delegate room:self didChangeStatus:status];
    }
}

- (void)createSignalingChannelWithEncodedToken:(NSString *)encodedToken {
    signalingChannel = [[ECSignalingChannel alloc] initWithEncodedToken:encodedToken
                                                           roomDelegate:self];
    [signalingChannel connect];
}

- (void)publish:(ECStream *)stream withOptions:(NSDictionary *)options {
    
	// Create a ECClient instance to handle peer connection for this publishing.
	// It is very important to use the same factory.
	publishClient = [[ECClient alloc] initWithDelegate:self
										andPeerFactory:stream.peerFactory];
	
	// Keep track of the stream that this room will be publishing
	_publishStream = stream;
	
	// Publishing options
	int videoCount = (int) stream.mediaStream.videoTracks.count;
	int audioCount = (int) stream.mediaStream.audioTracks.count;
	
	NSDictionary *opts = @{
						   @"video": videoCount > 0 ? @"true" : @"false",
						   @"audio": audioCount > 0 ? @"true" : @"false",
                           @"data": [options objectForKey:@"data"] ? [options objectForKey:@"data"] : @{},
                           @"attributes": [options objectForKey:@"attributes"] ? [options objectForKey:@"attributes"] : @"false",
						   };
	
	// Ask for publish
	[signalingChannel publish:opts signalingChannelDelegate:publishClient];
}

- (void)subscribe:(NSString *)streamId {
    // Create a ECClient instance to handle peer connection for this publishing.
    subscribeClient = [[ECClient alloc] initWithDelegate:self andPeerFactory:_peerFactory];
    
    // Ask for subscribing
    [signalingChannel subscribe:streamId signalingChannelDelegate:subscribeClient];
}

- (void)unsubscribe:(NSString *)streamId {
    [signalingChannel unsubscribe:streamId];
}

- (void)leave {
    [signalingChannel disconnect];
    
    if (subscribeClient) {
        [subscribeClient disconnect];
    }
}

#
# pragma mark - ECSignalingChannelRoomDelegate
#

- (void)signalingChannel:(ECSignalingChannel *)channel didError:(NSString *)reason {
    [_delegate room:self didError:ECRoomConnectionError reason:reason];
    self.status = ECRoomStatusError;
}

- (void)signalingChannel:(ECSignalingChannel *)channel didConnectToRoom:(NSDictionary *)roomMeta {
    NSString *roomId = [roomMeta objectForKey:@"id"];
    NSArray *streamIds = [roomMeta objectForKey:@"streams"];
    
    _roomId = roomId;
    
    [_delegate room:self didConnect:roomMeta];
    [_delegate room:self didReceiveStreamsList:streamIds];
    
    self.status = ECRoomStatusConnected;
}

- (void)signalingChannel:(ECSignalingChannel *)channel didDisconnectOfRoom:(NSDictionary *)roomMeta {
    self.status = ECRoomStatusDisconnected;
}

- (void)signalingChannel:(ECSignalingChannel *)channel didReceiveStreamIdReadyToPublish:(NSString *)streamId {
    L_DEBUG(@"Room: didReceiveStreamIdReadyToPublish streamId: %@", streamId);
    _publishStreamId = streamId;
}

- (void)signalingChannel:(ECSignalingChannel *)channel didStartRecordingStreamId:(NSString *)streamId
                                                                 withRecordingId:(NSString *)recordingId {
    [_delegate room:self didStartRecordingStreamId:streamId withRecordingId:recordingId];
}

- (void)signalingChannel:(ECSignalingChannel *)channel didStreamAddedWithId:(NSString *)streamId {
    if ([_publishStreamId isEqualToString:streamId]) {
        [_delegate room:self didPublishStreamId:streamId];
        if (_recordEnabled) {
            [signalingChannel startRecording:_publishStreamId];
        }
    } else {
        [_delegate room:self didAddedStreamId:streamId];
    }
}

- (void)signalingChannel:(ECSignalingChannel *)channel didStreamRemovedWithId:(NSString *)streamId {
    [_delegate room:self didRemovedStreamId:streamId];
}

- (void)signalingChannel:(ECSignalingChannel *)channel didUnsubscribeStreamWithId:(NSString *)streamId {
    [_delegate room:self didUnSubscribeStream:streamId];
}

#
# pragma mark - ECClientDelegate
#

- (void)appClient:(ECClient *)_client didChangeState:(ECClientState)state {
    L_INFO(@"Room: Client didChangeState: %@", clientStateToString(state));
}

- (void)appClient:(ECClient *)client didChangeConnectionState:(RTCICEConnectionState)state {
    L_DEBUG(@"Room: RTC Client didChangeConnectionState: %i", state);
}

- (RTCMediaStream *)streamToPublishByAppClient:(ECClient *)client {
    return _publishStream.mediaStream;
}

- (void)appClient:(ECClient *)client didReceiveRemoteStream:(RTCMediaStream *)stream
                                               withStreamId:(NSString *)streamId {
    L_DEBUG(@"Room: didReceiveRemoteStream");
    
    if ([_publishStreamId isEqualToString:streamId]) {
        // Ignore stream since it is the local one.
    } else {
        ECStream *erizoStream =  [[ECStream alloc] initWithRTCMediaStream:stream
                                                             withStreamId:streamId];
        [_delegate room:self didSubscribeStream:erizoStream];
    }
}

- (void)appClient:(ECClient *)client
    didError:(NSError *)error {
    L_ERROR(@"Room: Client error: %@", error.userInfo);
}

@end