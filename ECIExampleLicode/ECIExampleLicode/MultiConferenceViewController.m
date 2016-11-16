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

// Remote video view size
static CGFloat vWidth = 100.0;
static CGFloat vHeight = 120.0;

@interface MultiConferenceViewController () <UITextFieldDelegate, RTCEAGLVideoViewDelegate>
@end

@implementation MultiConferenceViewController {
    ECStream *localStream;
    ECRoom *remoteRoom;
    NSMutableArray *playerViews;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	//self textfield delegate
	self.inputUsername.delegate = self;
	
    // Initialize player views array
    playerViews = [NSMutableArray array];
    
    // Setup navigation
    self.tabBarItem.image = [UIImage imageNamed:@"Group-Selected"];
    
    // Initialize a stream and access local stream
    localStream = [[ECStream alloc] initLocalStream];
    
    // Render local stream
    if ([localStream hasVideo]) {
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
	[self showCallConnectViews:YES updateStatusMessage:[NSString stringWithFormat:@"Room error: %@", reason]];
}

- (void)room:(ECRoom *)room didConnect:(NSDictionary *)roomMetadata {
	[self showCallConnectViews:NO updateStatusMessage:@"Room connected!"];

	NSDictionary *attributes = @{
						   @"name": self.inputUsername.text,
						   @"actualName": self.inputUsername.text,
						   @"type": @"public",
						   };
	
	// We get connected and ready to publish, so publish.
	[remoteRoom publish:localStream withOptions:@{@"data": @FALSE, @"attributes": attributes}];
	
	// We get connected and ready to publish, so publish.
	//[remoteRoom publish:localStream withOptions:nil];
}

- (void)room:(ECRoom *)room didPublishStream:(NSDictionary *)stream {
	[self showCallConnectViews:NO updateStatusMessage:[NSString stringWithFormat:@"Published with ID: %@", [stream objectForKey:@"id"]]];
}

- (void)room:(ECRoom *)room didReceiveStreamsList:(NSArray *)list {
    // Subscribe to all streams available
    for (id item in list) {
        [remoteRoom subscribe:item];
    }
}

- (void)room:(ECRoom *)room didSubscribeStream:(ECStream *)stream {
	[self showCallConnectViews:NO updateStatusMessage:[NSString stringWithFormat:@"Subscribed: %@", stream.streamId]];
    
    // We have subscribed so let's watch the stream.
    [self watchStream:stream];
}

- (void)room:(ECRoom *)room didUnSubscribeStream:(NSString *)streamId {
    // Clean stuff
}

- (void)room:(ECRoom *)room didAddedStream:(NSDictionary *)stream {
	
	[self showCallConnectViews:NO updateStatusMessage:[NSString stringWithFormat:@"Subscribing stream: %@", [stream objectForKey:@"id"]]];
    
    // We subscribe to all streams added.
    [remoteRoom subscribe:[stream objectForKey:@"id"]];
}

- (void)room:(ECRoom *)room didRemovedStreamId:(NSString *)streamId {
	[self removeStream:streamId];
}

- (void)room:(ECRoom *)room didStartRecordingStreamId:(NSString *)streamId withRecordingId:(NSString *)recordingId recordingDate:(NSDate *)recordingDate {
}

- (void)room:(ECRoom *)room didFailStartRecordingStreamId:(NSString *)streamId withErrorMsg:(NSString *)errorMsg {
}

- (void)room:(ECRoom *)room didChangeStatus:(ECRoomStatus)status {
}

# pragma mark - RTCEAGLVideoViewDelegate

- (void)videoView:(RTCEAGLVideoView*)videoView didChangeVideoSize:(CGSize)size {
	NSLog(@"Change %p %f %f", videoView, size.width, size.height);
}

# pragma mark - UI Actions

- (IBAction)connect:(id)sender {

    NSString *username = self.inputUsername.text;
	[self showCallConnectViews:NO updateStatusMessage:@"Connecting with the room..."];

    // Obtain token from Licode servers
    [[LicodeServer sharedInstance] obtainMultiVideoConferenceToken:username
            completion:^(BOOL result, NSString *token) {
			if (result) {
				// Connect with the Room
				[remoteRoom createSignalingChannelWithEncodedToken:token];
			} else {
				[self showCallConnectViews:YES updateStatusMessage:@"Token fetch failed"];
			}
    }];
}

# pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return NO;
}

# pragma mark - Private

- (void)watchStream:(ECStream *)stream {
    // Setup a fram and init a player.
    CGRect frame = CGRectMake(0, 0, vWidth, vHeight);
    ECPlayerView *playerView = [[ECPlayerView alloc] initWithLiveStream:stream frame:frame];
	playerView.videoView.delegate = self;
    
    // Add player view to collection and to our view.
    [playerViews addObject:playerView];
    [self.view addSubview:playerView];
}

- (void)removeStream:(NSString *)streamId {
	for (int index = 0; index < [playerViews count]; index++) {
		ECPlayerView *playerView = [playerViews objectAtIndex:index];
		if ([playerView.stream.streamId caseInsensitiveCompare:streamId] == NSOrderedSame) {
			[playerViews removeObjectAtIndex:index];
			[playerView removeFromSuperview];
			break;
		}
	}
	
}

- (void)viewDidLayoutSubviews {
    for (int i=0; i<[playerViews count]; i++) {
        [self layoutPlayerView:playerViews[i] index:i];
    }
}

- (void)layoutPlayerView:(ECPlayerView *)playerView index:(int)index {

    CGRect frame;
    CGFloat vOffset = 80.0;
    CGFloat margin = 20.0;
    
    switch (index) {
        case 0:
            frame = CGRectMake(margin, vOffset, vWidth, vHeight);
            break;
        case 1:
            frame = CGRectMake(vWidth + margin * 2, vOffset, vWidth, vHeight);
            break;
        case 2:
            frame = CGRectMake(margin, vOffset + vHeight + margin, vWidth, vHeight);
            break;
        case 3:
            frame = CGRectMake(vWidth + margin * 2, vOffset + vHeight + margin, vWidth, vHeight);
            break;
        default:
            [NSException raise:NSGenericException
                        format:@"Sorry we allow only 4 streams on this example :)"];
            break;
    }
    
    [playerView setFrame:frame];
}

- (void)showCallConnectViews:(BOOL)show updateStatusMessage:(NSString *)statusMessage {
	dispatch_async(dispatch_get_main_queue(), ^{
		self.statusLabel.text = statusMessage;
		self.inputUsername.hidden = !show;
		self.connectButton.hidden = !show;
		if(!show) {
			[self.inputUsername resignFirstResponder];
		}
	});
}

@end
