//
//  ECSignalingChannelDup.h
//  ErizoClientIOS
//
//  Created by Alvaro Gil on 6/9/17.
//
//

#import "ECSignalingChannel.h"

@interface ECSignalingChannelDup : ECSignalingChannel
- (void)onUpdateAttributeStream:(NSDictionary *)msg;
@end
