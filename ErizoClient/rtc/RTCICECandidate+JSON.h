//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import "RTCICECandidate.h"

@interface RTCICECandidate (JSON)

+ (RTCICECandidate *)candidateFromJSONDictionary:(NSDictionary *)dictionary;
- (NSData *)JSONData;

@end
