//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

@import WebRTC;
#import "ECRoom.h"
#import "ECStream.h"
#import "ECCLient.h"
#import "ECClient+Internal.h"
#import "ECSignalingChannel.h"
#import "Logger.h"

static NSString * const kRTCStatsTypeSSRC        = @"ssrc";
static NSString * const kRTCStatsBytesSent       = @"bytesSent";
static NSString * const kRTCStatsLastDate        = @"lastDate";
static NSString * const kRTCStatsMediaTypeKey    = @"mediaType";

@implementation ECRoom {
    ECClient *publishClient;
    NSMutableDictionary *p2pClients;
    NSTimer *publishingStatsTimer;
    NSMutableDictionary *statsBySSRC;
}

- (instancetype)init {
    if (self = [super init]) {
        _recordEnabled = NO;
        if (_peerFactory) {
            _peerFactory = [[RTCPeerConnectionFactory alloc] init];
            _publishingStats = NO;
            p2pClients = [NSMutableDictionary dictionary];
        }
        _streamsByStreamId = [NSMutableDictionary dictionary];
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
    _signalingChannel = [[ECSignalingChannel alloc] initWithEncodedToken:encodedToken
                                                           roomDelegate:self
                                                         clientDelegate:self];
    [_signalingChannel connect];
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
    
    NSMutableDictionary *opts = [options mutableCopy];
    
    opts[@"video"] = videoCount > 0 ? @"true" : @"false";
    opts[@"audio"] = audioCount > 0 ? @"true" : @"false";
    
    if (!opts[@"data"]) {
        opts[@"data"] = @"false";
    }
    
    if (_peerToPeerRoom) {
        opts[@"state"] = @"p2p";
    } else {
        opts[@"state"] = @"erizo";
    }

    if (!opts[@"attributes"]) {
        opts[@"attributes"] = @{};
    }
	
	publishClient.streamOptions = opts;
	_publishStream.streamOptions = opts;

    // Reset stats used for bitrateCalculation
    statsBySSRC = [NSMutableDictionary dictionary];

    // Ask for publish
    [_signalingChannel publish:opts signalingChannelDelegate:publishClient];
}

- (BOOL)subscribe:(ECStream *)stream {
    if (!stream.streamId) {
        L_ERROR(@"Cannot subscribe to a stream without a streamId.");
        return NO;
    }

    if (self.status != ECRoomStatusConnected) {
        L_ERROR(@"You can't subscribe to a stream before connect to the room.");
        return NO;
    }

    if (![_streamsByStreamId objectForKey:stream.streamId]) {
        [_streamsByStreamId setObject:stream forKey:stream.streamId];
    }

    ECClient *client = [[ECClient alloc] initWithDelegate:self andPeerFactory:_peerFactory];
    [_signalingChannel subscribe:stream.streamId
        signalingChannelDelegate:client];

    return YES;
}

- (void)unsubscribe:(NSString *)streamId {
    [_signalingChannel unsubscribe:streamId];
}

- (void)leave {
    [_signalingChannel disconnect];
}

- (NSArray *)remoteStreams {
    NSMutableArray *remoteStreams = [NSMutableArray array];
    for (NSString *streamId in _streamsByStreamId) {
        ECStream *stream = [_streamsByStreamId objectForKey:streamId];
        if (![stream.streamId isEqualToString:_publishStreamId]) {
            [remoteStreams addObject:stream];
        }
    }
    return remoteStreams;
}

#
# pragma mark - ECSignalingChannelRoomDelegate
#
- (id<ECSignalingChannelDelegate>)clientDelegateRequiredForSignalingChannel:(ECSignalingChannel *)channel {
    id client = [[ECClient alloc] initWithDelegate:self andPeerFactory:_peerFactory];
    return client;
}

- (void)signalingChannel:(ECSignalingChannel *)channel didError:(NSString *)reason {
    [_delegate room:self didError:ECRoomConnectionError reason:reason];
    self.status = ECRoomStatusError;
}

- (void)signalingChannel:(ECSignalingChannel *)channel didConnectToRoom:(NSDictionary *)roomMeta {
    
    _roomMetadata = roomMeta;
    _roomId = [_roomMetadata objectForKey:@"id"];
    if ([_roomMetadata objectForKey:@"p2p"]) {
        _peerToPeerRoom = [[roomMeta objectForKey:@"p2p"] boolValue];
    }
    
    for (NSDictionary *streamData in [_roomMetadata objectForKey:@"streams"]) {
        NSString *streamId = [streamData objectForKey:@"id"];
        ECStream *stream = [_streamsByStreamId objectForKey:streamId];
        if (!stream) {
            stream = [[ECStream alloc] initWithStreamId:streamId
                                             attributes:[streamData objectForKey:@"attributes"]
                                       signalingChannel:self.signalingChannel];
        }
        [_streamsByStreamId setObject:stream forKey:streamId];
    }

    self.status = ECRoomStatusConnected;

    [_delegate room:self didConnect:_roomMetadata];
}

- (void)signalingChannel:(ECSignalingChannel *)channel didDisconnectOfRoom:(NSDictionary *)roomMeta {
    self.status = ECRoomStatusDisconnected;
}

- (void)signalingChannel:(ECSignalingChannel *)channel didReceiveStreamIdReadyToPublish:(NSString *)streamId {
    L_DEBUG(@"Room: didReceiveStreamIdReadyToPublish streamId: %@", streamId);
    _publishStreamId = streamId;
	
	NSMutableDictionary *options = [self.publishStream.streamOptions mutableCopy];
	options[@"id"] = streamId;
	self.publishStream.streamOptions = options;
	publishClient.streamOptions = options;
}

- (void)signalingChannel:(ECSignalingChannel *)channel didStartRecordingStreamId:(NSString *)streamId
         withRecordingId:(NSString *)recordingId recordingDate:(NSDate *)recordingDate {
    [_delegate room:self didStartRecordingStreamId:streamId withRecordingId:recordingId recordingDate:recordingDate];
}

- (void)signalingChannel:(ECSignalingChannel *)channel didFailStartRecordingStreamId:(NSString *)streamId
                                                                        withErrorMsg:(NSString *)errorMsg {
    [_delegate room:self didFailStartRecordingStreamId:streamId withErrorMsg:errorMsg];
}

- (void)signalingChannel:(ECSignalingChannel *)channel
    didStreamAddedWithId:(NSString *)streamId
                   event:(ECSignalingEvent *)event {
    if ([_publishStreamId isEqualToString:streamId]) {
        [_delegate room:self didPublishStreamId:streamId];
        if (_recordEnabled && !_peerToPeerRoom) {
            [_signalingChannel startRecording:_publishStreamId];
        }
    } else {
        ECStream *stream = [_streamsByStreamId objectForKey:streamId];
        if (!stream) {
            stream = [[ECStream alloc] initWithStreamId:streamId
                                             attributes:event.attributes
                                       signalingChannel:_signalingChannel];
            [_streamsByStreamId setObject:stream forKey:streamId];
        }
        [_delegate room:self didAddedStream:stream];
    }
}

- (void)signalingChannel:(ECSignalingChannel *)channel didRemovedStreamId:(NSString *)streamId {
    ECStream *stream = [_streamsByStreamId objectForKey:streamId];
    [_delegate room:self didRemovedStream:stream];
    [_streamsByStreamId removeObjectForKey:streamId];
}

- (void)signalingChannel:(ECSignalingChannel *)channel didUnsubscribeStreamWithId:(NSString *)streamId {
    ECStream *stream = [_streamsByStreamId objectForKey:streamId];
    [_delegate room:self didUnSubscribeStream:stream];
}

- (void)signalingChannel:(ECSignalingChannel *)channel didRequestPublishP2PStreamWithId:(NSString *)streamId
                                                                        peerSocketId:(NSString *)peerSocketId {
    if (![streamId isEqualToString:self.publishStreamId]) {
        L_ERROR(@"Requested to publish P2P Stream distinct from the one being published");
        return;
    }
    ECClient *client = [[ECClient alloc] initWithDelegate:self
                                              peerFactory:_peerFactory
                                                 streamId:streamId
                                             peerSocketId:peerSocketId];
    [p2pClients setValue:client forKey:peerSocketId];
    [_signalingChannel publishToPeerID:peerSocketId signalingChannelDelegate:client];
}

- (void)signalingChannel:(ECSignalingChannel *)channel fromStreamId:(NSString *)streamId receivedDataStream:(NSDictionary *)dataStream {
	if([_delegate respondsToSelector:@selector(room:fromStreamId:receivedDataStream:)]) {
		[_delegate room:self fromStreamId:streamId receivedDataStream:dataStream];
	}
}

- (void)signalingChannel:(ECSignalingChannel *)channel fromStreamId:(NSString *)streamId updateStreamAttributes:(NSDictionary *)attributeStream {
	if([_delegate respondsToSelector:@selector(room:fromStreamId:updateStreamAttributes:)]) {
		[_delegate room:self fromStreamId:streamId updateStreamAttributes:attributeStream];
	}
}

#
# pragma mark - ECClientDelegate
#

- (NSDictionary *)appClientRequestICEServers:(ECClient *)client {
    return [_roomMetadata objectForKey:@"iceServers"];
}

- (void)appClient:(ECClient *)_client didChangeState:(ECClientState)state {
    L_INFO(@"Room: Client didChangeState: %@", clientStateToString(state));

    if (_client == publishClient) {
        if (state == ECClientStateDisconnected) {
            [publishingStatsTimer invalidate];
        } else if (state == ECClientStateConnected) {
            publishingStatsTimer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                                                    target:self
                                                                  selector:@selector(gatherPublishingStats)
                                                                  userInfo:nil
                                                                   repeats:YES];
        }
    }
}

