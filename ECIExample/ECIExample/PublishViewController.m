//
//  PublishViewController.m
//  ECIExample
//
//  Created by Alvaro Gil on 8/28/15.
//  Copyright (c) 2015 Alvaro Gil. All rights reserved.
//

#import "PublishViewController.h"

#import "ECStream.h"
#import "ECRoom.h"
#import "ECClient.h"
#import "RTCEAGLVideoView.h"
#import "RTCVideoTrack.h"
#import "ErizoToken.h"

@interface PublishViewController ()

@end

@implementation PublishViewController {
    RTCEAGLVideoView *localVideoView;
    ECStream *localStream;
    ECRoom *remoteRoom;
    RTCVideoTrack *videoTrack;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create a view to render your own camera
    localVideoView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectMake(0, 0,
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
    
    // UI
    [localVideoView addSubview:self.statusLabel];
    [localVideoView addSubview:self.activityIndicatorOverlayView];
    
    // Token
    [self showOverlayActivityIndicator];
    self.statusLabel.text = @"Obtaining Erizo access token...";
    [[ErizoToken sharedInstance] obtainWithCompletionHandler:^(BOOL result, NSString *token) {
        self.statusLabel.text = @"Initializing Room with access token...";
        remoteRoom = [[ECRoom alloc] initWithEncodedToken:token delegate:self];
        [self hideOverlayActivityIndicator];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)publishButtonDown:(id)sender {
    self.statusLabel.text = @"Publishing local stream!";
    [remoteRoom publish:localStream withOptions:@{@"data": @FALSE}];
}

# pragma mark - ECRoomDelegate

- (void)room:(ECRoom *)room didError:(ECRoomErrorStatus *)status reason:(NSString *)reason {
    [self presentOkAlertDialog:@"Room connection error" message:reason presenter:self completionHandler:nil];
}

- (void)room:(ECRoom *)room didGetReady:(ECClient *)client {
    self.statusLabel.text = @"Room Connected!";
    NSLog(@"Connected to room id: %@", room.roomId);
    [localVideoView addSubview:self.publishButton];
}

- (void)room:(ECRoom *)room didPublishStreamId:(NSString *)streamId {
    self.statusLabel.text = @"Stream published!";
    NSLog(@"Published Stream ID: %@", streamId);
}

- (void)room:(ECRoom *)room didReceiveStreamsList:(NSArray *)list {
    // do nothing here
}

# pragma mark - Private


@end
