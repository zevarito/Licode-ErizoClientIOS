//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

@import WebRTC;
#import "ECStream.h"

@implementation ECStream {
}

# pragma mark - Initializers

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

- (instancetype)initLocalStream {
    self = [self initWithLocalStreamVideoConstraints:nil audioConstraints:nil];
    return self;
}

- (instancetype)initWithLocalStreamVideoConstraints:(RTCMediaConstraints *)videoConstraints
                                   audioConstraints:(RTCMediaConstraints *)audioConstraints {
    if (self = [self init]) {
        _peerFactory = [[RTCPeerConnectionFactory alloc] init];
        _defaultVideoConstraints = videoConstraints;
        _defaultAudioConstraints = audioConstraints;
		_isLocal = YES;
        [self createLocalStream];
    }
    return self;
}

- (instancetype)initWithRTCMediaStream:(RTCMediaStream *)mediaStream
                          withStreamId:(NSString *)streamId
                      signalingChannel:(ECSignalingChannel *)signalingChannel {
    if (self = [self init]) {
        _mediaStream = mediaStream;
        _streamId = streamId;
        _signalingChannel = signalingChannel;
        _isLocal = NO;
    }
    return self;
}

# pragma mark - Public Methods

- (RTCMediaStream *)createLocalStream {
    _mediaStream = [_peerFactory mediaStreamWithStreamId:@"LCMSv0"];

    [self generateVideoTracks];
    [self generateAudioTracks];

    return _mediaStream;
}

- (void)generateVideoTracks {
    for (RTCVideoTrack *localVideoTrack in _mediaStream.videoTracks) {
        [_mediaStream removeVideoTrack:localVideoTrack];
}

    RTCVideoTrack *localVideoTrack = [self createLocalVideoTrack];
    if (localVideoTrack) {
        [_mediaStream addVideoTrack:localVideoTrack];
    } else {
        L_ERROR(@"Could not add video track!");
    }
}

- (void)generateAudioTracks {
    for (RTCAudioTrack *localAudioTrack in _mediaStream.audioTracks) {
        [_mediaStream removeAudioTrack:localAudioTrack];
    }

    RTCAudioTrack *localAudioTrack = [self createLocalAudioTrack];
    if (localAudioTrack) {
        [_mediaStream addAudioTrack:localAudioTrack];
    } else {
        L_ERROR(@"Could not add audio track!");
    }
}

- (NSDictionary *)getAttributes {
	if(!self.streamAttributes) {
        return @{};
	}
    return self.streamAttributes;
}

- (void)setAttributes:(NSDictionary *)attributes {
    if (!self.isLocal) {
        L_WARNING(@"You are trying to set attributes on non local stream, ignoring.");
        return;
    }

    if (!self.signalingChannel) {
        L_WARNING(@"You are trying to set attributes on a not published yet stream.");
        return;
    }

    _streamAttributes = attributes;
    ECUpdateAttributeMessage *message = [[ECUpdateAttributeMessage alloc]
                                         initWithStreamId:self.streamId
                                         withAttribute:self.streamAttributes];
    [self.signalingChannel updateStreamAttributes:message];
}

- (BOOL)switchCamera {
    RTCVideoSource* source = ((RTCVideoTrack*)[_mediaStream.videoTracks objectAtIndex:0]).source;
    if ([source isKindOfClass:[RTCAVFoundationVideoSource class]]) {
        RTCAVFoundationVideoSource* avSource = (RTCAVFoundationVideoSource*)source;
        avSource.useBackCamera = !avSource.useBackCamera;
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)hasAudio {
	return (self.mediaStream.audioTracks.count > 0);
}

- (BOOL)hasVideo {
	return (self.mediaStream.videoTracks.count > 0);
}

- (BOOL)hasData {
	return [[NSString stringWithFormat:@"%@", [_streamOptions valueForKey:kStreamOptionData]]
            boolValue];
}

- (void)mute {
    for (RTCAudioTrack *audioTrack in _mediaStream.audioTracks) {
        audioTrack.isEnabled = NO;
    }
}

- (void)unmute {
    for (RTCAudioTrack *audioTrack in _mediaStream.audioTracks) {
        audioTrack.isEnabled = YES;
    }
}

- (BOOL)sendData:(NSDictionary *)data {
    if(!self.isLocal) {
        L_WARNING(@"Cannot send data from a non-local stream.");
        return NO;
    }
    
    if (!data || !self.signalingChannel) {
        L_WARNING(@"Cannot send data, either you pass nil data or signaling channel is not available.");
        return NO;
    }
    ECDataStreamMessage *message = [[ECDataStreamMessage alloc] initWithStreamId:self.streamId
                                                                        withData:data];
    [self.signalingChannel sendDataStream:message];
    return YES;
}

- (void)dealloc {
	_mediaStream = nil;
}

# pragma mark - Private Instance Methods

- (RTCVideoTrack *)createLocalVideoTrack {
    RTCVideoTrack* localVideoTrack = nil;
#if !TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE
    RTCAVFoundationVideoSource *source =
    [_peerFactory avFoundationVideoSourceWithConstraints:_defaultVideoConstraints];
    localVideoTrack = [_peerFactory videoTrackWithSource:source trackId:kLicodeVideoLabel];
#endif
    return localVideoTrack;
}

- (RTCAudioTrack *)createLocalAudioTrack {
    RTCAudioSource *audioSource = [_peerFactory audioSourceWithConstraints:_defaultAudioConstraints];
    RTCAudioTrack *audioTrack = [_peerFactory audioTrackWithSource:audioSource trackId:kLicodeAudioLabel];
    return audioTrack;
}

@end
