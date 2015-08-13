//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import "ECRoom.h"
#import "ECStream.h"
#import "rtc/ECClient.h"
#import "rtc/ECSignalingChannel.h"
#import "rtc/ECSignalingMessage.h"
#import "RTCAVFoundationVideoSource.h"
#import "RTCMediaConstraints.h"
#import "RTCMediaStream.h"
#import "Logger.h"

@interface ECRoom () <ECClientDelegate>
@end

@implementation ECRoom {
    ECClient *client;
    ECClientState *clientState;
    ECSignalingChannel *signalingChannel;
    RTCPeerConnectionFactory *factory;
    NSDictionary *decodedToken;
    id <RoomDelegate> delegate;
}

- (instancetype)init {
    if (self = [super init]) {
        self.isConnected = FALSE;
        factory = [[RTCPeerConnectionFactory alloc] init];
        client = [[ECClient alloc] initWithDelegate:self];
    }
    return self;
}

- (instancetype)initWithEncodedToken:(NSString*)encodedToken delegate:(id<RoomDelegate>)roomDelegate {
    if (self = [self init]) {
        [self createSignalingChannelWithEncodedToken:encodedToken];
        delegate = roomDelegate;
    }
    return self;
}

- (instancetype)initWithDelegate:(id<RoomDelegate>)roomDelegate {
    if (self = [self init]) {
        delegate = roomDelegate;
    }
    return self;
}

- (void)createSignalingChannelWithEncodedToken:(NSString *)encodedToken {
    [self decodeToken:encodedToken];
    signalingChannel = [[ECSignalingChannel alloc] initWithToken:decodedToken delegate:client];
    [signalingChannel open];
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

# pragma mark - ClientDelegate

- (void)appClient:(ECClient *)client didChangeState:(ECClientState)state {
    L_INFO(@"Room: Client didChangeState: %@", clientStateToString(state));
}

- (RTCMediaStream *)streamToPublishByAppClient:(ECClient *)client {
    return _publishStream.stream;
}

- (void)appClient:(ECClient *)client didChangeConnectionState:(RTCICEConnectionState)state {
    L_DEBUG(@"Room: didChangeConnectionState: %i", state);
}

- (void)appClient:(ECClient *)client didReceiveLocalVideoTrack:(RTCVideoTrack *)localVideoTrack {
    L_DEBUG(@"Room: didReceiveLocalVideoTrack");
    [delegate appClient:nil didReceiveLocalVideoTrack:localVideoTrack];
}

- (void)appClient:(ECClient *)client didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack {
    L_DEBUG(@"Room: didReceiveRemoteVideoTrack");
}

- (void)appClient:(ECClient *)client
    didError:(NSError *)error {
}

- (void)appClient:(ECClient *)client didStreamAddedWithId:(NSString *)streamId {
    [delegate didStreamAddedWithId:streamId];
    if (_recordEnabled) {
        [signalingChannel startRecording];
    }
}

- (void)appClient:(ECClient *)client didStartRecordingStreamId:(NSString *)streamId withRecordingId:(NSString *)recordingId {
    [delegate didStartRecordingStreamId:streamId withRecordingId:recordingId];
}

# pragma mark - Private

- (void)decodeToken:(NSString *)encodedToken {
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:encodedToken options:0];
    NSError *jsonParseError = nil;
    decodedToken = [NSJSONSerialization
                   JSONObjectWithData:decodedData
                   options:0
                   error:&jsonParseError];
    
    L_DEBUG(@"Room: decoded token object: %@", decodedToken);
}
@end