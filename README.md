# ErizoClientIOS

IOS Erizo Client for [Licode WebRTC Framework](http://lynckia.com/licode)

* [Features](#features)
* [Roadmap](#roadmap)
* [Installation](#installation)
* [Documentation](#documentation)
* [Examples](#examples)
* [Contributing](#contributing)
* [License](#license)

## Features

  * [Connect to Rooms with encoded tokens](#connect-to-a-room)
  * [Capture Audio & Video](#capture-audio-and-video)
  * [Publish local Media](#publish-local-media)
  * [Stream recording](#stream-recording)
  
## Roadmap
  * Subscribe live streams (wip)
  * Integrate with Licode online web examples
  * Figure out % of complete
  * Versioning
  * Improve documentation
  * Add *refactor* in between each previous item

## Installation

## Documentation

[Public API documentation](http://zevarito.github.io/ErizoClientIOS/docs/public/html/)

[Full API documentation](http://zevarito.github.io/ErizoClientIOS/docs/dev/html/)


## Examples

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
```

And in your **View Controller**:

```objc
// Create a view to render your own camera
RTCEAGLVideoView *localVideoView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectMake(0, 0,
   [[UIScreen mainScreen] applicationFrame].size.width,
   [[UIScreen mainScreen] applicationFrame].size.height)];

// Add your video view to your UI view
[self.view addSubview:localVideoView];

// Initialize a local stream
ECStream *localStream = [[ECStream alloc] initWithLocalStream];
    
if (localStream.stream.videoTracks.count > 0) {
    RTCVideoTrack *videoTrack = [localStream.stream.videoTracks objectAtIndex:0];
    [videoTrack addRenderer:localVideoView];
}
```

[ECRoomDelegate]:http://zevarito.github.io/ErizoClientIOS/docs/public/html/Protocols/ECRoomDelegate.html

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

## License

This library is released under MIT license, please take a look at [LICENSE file](./LICENSE) for details.
