//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import "Logger.h"
#import "ECSignalingMessage.h"
#import "RTCIceCandidate+JSON.h"
#import "RTCSessionDescription+JSON.h"
#import "Utilities.h"

static NSString const *kECSignalingMessageTypeKey = @"type";
static NSString const *kECSignalingMessageAgentIdKey = @"agentId";

@implementation ECSignalingMessage

@synthesize type = _type;

- (instancetype)init {
    [NSException raise:NSGenericException
                format:@"ECSignalingMessage cannot be initialized without streamId"];
    return self;
}

- (instancetype)initWithStreamId:(NSString *)streamId peerSocketId:(NSString *)peerSocketId {
    [NSException raise:NSGenericException
                format:@"ECSignalingMessage:initWithStreamId needs to be overrided in sub classes."];
    return self;
}

- (instancetype)initWithType:(ECSignalingMessageType)type
                    streamId:(NSString *)streamId
                peerSocketId:(NSString *)peerSocketId {
    if (self = [super init]) {
        if ([streamId isKindOfClass:[NSNumber class]]) {
            _streamId = [(NSNumber*)streamId stringValue];
        } else if ([streamId isKindOfClass:[NSString class]]) {
            _streamId = streamId;
        } else {
            NSAssert(true, @"streamId is not a string!");
        }
        _peerSocketId = peerSocketId;
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

    ECSignalingMessage *message = nil;
    NSDictionary *values;
    NSString *typeString;
    NSString *streamId;
    NSString *peerSocketId;

    values = [messageDict objectForKey:@"mess"];
    if (!values) {
        values = [messageDict objectForKey:@"msg"];
    }
    if (!values) {
        NSAssert(false, @"ECSignalingMessage:messageFromDictionary unable to parse messageDict");
    }

	if([values isKindOfClass:[NSDictionary class]]) {
		typeString = values[kECSignalingMessageTypeKey];
	} else {
		typeString = (NSString*)values;
	}

    if ([messageDict objectForKey:@"streamId"]) {
        streamId = [NSString stringWithFormat:@"%@", [messageDict objectForKey:@"streamId"]];
    }
    if (!streamId && [messageDict objectForKey:@"peerId"]) {
        streamId = [NSString stringWithFormat:@"%@", [messageDict objectForKey:@"peerId"]];
    }
    if ([messageDict objectForKey:@"peerSocket"]) {
        peerSocketId = [NSString stringWithFormat:@"%@", [messageDict objectForKey:@"peerSocket"]];
    }

    if ([typeString isEqualToString:@"candidate"]) {

        RTCIceCandidate *candidate = [RTCIceCandidate candidateFromJSONDictionary:values];
        message = [[ECICECandidateMessage alloc] initWithCandidate:candidate
                                                          streamId:streamId
                                                      peerSocketId:peerSocketId];

    } else if ([typeString isEqualToString:@"offer"] ||
               [typeString isEqualToString:@"answer"]) {

        RTCSessionDescription *description = [RTCSessionDescription descriptionFromJSONDictionary:values];
        message = [[ECSessionDescriptionMessage alloc] initWithDescription:description
                                                                  streamId:streamId
                                                              peerSocketId:peerSocketId];

    } else if ([typeString isEqualToString:@"bye"]) {
        message = [[ECByeMessage alloc] initWithStreamId:streamId
                                            peerSocketId:peerSocketId];

    } else if ([typeString isEqualToString:@"ready"]) {
        message = [[ECReadyMessage alloc] initWithStreamId:streamId
                                              peerSocketId:peerSocketId];
	} else if ([typeString isEqualToString:@"timeout"]) {
        message = [[ECTimeoutMessage alloc] initWithStreamId:streamId
                                                peerSocketId:peerSocketId];
	
	} else if ([typeString isEqualToString:@"failed"]) {
        message = [[ECFailedMessage alloc] initWithStreamId:streamId
                                               peerSocketId:peerSocketId];
		
	} else if ([typeString isEqualToString:@"started"]) {
        message = [[ECStartedMessage alloc] initWithStreamId:streamId
                                                peerSocketId:peerSocketId];
		
	} else if ([typeString isEqualToString:@"bandwidthAlert"]) {
		message = [[ECBandwidthAlertMessage alloc] initWithStreamId:streamId
													   peerSocketId:peerSocketId];

    } else if ([typeString isEqualToString:@"initializing"]) {
        NSString *agentId = values[kECSignalingMessageAgentIdKey];
        message = [[ECInitializingMessage alloc] initWithStreamId:streamId
                                                          agentId:agentId];
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

- (instancetype)initWithCandidate:(RTCIceCandidate *)candidate
                      streamId:(NSString *)streamId
                     peerSocketId:(NSString *)peerSocketId {
    NSAssert(streamId, @"ECICECandidateMessage initWithCandidate:streamId:peerSocketId: missing streamId");
    if (self = [super initWithType:kECSignalingMessageTypeCandidate
                          streamId:streamId
                      peerSocketId:peerSocketId]) {
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
                           streamId:(NSString *)streamId
                       peerSocketId:(NSString *)peerSocketId {
    NSAssert(streamId, @"ECSessionDescriptionMessage initWithDescription missing streamId");
    ECSignalingMessageType type = kECSignalingMessageTypeOffer;
    
    if (description.type == RTCSdpTypeOffer) {
        type = kECSignalingMessageTypeOffer;
    } else if (description.type == RTCSdpTypeAnswer) {
        type = kECSignalingMessageTypeAnswer;
    } else {
        NSAssert(NO, @"Unexpected sdp type: %ld", (long)description.type);
    }
    
    if (self = [super initWithType:type streamId:streamId peerSocketId:peerSocketId]) {
        _sessionDescription = description;
    }
    return self;
}

- (NSData *)JSONData {
    return [self.sessionDescription JSONData];
}

@end

@implementation ECByeMessage

- (instancetype)initWithStreamId:(RTCSessionDescription *)description
                        streamId:(NSString *)streamId
                    peerSocketId:(NSString *)peerSocketId {

    if (self = [super initWithType:kECSignalingMessageTypeBye
                          streamId:streamId
                      peerSocketId:peerSocketId]) {
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

- (instancetype)initWithStreamId:(id)streamId peerSocketId:(NSString *)peerSocketId {
    if (self = [super initWithType:kECSignalingMessageTypeReady
                          streamId:streamId
                      peerSocketId:peerSocketId]) {
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

- (instancetype)initWithStreamId:(id)streamId peerSocketId:(NSString *)peerSocketId {
    if (self = [super initWithType:kECSignalingMessageTypeTimeout
                          streamId:(NSString *)streamId
                      peerSocketId:(NSString *)peerSocketId]) {
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

- (instancetype)initWithStreamId:(id)streamId peerSocketId:(NSString *)peerSocketId {
    if (self = [super initWithType:kECSignalingMessageTypeFailed
                          streamId:(NSString *)streamId
                      peerSocketId:(NSString *)peerSocketId]) {
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

- (instancetype)initWithStreamId:(id)streamId peerSocketId:(NSString *)peerSocketId {
    if (self = [super initWithType:kECSignalingMessageTypeStarted
                          streamId:streamId
                      peerSocketId:peerSocketId]) {
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

@implementation ECBandwidthAlertMessage

- (instancetype)initWithStreamId:(id)streamId peerSocketId:(NSString *)peerSocketId {
	if (self = [super initWithType:kECSignalingMessageTypeBandwidthAlert
						  streamId:streamId
					  peerSocketId:peerSocketId]) {
	}
	return self;
}

- (NSData *)JSONData {
	NSDictionary *message = @{
							  @"type": @"bandwidthAlert"
							  };
	return [NSJSONSerialization dataWithJSONObject:message
										   options:NSJSONWritingPrettyPrinted
											 error:NULL];
}

@end

@implementation ECDataStreamMessage

- (instancetype)initWithStreamId:(id)streamId withData:(NSDictionary*) data {
	if (self = [super initWithType:kECSignalingMessageTypeDataStream
						  streamId:streamId
					  peerSocketId:nil]) {
		self.data = data;
	}
	return self;
}

- (NSData *)JSONData {
	return [NSJSONSerialization dataWithJSONObject:self.data
										   options:NSJSONWritingPrettyPrinted
											 error:NULL];
}

@end

@implementation ECInitializingMessage
- (instancetype)initWithStreamId:(id)streamId agentId:(NSString *)agentId {
    if (self = [super initWithType:kECSignalingMessageTypeInitializing
                          streamId:streamId
                      peerSocketId:agentId]) {
        self.agentId = agentId;
    }
    return self;
}
@end

@implementation ECUpdateAttributeMessage

- (instancetype)initWithStreamId:(id)streamId withAttribute:(NSDictionary*) attribute {
	if (self = [super initWithType:kECSignalingMessageTypeUpdateAttribute
						  streamId:streamId
					  peerSocketId:nil]) {
		self.attribute = attribute;
	}
	return self;
}

- (NSData *)JSONData {
	return [NSJSONSerialization dataWithJSONObject:self.attribute
										   options:NSJSONWritingPrettyPrinted
											 error:NULL];
}
@end

@implementation ECSlideShowMessage

- (instancetype)initWithStreamId:(id)streamId enableSlideShow:(BOOL) enable {
	if (self = [super initWithType:kECSignalingMessageTypeUpdateAttribute
						  streamId:streamId
					  peerSocketId:nil]) {
		self.enableSlideShow = enable;
	}
	return self;
}

- (NSData *)JSONData {
	
	NSDictionary *config = @{
							 @"slideShowMode": (self.enableSlideShow) ? @YES : @NO
							 };
	NSDictionary *message = @{
							  @"type": @"updatestream",
							  @"config": config
							  };
	return [NSJSONSerialization dataWithJSONObject:message
										   options:NSJSONWritingPrettyPrinted
											 error:NULL];
}

@end
