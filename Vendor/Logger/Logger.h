//
//  Logger.h
//
//  Created by Alvaro Gil on 7/15.
//  LICENSE: nil
//

#import <Foundation/Foundation.h>

#ifdef DEBUG
    #define L_DEBUG(f, ...) { \
        [[Logger sharedInstance] log:[Logger sharedInstance].debugPrefix file:@(__FILE__) line:@(__LINE__) format:f , ##__VA_ARGS__]; \
    }
#else
    #define L_DEBUG(f, ...) {}
#endif


#define L_ERROR(f, ...) { \
[[Logger sharedInstance] log:[Logger sharedInstance].errorPrefix file:@(__FILE__) line:@(__LINE__) format:f , ##__VA_ARGS__]; \
}

#define L_WARNING(f, ...) { \
[[Logger sharedInstance] log:[Logger sharedInstance].warningPrefix file:@(__FILE__) line:@(__LINE__) format:f , ##__VA_ARGS__]; \
}

#define L_INFO(f, ...) { \
[[Logger sharedInstance] log:[Logger sharedInstance].infoPrefix file:nil line:nil format:f , ##__VA_ARGS__]; \
}

@interface Logger : NSObject

///-----------------------------------
/// @name Initializers
///-----------------------------------

- (instancetype)init;
+ (instancetype)sharedInstance;

///-----------------------------------
/// @name Properties
///-----------------------------------

@property NSString *infoPrefix;
@property NSString *debugPrefix;
@property NSString *warningPrefix;
@property NSString *errorPrefix;

///-----------------------------------
/// @name Methods
///-----------------------------------

- (void)log:(NSString *)prefix file:(NSString *)file line:(NSNumber *)line format:(NSString *)format, ...;

@end