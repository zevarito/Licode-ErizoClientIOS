//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import "ErizoClient.h"
#import "ECClient+Internal.h"
#import "ECSignalingChannel.h"
#import "SDPUtils.h"
#import "RTCIceCandidate+JSON.m"
#import "RTCSessionDescription+JSON.h"

// Special log for client that appends streamId

#define C_L_DEBUG(f, ...) { \
    L_DEBUG([NSString stringWithFormat:@"sID: %@ : %@", _streamId, f], ##__VA_ARGS__); \
}
#define C_L_ERROR(f, ...) { \
    L_ERROR([NSString stringWithFormat:@"sID: %@ : %@", _streamId, f], ##__VA_ARGS__); \
}
#define C_L_INFO(f, ...) { \
    L_INFO([NSString stringWithFormat:@"sID: %@ : %@", _streamId, f], ##__VA_ARGS__); \
}
#define C_L_WARNING(f, ...) { \
    L_WARNING([NSString stringWithFormat:@"sID: %@ : %@", _streamId, f], ##__VA_ARGS__); \
}

/**
 Array of SDP replacements.
 
 Each element should be an array with `matching line` and `replacement line`
 
 @example
 @[@"\r\na=rtcp-fb:101 goog-remb", @""]]
 */

@implementation ECClient {
    ECClientState state;
}

