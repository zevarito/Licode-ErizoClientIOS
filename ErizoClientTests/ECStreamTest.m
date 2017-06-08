//
//  ECStreamTest.m
//  ErizoClientIOS
//
//  Created by Alvaro Gil on 5/23/17.
//
//

#import "ECUnitTest.h"
#import "ECStream.h"
#import "ECClient.h"


@interface ECStreamTest : ECUnitTest
@property ECStream *localStream;
@property ECStream *remoteStream;
@property ECSignalingChannel *mockedSignalingChannel;
@end

@implementation ECStreamTest

- (void)setUp {
    [super setUp];
    _localStream = [[ECStream alloc] initLocalStream];
    _remoteStream = [[ECStream alloc] initWithStreamId:@"123" attributes:@{} signalingChannel:nil];
    _mockedSignalingChannel = mock([ECSignalingChannel class]);
}

# pragma mark - Tests

- (void)testInitLocalStream {
    XCTAssertTrue([self isVideoEnabled:_localStream]);
    XCTAssertTrue([self isAudioEnabled:_localStream]);
    XCTAssertTrue([self isDataEnabled:_localStream]);
}

- (void)testInitLocalStreamWithAttributesFlaggedDirty {
    NSDictionary *attributes = @{
                                 @"name":@"susy"
                                };
    ECStream *stream = [[ECStream alloc] initLocalStreamWithOptions:nil
                                                         attributes:attributes];
    XCTAssertEqual(stream.streamAttributes, attributes);
    XCTAssertTrue(stream.dirtyAttributes);
}

- (void)testInitLocalStreamWithoutVideo {
    ECStream *stream = [[ECStream alloc] initLocalStreamWithOptions:@{
                                                                      kStreamOptionVideo:@FALSE
                                                                      }
                                                         attributes:nil
                                                   videoConstraints:nil
                                                   audioConstraints:nil];
    XCTAssertFalse([self isVideoEnabled:stream]);
}

- (void)testAudioStreamHasNotBeenAdded {
    ECStream *stream = [[ECStream alloc] initLocalStreamWithOptions:@{
                                                                      kStreamOptionAudio:@FALSE
                                                                      }
                                                         attributes:nil];
    XCTAssertFalse([stream hasAudio]);
}

- (void)testAudioStreamHasBeenAdded {
    XCTAssertTrue([_localStream hasAudio]);
}

- (void)testSetAttributesMustBeFlaggedDirtyForLocalStream {
    [_localStream setAttributes:@{@"name": @"cool stream"}];
    XCTAssertTrue(_localStream.dirtyAttributes);
    [_remoteStream setAttributes:@{@"name": @"cool stream"}];
    XCTAssertFalse(_remoteStream.dirtyAttributes);
}

- (void)testSetAttributesMustBeUnFlaggedDirtyWhenSignalingChannelAssigned {
    [_localStream setAttributes:@{@"name": @"cool stream"}];
    _localStream.signalingChannel = _mockedSignalingChannel;
    [verify(_mockedSignalingChannel) updateStreamAttributes:anything()];
    XCTAssertFalse(_localStream.dirtyAttributes);
}

# pragma mark - Helpers

- (BOOL)isVideoEnabled:(ECStream *)stream {
    return [[NSString stringWithFormat:@"%@",
             [stream.streamOptions objectForKey:kStreamOptionVideo]] boolValue];
}

- (BOOL)isAudioEnabled:(ECStream *)stream {
    return [[NSString stringWithFormat:@"%@",
             [stream.streamOptions objectForKey:kStreamOptionAudio]] boolValue];
}

- (BOOL)isDataEnabled:(ECStream *)stream {
    return [[NSString stringWithFormat:@"%@",
             [stream.streamOptions objectForKey:kStreamOptionData]] boolValue];
}

@end
