# Licode ErizoClientIOS

IOS Erizo Client for [Licode WebRTC Framework](http://lynckia.com/licode)

* [Features](#features)
* [Documentation](#documentation)
* [Example App](#example-app)
* [Installation](#installation)
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

If you have doubts about what this library can do and what can't do, open an issue asking.

## Documentation

If you are looking for use this library use the following documentation reference.

* [Public API documentation](http://zevarito.github.io/ErizoClientIOS/docs/public/html/)

If you want to contribute to develop this library take a look a the following
documentation reference.

* [Full API documentation](http://zevarito.github.io/ErizoClientIOS/docs/dev/html/)

## Example App

Checkout the source code and you will see a project named ECIExampleLicode which
offers multiple video conference that connects directly with [Licode Try It!] demo.

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

## Authorship

This library was written by Alvaro Gil (aka @zevarito) on July/2015.

It is influenced on and share utility code from App RTC Demo in Google WebRTC source code. 

## License

The MIT License

Copyright (C) 2015 Alvaro Gil (zevarito@gmail.com).

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



[ECRoom]:http://zevarito.github.io/ErizoClientIOS/docs/public/html/Classes/ECRoom.html
[ECRoomDelegate]:http://zevarito.github.io/ErizoClientIOS/docs/public/html/Protocols/ECRoomDelegate.html
[CocoaPods]:https://cocoapods.org
[Install CocoaPods]:https://guides.cocoapods.org/using/getting-started.html
[Licode Try It!]:https://chotis2.dit.upm.es
