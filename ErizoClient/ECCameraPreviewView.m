//
//  ErizoClientIOS
//
//  Copyright (c) 2018 Li Lin (allenlinli@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

@import WebRTC;
#import "ECCameraPreviewView.h"

@interface ECCameraPreviewView()

@property (strong, nonatomic, readonly) RTCCameraPreviewView *cameraPreviewView;

@end

@implementation ECCameraPreviewView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _cameraPreviewView = [[RTCCameraPreviewView alloc] initWithFrame:frame];
        [self addSubview:_cameraPreviewView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame localStream:(ECStream *)localStream {
    if (self = [self initWithFrame:frame]) {
        [self setupWithLocalStream:localStream];
    }
    return self;
}

- (void)setupWithLocalStream:(ECStream *)localStream {
    _localStream = localStream;
    
    if ([localStream.mediaStream.videoTracks.firstObject.source isKindOfClass:[RTCAVFoundationVideoSource class]]) {
        RTCAVFoundationVideoSource *videoSource = (RTCAVFoundationVideoSource *) localStream.mediaStream.videoTracks.firstObject.source;
        self.cameraPreviewView.captureSession = videoSource.captureSession;
    }
}

@end


