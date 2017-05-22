//
//  ECSignalingEvent.m
//  ErizoClientIOS
//
//  Created by Alvaro Gil on 5/18/17.
//
//

#import "ECSignalingEvent.h"

@implementation ECSignalingEvent

- (instancetype)initWithName:(NSString *)name message:(NSDictionary *)message {
    if (self = [super init]) {
        self.name = name;
        self.message = [message mutableCopy];

        self.streamId = [NSString stringWithFormat:@"%@", [message objectForKey:kEventKeyId]];
        self.peerSocketId = [message objectForKey:kEventKeyPeerSocketId];
        self.attributes = [message objectForKey:kEventKeyAttributes];
        self.updatedAttributes = [message objectForKey:kEventKeyUpdatedAttributes];
        self.dataStream = [message objectForKey:kEventKeyDataStream];
        self.audio = [(NSNumber *)[message objectForKey:kEventKeyAudio] boolValue];
        self.video = [(NSNumber *)[message objectForKey:kEventKeyVideo] boolValue];
        self.data = [(NSNumber *)[message objectForKey:kEventKeyData] boolValue];

        // FIXME: Sometimes id is provided and sometimes streamId is provided.
        if ((!self.streamId || [self.streamId isEqualToString:@""])
            && [message valueForKey:kEventKeyStreamId]) {
            self.streamId = [NSString stringWithFormat:@"%@", [message objectForKey:kEventKeyStreamId]];
        }
    }
    return self;
}

@end
