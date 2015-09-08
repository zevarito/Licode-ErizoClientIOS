//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import "RTCICEServer.h"
#import "RTCPeerConnectionFactory.h"
#import "RTCPair.h"
#import "RTCMediaConstraints.h"
#import "RTCMediaStream.h"
#import "RTCVideoTrack.h"
#import "RTCPeerConnectionInterface.h"
#import "RTCPeerConnectionDelegate.h"

#import "ECClient+Internal.h"
#import "ECSignalingChannel.h"
#import "SDPUtils.h"
#import "RTCICECandidate+JSON.h"
#import "RTCSessionDescription+JSON.h"

static NSString * const kECAppClientErrorDomain = @"ECAppClient";
//static NSInteger const kECAppClientErrorUnknown = -1;
//static NSInteger const kECAppClientErrorRoomFull = -2;
static NSInteger const kECAppClientErrorCreateSDP = -3;
static NSInteger const kECAppClientErrorSetSDP = -4;
//static NSInteger const kECAppClientErrorInvalidClient = -5;
//static NSInteger const kECAppClientErrorInvalidRoom = -6;

@implementation ECClient {
    ECClientState state;
    NSString *currentStreamId;
}

- (instancetype)init {
    if (self = [super init]) {
        _messageQueue = [NSMutableArray array];
    }
    return self;
}

- (instancetype)initWithDelegate:(id<ECClientDelegate>)delegate {
    if (self = [self init]) {
        _delegate = delegate;
        _factory = [[RTCPeerConnectionFactory alloc] init];
    }
    return  self;
}

- (instancetype)initWithDelegate:(id<ECClientDelegate>)delegate
                  andPeerFactory:(RTCPeerConnectionFactory *)peerFactory {
    if (self = [self init]) {
        _delegate = delegate;
        _factory =  peerFactory;
    }
    return  self;
}

- (void)setState:(ECClientState)newState {
    if (state == newState) {
        return;
    }
    state = newState;
    [self.delegate appClient:self didChangeState:state];
}

- (void)disconnect {
    if (state == ECClientStateDisconnected) {
        return;
    }
    
    [_peerConnection close];
    
    _isInitiator = NO;
    _hasReceivedSdp = NO;
    _messageQueue = [NSMutableArray array];
    
    [self setState:ECClientStateDisconnected];
}

