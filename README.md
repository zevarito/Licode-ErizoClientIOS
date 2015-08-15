# ErizoClientIOS

IOS Erizo Client for [Licode WebRTC Framework](http://lynckia.com/licode)

**Features**
  * [Connect to Rooms with encoded tokens](#connect-to-a-room)
  * [Capture Audio & Video](#capture-audio-and-video)
  * [Publish local Media](#publish-local-media)
  * [Stream recording](#stream-recording)
  
**Roadmap**
  * Consuming streams (WIP)
  * Versioning
  * Improve documentation

**Installation**

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

And in your **View Controller**

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
## Documentation

[Public API documentation](http://zevarito.github.io/ErizoClientIOS/docs/public/html/)

[Full API documentation](http://zevarito.github.io/ErizoClientIOS/docs/dev/html/)


[ECRoomDelegate]:http://zevarito.github.io/ErizoClientIOS/docs/public/html/Protocols/ECRoomDelegate.html
