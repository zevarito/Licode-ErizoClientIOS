//
//  Logger.h
//
//  Created by Alvaro Gil on 7/15.
//  LICENSE: nil
//

#import <Foundation/Foundation.h>

#ifdef DEBUG
#define L_DEBUG(f, ...) { \
logThis(LOG_MODE_DEBUG, @(__FILE__), @(__LINE__), f, ##__VA_ARGS__); \
}
#else
#define L_DEBUG(f, ...) {}
#endif

#define L_ERROR(f, ...) { \
logThis(LOG_MODE_ERROR, @(__FILE__), @(__LINE__), f, ##__VA_ARGS__); \
}

#define L_WARNING(f, ...) { \
logThis(LOG_MODE_WARNING, @(__FILE__), @(__LINE__), f, ##__VA_ARGS__); \
}

#define L_INFO(f, ...) { \
logThis(LOG_MODE_INFO, nil, nil, f, ##__VA_ARGS__); \
}

@class Logger;

typedef enum {
    LOG_MODE_UNKNOWN,
    LOG_MODE_DEBUG,
    LOG_MODE_INFO,
    LOG_MODE_WARNING,
    LOG_MODE_ERROR
} LOG_MODE;

typedef NS_OPTIONS(NSUInteger, LOG_MODE_MASK) {
    LOG_MODE_DEBUG_MASK         = 1 << LOG_MODE_DEBUG,
    LOG_MODE_INFO_MASK          = 1 << LOG_MODE_INFO,
    LOG_MODE_WARNING_MASK       = 1 << LOG_MODE_WARNING,
    LOG_MODE_ERROR_MASK         = 1 << LOG_MODE_ERROR
};


@interface Logger : NSObject

///-----------------------------------
/// @name Initializers
///-----------------------------------

- (instancetype)init;
+ (instancetype)sharedInstance;

///-----------------------------------
/// @name Properties
///-----------------------------------

@property LOG_MODE_MASK logModes;
@property NSMutableArray *prefixes;

///-----------------------------------
/// @name Methods
///-----------------------------------

- (void)log:(LOG_MODE)mode file:(NSString *)file line:(NSNumber *)line format:(NSString *)format, ...;
- (void)log:(LOG_MODE)mode file:(NSString *)file line:(NSNumber *)line format:(NSString *)format args:(va_list)args;
- (void)logWithModesOverride:(LOG_MODE_MASK)overrideModes mode:(LOG_MODE)mode file:(NSString *)file line:(NSNumber *)line
                      format:(NSString *)format args:(va_list)args;

@end

FOUNDATION_STATIC_INLINE void logThis(LOG_MODE mode, NSString *file, NSNumber *line, NSString *format, ...) {
    va_list args;
    va_start(args, format);
#ifdef LOG_MODES
    LOG_MODE_MASK overrideModes = LOG_MODES;
    [[Logger sharedInstance] logWithModesOverride:overrideModes mode:mode file:file line:line format:format args:args];
#else
    [[Logger sharedInstance] log:mode file:file line:line format:format args:args];
#endif
    va_end(args);
}