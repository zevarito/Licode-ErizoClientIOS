//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import "ECStream.h"
#import "RTCAVFoundationVideoSource.h"
#import "RTCVideoTrack.h"
#import "RTCAudioTrack.h"
#import "RTCEAGLVideoView.h"
#import "RTCMediaConstraints.h"
#import "RTCMediaStream.h"

@implementation ECStream {
}

# pragma mark - Initializers

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

- (instancetype)initLocalStream {
    self = [self initWithLocalStreamWithMediaConstraints:nil];
    return self;
}

- (instancetype)initWithLocalStreamWithMediaConstraints:(RTCMediaConstraints *)mediaConstraints {
    if (self = [self init]) {
        _peerFactory = [[RTCPeerConnectionFactory alloc] init];
        _mediaConstraints = mediaConstraints;
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
    _mediaStream = [_peerFactory mediaStreamWithLabel:@"LCMS"];

    [self generateVideoTracks];
    
    [_mediaStream addAudioTrack:[_peerFactory audioTrackWithID:@"LCMSa0"]];
    return _mediaStream;
}

- (void)generateVideoTracks {
    for (RTCVideoTrack *localVideoTrack in _mediaStream.videoTracks) {
        [_mediaStream removeVideoTrack:localVideoTrack];
    }
    
    RTCVideoTrack *localVideoTrack = [self createLocalVideoTrack];
    if (localVideoTrack) {
        [_mediaStream addVideoTrack:localVideoTrack];
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
        [audioTrack setEnabled:NO];
    }
}

- (void)unmute {
    for (RTCAudioTrack *audioTrack in _mediaStream.audioTracks) {
        [audioTrack setEnabled:YES];
    }
}

# pragma mark - Private Instance Methods

- (RTCVideoTrack *)createLocalVideoTrack {
    RTCVideoTrack* localVideoTrack = nil;
#if !TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE
    if (!_mediaConstraints) {
        _mediaConstraints = [self defaultMediaStreamConstraints];
    }
    RTCAVFoundationVideoSource *source =
    [[RTCAVFoundationVideoSource alloc] initWithFactory:_peerFactory
                                            constraints:_mediaConstraints];
    localVideoTrack =
    [[RTCVideoTrack alloc] initWithFactory:_peerFactory
                                    source:source
                                   trackId:@"LCMSv0"];
#endif
    return localVideoTrack;
}

- (RTCMediaConstraints *)defaultMediaStreamConstraints {
    RTCMediaConstraints* constraints = [[RTCMediaConstraints alloc]
                                        initWithMandatoryConstraints:nil
                                                 optionalConstraints:nil];
    return constraints;
}

@end
