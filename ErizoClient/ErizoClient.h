//
//  ErizoClientIOS
//
//  Copyright (c) 2015 Alvaro Gil (zevarito@gmail.com).
//
//  MIT License, see LICENSE file for details.
//

#import <Foundation/Foundation.h>

/**
 @interface ErizoClient
 
 This is a dummy class with the purpose of initialize the library
 before being used.
 
 You should call sharedInstance: before any call to other ErizoClient
 classes and methods.
 
 */
@interface ErizoClient : NSObject

/**
 Create a shared instance of ErizoClient.
 
 This initalizer should be called **allways** before start
 using the library.
 
 */
+ (instancetype)sharedInstance;

@end
