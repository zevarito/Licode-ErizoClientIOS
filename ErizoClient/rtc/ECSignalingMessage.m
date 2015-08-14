//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import "ECSignalingMessage.h"
#import "RTCICECandidate+JSON.h"
#import "RTCSessionDescription+JSON.h"
#import "Utilities.h"

static NSString const *kECSignalingMessageTypeKey = @"type";

@implementation ECSignalingMessage

@synthesize type = _type;

- (instancetype)initWithType:(ECSignalingMessageType)type {
    if (self = [super init]) {
        _type = type;
    }
    return self;
}

- (NSString *)description {
    return [[NSString alloc] initWithData:[self JSONData]
                                 encoding:NSUTF8StringEncoding];
}

+ (ECSignalingMessage *)messageFromJSONString:(NSString *)jsonString {
    NSDictionary *values = [NSDictionary dictionaryWithJSONString:jsonString];
    if (!values) {
        NSLog(@"Error parsing signaling message JSON.");
        return nil;
    }
    
    NSString *typeString = values[kECSignalingMessageTypeKey];
    ECSignalingMessage *message = nil;
    if ([typeString isEqualToString:@"candidate"]) {
        RTCICECandidate *candidate =
        [RTCICECandidate candidateFromJSONDictionary:values];
        message = [[ECICECandidateMessage alloc] initWithCandidate:candidate];
    } else if ([typeString isEqualToString:@"offer"] ||
               [typeString isEqualToString:@"answer"]) {
        RTCSessionDescription *description =
        [RTCSessionDescription descriptionFromJSONDictionary:values];
        message =
        [[ECSessionDescriptionMessage alloc] initWithDescription:description];
    } else if ([typeString isEqualToString:@"bye"]) {
        message = [[ECByeMessage alloc] init];
    } else if ([typeString isEqualToString:@"ready"]) {
        message = [[ECReadyMessage alloc] init];
    } else {
        NSLog(@"Unexpected type: %@", typeString);
    }
    return message;
}

- (NSData *)JSONData {
    return nil;
}

@end

@implementation ECICECandidateMessage

@synthesize candidate = _candidate;

- (instancetype)initWithCandidate:(RTCICECandidate *)candidate {
    if (self = [super initWithType:kECSignalingMessageTypeCandidate]) {
        _candidate = candidate;
    }
    return self;
}

- (NSData *)JSONData {
    return [_candidate JSONData];
}

@end

@implementation ECSessionDescriptionMessage

@synthesize sessionDescription = _sessionDescription;

- (instancetype)initWithDescription:(RTCSessionDescription *)description {
    ECSignalingMessageType type = kECSignalingMessageTypeOffer;
    NSString *typeString = description.type;
    if ([typeString isEqualToString:@"offer"]) {
        type = kECSignalingMessageTypeOffer;
    } else if ([typeString isEqualToString:@"answer"]) {
        type = kECSignalingMessageTypeAnswer;
    } else {
        NSAssert(NO, @"Unexpected type: %@", typeString);
    }
    if (self = [super initWithType:type]) {
        _sessionDescription = description;
    }
    return self;
}

- (NSData *)JSONData {
    return [_sessionDescription JSONData];
}

@end

@implementation ECByeMessage

- (instancetype)init {
    return [super initWithType:kECSignalingMessageTypeBye];
}

- (NSData *)JSONData {
    NSDictionary *message = @{
                              @"type": @"bye"
                              };
    return [NSJSONSerialization dataWithJSONObject:message
                                           options:NSJSONWritingPrettyPrinted
                                             error:NULL];
}

@end

@implementation ECReadyMessage

- (instancetype)init {
    return [super initWithType:kECSignalingMessageTypeReady];
}

- (NSData *)JSONData {
    NSDictionary *message = @{
                              @"type": @"ready"
                              };
    return [NSJSONSerialization dataWithJSONObject:message
                                           options:NSJSONWritingPrettyPrinted
                                             error:NULL];
}

@end
