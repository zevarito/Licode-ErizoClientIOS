//
//  ECIViewController.m
//  ECIExample
//
//  Created by Alvaro Gil on 8/29/15.
//  Copyright (c) 2015 Alvaro Gil. All rights reserved.
//

#import "ECIViewController.h"

@interface ECIViewController ()

@end

@implementation ECIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)presentOkAlertDialog:(NSString *)title message:(NSString *)message
                   presenter:(UIViewController *)controller
           completionHandler:(void (^)(void))completionHandler {
    
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:title
                                          message:message
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action) {
                                                   if (completionHandler) {
                                                       completionHandler();
                                                   }
                                               }];
    [alertController addAction:ok];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [controller presentViewController:alertController
                                 animated:YES
                               completion:nil];
    });
}

- (void)showOverlayActivityIndicator {
    [self showOverlayActivityIndicator:0.3];
}

- (void)showOverlayActivityIndicatorBlack {
    [self showOverlayActivityIndicator:1.0];
}

- (void)hideOverlayActivityIndicator {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicatorView stopAnimating];
        [self.activityIndicatorOverlayView removeFromSuperview];
    });
}

# pragma mark - Private

- (void)showOverlayActivityIndicator:(CGFloat)opactity {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.activityIndicatorOverlayView.alpha = opactity;
        [self.view addSubview:self.activityIndicatorOverlayView];
        [self.activityIndicatorView startAnimating];
    });
}

- (void)initializeActivityIndicator {
    
    UIScreen *screen = [UIScreen mainScreen];
    
    self.activityIndicatorOverlayView = [[UIView alloc] initWithFrame:screen.bounds];
    
    self.activityIndicatorView = [[UIActivityIndicatorView alloc]
                                  initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    self.activityIndicatorOverlayView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1.0];
    
    self.activityIndicatorView.center = self.activityIndicatorOverlayView.center;
    
    [self.activityIndicatorOverlayView addSubview:self.activityIndicatorView];
}

@end
