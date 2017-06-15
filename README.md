[![Build Status](https://travis-ci.org/zevarito/Licode-ErizoClientIOS.svg?branch=0.5.0)](https://travis-ci.org/zevarito/Licode-ErizoClientIOS)

# Licode ErizoClientIOS

IOS Erizo Client for [Licode WebRTC Framework](http://lynckia.com/licode)

## Contents

* [Features](#features)
* [Documentation](#documentation)
* [Example App](#example-app)
* [Installation](#installation)
* [License](#license)

## Features

  * Support SFU & P2P modes.
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

* [API documentation](http://zevarito.github.io/Licode-ErizoClientIOS/docs/public/html/)

## Example App

Checkout the source code and you will see a project named ECIExampleLicode which
offers an example video conference app that connects directly with [Licode Try It!] demo or your custom
Licode installation. You might need to comment/uncomment your desired connection method in this action
`- (IBAction)connect:(id)sender`.

Here is the relevant source to make work a multi-part video conference app. [Example App Source File].

This comment https://github.com/zevarito/Licode-ErizoClientIOS/issues/55#issuecomment-301854258 explains the different options to connect with Licode, use your own instance, official demo servers, connect directly with Nuve or use Licode demo API to retrive valid tokens in the official demo app.

![Example App](/screenshot.jpg?raw=true)

## Installation

[Build and link locally](https://github.com/zevarito/Licode-ErizoClientIOS/wiki/Build-locally-and-link-from-your-project)

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
