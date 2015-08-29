//
//  FirstViewController.h
//  ECIExample
//
//  Created by Alvaro Gil on 8/28/15.
//  Copyright (c) 2015 Alvaro Gil. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECIViewController.h"
#import "ECRoom.h"

@interface PublishViewController: ECIViewController <ECRoomDelegate>

@property (strong, nonatomic) IBOutlet UIButton *publishButton;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;

- (IBAction)publishButtonDown:(id)sender;

@end

