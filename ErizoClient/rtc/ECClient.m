//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import "ErizoClient.h"
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

// Special log for client that appends streamId

#define C_L_DEBUG(f, ...) { \
    L_DEBUG([NSString stringWithFormat:@"sID: %@ : %@", currentStreamId, f], ##__VA_ARGS__); \
}
#define C_L_ERROR(f, ...) { \
    L_ERROR([NSString stringWithFormat:@"sID: %@ : %@", currentStreamId, f], ##__VA_ARGS__); \
}
#define C_L_INFO(f, ...) { \
    L_INFO([NSString stringWithFormat:@"sID: %@ : %@", currentStreamId, f], ##__VA_ARGS__); \
}
#define C_L_WARNING(f, ...) { \
    L_WARNING([NSString stringWithFormat:@"sID: %@ : %@", currentStreamId, f], ##__VA_ARGS__); \
}

/**
 Array of SDP replacements.
 
 Each element should be an array with `matching line` and `replacement line`
 
 @example
 @[@"\r\na=rtcp-fb:101 goog-remb", @""]]
 */

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

#
# pragma mark - Constraints
#

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

#
# pragma mark - ECSignalingChannelDelegate
#

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
    _iceServers = [NSMutableArray array];
    
    for (NSDictionary *dict in [_serverConfiguration objectForKey:@"iceServers"]) {
        NSString *username = [dict objectForKey:@"username"] ? [dict objectForKey:@"username"] : @"";
        NSString *password = [dict objectForKey:@"credential"] ? [dict objectForKey:@"credential"] : @"";
        
        RTCICEServer *iceServer = [[RTCICEServer alloc]
                                    initWithURI:[NSURL URLWithString:[dict objectForKey:@"url"]]
                                    username:username
                                    password:password];
        
        [_iceServers addObject:iceServer];
    }
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
        case kECSignalingMessageTypeStarted:
        case kECSignalingMessageTypeReady:
        case kECSignalingMessageTypeBye:
            [self processSignalingMessage:message];
            return;
        default:
            C_L_INFO(@"");
            break;
    }
    
    [self drainMessageQueueIfReady];
}

#
# pragma mark - RTCPeerConnectionDelegate
#

