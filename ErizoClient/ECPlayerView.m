//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

@import WebRTC;
#import "ECPlayerView.h"

@implementation ECPlayerView {
    
CGRect viewFrame;

}

- (instancetype)init {
    if (self = [super init]) {
        _videoView = [[RTCEAGLVideoView alloc] initWithFrame:self.frame];
        [self addSubview:_videoView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    viewFrame = frame;
    if (self = [super initWithFrame:frame]) {
        _videoView = [[RTCEAGLVideoView alloc] initWithFrame:frame];
        [self addSubview:_videoView];
    }
    return self;
}

- (instancetype)initWithLiveStream:(ECStream *)liveStream frame:(CGRect)frame {
    if (self = [self initWithFrame:frame]) {
        _stream  = liveStream;
        
        if (_stream.mediaStream.videoTracks.count > 0) {
            RTCVideoTrack *videoTrack = [_stream.mediaStream.videoTracks objectAtIndex:0];
            [videoTrack addRenderer:_videoView];
        }
    }
    return self;
}

- (instancetype)initWithLiveStream:(ECStream *)liveStream {
    CGRect fullScreenFrame = CGRectMake(0, 0,
               [[UIScreen mainScreen] applicationFrame].size.width,
               [[UIScreen mainScreen] applicationFrame].size.height);
    
    if (self = [self initWithLiveStream:liveStream frame:fullScreenFrame]) {
    }
    return self;
}

- (void)dealloc {
    [self removeRenderer];
}

- (void)removeRenderer {
    if (_stream.mediaStream.videoTracks.count > 0) {
        RTCVideoTrack *videoTrack = [_stream.mediaStream.videoTracks objectAtIndex:0];
        
        [videoTrack removeRenderer:_videoView];
    }
}

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

# pragma mark - RTCEAGLVideoViewDelegate

- (void)videoView:(RTCEAGLVideoView*)videoView didChangeVideoSize:(CGSize)size {
}

@end
