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
// CEOD provides different JSON, and this parses that.
+ (NSArray *)serversFromCEODJSONDictionary:(NSDictionary *)dictionary;

@end

