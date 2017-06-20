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
#import "Nuve.h"
#import "ErizoClient.h"

static NSString *roomId = @"591df649e29e562067143117";
static NSString *roomName = @"IOS Demo APP";
static NSString *kDefaultUserName = @"ErizoIOS";

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
    
    RTCSetMinDebugLogLevel(RTCLoggingSeverityError);
	
    // Initialize player views array
    playerViews = [NSMutableArray array];
    
    // Setup navigation
    self.tabBarItem.image = [UIImage imageNamed:@"Group-Selected"];
    
    // Access to local camera
    [self initializeLocalStream];

    // Setup UI
    [self setupUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setupUI {
    self.statusLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
                                            initWithTarget:self
                                                    action:@selector(didTapLabelWithGesture:)];
    [self.statusLabel addGestureRecognizer:tapGesture];

    [self showCallConnectViews:YES updateStatusMessage:@"Ready"];
}

- (void)initializeLocalStream {
    // Initialize a stream and access local stream
    localStream = [[ECStream alloc] initLocalStreamWithOptions:nil attributes:@{@"name":@"localStream"}];
    
    // Render local stream
    if ([localStream hasVideo]) {
        RTCVideoTrack *videoTrack = [localStream.mediaStream.videoTracks objectAtIndex:0];
        [videoTrack addRenderer:_localView];
    }
}

# pragma mark - ECRoomDelegate

- (void)room:(ECRoom *)room didError:(ECRoomErrorStatus)status reason:(NSString *)reason {
	[self showCallConnectViews:YES
           updateStatusMessage:[NSString stringWithFormat:@"Room error: %@", reason]];
}

- (void)room:(ECRoom *)room didConnect:(NSDictionary *)roomMetadata {
	[self showCallConnectViews:NO updateStatusMessage:@"Room connected!"];

    NSDictionary *attributes = @{
						   @"name": kDefaultUserName,
						   @"actualName": kDefaultUserName,
						   @"type": @"public",
						   };
    [localStream setAttributes:attributes];
	
	// We get connected and ready to publish, so publish.
    [remoteRoom publish:localStream];

    // Subscribe all streams available in the room.
    for (ECStream *stream in remoteRoom.remoteStreams) {
        [remoteRoom subscribe:stream];
    }
}

- (void)room:(ECRoom *)room didPublishStream:(ECStream *)stream {
    [self.unpublishButton setTitle:@"UnPublish" forState:UIControlStateNormal];
	[self showCallConnectViews:NO
           updateStatusMessage:[NSString stringWithFormat:@"Published with ID: %@", stream.streamId]];
}

- (void)room:(ECRoom *)room didSubscribeStream:(ECStream *)stream {
	[self showCallConnectViews:NO
           updateStatusMessage:[NSString stringWithFormat:@"Subscribed: %@", stream.streamId]];

    // We have subscribed so let's watch the stream.
    [self watchStream:stream];
}

- (void)room:(ECRoom *)room didUnSubscribeStream:(ECStream *)stream {
    [self removeStream:stream.streamId];
}

- (void)room:(ECRoom *)room didAddedStream:(ECStream *)stream {
    // We subscribe to all streams added.
	[self showCallConnectViews:NO
           updateStatusMessage:[NSString stringWithFormat:@"Subscribing stream: %@", stream.streamId]];

    [remoteRoom subscribe:stream];
}

- (void)room:(ECRoom *)room didRemovedStream:(ECStream *)stream {
	[self removeStream:stream.streamId];
}

- (void)room:(ECRoom *)room didStartRecordingStream:(ECStream *)stream
                                    withRecordingId:(NSString *)recordingId
                                      recordingDate:(NSDate *)recordingDate {
    // TODO
}

- (void)room:(ECRoom *)room didFailStartRecordingStream:(ECStream *)stream
                                           withErrorMsg:(NSString *)errorMsg {
    // TODO
}

- (void)room:(ECRoom *)room didUnpublishStream:(ECStream *)stream {
    dispatch_async(dispatch_get_main_queue(), ^{
        localStream = nil;
        [_unpublishButton setTitle:@"Publish" forState:UIControlStateNormal];
    });
}

- (void)room:(ECRoom *)room didChangeStatus:(ECRoomStatus)status {
    switch (status) {
        case ECRoomStatusDisconnected:
            [self showCallConnectViews:YES updateStatusMessage:@"Room Disconnected"];
            break;
    }
}

- (void)room:(ECRoom *)room didReceiveData:(NSDictionary *)data fromStream:(ECStream *)stream {
	L_INFO(@"received data stream %@ %@\n", stream.streamId, data);
}

- (void)room:(ECRoom *)room didUpdateAttributesOfStream:(ECStream *)stream {
	L_INFO(@"updated attributes stream %@ %@\n", stream.streamId, stream.streamAttributes);
}

# pragma mark - RTCEAGLVideoViewDelegate

- (void)videoView:(RTCEAGLVideoView*)videoView didChangeVideoSize:(CGSize)size {
	L_INFO(@"Change %p %f %f", videoView, size.width, size.height);
}

