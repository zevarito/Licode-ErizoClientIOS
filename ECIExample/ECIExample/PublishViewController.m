//
//  PublishViewController.m
//  ECIExample
//
//  Created by Alvaro Gil on 8/28/15.
//  Copyright (c) 2015 Alvaro Gil. All rights reserved.
//

#import "PublishViewController.h"

#import "ECStream.h"
#import "RTCEAGLVideoView.h"
#import "RTCVideoTrack.h"

@interface PublishViewController ()

@end

@implementation PublishViewController {
    ECStream *localStream;
    RTCVideoTrack *videoTrack;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create a view to render your own camera
    RTCEAGLVideoView *localVideoView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectMake(0, 0,
                                            [[UIScreen mainScreen] applicationFrame].size.width,
                                            [[UIScreen mainScreen] applicationFrame].size.height)];
    
    // Add your video view to your UI view
    [self.view addSubview:localVideoView];
    
    // Initialize a local stream
    localStream = [[ECStream alloc] initWithLocalStream];
    
    // If there are local stream, render in view.
    if (localStream.mediaStream.videoTracks.count > 0) {
        videoTrack = [localStream.mediaStream.videoTracks objectAtIndex:0];
        [videoTrack addRenderer:localVideoView];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
