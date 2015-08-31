//
//  SecondViewController.h
//  ECIExample
//
//  Created by Alvaro Gil on 8/28/15.
//  Copyright (c) 2015 Alvaro Gil. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECIViewController.h"
#import "ECRoom.h"

@interface SubscribeViewController : ECIViewController <ECRoomDelegate>

@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UITextField *tokenTextField;
@property (strong, nonatomic) IBOutlet UIButton *subscribeButton;

- (IBAction)subscribe:(id)sender;

@end

