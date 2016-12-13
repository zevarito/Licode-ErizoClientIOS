//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import <UIKit/UIKit.h>
@import WebRTC;
#import "ECStream.h"

@interface ECPlayerView : UIView <RTCEAGLVideoViewDelegate>

///-----------------------------------
/// @name Initializers
///-----------------------------------

/**
 Create a Player View with a given stream that is being
 consumed.
 
 @param liveStream The stream that is being consumed by the client.
 
 For example you can initialize a player right after ECRoomDelegate
 has fired ECRoomDelegate:didSubscribeStream passing the ECStream
 object to this initializer.
 
 @see ECRoomDelegate
 
 @returns instancetype
 */
- (instancetype)initWithLiveStream:(ECStream *)liveStream;

/**
 Create a Player View with the given stream that is being consumed in
 a custom frame.
 
 @param liveStream The stream that is being consumed by the client.
 @param frame Custom frame where this control should be rendered.

 @see ECRoomDelegate
 
 @returns instancetype
 */
- (instancetype)initWithLiveStream:(ECStream *)liveStream frame:(CGRect)frame;


/**
 Remove the current assigned rendered for this player
 */
- (void)removeRenderer;

///-----------------------------------
/// @name Properties
///-----------------------------------

/// Stream object that contains a media stream
@property (strong, nonatomic, readonly) ECStream *stream;

/// View where the video gets rendered
@property (strong, nonatomic, readonly) RTCEAGLVideoView *videoView;

@end
