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
    _remoteStream = [[ECStream alloc] initWithStreamId:@"123"
                                            attributes:@{}
                                      signalingChannel:_mockedSignalingChannel];
    _mockedSignalingChannel = mock([ECSignalingChannel class]);
}

# pragma mark - Tests

- (void)testInitLocalStream {
    XCTAssertTrue([self isVideoEnabled:_localStream]);
    XCTAssertTrue([self isAudioEnabled:_localStream]);
    XCTAssertTrue([self isDataEnabled:_localStream]);
}

- (void)testInitLocalStreamAndUpdateOptions {
    ECStream *stream = [[ECStream alloc] initLocalStream];
    [stream.streamOptions setValue:@NO forKey:kStreamOptionData];
    [stream.streamOptions setValue:@NO forKey:kStreamOptionVideo];
    [stream.streamOptions setValue:@YES forKey:kStreamOptionAudio];
    [stream.streamOptions setValue:@300 forKey:kStreamOptionMinVideoBW];
    [stream.streamOptions setValue:@1024 forKey:kStreamOptionMaxVideoBW];
    XCTAssertFalse([self isVideoEnabled:stream]);
    XCTAssertTrue([self isAudioEnabled:stream]);
    XCTAssertFalse([self isDataEnabled:stream]);
    XCTAssertEqual(300, [[stream.streamOptions objectForKey:kStreamOptionMinVideoBW] intValue]);
    XCTAssertEqual(1024, [[stream.streamOptions objectForKey:kStreamOptionMaxVideoBW] intValue]);
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
    XCTAssertFalse([stream hasVideo]);
}

- (void)testInitLocalStreamWithoutAudio {
    ECStream *stream = [[ECStream alloc] initLocalStreamWithOptions:@{
                                                                      kStreamOptionAudio:@FALSE
                                                                      }
                                                         attributes:nil
                                                   videoConstraints:nil
                                                   audioConstraints:nil];
    XCTAssertFalse([self isAudioEnabled:stream]);
    XCTAssertFalse([stream hasAudio]);
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

- (void)testLocalStreamRelease {
    __weak ECStream *weakReference;
    @autoreleasepool {
        ECStream *reference = [[ECStream alloc] initLocalStream];
        weakReference = reference;
    }
    XCTAssertNil(weakReference);
}

# pragma mark - Helpers

- (BOOL)isVideoEnabled:(ECStream *)stream {
    return [[NSString stringWithFormat:@"%@",
             [stream.streamOptions objectForKey:@"video"]] boolValue];
}

- (BOOL)isAudioEnabled:(ECStream *)stream {
    return [[NSString stringWithFormat:@"%@",
             [stream.streamOptions objectForKey:@"audio"]] boolValue];
}

- (BOOL)isDataEnabled:(ECStream *)stream {
    return [[NSString stringWithFormat:@"%@",
             [stream.streamOptions objectForKey:@"data"]] boolValue];
}

@end
