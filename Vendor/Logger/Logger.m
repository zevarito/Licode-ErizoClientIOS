//
//  Logger.m
//
//  Created by Alvaro Gil on 7/15.
//  LICENSE: nil
//

#import "Logger.h"

@implementation Logger

- (instancetype)init {
    if (self = [super init]) {
        self.infoPrefix = @"💚INFO💚";
        self.warningPrefix = @"💛WARN💛";
        self.debugPrefix = @"💙DEBUG💙";
        self.errorPrefix = @"💔ERROR💔";
    }
    return self;
}

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)log:(NSString *)prefix file:(NSString *)file line:(NSNumber *)line format:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    
    NSString *source;
    NSString *message;
    NSString *output;
    
    message = [NSString stringWithFormat:@"\n%@: %@", prefix, format];
    
    if (file && line) {
        source = [NSString stringWithFormat:@"\nSource: %@:%@", file, line];
    } else {
        source = @"";
    }
    
    output = [NSString stringWithFormat:@"%@%@\n\n", source, message];
    
    NSLogv(output, args);
    
    va_end(args);
}


@end