- (void)appClient:(ECClient *)client didChangeConnectionState:(RTCIceConnectionState)state {
    L_DEBUG(@"Room: RTC Client didChangeConnectionState: %i", state);
}

- (RTCMediaStream *)streamToPublishByAppClient:(ECClient *)client {
    return _publishStream.mediaStream;
}

- (void)appClient:(ECClient *)client didReceiveRemoteStream:(RTCMediaStream *)remoteStream
                                               withStreamId:(NSString *)streamId {
    L_DEBUG(@"Room: didReceiveRemoteStream");
    if ([_publishStreamId isEqualToString:streamId]) {
        // Ignore this stream since it is local.
    } else {
        ECStream *stream = [_streamsByStreamId objectForKey:streamId];
        stream.mediaStream = remoteStream;
        stream.signalingChannel = _signalingChannel;
        [_delegate room:self didSubscribeStream:stream];
    }
}

- (void)appClient:(ECClient *)client didError:(NSError *)error {
    L_ERROR(@"Room: Client error: %@", error.userInfo);
    ECRoomErrorStatus roomError = ECRoomUnknownError;
    if (error.code == kECAppClientErrorSetSDP) {
        roomError = ECRoomClientFailedSDP;
    }
    [_delegate room:self didError:roomError reason:[error.userInfo description]];
}

