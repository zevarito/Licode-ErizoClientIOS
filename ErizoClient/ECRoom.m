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
        if (!_peerFactory) {
            _peerFactory = [[RTCPeerConnectionFactory alloc] init];
        }
        _recordEnabled = NO;
        _publishingStats = NO;
        p2pClients = [NSMutableDictionary dictionary];
        _streamsByStreamId = [NSMutableDictionary dictionary];
        self.status = ECRoomStatusReady;
        self.defaultSubscribingStreamOptions = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                         @"audio": @YES,
                                                                                         @"video": @YES,
                                                                                         @"data": @YES,
                                                                                         @"muteStream": @{@"audio": @NO, @"video": @NO}
                                                                                         }];
    }
    return self;
}

- (instancetype)initWithDelegate:(id<ECRoomDelegate>)roomDelegate
                  andPeerFactory:(nullable RTCPeerConnectionFactory *)factory {
    if (self = [self init]) {
        _delegate = roomDelegate;
        if (factory) {
            _peerFactory = factory;
        }
        self.status = ECRoomStatusReady;
    }
    return self;
}

- (instancetype)initWithEncodedToken:(NSString *)encodedToken
                            delegate:(id<ECRoomDelegate>)delegate
                      andPeerFactory:(RTCPeerConnectionFactory *)factory {
    if (self = [self initWithDelegate:delegate andPeerFactory:factory]) {
        [self connectWithEncodedToken:encodedToken];
    }
    return self;
}

- (void)setStatus:(ECRoomStatus)status {
    _status = status;
    if ([self.delegate respondsToSelector:@selector(room:didChangeStatus:)]) {
        [self.delegate room:self didChangeStatus:status];
    }
}

- (void)connectWithEncodedToken:(NSString *)encodedToken {
    _signalingChannel = [[ECSignalingChannel alloc] initWithEncodedToken:encodedToken
                                                            roomDelegate:self
                                                          clientDelegate:self];
    [_signalingChannel connect];
}

- (void)publish:(ECStream *)stream {
    
    // Create a ECClient instance to handle peer connection for this publishing.
    // It is very important to use the same factory.
    publishClient = [[ECClient alloc] initWithDelegate:self
                                           peerFactory:stream.peerFactory
                                              streamId:nil
                                          peerSocketId:nil
                                               options:[self getClientOptionsWithStream:stream]];
    
    // Keep track of the stream that this room will be publishing
    _publishStream = stream;
    
    NSMutableDictionary *options = [stream.streamOptions mutableCopy];
    [options setObject:stream.streamAttributes forKey:@"attributes"];
    
    // Reset stats used for bitrateCalculation
    statsBySSRC = [NSMutableDictionary dictionary];

    // Ask for publish
    [_signalingChannel publish:options signalingChannelDelegate:publishClient];
}

- (void)unpublish {
    [_signalingChannel unpublish:_publishStreamId
        signalingChannelDelegate:publishClient];
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

    ECClient *client = [[ECClient alloc] initWithDelegate:self
                                              peerFactory:_peerFactory
                                                 streamId:nil
                                             peerSocketId:nil
                                                  options:[self getClientOptionsWithStream:stream]];
    [_signalingChannel subscribe:stream.streamId
                   streamOptions:self.defaultSubscribingStreamOptions
        signalingChannelDelegate:client];

    return YES;
}

- (void)unsubscribe:(ECStream *)stream {
    [_signalingChannel unsubscribe:stream.streamId];
}