- (RTCMediaConstraints *)defaultPeerConnectionConstraints {
    NSArray *optionalConstraints = @[
                                     [[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"true"]
                                     ];
    RTCMediaConstraints* constraints =
    [[RTCMediaConstraints alloc]
     initWithMandatoryConstraints:nil
     optionalConstraints:optionalConstraints];
    return constraints;
}

- (RTCMediaConstraints *)defaultAnswerConstraints {
    return [self defaultOfferConstraints];
}

- (RTCMediaConstraints *)defaultOfferConstraints {
    NSArray *mandatoryConstraints = @[
                                      [[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:@"true"],
                                      [[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:@"true"]
                                      ];
    RTCMediaConstraints* constraints =
    [[RTCMediaConstraints alloc]
     initWithMandatoryConstraints:mandatoryConstraints
     optionalConstraints:nil];
    return constraints;
}

# pragma mark - ECSignalingChannelDelegate

- (void)signalingChannelDidOpenChannel:(ECSignalingChannel *)signalingChannel {
    _signalingChannel = signalingChannel;
    [self setState:ECClientStateReady];
}

- (void)signalingChannel:(ECSignalingChannel *)signalingChannel readyToPublishStreamId:(NSString *)streamId {
    _isInitiator = YES;
    currentStreamId = streamId;
    [self startPublishSignaling];
}

- (void)signalingChannel:(ECSignalingChannel *)channel readyToSubscribeStreamId:(NSString *)streamId {
    _isInitiator = NO;
    currentStreamId = streamId;
    [self startSubscribeSignaling];
}

- (void)signalingChannel:(ECSignalingChannel *)channel
            didReceiveServerConfiguration:(NSDictionary *)serverConfiguration {
    
    _serverConfiguration = serverConfiguration;
    
    // Stunt
    NSURL *defaultSTUNServerURL = [NSURL URLWithString:[_serverConfiguration objectForKey:@"stunServerUrl"]];
    RTCICEServer *stuntServer = [[RTCICEServer alloc] initWithURI:defaultSTUNServerURL
                                                         username:@""
                                                         password:@""];
    
    // Turn
    NSDictionary *turnConfiguration = [_serverConfiguration objectForKey:@"turnServer"];
    RTCICEServer *turnServer = [[RTCICEServer alloc]
                                initWithURI:[NSURL URLWithString:[turnConfiguration objectForKey:@"url"]]
                                username:[turnConfiguration objectForKey:@"username"]
                                password:[turnConfiguration objectForKey:@"password"]];
    
    _iceServers = [NSMutableArray arrayWithObjects:stuntServer, turnServer, nil];
}

- (void)signalingChannel:(ECSignalingChannel *)channel didReceiveMessage:(ECSignalingMessage *)message {
    switch (message.type) {
        case kECSignalingMessageTypeOffer:
        case kECSignalingMessageTypeAnswer:
            _hasReceivedSdp = YES;
            [_messageQueue insertObject:message atIndex:0];
            break;
        case kECSignalingMessageTypeCandidate:
            [_messageQueue addObject:message];
            break;
        case kECSignalingMessageTypeReady:
        case kECSignalingMessageTypeBye:
            [self processSignalingMessage:message];
            return;
    }
    
    [self drainMessageQueueIfReady];
}

#pragma mark - RTCPeerConnectionDelegate
// Callbacks for this delegate occur on non-main thread and need to be
// dispatched back to main queue as needed.

- (void)peerConnection:(RTCPeerConnection *)peerConnection
 signalingStateChanged:(RTCSignalingState)stateChanged {
    dispatch_async(dispatch_get_main_queue(), ^{
        L_DEBUG(@"Signaling state changed: %d", stateChanged);
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
           addedStream:(RTCMediaStream *)stream {
    dispatch_async(dispatch_get_main_queue(), ^{
        L_DEBUG(@"Received %lu video tracks and %lu audio tracks",
              (unsigned long)stream.videoTracks.count,
              (unsigned long)stream.audioTracks.count);
        
        [self.delegate appClient:self didReceiveRemoteStream:stream withStreamId:currentStreamId];
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
         removedStream:(RTCMediaStream *)stream {
    dispatch_async(dispatch_get_main_queue(), ^{
        L_DEBUG(@"Stream was removed.");
    });
}

- (void)peerConnectionOnRenegotiationNeeded: (RTCPeerConnection *)peerConnection {
    dispatch_async(dispatch_get_main_queue(), ^{
        L_DEBUG(@"WARNING: Renegotiation needed but unimplemented.");
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
  iceConnectionChanged:(RTCICEConnectionState)newState {
    dispatch_async(dispatch_get_main_queue(), ^{
    L_DEBUG(@"ICE state changed: %d", newState);
    
        switch (newState) {
            case RTCICEConnectionConnected: {
                [self setState:ECClientStateConnected];
                break;
            }
            case RTCICEConnectionClosed:
            case RTCICEConnectionFailed:
            case RTCICEConnectionDisconnected: {
                [self disconnect];
                break;
            }
            case RTCICEConnectionNew:
            case RTCICEConnectionChecking:
            case RTCICEConnectionCompleted:
                break;
                
            default:
                break;
        }
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
   iceGatheringChanged:(RTCICEGatheringState)newState {
    dispatch_async(dispatch_get_main_queue(), ^{
        L_DEBUG(@"ICE gathering state changed: %d", newState);
        if (newState == RTCICEGatheringComplete) {
            [_signalingChannel drainMessageQueueForStreamId:currentStreamId];
        }
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
       gotICECandidate:(RTCICECandidate *)candidate {
    dispatch_async(dispatch_get_main_queue(), ^{
        ECICECandidateMessage *message =
        [[ECICECandidateMessage alloc] initWithCandidate:candidate andStreamId:currentStreamId];
        [_signalingChannel enqueueSignalingMessage:message];
        [_messageQueue addObject:message];
    });
}

- (void)peerConnection:(RTCPeerConnection*)peerConnection
    didOpenDataChannel:(RTCDataChannel*)dataChannel {
    dispatch_async(dispatch_get_main_queue(), ^{
        L_DEBUG(@"DataChannel Did open DataChannel");
    });
}

#
# pragma mark - RTCSessionDescriptionDelegate
#

- (void)peerConnection:(RTCPeerConnection *)peerConnection
didCreateSessionDescription:(RTCSessionDescription *)sdp
                 error:(NSError *)error {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            L_ERROR(@"Failed to create session description. Error: %@", error);
            [self disconnect];
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: @"Failed to create session description.",
                                       };
            NSError *sdpError =
            [[NSError alloc] initWithDomain:kECAppClientErrorDomain
                                       code:kECAppClientErrorCreateSDP
                                   userInfo:userInfo];
            [self.delegate appClient:self didError:sdpError];
            return;
        }
        
        L_INFO(@"did create a session description!");
        
        RTCSessionDescription *sdpCodecPreferring =
        [SDPUtils descriptionForDescription:sdp
                        //preferredVideoCodec:@"VP8"];
                        preferredVideoCodec:@"H264"];
        [_peerConnection setLocalDescriptionWithDelegate:self
                                      sessionDescription:sdpCodecPreferring];
        ECSessionDescriptionMessage *message =
            [[ECSessionDescriptionMessage alloc] initWithDescription:sdpCodecPreferring
                                                         andStreamId:currentStreamId];
        [_signalingChannel sendSignalingMessage:message];
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didSetSessionDescriptionWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            L_DEBUG(@"Failed to set session description. Error: %@", error);
            [self disconnect];
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: @"Failed to set session description.",
                                       };
            NSError *sdpError =
            [[NSError alloc] initWithDomain:kECAppClientErrorDomain
                                       code:kECAppClientErrorSetSDP
                                   userInfo:userInfo];
            [self.delegate appClient:self didError:sdpError];
            return;
        }
        // If we're answering and we've just set the remote offer we need to create
        // an answer and set the local description.
        if (!_isInitiator && !_peerConnection.localDescription) {
            RTCMediaConstraints *constraints = [self defaultAnswerConstraints];
            [_peerConnection createAnswerWithDelegate:self
                                          constraints:constraints];
            
        }
    });
}

# 
# pragma mark - Private
#

- (void)startPublishSignaling {
    L_INFO(@"Start publish signaling");
    self.state = ECClientStateConnecting;
    
    L_INFO(@"Creating PeerConnection");
    RTCMediaConstraints *constraints = [self defaultPeerConnectionConstraints];
    RTCConfiguration *config = [[RTCConfiguration alloc] init];
    config.iceServers = _iceServers;
    _peerConnection = [_factory peerConnectionWithConfiguration:config
                                                    constraints:constraints
                                                       delegate:self];
    
    L_INFO(@"Adding local media stream to PeerConnection");
    _localStream = [self.delegate streamToPublishByAppClient:self];
    [_peerConnection addStream:_localStream];
    
    [_peerConnection createOfferWithDelegate:self
                                 constraints:[self defaultOfferConstraints]];
}

- (void)startSubscribeSignaling {
    L_INFO(@"Start subscribe signaling");
    self.state = ECClientStateConnecting;
    
    L_INFO(@"Creating PeerConnection");
    RTCMediaConstraints *constraints = [self defaultPeerConnectionConstraints];
    RTCConfiguration *config = [[RTCConfiguration alloc] init];
    config.iceServers = _iceServers;
    _peerConnection = [_factory peerConnectionWithConfiguration:config
                                                    constraints:constraints
                                                       delegate:self];
    
    [_peerConnection createOfferWithDelegate:self
                                 constraints:[self defaultOfferConstraints]];
}

// Processes the messages that we've received from the room server and the
// signaling channel. The offer or answer message must be processed before other
// signaling messages, however they can arrive out of order. Hence, this method
// only processes pending messages if there is a peer connection object and
// if we have received either an offer or answer.
- (void)drainMessageQueueIfReady {
    if (!_peerConnection || !_hasReceivedSdp) {
        return;
    }
    for (ECSignalingMessage *message in _messageQueue) {
        [self processSignalingMessage:message];
    }
    [_messageQueue removeAllObjects];
}

- (void)processSignalingMessage:(ECSignalingMessage *)message {
    NSParameterAssert(_peerConnection ||
                      message.type == kECSignalingMessageTypeBye);
    switch (message.type) {
        case kECSignalingMessageTypeReady:
            break;
        case kECSignalingMessageTypeOffer:
        case kECSignalingMessageTypeAnswer: {
            ECSessionDescriptionMessage *sdpMessage =
            (ECSessionDescriptionMessage *)message;
            RTCSessionDescription *description = sdpMessage.sessionDescription;
            RTCSessionDescription *sdpCodecPreferring =
            [SDPUtils descriptionForDescription:description
                               //preferredVideoCodec:@"VP8"];
                               preferredVideoCodec:@"H264"];
            [_peerConnection setRemoteDescriptionWithDelegate:self
                                           sessionDescription:sdpCodecPreferring];
            break;
        }
        case kECSignalingMessageTypeCandidate: {
            ECICECandidateMessage *candidateMessage =
            (ECICECandidateMessage *)message;
            [_peerConnection addICECandidate:candidateMessage.candidate];
            break;
        }
        case kECSignalingMessageTypeBye:
            [self disconnect];
            break;
    }
}

#
# pragma mark - Extern functions
#

NSString * clientStateToString(ECClientState state) {
    NSString *result = nil;
    switch(state) {
        case ECClientStateDisconnected:
            result = @"ECClientStateDisconnected";
            break;
        case ECClientStateReady:
            result = @"ECClientStateReady";
            break;
        case ECClientStateConnecting:
            result = @"ECClientStateConnecting";
            break;
        case ECClientStateConnected:
            result = @"ECClientStateConnected";
            break;
        default:
            [NSException raise:NSGenericException format:@"Unexpected ECClientState."];
    }
    
    return result;
}

@end