# pragma mark - RTC Stats

- (void)gatherPublishingStats {
    if (!self.publishingStats || !publishClient)
        return;

	NSArray<RTCMediaStreamTrack *> *tracks = _publishStream.mediaStream.videoTracks;
	tracks = [tracks arrayByAddingObjectsFromArray:(NSArray<RTCMediaStreamTrack *> *)_publishStream.mediaStream.audioTracks];

    for (RTCMediaStreamTrack *track in tracks) {
        [publishClient.peerConnection statsForTrack:track
                                   statsOutputLevel:RTCStatsOutputLevelStandard
                                  completionHandler:^(NSArray<RTCLegacyStatsReport *> * _Nonnull stats) {

                                  for (RTCLegacyStatsReport *stat in stats) {
                                      if ([stat.type isEqualToString:kRTCStatsTypeSSRC]) {

                                          [self processRTCLegacyStatsReport:stat];

                                          [statsBySSRC setObject:@{
                                                                    kRTCStatsBytesSent: [stat.values objectForKey:kRTCStatsBytesSent],
                                                                    kRTCStatsLastDate: [NSDate date]
                                                                   } forKey:[stat.values objectForKey:kRTCStatsTypeSSRC]];

                                      }
                                  }
                              }];
    }
}

- (void)processRTCLegacyStatsReport:(RTCLegacyStatsReport *)statsReport {

    NSString *ssrc = [statsReport.values objectForKey:kRTCStatsTypeSSRC];
    NSString *mediaType = [statsReport.values objectForKey:kRTCStatsMediaTypeKey];

    unsigned long kbps = [self calculateBitrateForStatsReport:statsReport];

    L_INFO(@"RTC Publishing %@ Stats Type: %@, ID: %@ Dict: %@",
           mediaType, statsReport.type, statsReport.reportId, statsReport.values);
    L_INFO(@"RTC Publishing %@ kbps: %lld", mediaType, kbps)

    if (!self.statsDelegate)
        return;

    if ([_statsDelegate respondsToSelector:@selector(room:publishingClient:mediaType:ssrc:didReceiveStats:)]) {
        [_statsDelegate room:self
            publishingClient:publishClient
                   mediaType:mediaType
                        ssrc:ssrc
             didReceiveStats:statsReport];
    }

    if ([_statsDelegate respondsToSelector:@selector(room:publishingClient:mediaType:ssrc:didPublishingAtKbps:)]) {
        [_statsDelegate room:self
            publishingClient:publishClient
                   mediaType:mediaType
                        ssrc:ssrc
         didPublishingAtKbps:kbps];
    }
}

- (unsigned long)calculateBitrateForStatsReport:(RTCLegacyStatsReport *)statsReport {

    NSString *ssrc = [statsReport.values objectForKey:kRTCStatsTypeSSRC];
    unsigned long bytesSent = [[statsReport.values objectForKey:kRTCStatsBytesSent] intValue];
    unsigned long lastBytesSent = [[[statsBySSRC objectForKey:ssrc] objectForKey:kRTCStatsBytesSent] intValue];
    NSDate *lastStatsDate = [[statsBySSRC objectForKey:ssrc] objectForKey:kRTCStatsLastDate];

    NSTimeInterval seconds = [lastStatsDate timeIntervalSinceNow];
    unsigned long kbps = (((bytesSent - lastBytesSent) * 8) / fabs(seconds)) / 1000.0;

    return kbps;
}

@end
