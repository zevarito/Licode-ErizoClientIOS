//
//  MultiConferenceViewController.m
//  ECIExampleLicode
//
//  Created by Alvaro Gil on 9/4/15.
//  Copyright (c) 2015 Alvaro Gil. All rights reserved.
//

#import "MultiConferenceViewController.h"
#import "ECRoom.h"
#import "ECStream.h"
#import "ECPlayerView.h"
#import "LicodeServer.h"

@interface MultiConferenceViewController ()
@end

@implementation MultiConferenceViewController {

ECStream *localStream;
ECRoom *remoteRoom;
int remoteStreamsCount;
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Keep track of how many remote streams were added.
    remoteStreamsCount = 0;
    
    // Setup navigation
    self.tabBarItem.image = [UIImage imageNamed:@"Group-Selected"];
    
    // Initialize a stream and access local stream
    localStream = [[ECStream alloc] initLocalStream];
    
    // Render local stream
    if (localStream.mediaStream.videoTracks.count > 0) {
        RTCVideoTrack *videoTrack = [localStream.mediaStream.videoTracks objectAtIndex:0];
        [videoTrack addRenderer:_localView];
    }
    
    // Initialize room (without token!)
    remoteRoom = [[ECRoom alloc] initWithDelegate:self andPeerFactory:localStream.peerFactory];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

# pragma mark - ECRoomDelegate

- (void)room:(ECRoom *)room didError:(ECRoomErrorStatus *)status reason:(NSString *)reason {
    self.statusLabel.text = [NSString stringWithFormat:@"Room error: %@", reason];
    self.inputUsername.hidden = NO;
    self.connectButton.hidden = NO;
}

- (void)room:(ECRoom *)room didConnect:(NSDictionary *)roomMetadata {
    self.statusLabel.text = @"Room connected!";
    
    // We get connected and ready to publish, so publish.
    [remoteRoom publish:localStream withOptions:@{@"data": @FALSE}];
}

- (void)room:(ECRoom *)room didPublishStreamId:(NSString *)streamId {
    self.statusLabel.text = [NSString stringWithFormat:@"Published with ID: %@", streamId];
    self.inputUsername.hidden = YES;
    self.connectButton.hidden = YES;
}

- (void)room:(ECRoom *)room didReceiveStreamsList:(NSArray *)list {
    // Subscribe to all streams available
    for (id item in list) {
        [remoteRoom subscribe:[item valueForKey:@"id"]];
    }
}

- (void)room:(ECRoom *)room didSubscribeStream:(ECStream *)stream {
    self.statusLabel.text = [NSString stringWithFormat:@"Subscribed: %@", stream.streamId];
    
    // We have subscribed so let's watch the stream.
    [self watchStream:stream];
}

- (void)room:(ECRoom *)room didUnSubscribeStream:(NSString *)streamId {
    // Clean stuff
}

- (void)room:(ECRoom *)room didAddedStreamId:(NSString *)streamId {
   
    self.statusLabel.text = [NSString stringWithFormat:@"Subscribing stream: %@", streamId];
    
    // We subscribe to all streams added.
    [remoteRoom subscribe:streamId];
}

- (void)room:(ECRoom *)room didRemovedStreamId:(NSString *)streamId {
}

# pragma mark - UI Actions

- (IBAction)connect:(id)sender {
   
    self.connectButton.hidden = YES;
    self.inputUsername.hidden = YES;
    [self.inputUsername resignFirstResponder];
    
    NSString *username = self.inputUsername.text;
    self.statusLabel.text = @"Connecting with the room...";

    // Obtain token from Licode servers
    [[LicodeServer sharedInstance] obtainMultiVideoConferenceToken:username
            completion:^(BOOL result, NSString *token) {
                
                // Connect with the Room
                [remoteRoom createSignalingChannelWithEncodedToken:token];
    }];
}

# pragma mark - Private

- (void)watchStream:(ECStream *)stream {
    // Stream sizes and position
    remoteStreamsCount++;
    CGRect frame;
    CGFloat vWidth = 100.0;
    CGFloat vHeight = 120.0;
    
    switch (remoteStreamsCount) {
        case 1:
            frame = CGRectMake(10.0, 40.0, vWidth, vHeight);
            break;
        case 2:
            frame = CGRectMake(vWidth + 10.0, 40.0, vWidth, vHeight);
            break;
        case 3:
            frame = CGRectMake(10.0, vHeight + 10.0, vWidth, vHeight);
            break;
        case 4:
            frame = CGRectMake(vWidth + 10.0, vHeight + 10.0, vWidth, vHeight);
            break;
    }
    
    UIView *view = [[UIView alloc] initWithFrame:frame];
    // FIXME: There si a problem with video frames when they are not full screen
    // uncomment line bellow to see the wrong offset.
    // view.backgroundColor = [UIColor redColor];
    [self.view addSubview:view];
    
    // Setup a fram and init a player.
    ECPlayerView *playerView = [[ECPlayerView alloc] initWithLiveStream:stream frame:frame];
    
    // Add player to our main view.
    [self.view addSubview:playerView];
}

@end
