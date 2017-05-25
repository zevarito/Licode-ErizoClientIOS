//
//  ECRoomTest.m
//  ErizoClientIOS
//
//  Created by Alvaro Gil on 5/24/17.
//
//

#import "ECUnitTest.h"
#import "ECRoom.h"
#import "ECClient.h"
@import WebRTC;

@interface ECRoomTest : ECUnitTest
@property ECRoom *room;
@property ECRoom *connectedRoom;
@property ECSignalingChannel *mockedSignalingChannel;
@property ECStream *simpleStream;
@end

@implementation ECRoomTest

- (void)setUp {
    _mockedSignalingChannel = mock([ECSignalingChannel class]);
    _room = [[ECRoom alloc] init];
    _connectedRoom = [[ECRoom alloc] init];
    _connectedRoom.signalingChannel = _mockedSignalingChannel;
    [_connectedRoom signalingChannel:_mockedSignalingChannel
                    didConnectToRoom:@{
                                       @"id": @"roomId123",
                                       @"p2p": @"false",
                                       @"streams": @[]
                                       }];

    _simpleStream = [[ECStream alloc] initWithStreamId:@"123"
                                      signalingChannel:_mockedSignalingChannel];
}

- (void)testSubscribeStreamWithoutStreamId {
    ECStream *stream = [[ECStream alloc] init];
    XCTAssertFalse([_room subscribe:stream]);
}

- (void)testSubscribeWithoutBeingConnected {
    XCTAssertNotEqual(_room.status, ECRoomStatusConnected);
    XCTAssertFalse([_room subscribe:_simpleStream]);
    XCTAssertEqual(_connectedRoom.status, ECRoomStatusConnected);
    XCTAssertTrue([_connectedRoom subscribe:_simpleStream]);
}

- (void)testSubscribeStreamMustKeepReferenceToStream {
    [_connectedRoom subscribe:_simpleStream];
    ECStream *roomStream = (ECStream *)[_connectedRoom.streamsByStreamId valueForKey:@"123"];
    XCTAssertNotNil(roomStream);
    XCTAssertEqual(_simpleStream, roomStream);
}

- (void)testSubscribeStreamMustStartSignaling {
    [_connectedRoom subscribe:_simpleStream];
    [verify(_mockedSignalingChannel) subscribe:@"123"
                      signalingChannelDelegate:anything()];
}

- (void)testReceiveRemoteStreamMustAssignSignalingChannelToStream {
    ECStream *mockedStream = mock([ECStream class]);
    [given([mockedStream streamId]) willReturn:@"123"];
    [_connectedRoom subscribe:mockedStream];
    [_connectedRoom appClient:mock([ECClient class])
       didReceiveRemoteStream:mock([RTCMediaStream class])
            withStreamOptions:@{
                                @"id":@"123"
                                }];
    [verify(mockedStream) setSignalingChannel:_mockedSignalingChannel];
}

@end