- (instancetype)init {
    if (self = [super init]) {
        _messageQueue = [NSMutableArray array];
        _limitBitrate = NO;
        _maxBitrate = [NSNumber numberWithInteger:1000];
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
                     peerFactory:(RTCPeerConnectionFactory *)peerFactory
                    peerSocketId:(NSString *)peerSocketId {
    if (self = [self initWithDelegate:delegate andPeerFactory:peerFactory]) {
        _peerSocketId = peerSocketId;
    }
    return  self;
}

- (instancetype)initWithDelegate:(id<ECClientDelegate>)delegate
                     peerFactory:(RTCPeerConnectionFactory *)peerFactory
                        streamId:(NSString *)streamId
                    peerSocketId:(NSString *)peerSocketId {
    if (self = [self initWithDelegate:delegate andPeerFactory:peerFactory]) {
        _peerSocketId = peerSocketId;
        _streamId = streamId;
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

- (instancetype)initWithDelegate:(id<ECClientDelegate>)delegate
                     peerFactory:(RTCPeerConnectionFactory *)peerFactory
                        streamId:(NSString *)streamId
                    peerSocketId:(NSString *)peerSocketId
                         options:(NSDictionary *)options {
    if (self = [self initWithDelegate:delegate peerFactory:peerFactory streamId:streamId peerSocketId:peerSocketId]) {
        _clientOptions = options;
    }
    return self;
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
    NSDictionary *optionalConstraints = @{@"DtlsSrtpKeyAgreement":@"true"};
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
    NSDictionary *mandatoryConstraints = @{
                                      @"OfferToReceiveAudio": @"true",
                                      @"OfferToReceiveVideo": @"true"
                                      };
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
    // Assume Client delegate (Room) has received ice servers
    NSDictionary *iceServers = [_delegate appClientRequestICEServers:self];
    [self setupICEServers:iceServers];
    [self setState:ECClientStateReady];
}

- (void)signalingChannel:(ECSignalingChannel *)signalingChannel
  readyToPublishStreamId:(NSString *)streamId
            peerSocketId:(NSString *)peerSocketId {

    _streamId = streamId;
    _peerSocketId = peerSocketId;

    if (_peerSocketId) {
        _isInitiator = NO;
        [self startPublishSignaling];
    } else {
        _isInitiator = YES;
        [self startPublishSignaling];
    }
}

- (void)signalingChannelPublishFailed:(ECSignalingChannel *)signalingChannel {
}

- (void)signalingChannel:(ECSignalingChannel *)channel
readyToSubscribeStreamId:(NSString *)streamId
            peerSocketId:(NSString *)peerSocketId {
    _isInitiator = NO;
    _streamId = streamId;
    _peerSocketId = peerSocketId;
    [self startSubscribeSignaling];
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
          didAddStream:(nonnull RTCMediaStream *)stream {
    dispatch_async(dispatch_get_main_queue(), ^{
        C_L_DEBUG(@"Received %lu video tracks and %lu audio tracks",
                  (unsigned long)stream.videoTracks.count,
                  (unsigned long)stream.audioTracks.count);
        
        [self.delegate appClient:self didReceiveRemoteStream:stream withStreamId:self.streamId];
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
       didRemoveStream:(RTCMediaStream *)stream {
    C_L_DEBUG(@"Stream was removed.");
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
                didChangeSignalingState:(RTCSignalingState)stateChanged {
    dispatch_async(dispatch_get_main_queue(), ^{
        C_L_DEBUG(@"Signaling state changed: %d", stateChanged);
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
                                didChangeIceConnectionState:(RTCIceConnectionState)newState {

    dispatch_async(dispatch_get_main_queue(), ^{
        C_L_DEBUG(@"ICE state changed: %d", newState);
    
        switch (newState) {
            case RTCIceConnectionStateNew:
            case RTCIceConnectionStateCompleted:
                break;
            case RTCIceConnectionStateChecking:
                break;
                
            case RTCIceConnectionStateConnected: {
                [self setState:ECClientStateConnected];
                break;
            }
            case RTCIceConnectionStateFailed: {
                L_WARNING(@"RTCIceConnectionStateFailed %@", peerConnection);
                break;
            }
            case RTCIceConnectionStateClosed:
            case RTCIceConnectionStateDisconnected: {
                [self disconnect];
                break;
            }
            default:
                break;
        }
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
                didChangeIceGatheringState:(RTCIceGatheringState)newState {
    dispatch_async(dispatch_get_main_queue(), ^{
        C_L_DEBUG(@"ICE gathering state changed: %d", newState);
        if (newState == RTCIceGatheringStateComplete) {
            [_signalingChannel drainMessageQueueForStreamId:_streamId peerSocketId:_peerSocketId];
        }
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didRemoveIceCandidates:(nonnull NSArray<RTCIceCandidate *> *)candidates {
    dispatch_async(dispatch_get_main_queue(), ^{
        C_L_DEBUG(@"Remove ICE candidates: %@", candidates);
    });
}


- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didGenerateIceCandidate:(nonnull RTCIceCandidate *)candidate {
    dispatch_async(dispatch_get_main_queue(), ^{
        C_L_DEBUG(@"Generated ICE candidate: %@", candidate);
        ECICECandidateMessage *message =
        [[ECICECandidateMessage alloc] initWithCandidate:candidate
                                                streamId:_streamId
                                            peerSocketId:_peerSocketId];
        [_signalingChannel enqueueSignalingMessage:message];
    });
}

- (void)peerConnection:(RTCPeerConnection*)peerConnection
    didOpenDataChannel:(RTCDataChannel*)dataChannel {
    dispatch_async(dispatch_get_main_queue(), ^{
        C_L_DEBUG(@"DataChannel Did open DataChannel");
    });
}

- (void)peerConnectionShouldNegotiate:(RTCPeerConnection *)peerConnection {
    C_L_WARNING(@"Renegotiation needed but unimplemented.");
}

# 
# pragma mark - Private
#

- (void)setupICEServers:(NSDictionary *)ICEServersConfiguration {
    _iceServers = [NSMutableArray array];

    for (NSDictionary *dict in ICEServersConfiguration) {
        NSString *username = [dict objectForKey:@"username"] ? [dict objectForKey:@"username"] : nil;
        NSString *password = [dict objectForKey:@"credential"] ? [dict objectForKey:@"credential"] : nil;
        NSArray *urls = @[];

        if ([dict objectForKey:@"urls"] && [[dict objectForKey:@"urls"] isKindOfClass:[NSArray class]]) {
            urls = [dict objectForKey:@"urls"];
        } else if ([dict objectForKey:@"url"] && [[dict objectForKey:@"url"] isKindOfClass:[NSString class]]) {
            urls = @[[dict objectForKey:@"url"]];
        } else {
            L_ERROR(@"No url found for ICEServer!");
            continue;
        }

        RTCIceServer *iceServer = [[RTCIceServer alloc] initWithURLStrings:urls
                                                                  username:username
                                                                credential:password];
        [_iceServers addObject:iceServer];
    }

    L_DEBUG(@"Ice Servers: %@", _iceServers);
}

- (void)startPublishSignaling {
    if (_peerSocketId) {
        C_L_INFO(@"Start publish P2P signaling");
    } else {
        C_L_INFO(@"Start publish signaling");
    }

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
    __weak ECClient *weakSelf = self;
    [_peerConnection offerForConstraints:[self defaultOfferConstraints]
                       completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
                           ECClient *strongSelf = weakSelf;
                           [strongSelf peerConnection:strongSelf.peerConnection didCreateSessionDescription:sdp error:error];
    }];
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
    __weak ECClient *weakSelf = self;
    if (_peerSocketId) {
        [self drainMessageQueueIfReady];
    } else {
        [_peerConnection offerForConstraints:[self defaultOfferConstraints]
                           completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
                               ECClient *strongSelf = weakSelf;
                               [strongSelf peerConnection:strongSelf.peerConnection didCreateSessionDescription:sdp error:error];
                           }];
    }
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
    switch (message.type) {
        case kECSignalingMessageTypeReady:
            break;
        case kECSignalingMessageTypeStarted:
            break;
        case kECSignalingMessageTypeOffer:
        case kECSignalingMessageTypeAnswer: {
            ECSessionDescriptionMessage *sdpMessage = (ECSessionDescriptionMessage *)message;
            RTCSessionDescription *description = sdpMessage.sessionDescription;
            RTCSessionDescription *newSDP =
                [SDPUtils descriptionForDescription:description
                                preferredVideoCodec:[[self class] getPreferredVideoCodec]];
            
            newSDP = [self descriptionForDescription:newSDP bandwidthOptions:_clientOptions];
            
            __weak ECClient *weakSelf = self;
            [_peerConnection setRemoteDescription:newSDP
                                completionHandler:^(NSError * _Nullable error) {
                ECClient *strongSelf = weakSelf;
                [strongSelf peerConnection:strongSelf.peerConnection didSetSessionDescriptionWithError:error];
            }];
            break;
        }
        case kECSignalingMessageTypeCandidate: {
            ECICECandidateMessage *candidateMessage =
            (ECICECandidateMessage *)message;
            [_peerConnection addIceCandidate:candidateMessage.candidate];
            break;
        }
        case kECSignalingMessageTypeBye:
            [self disconnect];
            break;
        
        default:
            C_L_WARNING(@"Unhandled Message", message);
            break;
    }
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didSetSessionDescriptionWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            C_L_ERROR(@"Failed to set session description: %@", error);
            NSError *sdpError =
            [[NSError alloc] initWithDomain:kECAppClientErrorDomain
                                       code:kECAppClientErrorSetSDP
                                   userInfo:error.userInfo];
            [self.delegate appClient:self didError:sdpError];
            [self disconnect];
            return;
        }
        // If we're answering and we've just set the remote offer we need to create
        // an answer and set the local description.
        if (!_isInitiator && !_peerConnection.localDescription) {
            RTCMediaConstraints *constraints = [self defaultAnswerConstraints];
            __weak ECClient *weakSelf = self;
            [_peerConnection answerForConstraints:constraints
                                completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
                
                ECClient *strongSelf = weakSelf;
                [strongSelf peerConnection:strongSelf.peerConnection didCreateSessionDescription:sdp
                                                                                           error:error];
            }];
        }
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didCreateSessionDescription:(RTCSessionDescription *)sdp
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
        
        RTCSessionDescription *newSDP =
                    [SDPUtils descriptionForDescription:sdp
                                    preferredVideoCodec:[[self class] getPreferredVideoCodec]];
        
        newSDP = [self descriptionForDescription:newSDP bandwidthOptions:_clientOptions];

        if (sdpHackCallback) {
            newSDP = sdpHackCallback(newSDP);
        }

        __weak typeof(self) weakSelf = self;
        [_peerConnection setLocalDescription:newSDP completionHandler:^(NSError * _Nullable error) {
            ECClient *strongSelf = weakSelf;
            [strongSelf peerConnection:strongSelf.peerConnection didSetSessionDescriptionWithError:error];

            if (!error) {
                ECSessionDescriptionMessage *message = [[ECSessionDescriptionMessage alloc]
                                                         initWithDescription:newSDP
                                                                    streamId:weakSelf.streamId
                                                                peerSocketId:weakSelf.peerSocketId];
                [weakSelf.signalingChannel sendSignalingMessage:message];

                if (weakSelf.limitBitrate) {
                    [strongSelf setMaxBitrateForPeerConnectionVideoSender];
                }
            } else {
                [strongSelf.delegate appClient:strongSelf didError:error];
            }
        }];
        
    });
}

- (void)setMaxBitrateForPeerConnectionVideoSender {
    for (RTCRtpSender *sender in _peerConnection.senders) {
        if (sender.track != nil) {
            if ([sender.track.kind isEqualToString:kRTCMediaStreamTrackKindVideo]) {
                [self setMaxBitrate:_maxBitrate forVideoSender:sender];
            }
        }
    }
}

- (void)setMaxBitrate:(NSNumber *)maxBitrate forVideoSender:(RTCRtpSender *)sender {
    if (maxBitrate.intValue <= 0) {
        return;
    }
    
    RTCRtpParameters *parametersToModify = sender.parameters;
    for (RTCRtpEncodingParameters *encoding in parametersToModify.encodings) {
        encoding.maxBitrateBps = @(maxBitrate.intValue * kKbpsMultiplier);
    }
    [sender setParameters:parametersToModify];
}

- (RTCSessionDescription *)descriptionForDescription:(RTCSessionDescription *)description
                                    bandwidthOptions:(NSDictionary *)options {
    RTCSessionDescription *newSDP = description;
    id value = options[kClientOptionMaxVideoBW];
    if (value && [value isKindOfClass:[NSNumber class]]) {
        NSInteger maxVideoBW = [(NSNumber *)value integerValue];
        newSDP = [SDPUtils descriptionForDescription:newSDP bandwidthLimit:maxVideoBW forMediaType:@"video"];
    }
    
    value = options[kClientOptionMaxAudioBW];
    if (value && [value isKindOfClass:[NSNumber class]]) {
        NSInteger maxAudioBW = [(NSNumber *)value integerValue];
        newSDP = [SDPUtils descriptionForDescription:newSDP bandwidthLimit:maxAudioBW forMediaType:@"audio"];
    }
    
    return newSDP;
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

+ (void)hackSDPWithBlock:(SDPHackCallback)callback {
    sdpHackCallback = callback;
}

@end