# pragma mark - UI Actions

- (IBAction)connect:(id)sender {
    if (!localStream) {
        [self initializeLocalStream];
    }

    NSString *username = kDefaultUserName;
	[self showCallConnectViews:NO
           updateStatusMessage:@"Connecting with the room..."];

    // Initialize room (without token!)
    remoteRoom = [[ECRoom alloc] initWithDelegate:self
                                   andPeerFactory:[[RTCPeerConnectionFactory alloc] init]];

    /*

    Method 1: Chotis example:
    =========================

    Obtains a token from official Licode demo servers.
    This method is useful if you don't have a custom Licode deployment and
    want to try it. Keep in mind that many times demo servers are down or
    with self-signed or expired certificates.
    You might need to update room ID on LicodeServer.m file.

    [[LicodeServer sharedInstance] obtainMultiVideoConferenceToken:username
            completion:^(BOOL result, NSString *token) {
			if (result) {
				// Connect with the Room
				[remoteRoom connectWithEncodedToken:token];
			} else {
				[self showCallConnectViews:YES updateStatusMessage:@"Token fetch failed"];
			}
    }];

    Method 2: Connect with Nuve directly without middle server API:
    ===============================================================

    The following methods are recommended if you already have your own
    Licode deployment. Check Nuve.h for sub-API details.


    Method 2.1: Create token for the first room name/type available with the posibility
                to create one if not exists.



    [[Nuve sharedInstance] createTokenForTheFirstAvailableRoom:nil
                                                      roomType:RoomTypeMCU
                                                      username:username
                                                        create:YES
                                                    completion:^(BOOL success, NSString *token) {
                                                        if (success) {
                                                            [remoteRoom connectWithEncodedToken:token];
                                                        } else {
                                                            [self showCallConnectViews:YES
                                                                   updateStatusMessage:@"Error!"];
                                                        }
                                                    }];


    Method 2.2: Create a token for a given room id.
    */
    [[Nuve sharedInstance] createTokenForRoomId:roomId
                                       username:username
                                           role:kLicodePresenterRole
                                     completion:^(BOOL success, NSString *token) {
                                         if (success) {
                                            [remoteRoom connectWithEncodedToken:token];
                                         } else {
                                             [self showCallConnectViews:YES
                                                    updateStatusMessage:@"Error!"];
                                         }
                                     }];
    /*
    Method 2.3: Create a Room and then create a Token.

    [[Nuve sharedInstance] createRoomAndCreateToken:roomName
                                           roomType:RoomTypeMCU
                                           username:username
                                              completion:^(BOOL success, NSString *token) {
                                             if (success) {
                                                 [remoteRoom connectWithEncodedToken:token];
                                             } else {
                                                 [self showCallConnectViews:YES
                                                        updateStatusMessage:@"Error!"];
                                             }
                                         }];
        */

}

- (IBAction)leave:(id)sender {
    for (ECStream *stream in remoteRoom.remoteStreams) {
        [self removeStream:stream.streamId];
    }
    [remoteRoom leave];
    remoteRoom = nil;
    [self showCallConnectViews:YES updateStatusMessage:@"Ready"];
}

- (IBAction)unpublish:(id)sender {
    if (localStream) {
        [remoteRoom unpublish];
    } else {
        [self initializeLocalStream];
        [remoteRoom publish:localStream];
        [self.unpublishButton setTitle:@"UnPublish" forState:UIControlStateNormal];
    }
}

- (void)didTapLabelWithGesture:(UITapGestureRecognizer *)tapGesture {
	NSDictionary *data = @{
						   @"name": kDefaultUserName,
						   @"msg": @"my test message in licode chat room"
						   };
	[localStream sendData:data];
	
	NSDictionary *attributes = @{
						   @"name": kDefaultUserName,
						   @"actualName": kDefaultUserName,
						   @"type": @"public",
						   };
	[localStream setAttributes:attributes];
}

- (void)closeStream:(id)sender {
    NSString *streamId = [NSString stringWithFormat:@"%ld", (long)((UIButton *)sender).tag];
    for (ECStream *stream in remoteRoom.remoteStreams) {
        if ([stream.streamId isEqualToString:streamId]) {
            [remoteRoom unsubscribe:stream];
        }
    }
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
    
    // Add button to unsubscribe the stream
    CGRect closeFrame = CGRectMake(0, playerView.frame.size.height - 20,
                                   playerView.frame.size.width, 20);
    UIButton *close = [[UIButton alloc] initWithFrame:closeFrame];
    close.titleLabel.font = [UIFont systemFontOfSize:15.0];
    close.tag = [stream.streamId integerValue];
    [close setTitle:@"Close" forState:UIControlStateNormal];
    close.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    [close addTarget:self action:@selector(closeStream:)
                forControlEvents:UIControlEventTouchUpInside];
    [playerView.videoView addSubview:close];

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
		self.connectButton.hidden = !show;
        self.leaveButton.hidden = show;
        self.unpublishButton.hidden = show;
	});
}

@end
