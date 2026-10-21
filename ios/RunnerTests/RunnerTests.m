@import XCTest;
@import integration_test;

@interface RunnerTests : XCTestCase
@end

@implementation RunnerTests

- (void)testFlutterIntegration {
  __block NSUInteger completedTests = 0;
  FLTIntegrationTestRunner *runner = [[FLTIntegrationTestRunner alloc] init];
  [runner testIntegrationTestWithResults:^(SEL testSelector, BOOL success, NSString *message) {
    completedTests += 1;
    XCTAssertTrue(success, @"%@: %@", NSStringFromSelector(testSelector), message);
  }];
  XCTAssertGreaterThan(completedTests, 0U, @"No Flutter integration tests reported results.");
}

@end
