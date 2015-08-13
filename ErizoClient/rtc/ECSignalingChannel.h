//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import "SocketIO.h"
#import "SocketIOPacket.h"
#import "ECSignalingMessage.h"

@class ECSignalingChannel;

@protocol ECSignalingChannelDelegate <NSObject>

- (void)didOpenChannel:(ECSignalingChannel*)signalingChannel;
- (void)didReceiveServerConfiguration:(NSDictionary *)serverConfiguration;
- (void)didReceiveMessage:(ECSignalingMessage*)message;
- (void)didReceiveStreamIdReadyToPublish;
- (void)didStreamAddedWithId:(NSString*)streamId;
- (void)didStartRecordingStreamId:(NSString*)streamId withRecordingId:(NSString*)recordingId;

@end

@interface ECSignalingChannel : NSObject

- (instancetype)initWithToken:(NSDictionary*)token delegate:(id)signalingDelegate;
- (void)open;
- (void)disconnect;
- (void)enqueueSignalingMessage:(ECSignalingMessage*)message;
- (void)sendSignalingMessage:(ECSignalingMessage*)message;
- (void)drainMessageQueue;
- (void)publish:(NSDictionary*)attributes;
- (void)startRecording;
    
@end
