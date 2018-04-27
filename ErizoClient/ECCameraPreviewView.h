//
//  ErizoClientIOS
//
//  Copyright (c) 2018 Li Lin (allenlinli@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import <UIKit/UIKit.h>
@import WebRTC;
#import "ECStream.h"

@interface ECCameraPreviewView : UIView

- (instancetype)initWithFrame:(CGRect)frame;

- (instancetype)initWithFrame:(CGRect)frame localStream:(ECStream *)localStream withLocalCapturer:(RTCCameraVideoCapturer *)localCapturer;

- (void)setupWithLocalStream:(ECStream *)localStream;

/// Local stream object that contains a media stream
@property (strong, nonatomic, readonly) ECStream *localStream;

@end
