//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

@import WebRTC;
#import "ECStream.h"

@implementation ECStream

@synthesize signalingChannel = _signalingChannel;

# pragma mark - Initializers

- (instancetype)init {
    if (self = [super init]) {
        _streamAttributes = @{};
        _streamOptions = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                        kStreamOptionVideo: @YES,
                                                                        kStreamOptionAudio: @YES,
                                                                        kStreamOptionData: @YES,
                                                                        kStreamOptionLabel: @"LCMSv0"
                           }];
    }
    return self;
}

- (instancetype)initLocalStream {
    self = [self initLocalStreamVideoConstraints:nil audioConstraints:nil];
    return self;
}

- (instancetype)initLocalStreamWithOptions:(NSDictionary *)options
                                attributes:(NSDictionary *)attributes {
    if (self = [self initLocalStreamWithOptions:options
                                     attributes:attributes
                               videoConstraints:nil
                               audioConstraints:nil]) {
    }
    return self;
}

- (instancetype)initLocalStreamWithOptions:(NSDictionary *)options
                                attributes:(NSDictionary *)attributes
                          videoConstraints:(RTCMediaConstraints *)videoConstraints
                          audioConstraints:(RTCMediaConstraints *)audioConstraints {
    if (self = [self init]) {
        _peerFactory = [[RTCPeerConnectionFactory alloc] init];
        _defaultVideoConstraints = videoConstraints;
        _defaultAudioConstraints = audioConstraints;
        _isLocal = YES;
        if (options) {
            NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:_streamOptions];
            for (NSString *key in options) {
                [tempDict setValue:[options valueForKey:key] forKey:key];
            }
            _streamOptions = [NSMutableDictionary dictionaryWithDictionary:tempDict];
        }
        if (attributes) {
            [self setAttributes:attributes];
        }
        [self createLocalStream];
    }
    return self;
}

- (instancetype)initLocalStreamVideoConstraints:(RTCMediaConstraints *)videoConstraints
                               audioConstraints:(RTCMediaConstraints *)audioConstraints {
    if (self = [self initLocalStreamWithOptions:nil
                                     attributes:nil
                               videoConstraints:videoConstraints
                               audioConstraints:audioConstraints]) {
    }
    return self;
}

- (instancetype)initWithStreamId:(NSString *)streamId
                      attributes:(NSDictionary *)attributes
                signalingChannel:(ECSignalingChannel *)signalingChannel {
    if (self = [self init]) {
        _streamId = streamId;
        _isLocal = NO;
        _streamAttributes = attributes;
        _dirtyAttributes = NO;
        self.signalingChannel = signalingChannel;
    }
    return self;
}

# pragma mark - Public Methods

- (void)setSignalingChannel:(ECSignalingChannel *)signalingChannel {
    if (signalingChannel) {
        _signalingChannel = signalingChannel;
        if (_dirtyAttributes) {
            [self setAttributes:_streamAttributes];
        }
    }
}

- (ECSignalingChannel *)signalingChannel {
    return _signalingChannel;
}

- (RTCMediaStream *)createLocalStream {
    _mediaStream = [_peerFactory mediaStreamWithStreamId:@"LCMSv0"];

    if ([(NSNumber *)[_streamOptions objectForKey:kStreamOptionVideo] boolValue])
        [self generateVideoTracks];

    if ([(NSNumber *)[_streamOptions objectForKey:kStreamOptionAudio] boolValue])
        [self generateAudioTracks];

    return _mediaStream;
}

- (void)generateVideoTracks {
    [self removeVideoTracks];

    RTCVideoTrack *localVideoTrack = [self createLocalVideoTrack];
    if (localVideoTrack) {
        [_mediaStream addVideoTrack:localVideoTrack];
    } else {
#if !TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE
        L_ERROR(@"Could not add video track!");
#else
        L_WARNING(@"Simulator doesn't have access to camera, not adding video track.");
#endif
    }
}

- (void)generateAudioTracks {
    [self removeAudioTracks];

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
    _streamAttributes = attributes;

    if (!self.isLocal) {
        _dirtyAttributes = NO;
        return;
    } else if (!self.signalingChannel) {
        _dirtyAttributes = YES;
        return;
    }

    ECUpdateAttributeMessage *message = [[ECUpdateAttributeMessage alloc]
                                         initWithStreamId:self.streamId
                                         withAttribute:self.streamAttributes];
    [self.signalingChannel updateStreamAttributes:message];
    _dirtyAttributes = NO;
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
    if (![(NSNumber *)[_streamOptions objectForKey:kStreamOptionData] boolValue]) {
        L_WARNING(@"Trying to send data on a non enabled data stream.");
        return NO;
    }

    if (!self.isLocal) {
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

- (BOOL)enableSlideShow:(BOOL)enable {
	if (self.isLocal) {
		L_WARNING(@"Cannot send message from a local stream.");
		return NO;
	}
	
	if (!self.signalingChannel) {
		L_WARNING(@"Cannot send message, either you pass nil data or signaling channel is not available.");
		return NO;
	}
	ECSlideShowMessage *message = [[ECSlideShowMessage alloc] initWithStreamId:self.streamId
																	 enableSlideShow:enable];
	[self.signalingChannel sendSignalingMessage:message];
	return YES;
}

- (void)dealloc {
    [self removeAudioTracks];
    [self removeVideoTracks];
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

- (void)removeAudioTracks {
    if (!_mediaStream) return;

    for (RTCAudioTrack *localAudioTrack in _mediaStream.audioTracks) {
        [_mediaStream removeAudioTrack:localAudioTrack];
    }
}

- (void)removeVideoTracks {
    if (!_mediaStream) return;

    for (RTCVideoTrack *localVideoTrack in _mediaStream.videoTracks) {
        [_mediaStream removeVideoTrack:localVideoTrack];
    }
}

@end
