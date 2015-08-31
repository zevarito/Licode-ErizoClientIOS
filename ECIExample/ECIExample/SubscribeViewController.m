//
//  SecondViewController.m
//  ECIExample
//
//  Created by Alvaro Gil on 8/28/15.
//  Copyright (c) 2015 Alvaro Gil. All rights reserved.
//

#import "SubscribeViewController.h"
#import "AppDelegate.h"
#import "ErizoToken.h"
#import "ECPlayerView.h"
#import "ECRoom.h"

@interface SubscribeViewController ()

@end

@implementation SubscribeViewController {

    // The remote Erizo stream that we will consume.
    ECStream *remoteStream;

    // The room we will connect.
    ECRoom *remoteRoom;

    // The video player we will use to reproduce the stream.
    ECPlayerView *playerView;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // UI
    [self.view addSubview:self.statusLabel];
    [self.view addSubview:self.activityIndicatorOverlayView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

# pragma mark - ECRoomDelegate

// Print Room errors if arrive.
- (void)room:(ECRoom *)room didError:(ECRoomErrorStatus *)status reason:(NSString *)reason {
    [self presentOkAlertDialog:@"Room connection error" message:reason presenter:self completionHandler:nil];
}

// Indicates we have connected with the room successfuly
- (void)room:(ECRoom *)room didGetReady:(ECClient *)client {
    self.statusLabel.text = @"Room Connected!";
    NSLog(@"Connected to room id: %@", room.roomId);
}

// This event will be called once you get subscribed to the stream.
- (void)room:(ECRoom *)room didSubscribeStream:(ECStream *)stream {
    // Initialize a player view.
    playerView = [[ECPlayerView alloc] initWithLiveStream:stream];
    
    // Add your player view to your own view.
    [self.view addSubview:playerView];
}

// We will receive a list of streams as soon as we get connected into the room
// and subscribe to the first one.
- (void)room:(ECRoom *)room didReceiveStreamsList:(NSArray *)list {
    if ([list count] > 0) {
        // Get the ID of first stream in the list.
        NSDictionary *streamMeta = [list objectAtIndex:0];
        
        // Subscribe to that stream ID.
        [room subscribe:[streamMeta objectForKey:@"id"]];
    }
}

- (IBAction)subscribe:(id)sender {
    // Token
    [self showOverlayActivityIndicator];
    self.statusLabel.text = @"Obtaining Erizo access token...";
    
    // Nasty backend configuration to get an access token with Subscribing priviledges.
    AppDelegate *app        = [[UIApplication sharedApplication] delegate];
    NSString *url           = [app.plist objectForKey:@"Subscribe Token URL"];
    NSString *method        = [app.plist objectForKey:@"Subscribe Token Method"];
    NSDictionary *postData  = [app.plist objectForKey:@"Subscribe Token POST JSON"];
    NSString *namespace     = [app.plist objectForKey:@"Subscribe Token JSON Namespace"];
    NSString *field         = [app.plist objectForKey:@"Subscribe Token JSON Field"];
    
    // Obtain that token.
    [[ErizoToken sharedInstance]obtainWithStringURL:url requestMethod:method
                              responseJSONNamespace:namespace responseJSONField:field
                                           postData:postData
                                         completion:^(BOOL result, NSString *token) {
                                             
                                             self.statusLabel.text = @"Initializing Room with access token...";
                                             // Connect with the Room at the given access token.
                                             remoteRoom = [[ECRoom alloc] initWithEncodedToken:token delegate:self];
                                             [self hideOverlayActivityIndicator];
                                         }];
}
@end
