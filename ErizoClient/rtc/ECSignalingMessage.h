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

typedef enum {
    kECSignalingMessageTypeCandidate,
    kECSignalingMessageTypeOffer,
    kECSignalingMessageTypeAnswer,
    kECSignalingMessageTypeBye,
    kECSignalingMessageTypeReady
} ECSignalingMessageType;

@interface ECSignalingMessage : NSObject

@property(nonatomic, readonly) ECSignalingMessageType type;

+ (ECSignalingMessage *)messageFromJSONString:(NSString *)jsonString;
+ (ECSignalingMessageType)messageTypeFromString:(NSString*)name;
- (NSData *)JSONData;

@end

@interface ECICECandidateMessage : ECSignalingMessage

@property(nonatomic, readonly) RTCICECandidate *candidate;

- (instancetype)initWithCandidate:(RTCICECandidate *)candidate;

@end

@interface ECSessionDescriptionMessage : ECSignalingMessage

@property(nonatomic, readonly) RTCSessionDescription *sessionDescription;

- (instancetype)initWithDescription:(RTCSessionDescription *)description;

@end

@interface ECByeMessage : ECSignalingMessage
@end

@interface ECReadyMessage : ECSignalingMessage
@end