- (void)leave {
    if (_status == ECRoomStatusConnected) {
        [_signalingChannel disconnect];
    } else {
        self.status = ECRoomStatusDisconnected;
    }
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
# pragma mark - Private
#

- (NSNumber *)getDefaultVideoBandwidth {
    if (!self.roomMetadata) {
        return nil;
    }
    
    id defaultVideoBW = self.roomMetadata[@"defaultVideoBW"];
    if (defaultVideoBW && [defaultVideoBW isKindOfClass:[NSNumber class]]) {
        return defaultVideoBW;
    }
    return nil;
}

- (NSNumber *)getMaxVideoBandwidth {
    if (!self.roomMetadata) {
        return nil;
    }
    
    id maxVideoBW = self.roomMetadata[@"maxVideoBW"];
    if (maxVideoBW && [maxVideoBW isKindOfClass:[NSNumber class]]) {
        return maxVideoBW;
    }
    return nil;
}

- (NSDictionary *)getClientOptionsWithStream:(ECStream *)stream {
    NSDictionary *streamOptions = stream.streamOptions;
    if (!streamOptions) {
        return nil;
    }
    
    NSNumber *roomDefaultVideoBW = [self getDefaultVideoBandwidth];
    NSNumber *roomMaxVideoBW = [self getMaxVideoBandwidth];
    NSNumber *maxVideoBW = roomDefaultVideoBW ?: nil;
    
    id value = streamOptions[kStreamOptionMaxVideoBW];
    if (value && [value isKindOfClass:[NSNumber class]]) {
        maxVideoBW = value;
    }
    if (roomMaxVideoBW && [maxVideoBW integerValue] > [roomMaxVideoBW integerValue]) {
        maxVideoBW = roomMaxVideoBW;
    }
    
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    if (maxVideoBW) {
        options[kClientOptionMaxVideoBW] = maxVideoBW;
    }
    if (streamOptions[kStreamOptionMaxAudioBW]) {
        options[kClientOptionMaxAudioBW] = streamOptions[kStreamOptionMaxAudioBW];
    }
    
    if (options.count > 0) {
        return [NSDictionary dictionaryWithDictionary:options];
    } else {
        return nil;
    }
}

#
# pragma mark - ECSignalingChannelRoomDelegate
#
- (id<ECSignalingChannelDelegate>)clientDelegateRequiredForSignalingChannel:(ECSignalingChannel *)channel {
    id client = [[ECClient alloc] initWithDelegate:self andPeerFactory:_peerFactory];
    return client;
}

- (void)signalingChannel:(ECSignalingChannel *)channel didError:(NSError *)error {
    [_delegate room:self didError:error status:ECRoomErrorSignaling];
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
    _publishStream.streamId = streamId;
}

- (void)signalingChannel:(ECSignalingChannel *)channel didStartRecordingStreamId:(NSString *)streamId
         withRecordingId:(NSString *)recordingId recordingDate:(NSDate *)recordingDate {
    [_delegate room:self didStartRecordingStream:_publishStream withRecordingId:recordingId recordingDate:recordingDate];
}

- (void)signalingChannel:(ECSignalingChannel *)channel didFailStartRecordingStreamId:(NSString *)streamId
                                                                        withErrorMsg:(NSString *)errorMsg {
    [_delegate room:self didFailStartRecordingStream:_publishStream withErrorMsg:errorMsg];
}

- (void)signalingChannel:(ECSignalingChannel *)channel
    didStreamAddedWithId:(NSString *)streamId
                   event:(ECSignalingEvent *)event {
    if ([_publishStreamId isEqualToString:streamId]) {
        [_delegate room:self didPublishStream:_publishStream];
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
    if (stream) {
        [_delegate room:self didRemovedStream:stream];
        [_streamsByStreamId removeObjectForKey:streamId];
    }
    
    if ([streamId isEqualToString:_publishStreamId]) {
        publishClient = nil;
    }
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
                                             peerSocketId:peerSocketId
                                                  options:[self getClientOptionsWithStream:self.publishStream]];
    [p2pClients setValue:client forKey:peerSocketId];
    [_signalingChannel publishToPeerID:peerSocketId signalingChannelDelegate:client];
}

- (void)signalingChannel:(ECSignalingChannel *)channel fromStreamId:(NSString *)streamId receivedDataStream:(NSDictionary *)dataStream {
	if([_delegate respondsToSelector:@selector(room:didReceiveData:fromStream:)]) {
        ECStream *stream = [_streamsByStreamId objectForKey:streamId];
        [_delegate room:self didReceiveData:dataStream fromStream:stream];
	}
}

- (void)signalingChannel:(ECSignalingChannel *)channel fromStreamId:(NSString *)streamId updateStreamAttributes:(NSDictionary *)attributes {
	if([_delegate respondsToSelector:@selector(room:didUpdateAttributesOfStream:)]) {
        ECStream *stream = [_streamsByStreamId objectForKey:streamId];
        [stream setAttributes:attributes];
		[_delegate room:self didUpdateAttributesOfStream:stream];
	}
}

- (void)signalingChannel:(ECSignalingChannel *)channel didUnpublishStreamWithId:(NSString *)streamId {
    if ([_publishStreamId isEqualToString:streamId]) {
        [_delegate room:self didUnpublishStream:_publishStream];
        publishClient = nil;
        _publishStream = nil;
        _publishStreamId = nil;
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
            self.status = ECRoomStatusDisconnected;
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
        stream.peerFactory = _peerFactory;
        stream.mediaStream = remoteStream;
        stream.signalingChannel = _signalingChannel;
        [_delegate room:self didSubscribeStream:stream];
    }
}

- (void)appClient:(ECClient *)client didError:(NSError *)error {
    L_ERROR(@"Room: Client error: %@", error.userInfo);
    ECRoomErrorStatus roomErrorStatus = ECRoomErrorClient;
    if (error.code == kECAppClientErrorSetSDP) {
        roomErrorStatus = ECRoomErrorClientFailedSDP;
    }
    [_delegate room:self didError:error status:roomErrorStatus];
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
