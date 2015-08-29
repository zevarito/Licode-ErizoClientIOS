# Licode ErizoClientIOS

IOS Erizo Client for [Licode WebRTC Framework](http://lynckia.com/licode)

* [Features](#features)
* [Roadmap](#roadmap)
* [Installation](#installation)
* [Documentation](#documentation)
* [Examples](#examples)
* [Contributing](#contributing)
* [Authorship](#authorship)
* [License](#license)

## Features

  * Connect to Rooms with encoded tokens.
  * Capture local Audio & Video media.
  * Ability to switch between front/rear camera.
  * Publish local Media.
  * Subscribe live streams.
  * Reproduce live streams.
  * Server side stream recording.
  
## Roadmap
  * Integrate with Licode online web examples.
  * Figure out % of complete.
  * Versioning.
  * Improve documentation.
  * Move from SocketIO-objc to official SocketIO lib.
  * Add *refactor* in between each previous item.

## Installation

This project includes `libjingle_peerconnection` with [CocoaPods], if you don't have Pods installed, please follow this guide before start: [Install CocoaPods].

##### Guide

* Clone this repo
```bash
git clone git@github.com:zevarito/ErizoClientIOS.git
```

* Install pods
```bash
pod install
```

* Open XCode Workspace
```bash
open ErizoClientIOS.xcworkspace/
```

* Build

* Link result library into your project

Drag the compiled library here:

```
XCode > Project Properties > Build Phases > Link Binary With Libraries
```

* Add search path into your project

If you are working on a workspace with ErizoClient inside, you might use something
like this:

```
${SRCROOT}/../Vendor
${SRCROOT}/../ErizoClient
${SRCROOT}/../ErizoClient/rtc
```

If not, just point to the directory where ErizoClient is.

## Documentation

[Public API documentation](http://zevarito.github.io/ErizoClientIOS/docs/public/html/)

[Full API documentation](http://zevarito.github.io/ErizoClientIOS/docs/dev/html/)


## Examples

  * [Example App](#example-app)
  * [New project setup](#new-project-setup)
  * [Connect to Rooms with a encoded token](#connect-to-a-room)
  * [Capture Audio & Video](#capture-audio-and-video)
  * [Publish local Media](#publish-local-media)
  * [Subscribe live streams](#subscribe-live-streams)
  * [Stream recording](#stream-recording)
 
### Example App

There is an example project inside lib workspace that you can check as reference
to use ErizoClientIOS on your own project.

Be sure to edit `debug.xcconfig.sample` under ECIExample folder with the values
needed for the examples to work. Then rename that file removing `.sample` part.

### New Project Setup

These steps are needed if you want to start a new application.

Add this in your `AppDelegate.m`:
```objc
#import "ErizoClient.h"

[ErizoClient sharedInstance];
```

### Connect to a Room

Import this headers:

```objc
#import "ECRoom.h"
```

In your pivot class:

```objc
// Instantiate a Room with the token you get from the server to authenticate.
ECRoom *room = [[ECRoom alloc] initWithEncodedToken:encodedToken delegate:self];
```

Be sure to have implemented [ECRoomDelegate] protocol in your delegate.
```objc
- (void)room:(ECRoom *)room didGetReady:(ECClient *)client {
  // Enable start broadcast button
}
```

### Capture Audio and Video

Import this headers:

```objc
#import "ECStream.h"
#import "RTCEAGLVideoView.h"
#import "RTCVideoTrack.h"
```

And in your **View Controller**:

```objc

// Define these iVars
ECStream *localStream;
RTCVideoTrack *videoTrack;

// Create a view to render your own camera
RTCEAGLVideoView *localVideoView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectMake(0, 0,
   [[UIScreen mainScreen] applicationFrame].size.width,
   [[UIScreen mainScreen] applicationFrame].size.height)];

// Add your video view to your UI view
[self.view addSubview:localVideoView];

// Initialize a local stream
localStream = [[ECStream alloc] initWithLocalStream];
    
if (localStream.mediaStream.videoTracks.count > 0) {
    videoTrack = [localStream.mediaStream.videoTracks objectAtIndex:0];
    [videoTrack addRenderer:localVideoView];
}
```

To switch between front and rear camera.

```objc
[localStream switchCamera];
```

### Publish local Media

Once you have connected to a room (*Example 1*) and got access to local media (*Example 2*), you are ready to publish audio and video.

```objc
[room publish:localStream withOptions:@{@"data": @FALSE}];
```

Be sure to have implemented [ECRoomDelegate] protocol in your delegate.

```objc
- (void)room:(ECRoom *)room didPublishStreamId:(NSString *)streamId {
     // do something with the streamId
}
```

### Subscribe live streams

This example assumes someone is already publishing into the room you are trying to subscribe streams.

Include the following headers.

```objc
#import "ECStream.h"
#import "ECRoom.h"
#import "ECPlayerView.h"
```

Initialize an [ECRoom] instance with access token.

```objc
ECRoom *room = [ECRoom initWithEncodedToken:token delegate:self];
```

Be sure to implement the following methods of [ECRoomDelegate].

```objc
// This event will be called once you get connected to the room
- (void)room:(ECRoom *)room didReceiveStreamsList:(NSArray *)list {
    if ([list count] > 0) {
        // Get the ID of first stream in the list.
        NSDictionary *streamMeta = [list objectAtIndex:0];
        
        // Subscribe to that stream ID.
        [room subscribe:[streamMeta objectForKey:@"id"]];
    }
}

// This event will be called once you get subscribed to the stream.
- (void)room:(ECRoom *)room didSubscribeStream:(ECStream *)stream {
    // Initialize a player view.
    playerView = [[ECPlayerView alloc] initWithLiveStream:stream];
    
    // Add your player view to your own view.
    [self.view addSubview:playerView];
}
```

### Stream recording

Once you have connected to a room (*Example 1*) and got access to local media (*Example 2*), and published your stream (*Example 3*), you are able to record your stream on server side.

Tell room that you want to record your publishing stream.
```objc
room.recordEnabled = YES;
```

Publish the stream.
```objc
[room publish:localStream withOptions:@{@"data": @FALSE}];
```

Be sure to implement ECRoomDelegate methods on your delegate.
```objc
- (void)room:(ECRoom *)room didStartRecordingStreamId:(NSString *)streamId withRecordingId:(NSString *)recordingId {
      // do something with the recordingId
}
```
## Contributing

Don't hesitate on

* Fill issues
* Send pull requests
* Feature requests
* Comments
* ... whatever you like.

## Authorship

This library was written by Alvaro Gil (aka @zevarito) on July/2015.

It is influenced on and share utility code from App RTC Demo in Google WebRTC source code. 

## License

This library is released under MIT license, please take a look at [LICENSE file](./LICENSE) for details.


[ECRoom]:http://zevarito.github.io/ErizoClientIOS/docs/public/html/Classes/ECRoom.html
[ECRoomDelegate]:http://zevarito.github.io/ErizoClientIOS/docs/public/html/Protocols/ECRoomDelegate.html
[CocoaPods]:https://cocoapods.org
[Install CocoaPods]:https://guides.cocoapods.org/using/getting-started.html