- (void)peerConnection:(RTCPeerConnection *)peerConnection
 signalingStateChanged:(RTCSignalingState)stateChanged {
    dispatch_async(dispatch_get_main_queue(), ^{
        C_L_DEBUG(@"Signaling state changed: %d", stateChanged);
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
           addedStream:(RTCMediaStream *)stream {
    dispatch_async(dispatch_get_main_queue(), ^{
        C_L_DEBUG(@"Received %lu video tracks and %lu audio tracks",
              (unsigned long)stream.videoTracks.count,
              (unsigned long)stream.audioTracks.count);
        
        [self.delegate appClient:self didReceiveRemoteStream:stream withStreamId:currentStreamId];
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
         removedStream:(RTCMediaStream *)stream {
    dispatch_async(dispatch_get_main_queue(), ^{
        C_L_DEBUG(@"Stream was removed.");
    });
}

- (void)peerConnectionOnRenegotiationNeeded: (RTCPeerConnection *)peerConnection {
    dispatch_async(dispatch_get_main_queue(), ^{
        C_L_DEBUG(@"WARNING: Renegotiation needed but unimplemented.");
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
  iceConnectionChanged:(RTCICEConnectionState)newState {
    dispatch_async(dispatch_get_main_queue(), ^{
        C_L_DEBUG(@"ICE state changed: %d", newState);
    
        switch (newState) {
            case RTCICEConnectionNew:
            case RTCICEConnectionCompleted:
                break;
            case RTCICEConnectionChecking:
                break;
                
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
            default:
                break;
        }
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
   iceGatheringChanged:(RTCICEGatheringState)newState {
    dispatch_async(dispatch_get_main_queue(), ^{
        C_L_DEBUG(@"ICE gathering state changed: %d", newState);
        if (newState == RTCICEGatheringComplete) {
            [_signalingChannel drainMessageQueueForStreamId:currentStreamId];
        }
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
       gotICECandidate:(RTCICECandidate *)candidate {
    dispatch_async(dispatch_get_main_queue(), ^{
        C_L_DEBUG(@"Got ICE candidate");
        ECICECandidateMessage *message =
        [[ECICECandidateMessage alloc] initWithCandidate:candidate andStreamId:currentStreamId];
        [_signalingChannel enqueueSignalingMessage:message];
    });
}

- (void)peerConnection:(RTCPeerConnection*)peerConnection
    didOpenDataChannel:(RTCDataChannel*)dataChannel {
    dispatch_async(dispatch_get_main_queue(), ^{
        C_L_DEBUG(@"DataChannel Did open DataChannel");
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
            C_L_ERROR(@"Failed to create session description. Error: %@", error);
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
        
        C_L_INFO(@"did create a session description!");
        
        RTCSessionDescription *sdpCodecPreferring =
            [SDPUtils descriptionForDescription:sdp preferredVideoCodec:[[self class] getPreferredVideoCodec]];
        
        
        NSString *newSDPString = [self hackSDP:[sdpCodecPreferring description]];
        
        RTCSessionDescription *newSDP = [[RTCSessionDescription alloc] initWithType:sdp.type sdp:newSDPString];
        
        [_peerConnection setLocalDescriptionWithDelegate:self
                                      sessionDescription:newSDP];
        
        ECSessionDescriptionMessage *message =
            [[ECSessionDescriptionMessage alloc] initWithDescription:sdpCodecPreferring
                                                         andStreamId:currentStreamId];
        [_signalingChannel sendSignalingMessage:message];
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didSetSessionDescriptionWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            C_L_DEBUG(@"Failed to set session description. Error: %@", error);
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

- (NSString *)hackSDP:(NSString *)sdp {
    NSString *newSDPString = [sdp copy];
    
    for (NSArray *replacementAry in sdpReplacements) {
    
        NSString *previousSDPString = [newSDPString copy];
        newSDPString = [newSDPString stringByReplacingOccurrencesOfString:replacementAry.firstObject
                                                               withString:replacementAry.lastObject];
        
        NSError *error = NULL;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:replacementAry.firstObject options:NSRegularExpressionCaseInsensitive error:&error];
        if (error) {
            L_ERROR(@"SDP Replacement: Cannot create Regex for: %@", replacementAry.firstObject);
            return nil;
        }
        newSDPString = [regex stringByReplacingMatchesInString:newSDPString
                                                       options:0
                                                         range:NSMakeRange(0, [newSDPString length])
                                                  withTemplate:replacementAry.lastObject];
        
        
        if (![newSDPString isEqualToString:previousSDPString]) {
            L_DEBUG(@"SDP Line replaced! %@ with %@", replacementAry.firstObject, replacementAry.lastObject);
        }
    }
    
    return newSDPString;
}

- (void)startPublishSignaling {
    C_L_INFO(@"Start publish signaling");
    self.state = ECClientStateConnecting;
    
    C_L_INFO(@"Creating PeerConnection");
    RTCMediaConstraints *constraints = [self defaultPeerConnectionConstraints];
    RTCConfiguration *config = [[RTCConfiguration alloc] init];
    config.iceServers = _iceServers;
    _peerConnection = [_factory peerConnectionWithConfiguration:config
                                                    constraints:constraints
                                                       delegate:self];
    
    C_L_INFO(@"Adding local media stream to PeerConnection");
    _localStream = [self.delegate streamToPublishByAppClient:self];
    [_peerConnection addStream:_localStream];
    
    [_peerConnection createOfferWithDelegate:self
                                 constraints:[self defaultOfferConstraints]];
}

- (void)startSubscribeSignaling {
    C_L_INFO(@"Start subscribe signaling");
    self.state = ECClientStateConnecting;
    
    C_L_INFO(@"Creating PeerConnection");
    RTCMediaConstraints *constraints = [self defaultPeerConnectionConstraints];
    RTCConfiguration *config = [[RTCConfiguration alloc] init];
    config.iceServers = _iceServers;
    _peerConnection = [_factory peerConnectionWithConfiguration:config
                                                    constraints:constraints
                                                       delegate:self];
    
    [_peerConnection createOfferWithDelegate:self
                                 constraints:[self defaultOfferConstraints]];
}

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
                                preferredVideoCodec:[[self class] getPreferredVideoCodec]];
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
        
        default:
            C_L_WARNING(@"Unhandled Message");
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

#
# pragma mark - Class methods
#
+ (void)replaceSDPLine:(NSString *)line withNewLine:(NSString *)newLine {
    if (!sdpReplacements) {
        sdpReplacements = [NSMutableArray array];
    }
    
    [sdpReplacements addObject:@[line, newLine]];
}

+ (void)setPreferredVideoCodec:(NSString *)codec {
    preferredVideoCodec = codec;
}

+ (NSString *)getPreferredVideoCodec {
    if (preferredVideoCodec) {
        return preferredVideoCodec;
    } else {
        return defaultVideoCodec;
    }
}

@end