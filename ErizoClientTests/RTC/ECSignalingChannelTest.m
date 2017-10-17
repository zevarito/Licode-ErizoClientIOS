//
//  ECSignalingChannelTest.m
//  ErizoClientIOS
//
//  Created by Alvaro Gil on 6/8/17.
//
//

#import "ECUnitTest.h"
#import "ECSignalingChannelDup.h"
#import "ECRoom.h"

@interface ECSignalingChannelOpened : ECSignalingChannel
@end

@interface ECSignalingChannelTest : ECUnitTest
@property ECSignalingChannelDup *signalingChannel;
@property id<ECSignalingChannelRoomDelegate> mockedRoomDelegate;
@end

@implementation ECSignalingChannelTest

- (void)setUp {
    [super setUp];
    _mockedRoomDelegate = mockProtocol(@protocol(ECSignalingChannelRoomDelegate));
    _signalingChannel = [[ECSignalingChannelDup alloc] initWithEncodedToken:@"token"
                                                               roomDelegate:_mockedRoomDelegate
                                                             clientDelegate:nil];
}

- (void)tearDown {
    [super tearDown];
}

@end
