//
//  LBXCompletingNavigationControllerTests.m
//  LBXCompletingNavigationControllerTests
//
//  Created by Nicholas Zeltzer on 3/1/14.
//  Copyright (c) 2014 Nicholas Zeltzer.
//

/**
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "as is" basis,
 without warranties or conditions of any kind, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */
#import <XCTest/XCTest.h>
#import "LBXCompletingNavigationController.h"

@protocol LBXCompletingNavigationControllerTestProtocol <NSObject, UINavigationControllerDelegate>

@property (nonatomic, readwrite, weak) id <UINavigationControllerDelegate> internalDelegate;
@property (nonatomic, readwrite, weak) id <UINavigationControllerDelegate> externalDelegate;

@end

@interface LBXCompletingNavigationControllerTests : XCTestCase <UINavigationControllerDelegate> {
    dispatch_group_t _pushGroup;
    dispatch_queue_t _pushQueue;
    dispatch_semaphore_t _pushSema;
    dispatch_once_t _pushSpawn;
}

@property (nonatomic, readwrite, strong) LBXCompletingNavigationController <LBXCompletingNavigationControllerTestProtocol> *navigationController;
@property (nonatomic, readwrite, strong) UIViewController *rootViewController;

@end

@implementation LBXCompletingNavigationControllerTests

- (void)setUp
{
    [super setUp];
    
    self.rootViewController = ({
        UIViewController *controller = [[UIViewController alloc] initWithNibName:nil bundle:nil];
        controller;
    });
    
    self.navigationController = ({
        LBXCompletingNavigationController <LBXCompletingNavigationControllerTestProtocol> *controller = (LBXCompletingNavigationController<LBXCompletingNavigationControllerTestProtocol>*)[[LBXCompletingNavigationController alloc] initWithRootViewController:self.rootViewController];
        controller;
    });
    
    XCTAssert([self.navigationController respondsToSelector:@selector(externalDelegate)],
              @"Navigation controller does not implement external delegate");
    XCTAssert([self.navigationController respondsToSelector:@selector(internalDelegate)],
              @"Navigation controller does not implement internal delegate");
    
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInitialState;
{
    id <UINavigationControllerDelegate> internalDelegate = (id<UINavigationControllerDelegate>)[self.navigationController internalDelegate];
    id <UINavigationControllerDelegate> externalDelegate = (id<UINavigationControllerDelegate>)[self.navigationController externalDelegate];
    id <UINavigationControllerDelegate> publicDelegate = (id<UINavigationControllerDelegate>)[self.navigationController delegate];
    
    XCTAssert(internalDelegate == self.navigationController,
              @"Navigation controller internal delegate does not equal self");
    XCTAssert(externalDelegate == nil,
              @"Navigation controller's external delegate is not nil before assignment");
    XCTAssert(publicDelegate == self.navigationController,
              @"Navigation controller's public delegate did not return self");
    XCTAssert([self.navigationController respondsToSelector:@selector(navigationController:didShowViewController:animated:)],
              @"Navigation controller did not respond to completion method");
}

- (void)testAssignment;
{
    
    [self.navigationController setDelegate:self];

    id <UINavigationControllerDelegate> internalDelegate = (id<UINavigationControllerDelegate>)[self.navigationController internalDelegate];
    id <UINavigationControllerDelegate> externalDelegate = (id<UINavigationControllerDelegate>)[self.navigationController externalDelegate];
    id <UINavigationControllerDelegate> publicDelegate = (id<UINavigationControllerDelegate>)[self.navigationController delegate];
    
    XCTAssert(internalDelegate == self.navigationController,
              @"Navigation controller internal delegate does not equal self");
    XCTAssert(externalDelegate == self,
              @"Navigation controller's external delegate does not equal assignment");
    XCTAssert(publicDelegate == self.navigationController,
              @"Navigation controller's public delegate did not return self");
    
    XCTAssert(![externalDelegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)],
              @"Navigation controller's external delegate responded to unimplemented method.");
    
    XCTAssert([internalDelegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)],
              @"Navigation controller failed to respond to method implemented by internal delegate.");

    XCTAssert([internalDelegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)],
              @"Navigation controller failed to respond to method implemented by external delegate.");
    
    [self.navigationController setDelegate:nil];
    
    XCTAssert(![internalDelegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)],
              @"Navigation controller responded to unimplemented method.");

}

