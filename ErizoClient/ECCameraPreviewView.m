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
        CGRect rect = CGRectMake(0.0, 0.0, frame.size.width, frame.size.height);
        _cameraPreviewView = [[RTCCameraPreviewView alloc] initWithFrame:rect];
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
    if (localStream == nil) {
        self.cameraPreviewView.captureSession = nil;
        return;
    }
    if (!localStream.isLocal) {
        return;
    }
    
    _localStream = localStream;
    
    if ([localStream.mediaStream.videoTracks.firstObject.source isKindOfClass:[RTCAVFoundationVideoSource class]]) {
        RTCAVFoundationVideoSource *videoSource = (RTCAVFoundationVideoSource *) localStream.mediaStream.videoTracks.firstObject.source;
        self.cameraPreviewView.captureSession = videoSource.captureSession;
    }
}

@end


