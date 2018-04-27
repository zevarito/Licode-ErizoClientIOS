//
//  ErizoClientIOS
//
//  Copyright (c) 2018 Li Lin (allenlinli@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import <UIKit/UIKit.h>
@import WebRTC;
#import "ECStream.h"

@interface ECCameraPreviewView : UIView

///-----------------------------------
/// @name Initializers
///-----------------------------------

/**
Create a ECCameraPreviewView.

@param frame Custom frame where this view should be rendered.

@returns instancetype
*/
- (instancetype)initWithFrame:(CGRect)frame;

/**
 Create a ECCameraPreviewView with a local stream that is being displayed on this ECCameraPreview.
 
 @param frame Custom frame where this view should be rendered.
 
 @returns instancetype
 */
- (instancetype)initWithFrame:(CGRect)frame localStream:(ECStream *)localStream;

/**
 Setup this ECCameraPreviewView with a local stream that is being displayed on this ECCameraPreview.
 */
- (void)setupWithLocalStream:(ECStream *)localStream;

///-----------------------------------
/// @name Properties
///-----------------------------------

/// Local stream object that contains a media stream
@property (strong, nonatomic, readonly) ECStream *localStream;

@end
