//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import <Foundation/Foundation.h>

#import "RTCICECandidate.h"
#import "RTCSessionDescription.h"

typedef NS_ENUM(NSInteger, ECSignalingMessageType) {
    kECSignalingMessageTypeCandidate,
    kECSignalingMessageTypeOffer,
    kECSignalingMessageTypeAnswer,
    kECSignalingMessageTypeBye,
    kECSignalingMessageTypeReady,
	kECSignalingMessageTypeTimeout,
	kECSignalingMessageTypeFailed,
	kECSignalingMessageTypeStarted
};

@interface ECSignalingMessage : NSObject

- (instancetype)initWithStreamId:(id)streamId;

@property(nonatomic, readonly) ECSignalingMessageType type;
@property(readonly) NSString *streamId;

+ (ECSignalingMessage *)messageFromDictionary:(NSDictionary *)dictionary;
- (NSData *)JSONData;

@end

@interface ECICECandidateMessage : ECSignalingMessage

@property(nonatomic, readonly) RTCICECandidate *candidate;

- (instancetype)initWithCandidate:(RTCICECandidate *)candidate
                      andStreamId:(id)streamId;

@end

@interface ECSessionDescriptionMessage : ECSignalingMessage

@property(nonatomic, readonly) RTCSessionDescription *sessionDescription;

- (instancetype)initWithDescription:(RTCSessionDescription *)description
                        andStreamId:(id)streamId;

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
