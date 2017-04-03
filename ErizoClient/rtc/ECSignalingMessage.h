//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

@import WebRTC;
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ECSignalingMessageType) {
    kECSignalingMessageTypeCandidate,
    kECSignalingMessageTypeOffer,
    kECSignalingMessageTypeAnswer,
    kECSignalingMessageTypeBye,
    kECSignalingMessageTypeReady,
	kECSignalingMessageTypeTimeout,
	kECSignalingMessageTypeFailed,
	kECSignalingMessageTypeStarted,
	kECSignalingMessageTypeBandwidthAlert,
	kECSignalingMessageTypeDataStream
};

@interface ECSignalingMessage : NSObject

- (instancetype)initWithStreamId:(id)streamId peerSocketId:(NSString *)peerSocketId;

@property(nonatomic, readonly) ECSignalingMessageType type;
@property(readonly) NSString *streamId;
@property(readonly) NSString *peerSocketId;

+ (ECSignalingMessage *)messageFromDictionary:(NSDictionary *)dictionary;
- (NSData *)JSONData;

@end

@interface ECICECandidateMessage : ECSignalingMessage

@property(nonatomic, readonly) RTCIceCandidate *candidate;

- (instancetype)initWithCandidate:(RTCIceCandidate *)candidate
                         streamId:(NSString *)streamId
                     peerSocketId:(NSString *)peerSocketId;

@end

@interface ECSessionDescriptionMessage : ECSignalingMessage

@property(nonatomic, readonly) RTCSessionDescription *sessionDescription;

- (instancetype)initWithDescription:(RTCSessionDescription *)description
                        streamId:(NSString *)streamId
                       peerSocketId:(NSString *)peerSocketId;

@end

@interface ECByeMessage : ECSignalingMessage
@end

@interface ECReadyMessage : ECSignalingMessage
@end

@interface ECTimeoutMessage : ECSignalingMessage
@end

@interface ECFailedMessage : ECSignalingMessage
@end

@interface ECStartedMessage : ECSignalingMessage
@end

@interface ECBandwidthAlertMessage : ECSignalingMessage
@end

@interface ECDataStreamMessage : ECSignalingMessage

@property(nonatomic, strong) NSDictionary* data;

- (instancetype)initWithStreamId:(id)streamId withData:(NSDictionary*) data;

@end
