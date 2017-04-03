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
        _mediaConstraints = videoConstraints;
        _defaultVideoConstraints = videoConstraints;
        _defaultAudioConstraints = audioConstraints;
        [self createLocalStream];
    }
    return self;
}

/// @deprecated
- (instancetype)initWithLocalStreamWithMediaConstraints:(RTCMediaConstraints *)mediaConstraints {
    if (self = [self init]) {
        _peerFactory = [[RTCPeerConnectionFactory alloc] init];
        _mediaConstraints = mediaConstraints;
        _defaultVideoConstraints = mediaConstraints;
        [self createLocalStream];
    }
    return self;
}

- (instancetype)initWithRTCMediaStream:(RTCMediaStream *)mediaStream
                          withStreamId:(NSString *)streamId {
    if (self = [self init]) {
        _mediaStream = mediaStream;
        _streamId = streamId;
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
	return NO;
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
