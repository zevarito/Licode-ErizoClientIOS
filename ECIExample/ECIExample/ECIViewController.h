//
//  ECIViewController.h
//  ECIExample
//
//  Created by Alvaro Gil on 8/29/15.
//  Copyright (c) 2015 Alvaro Gil. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ECIViewController : UIViewController

@property (strong, nonatomic) UIView *activityIndicatorOverlayView;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;

- (void)presentOkAlertDialog:(NSString *)title message:(NSString *)message
                   presenter:(UIViewController *)controller
           completionHandler:(void (^)(void))completionHandler;

- (void)showOverlayActivityIndicator;
- (void)showOverlayActivityIndicatorBlack;
- (void)hideOverlayActivityIndicator;

@end
