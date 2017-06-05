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
@property ECStream *mockedStream;
@property ECRoom *room;
@property ECRoom *connectedRoom;
@property ECRoom *roomWithDelegate;
@property ECSignalingChannel *mockedSignalingChannel;
@property id<ECRoomDelegate> mockedRoomDelegate;
@property ECStream *simpleStream;
@end

@implementation ECRoomTest

- (void)setUp {
    _mockedSignalingChannel = mock([ECSignalingChannel class]);
    _mockedRoomDelegate = mockProtocol(@protocol(ECRoomDelegate));
    _mockedStream = mock([ECStream class]);
    [given([_mockedStream streamId]) willReturn:@"123"];
    _room = [[ECRoom alloc] initWithDelegate:_mockedRoomDelegate andPeerFactory:nil];
    _connectedRoom = [[ECRoom alloc] initWithDelegate:_mockedRoomDelegate andPeerFactory:nil];
    _connectedRoom.signalingChannel = _mockedSignalingChannel;
    [_connectedRoom signalingChannel:_mockedSignalingChannel
                    didConnectToRoom:@{
                                       @"id": @"roomId123",
                                       @"p2p": @"false",
                                       @"streams": @[]
                                       }];

    _simpleStream = [[ECStream alloc] initWithStreamId:@"123"
                                            attributes:@{}
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
    [_connectedRoom subscribe:_mockedStream];
    [_connectedRoom appClient:mock([ECClient class])
       didReceiveRemoteStream:mock([RTCMediaStream class])
            withStreamId:@"123"];
    [verify(_mockedStream) setSignalingChannel:_mockedSignalingChannel];
}

- (void)testRemoteStreamsPropertyReturnsRemoteStreamsOnly {
    [_room signalingChannel:nil didStreamAddedWithId:@"abc" event:nil];
    [_room signalingChannel:nil didStreamAddedWithId:@"def" event:nil];
    [_room signalingChannel:nil didReceiveStreamIdReadyToPublish:@"123"];
    XCTAssertEqual([[_room remoteStreams] count], 2);
    for (ECStream *stream in _room.remoteStreams) {
        XCTAssertNotEqual(stream.streamId, @"123");
    }
}

# pragma mark - delegate ECRoomDelegate

- (void)testECRoomDelegateReceiveDidAddedStreamWhenSubscribing {
    [_connectedRoom subscribe:_mockedStream];
    [_connectedRoom signalingChannel:nil didStreamAddedWithId:@"123" event:nil];
    [verify(_mockedRoomDelegate) room:_connectedRoom didAddedStream:_mockedStream];
}
    
- (void)testECRoomDelegateReceiveDidPublishStreamIdWhenPublishing {
    [_connectedRoom signalingChannel:nil didReceiveStreamIdReadyToPublish:@"123"];
    [_connectedRoom signalingChannel:nil didStreamAddedWithId:@"123" event:nil];
    [verify(_mockedRoomDelegate) room:_connectedRoom didPublishStreamId:@"123"];
    [verifyCount(_mockedRoomDelegate, never()) room:_connectedRoom didAddedStream:_mockedStream];
}

- (void)testCreateECStreamWhenReceiveNewStreamId {
    [_room signalingChannel:nil didStreamAddedWithId:@"123" event:nil];
    XCTAssertEqual([_room.remoteStreams count], 1);
}

# pragma mark - conform ECSignalingChannel

- (void)testSignalingChannelDidConnectToRoomCreateAvailableStreamsWithAttributes {
    [_room signalingChannel:_mockedSignalingChannel
                    didConnectToRoom:@{
                                       @"id": @"roomId123",
                                       @"p2p": @"false",
                                       @"streams": @[@{
                                                        @"audio": @1,
                                                        @"video": @1,
                                                        @"id": @"abc",
                                                        @"attributes": @{@"name": @"john"}
                                                        },
                                                     @{
                                                        @"audio": @1,
                                                        @"video": @1,
                                                        @"id": @"def",
                                                        @"attributes": @{@"name": @"susan"}
                                                        }]
                                       }];
    XCTAssertEqual([_room.remoteStreams count], 2);
    NSString *john = [((ECStream *)[_room.remoteStreams objectAtIndex:0]).streamAttributes objectForKey:@"name"];
    NSString *susan = [((ECStream *)[_room.remoteStreams objectAtIndex:1]).streamAttributes objectForKey:@"name"];
    XCTAssertEqual(john, @"john");
    XCTAssertEqual(susan, @"susan");
}

- (void)testSignalingChannelDidRemovedStreamId {
    [_room signalingChannel:nil didStreamAddedWithId:@"123" event:nil];
    ECStream *stream = _room.remoteStreams[0];
    [_room signalingChannel:nil didRemovedStreamId:@"123"];
    [verify(_mockedRoomDelegate) room:_room didRemovedStream:stream];
    XCTAssertEqual([_room.remoteStreams count], 0);
}

@end
