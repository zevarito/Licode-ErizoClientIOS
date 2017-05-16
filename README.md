# Licode ErizoClientIOS

IOS Erizo Client for [Licode WebRTC Framework](http://lynckia.com/licode)

**Upgrade notes**

If you are upgrading from a previous version/commit to 0.3.0 tag release, please follow this instructions: https://github.com/zevarito/Licode-ErizoClientIOS/wiki/Upgrade-to-0.3.0.

## Contents

* [Features](#features)
* [Documentation](#documentation)
* [Example App](#example-app)
* [Installation](#installation)
* [New issues guidelines](#new-issues-guidelines)
* [Authorship](#authorship)
* [License](#license)

## Features

  * Support MCU & P2P modes.
  * Connect to Rooms with encoded tokens.
  * Capture local Audio & Video media.
  * Ability to switch between front/rear camera.
  * Publish local Media.
  * Subscribe live streams.
  * Reproduce live streams.
  * Server side stream recording.
  * Stream custom attributes.
  * Data Channel

If you have doubts about what this library can do and what can't do, open an issue asking.

## Documentation

If you are looking for use this library use the following documentation reference.

* [Public API documentation](http://zevarito.github.io/Licode-ErizoClientIOS/docs/public/html/)

If you want to contribute to develop this library take a look a the following
documentation reference.

* [Full API documentation](http://zevarito.github.io/Licode-ErizoClientIOS/docs/dev/html/)

## Example App

Checkout the source code and you will see a project named ECIExampleLicode which
offers multiple video conference that connects directly with [Licode Try It!] demo.

Here is the relevant source to make work a multiconference video app, [Example App Source File].

This comment https://github.com/zevarito/Licode-ErizoClientIOS/issues/55#issuecomment-301854258 explains the different options to connect with Licode, use your own instance, official demo servers, connect directly with Nuve or use Licode demo API to retrive valid tokens in the official demo app.

![Example App](/screenshot.jpg?raw=true)

## Installation

[Build and link locally](https://github.com/zevarito/Licode-ErizoClientIOS/wiki/Build-locally-and-link-from-your-project)

## New issues guidelines

* Ensure that what is not working in your app does *effectively not work* on [Example App](#example-app).

Please provide the following information:

* Against which revision of Webrtc are you building?
* Is your Webrtc build debug or release?
* Which IOS archs are you targeting?
* In which IOS device are you testing?
* Include logs or a screen capture of them.

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
[Example App Source File]:https://github.com/zevarito/ErizoClientIOS/blob/master/ECIExampleLicode/ECIExampleLicode/MultiConferenceViewController.m
