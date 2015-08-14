//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import "ECClient.h"

#import "ECSignalingChannel.h"
#import "ECSignalingMessage.h"
#import "RTCPeerConnection.h"
#import "RTCPeerConnectionDelegate.h"
#import "RTCPeerConnectionFactory.h"
#import "RTCSessionDescriptionDelegate.h"
#import "RTCICECandidate.h"
#import "RTCSessionDescription.h"

@interface ECClient () <ECSignalingChannelDelegate, RTCPeerConnectionDelegate, RTCSessionDescriptionDelegate>

@property(nonatomic, strong) RTCPeerConnection *peerConnection;
@property(nonatomic, strong) RTCPeerConnectionFactory *factory;
@property(nonatomic, strong) NSMutableArray *messageQueue;
@property(nonatomic, assign) BOOL hasReceivedSdp;
@property(nonatomic, strong) ECSignalingChannel *signalingChannel;
@property(nonatomic, assign) BOOL isInitiator;
@property(nonatomic, strong) NSMutableArray *iceServers;
@property(nonatomic, strong) RTCMediaConstraints *defaultPeerConnectionConstraints;


@end