- (void)testDispatchMechanism;
{
    
    // This is more for demonstration purposes than anything else.
    
    __block BOOL didFinish1 = NO;
    __block BOOL didFinish2 = NO;
    __block BOOL didFinish3 = NO;

    dispatch_semaphore_t waitSema = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self dispatchWithCompletion:^{
            NSLog(@"Finish 1");
            XCTAssertFalse(didFinish2, @"2 < 1");
            XCTAssertFalse(didFinish3, @"3 < 1");
            XCTAssertFalse(didFinish1, @"1 < 1");
            didFinish1 = YES;
        }];
        [self dispatchWithCompletion:^{
            NSLog(@"Finish 2");
            XCTAssert(didFinish1, @"2 < 1");
            XCTAssertFalse(didFinish3, @"3 < 2");
            XCTAssertFalse(didFinish2, @"2 < 2");
            didFinish2 = YES;
        }];
        [self dispatchWithCompletion:^{
            NSLog(@"Finish 3");
            XCTAssert(didFinish1, @"3 < 1");
            XCTAssert(didFinish2, @"3 < 2");
            XCTAssertFalse(didFinish3, @"3 < 3");
            didFinish3 = YES;
            dispatch_semaphore_signal(waitSema);
        }];
    });
    dispatch_semaphore_wait(waitSema, DISPATCH_TIME_FOREVER);
    XCTAssert(didFinish1 && didFinish2 && didFinish3, @"Failed to finish");
}

#pragma mark UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated;
{
    
}

#pragma mark Dispatch Mechanism

- (void)dispatchWithCompletion:(void(^)())completion;
{
    
    dispatch_once(&_pushSpawn, ^{
        _pushQueue = dispatch_queue_create("com.LBXCompletingNavigationController.push", DISPATCH_QUEUE_SERIAL);
        _pushGroup = dispatch_group_create();
    });
    
    // Dispatch groups and serial queues, in combination, can be used to prevent subsequently submitted block
    // object from executing before a previous, asynchronously completing, block has finished.
    
    /** Think about it like this:
     1. Serial Queues are FIFO: block 2 executes when block 1 finishes.
     2. Blocks that do work asynchronously may "finish" before the work they started.
     2. Dispatch groups provide a way for a block to specify when the "work" it has started has finished.
    */
    
    dispatch_async(_pushQueue, ^{
        // Signal that this block is about to begin work in this group.
        dispatch_group_enter(_pushGroup);
        XCTAssert(_pushSema == NULL, @"Semaphore is not NULL");
        // Create a semaphore – e.g., a switch that someone else can signal.
        self->_pushSema = dispatch_semaphore_create(0);
        // Pretend we're doing expensive work on a different thread.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self triggerCompletion];
        });
        // Wait until the semaphore is triggered. This is a private queue, so we're not blocking anyone else.
        dispatch_semaphore_wait(_pushSema, DISPATCH_TIME_FOREVER);
        // The semaphore has been triggered – we unblock and proceed.
        completion();
        // Set the semaphore to NULL for test purposes.
        self->_pushSema = NULL;
        // Signal that this block has finished all the work for this group.
        dispatch_group_leave(_pushGroup);
        // Now that this block has left the group, the next block in line will begin.
    });
    

    
}

- (void)triggerCompletion;
{
    if (_pushSema) {
        dispatch_semaphore_signal(_pushSema);
    }
}

@end
