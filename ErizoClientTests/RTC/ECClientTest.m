//
//  ECClientTest.m
//  ErizoClientIOS
//
//  Created by Alvaro Gil on 6/20/17.
//
//

#import "ECUnitTest.h"
#import "ECClient.h"

@interface ECClientTest : ECUnitTest
@end

@interface ECClientDelegateConformClass : NSObject<ECClientDelegate>
@property (strong) ECClient *client;
@end
@implementation ECClientDelegateConformClass
@end

@implementation ECClientTest

- (void)setUp {
    [super setUp];
}

- (void)testECClientWeakReferenceHisDelegate {
    __weak typeof(ECClient) *weakClient;

    @autoreleasepool {
        ECClientDelegateConformClass *conformClass = [[ECClientDelegateConformClass alloc] init];
        ECClient *client = [[ECClient alloc] initWithDelegate:conformClass];
        conformClass.client = client;
        weakClient = client;
        conformClass = nil;
    }
    XCTAssertNil(weakClient);
}

@end
