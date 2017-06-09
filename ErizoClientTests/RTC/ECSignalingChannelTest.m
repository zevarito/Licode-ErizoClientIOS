//
//  ECSignalingChannelTest.m
//  ErizoClientIOS
//
//  Created by Alvaro Gil on 6/8/17.
//
//

#import "ECUnitTest.h"
#import "SocketIOPacket.h"
#import "ECSignalingChannelDup.h"
#import "ECRoom.h"

@interface ECSignalingChannelOpened : ECSignalingChannel<SocketIODelegate>
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

# pragma mark - SocketIO

- (void)testSocketIODidReceiveEventOnUpdateAttributeStream {
    SocketIOPacket *paquet = mock([SocketIOPacket class]);
    [given(paquet.name) willReturn:kEventOnUpdateAttributeStream];
    NSDictionary *attributes = @{@"name":@"susan"};
    [given(paquet.args) willReturn:@[@{@"id":@"123", kEventKeyUpdatedAttributes:attributes}]];
    [_signalingChannel socketIO:nil didReceiveEvent:paquet];
    [verify(_mockedRoomDelegate) signalingChannel:_signalingChannel
                                     fromStreamId:@"123"
                           updateStreamAttributes:attributes];
}

@end
