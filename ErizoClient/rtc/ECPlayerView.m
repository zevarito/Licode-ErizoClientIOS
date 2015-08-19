//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import "ECPlayerView.h"
#import "RTCMediaStream.h"
#import "RTCVideoTrack.h"

@implementation ECPlayerView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)init {
    if (self = [super init]) {
        _videoView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectMake(0, 0,
                            [[UIScreen mainScreen] applicationFrame].size.width,
                            [[UIScreen mainScreen] applicationFrame].size.height)];

        [self addSubview:_videoView];
    }
    return self;
}

- (instancetype)initWithLiveStream:(ECStream *)liveStream {
    if (self = [self init]) {
        _stream  = liveStream;
        RTCVideoTrack *videoTrack = [_stream.mediaStream.videoTracks objectAtIndex:0];
        [videoTrack addRenderer:_videoView];
    }
    return self;
}

@end
