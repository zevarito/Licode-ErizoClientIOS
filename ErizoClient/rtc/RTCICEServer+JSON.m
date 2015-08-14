//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import "RTCICEServer+JSON.h"

static NSString const *kRTCICEServerUsernameKey = @"username";
static NSString const *kRTCICEServerPasswordKey = @"password";
static NSString const *kRTCICEServerUrisKey = @"uris";
static NSString const *kRTCICEServerUrlKey = @"urls";
static NSString const *kRTCICEServerCredentialKey = @"credential";

@implementation RTCICEServer (JSON)

+ (RTCICEServer *)serverFromJSONDictionary:(NSDictionary *)dictionary {
    NSString *url = dictionary[kRTCICEServerUrlKey];
    NSString *username = dictionary[kRTCICEServerUsernameKey];
    NSString *credential = dictionary[kRTCICEServerCredentialKey];
    username = username ? username : @"";
    credential = credential ? credential : @"";
    return [[RTCICEServer alloc] initWithURI:[NSURL URLWithString:url]
                                    username:username
                                    password:credential];
}

@end

