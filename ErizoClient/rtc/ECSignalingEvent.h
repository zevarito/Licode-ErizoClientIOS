//
//  ECSignalingEvent.h
//  ErizoClientIOS
//
//  Created by Alvaro Gil on 5/18/17.
//
//

#import <Foundation/Foundation.h>

///-----------------------------------
/// @name Dictionary Keys
///-----------------------------------
static NSString *const kEventKeyId                  = @"id";
static NSString *const kEventKeyStreamId            = @"streamId";
static NSString *const kEventKeyPeerSocketId        = @"peerSocket";
static NSString *const kEventKeyAudio               = @"audio";
static NSString *const kEventKeyData                = @"data";
static NSString *const kEventKeyVideo               = @"video";
static NSString *const kEventKeyAttributes          = @"attributes";
static NSString *const kEventKeyUpdatedAttributes   = @"attrs";
static NSString *const kEventKeyDataStream          = @"msg";

///-----------------------------------
/// @name Erizo Event Types
///-----------------------------------
static NSString * const kEventOnAddStream				= @"onAddStream";
static NSString * const kEventOnRemoveStream			= @"onRemoveStream";
static NSString * const kEventSignalingMessageErizo		= @"signaling_message_erizo";
static NSString * const kEventSignalingMessagePeer		= @"signaling_message_peer";
static NSString * const kEventPublishMe					= @"publish_me";
static NSString * const kEventOnDataStream				= @"onDataStream";
static NSString * const kEventOnUpdateAttributeStream	= @"onUpdateAttributeStream";

/**
 @interface ECSignalingEvent
 */
@interface ECSignalingEvent : NSObject

@property NSString *name;
@property NSDictionary *message;
@property NSString *streamId;
@property NSString *peerSocketId;
@property NSDictionary *attributes;
@property NSDictionary *updatedAttributes;
@property NSDictionary *dataStream;
@property BOOL audio;
@property BOOL video;
@property BOOL data;

- (instancetype)initWithName:(NSString *)name
                     message:(NSDictionary *)message;
@end
