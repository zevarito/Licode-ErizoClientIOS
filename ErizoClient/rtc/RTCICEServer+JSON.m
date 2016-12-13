//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import "RTCIceServer+JSON.h"
#import "Logger.h"

static NSString const *kRTCICEServerUsernameKey = @"username";
static NSString const *kRTCICEServerPasswordKey = @"password";
static NSString const *kRTCICEServerUrisKey = @"uris";
static NSString const *kRTCICEServerUrlKey = @"urls";
static NSString const *kRTCICEServerCredentialKey = @"credential";

@implementation RTCIceServer (JSON)

+ (RTCIceServer *)serverFromJSONDictionary:(NSDictionary *)dictionary {
    NSString *url = dictionary[kRTCICEServerUrlKey];
    NSString *username = dictionary[kRTCICEServerUsernameKey];
    NSString *credential = dictionary[kRTCICEServerCredentialKey];

    if (!username) {
        username = @"";
        L_WARNING(@"No ICE server username provided, using empty.");
    }
    if (!credential) {
        credential = @"";
        L_WARNING(@"No ICE server credential provided, using empty.");
    }

    return [[RTCIceServer alloc] initWithURLStrings:@[url]
                                    username:username
                                  credential:credential];
}

@end

