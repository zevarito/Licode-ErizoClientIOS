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
#import "RTCEAGLVideoView.h"
#import "RTCMediaConstraints.h"
#import "RTCMediaStream.h"

@implementation ECStream {
    RTCPeerConnectionFactory *factory;
}

# pragma mark - Constructors

- (instancetype)init {
    if (self = [super init]) {
        factory = [[RTCPeerConnectionFactory alloc] init];
    }
    return self;
}

- (instancetype)initWithLocalStream:(RTCMediaConstraints *)mediaConstraints {
    if (self = [self init]) {
        [self createLocalStream:mediaConstraints];
    }
    return self;
}

# pragma mark - Public Methods

- (RTCMediaStream *)createLocalStream:(RTCMediaConstraints *)mediaConstraints {
    _stream = [factory mediaStreamWithLabel:@"LCMS"];
    RTCVideoTrack *localVideoTrack = [self createLocalVideoTrack:mediaConstraints];
    if (localVideoTrack) {
        [_stream addVideoTrack:localVideoTrack];
    }
    [_stream addAudioTrack:[factory audioTrackWithID:@"LCMSa0"]];
    return _stream;
}

# pragma mark - Private Instance Methods

- (RTCVideoTrack *)createLocalVideoTrack:(RTCMediaConstraints *)mediaConstraints {
    RTCVideoTrack* localVideoTrack = nil;
#if !TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE
    if (!mediaConstraints) {
        mediaConstraints = [self defaultMediaStreamConstraints];
    }
    RTCAVFoundationVideoSource *source =
    [[RTCAVFoundationVideoSource alloc] initWithFactory:factory
                                            constraints:mediaConstraints];
    localVideoTrack =
    [[RTCVideoTrack alloc] initWithFactory:factory
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
