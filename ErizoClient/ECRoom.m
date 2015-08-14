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
    ECClient *client;
    ECSignalingChannel *signalingChannel;
    ECClientState clientState;
    NSDictionary *decodedToken;
    NSMutableArray *streamsArray;
}

- (instancetype)init {
    if (self = [super init]) {
        streamsArray = [[NSMutableArray alloc] init];
        client = [[ECClient alloc] initWithDelegate:self];
    }
    return self;
}

- (instancetype)initWithDelegate:(id<ECRoomDelegate>)roomDelegate {
    if (self = [self init]) {
        _delegate = roomDelegate;
    }
    return self;
}

- (instancetype)initWithEncodedToken:(NSString*)encodedToken delegate:(id<ECRoomDelegate>)roomDelegate {
    if (self = [self initWithDelegate:roomDelegate]) {
        [self createSignalingChannelWithEncodedToken:encodedToken];
    }
    return self;
}

- (void)dealloc {
    client = nil;
    signalingChannel = nil;
    streamsArray = nil;
    decodedToken = nil;
}

- (void)createSignalingChannelWithEncodedToken:(NSString *)encodedToken {
    signalingChannel = [[ECSignalingChannel alloc] initWithEncodedToken:encodedToken
                                                      signalingDelegate:client roomDelegate:self];
    [signalingChannel connect];
}

- (void)publish:(ECStream *)stream withOptions:(NSDictionary *)options {
    _publishStream = stream;
    
    int videoCount = _publishStream.stream.videoTracks.count;
    int audioCount = _publishStream.stream.audioTracks.count;
    
    NSDictionary *opts = @{
                           @"video": videoCount > 0 ? @"true" : @"false",
                           @"audio": audioCount > 0 ? @"true" : @"false",
                           @"data": [options objectForKey:@"data"],
                           };
    
    [signalingChannel publish:opts];
}

#
# pragma mark - ECSignalingChannelRoomDelegate
#

- (void)signalingChannel:(ECSignalingChannel *)channel didReceiveStreamIdReadyToPublish:(NSString *)streamId {
    _publishStreamId = streamId;
    [_delegate room:self didPublishStreamId:streamId];
    
    if (_recordEnabled) {
        [signalingChannel startRecording];
    }
}

- (void)signalingChannel:(ECSignalingChannel *)channel didStartRecordingStreamId:(NSString *)streamId
                                                                 withRecordingId:(NSString *)recordingId {
    [_delegate room:self didStartRecordingStreamId:streamId withRecordingId:recordingId];
}

- (void)signalingChannel:(ECSignalingChannel *)channel didStreamAddedWithId:(NSString *)streamId {

}

#
# pragma mark - ECClientDelegate
#

- (void)appClient:(ECClient *)client didChangeState:(ECClientState)state {
    L_INFO(@"Room: Client didChangeState: %@", clientStateToString(state));
    clientState = state;
}

- (RTCMediaStream *)streamToPublishByAppClient:(ECClient *)client {
    return _publishStream.stream;
}

- (void)appClient:(ECClient *)client didChangeConnectionState:(RTCICEConnectionState)state {
    L_DEBUG(@"Room: didChangeConnectionState: %i", state);
}

- (void)appClient:(ECClient *)client didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack {
    L_DEBUG(@"Room: didReceiveRemoteVideoTrack");
}

- (void)appClient:(ECClient *)client
    didError:(NSError *)error {
}

@end