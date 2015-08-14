//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import "RTCICEServer.h"

@interface RTCICEServer (JSON)

+ (RTCICEServer *)serverFromJSONDictionary:(NSDictionary *)dictionary;

@end

