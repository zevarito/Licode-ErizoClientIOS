//
//  MultiConferenceViewController.h
//  ECIExampleLicode
//
//  Created by Alvaro Gil on 9/4/15.
//  Copyright (c) 2015 Alvaro Gil. All rights reserved.
//

#import <UIKit/UIKit.h>
@import WebRTC;
#import "ECRoom.h"

@interface MultiConferenceViewController : UIViewController <ECRoomDelegate>

@property (strong, nonatomic) IBOutlet UITextField *inputUsername;
@property (strong, nonatomic) IBOutlet UIButton *connectButton;
@property (strong, nonatomic) IBOutlet RTCEAGLVideoView *localView;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;

- (IBAction)connect:(id)sender;

@end

