//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import "Logger.h"
#import "ECSignalingMessage.h"
#import "RTCICECandidate+JSON.h"
#import "RTCSessionDescription+JSON.h"
#import "Utilities.h"

static NSString const *kECSignalingMessageTypeKey = @"type";

@implementation ECSignalingMessage

@synthesize type = _type;

- (instancetype)init {
    [NSException raise:NSGenericException
                format:@"ECSignalingMessage cannot be initialized without streamId"];
    return self;
}

- (instancetype)initWithStreamId:(NSString *)streamId {
    [NSException raise:NSGenericException
                format:@"ECSignalingMessage:initWithStreamId needs to be overrided in sub classes."];
    return self;
}

- (instancetype)initWithType:(ECSignalingMessageType)type streamId:(NSString *)streamId {
    if (self = [super init]) {
        if ([streamId isKindOfClass:[NSNumber class]]) {
            _streamId = [(NSNumber*)streamId stringValue];
        } else if ([streamId isKindOfClass:[NSString class]]) {
            _streamId = streamId;
        } else {
            NSAssert(true, @"streamId is not a string!");
        }
        _type = type;
    }
    return self;
}

- (NSString *)description {
    return [[NSString alloc] initWithData:[self JSONData]
                                 encoding:NSUTF8StringEncoding];
}

+ (ECSignalingMessage *)messageFromDictionary:(NSDictionary *)messageDict {
    
    NSAssert(messageDict, @"ECSignalingMessage messageFromDictionary: undefined messageDict");
    
    NSDictionary *values = [messageDict objectForKey:@"mess"];
	NSString *typeString = nil;
	if([values isKindOfClass:[NSDictionary class]]) {
		typeString = values[kECSignalingMessageTypeKey];
	} else {
		typeString = (NSString*) values;
	}
    //NSString *typeString = values[kECSignalingMessageTypeKey];
    NSString *streamId = [[messageDict objectForKey:@"streamId"] stringValue];
    if (!streamId) {
        streamId = [messageDict objectForKey:@"peerId"];
    }
    ECSignalingMessage *message = nil;
    
    if ([typeString isEqualToString:@"candidate"]) {
        
        RTCICECandidate *candidate = [RTCICECandidate candidateFromJSONDictionary:values];
        message = [[ECICECandidateMessage alloc] initWithCandidate:candidate
                                                       andStreamId:streamId];
        
    } else if ([typeString isEqualToString:@"offer"] ||
               [typeString isEqualToString:@"answer"]) {
        
        RTCSessionDescription *description = [RTCSessionDescription descriptionFromJSONDictionary:values];
        message = [[ECSessionDescriptionMessage alloc] initWithDescription:description
                                                               andStreamId:streamId];
    } else if ([typeString isEqualToString:@"bye"]) {
        message = [[ECByeMessage alloc] initWithStreamId:streamId];
        
    } else if ([typeString isEqualToString:@"ready"]) {
        message = [[ECReadyMessage alloc] initWithStreamId:streamId];
		
	} else if ([typeString isEqualToString:@"timeout"]) {
		message = [[ECTimeoutMessage alloc] initWithStreamId:streamId];
	
	} else if ([typeString isEqualToString:@"failed"]) {
		message = [[ECFailedMessage alloc] initWithStreamId:streamId];
		
	} else if ([typeString isEqualToString:@"started"]) {
		message = [[ECStartedMessage alloc] initWithStreamId:streamId];
		
	} else {
        L_WARNING(@"Unexpected type: %@", typeString);
    }
    return message;
}

- (NSData *)JSONData {
    return nil;
}

@end

@implementation ECICECandidateMessage

@synthesize candidate = _candidate;

- (instancetype)initWithCandidate:(RTCICECandidate *)candidate andStreamId:(NSString *)streamId {
    NSAssert(streamId, @"ECICECandidateMessage initWithCandidate:andStreamId: missing streamId");
    if (self = [super initWithType:kECSignalingMessageTypeCandidate streamId:streamId]) {
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

- (instancetype)initWithDescription:(RTCSessionDescription *)description
                        andStreamId:(NSString *)streamId {
    NSAssert(streamId, @"ECSessionDescriptionMessage initWithDescription missing streamId");
    ECSignalingMessageType type = kECSignalingMessageTypeOffer;
    
    NSString *typeString = description.type;
    if ([typeString isEqualToString:@"offer"]) {
        type = kECSignalingMessageTypeOffer;
    } else if ([typeString isEqualToString:@"answer"]) {
        type = kECSignalingMessageTypeAnswer;
    } else {
        NSAssert(NO, @"Unexpected type: %@", typeString);
    }
    
    if (self = [super initWithType:type streamId:streamId]) {
        _sessionDescription = description;
    }
    return self;
}

- (NSData *)JSONData {
    return [_sessionDescription JSONData];
}

@end

@implementation ECByeMessage

- (instancetype)initWithStreamId:(id)streamId {
    if (self = [super initWithType:kECSignalingMessageTypeBye streamId:streamId]) {
    }
    return self;
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

- (instancetype)initWithStreamId:(id)streamId {
    if (self = [super initWithType:kECSignalingMessageTypeReady streamId:streamId]) {
    }
    return self;
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

@implementation ECTimeoutMessage

- (instancetype)initWithStreamId:(id)streamId {
	if (self = [super initWithType:kECSignalingMessageTypeTimeout streamId:streamId]) {
	}
	return self;
}

- (NSData *)JSONData {
	NSDictionary *message = @{
							  @"type": @"timeout"
							  };
	return [NSJSONSerialization dataWithJSONObject:message
										   options:NSJSONWritingPrettyPrinted
											 error:NULL];
}

@end

@implementation ECFailedMessage

- (instancetype)initWithStreamId:(id)streamId {
	if (self = [super initWithType:kECSignalingMessageTypeFailed streamId:streamId]) {
	}
	return self;
}

- (NSData *)JSONData {
	NSDictionary *message = @{
							  @"type": @"failed"
							  };
	return [NSJSONSerialization dataWithJSONObject:message
										   options:NSJSONWritingPrettyPrinted
											 error:NULL];
}

@end

@implementation ECStartedMessage

- (instancetype)initWithStreamId:(id)streamId {
	if (self = [super initWithType:kECSignalingMessageTypeStarted streamId:streamId]) {
	}
	return self;
}

- (NSData *)JSONData {
	NSDictionary *message = @{
							  @"type": @"started"
							  };
	return [NSJSONSerialization dataWithJSONObject:message
										   options:NSJSONWritingPrettyPrinted
											 error:NULL];
}

@end