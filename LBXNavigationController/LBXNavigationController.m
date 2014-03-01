//
//  LBXNavigationController.m
//  LBXNavigationController
//
//  Created by Nicholas Zeltzer on 3/1/14.
//  Copyright (c) 2014 LawBox. All rights reserved.
//

#import "LBXNavigationController.h"
#import <objc/objc-runtime.h>

@interface LBXNavigationController () <UINavigationControllerDelegate> {
    dispatch_once_t _pushSpawn;
    dispatch_queue_t _pushQueue;
    dispatch_group_t _pushGroup;
    dispatch_semaphore_t _pushSema;
}

@property (nonatomic, readwrite, assign) id <UINavigationControllerDelegate> internalDelegate;

BOOL lbx_protocol_includesSelector(Protocol *aProtocol, SEL aSelector);

@end

#pragma mark - Implementation

@implementation LBXNavigationController

@dynamic internalDelegate, delegate;

#pragma mark Initialization

- (id)initWithCoder:(NSCoder *)aDecoder;
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self LBXSetupNavigationController];
    }
    return self;
}

- (instancetype)initWithNavigationBarClass:(Class)navigationBarClass toolbarClass:(Class)toolbarClass;
{
    self = [super initWithNavigationBarClass:navigationBarClass toolbarClass:toolbarClass];
    if (self) {
        [self LBXSetupNavigationController];
    }
    return self;
}

- (id)initWithRootViewController:(UIViewController *)rootViewController;
{
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        [self LBXSetupNavigationController];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self LBXSetupNavigationController];
    }
    return self;
}

- (void)dealloc;
{
    [self setInternalDelegate:nil];
    [self setExternalDelegate:nil];
}

#pragma mark Setup

- (void)LBXSetupNavigationController;
{
    [self setInternalDelegate:self];
}

#pragma mark Accessors

- (id<UINavigationControllerDelegate>)internalDelegate;
{
    return [super delegate];
}

- (void)setInternalDelegate:(id<UINavigationControllerDelegate>)internalDelegate;
{
    [super setDelegate:internalDelegate];
}

/** 
 Override the setDelegate accessor to assign the external delegate property instead.
 */

- (void)setDelegate:(id<UINavigationControllerDelegate>)delegate;
{
    self.externalDelegate = delegate;
}

/**
 The ObjC runtime doesn't provide a means to distinguish callers, so calls to delegate will return this object.
 */

- (id<UINavigationControllerDelegate>)delegate;
{
    return self.internalDelegate;
}

#pragma mark NSObjectProtocol

/** The UINavigationControllerDelegate protocol includes optional methods. The default implementation of 
 respondsToSelector will only return YES for methods this class has implemented. Manually implementing 
 each protocol method is sloppy and likely to break as new protocol methods are added. Instead, 
 dynamically filter out selectors that belong to the UINavigationControllerDelegate protocol and check
 to see if either this object, or its external delegate responds.*/

- (BOOL)respondsToSelector:(SEL)aSelector;
{
    /**
     If the selector is part of the UINavigationControllerDelegate protocol, and this class has
     not implemented the protocol method, check to see if the external delegate responds.
     */
    
    if (lbx_protocol_includesSelector(@protocol(UINavigationControllerDelegate), aSelector)) {
        BOOL responds = [super respondsToSelector:aSelector];
        if (!responds) {
            responds = ([self.externalDelegate respondsToSelector:aSelector]);
        }
        return responds;
    }
    return [super respondsToSelector:aSelector];
}

#pragma mark NSObject

/**
 "When an object can’t respond to a message because it doesn’t have a method matching the selector in the message, the runtime system informs the object by sending it a forwardInvocation: message."
 'Message Forwarding', Cocoa Documentation. 
 https://developer.apple.com/library/mac/documentation/cocoa/conceptual/ObjCRuntimeGuide/Articles/ocrtForwarding.html.
 */

- (void)forwardInvocation:(NSInvocation*)invocation;
{
    SEL selector = [invocation selector];
    if (lbx_protocol_includesSelector(@protocol(UINavigationControllerDelegate), selector) &&
        ([self.externalDelegate respondsToSelector:selector])) {
        [invocation invokeWithTarget:self.externalDelegate];
    }
    else {
        [super forwardInvocation:invocation];
    }
}

#pragma mark Navigation

- (void)pushViewController:(UIViewController *)viewController
                  animated:(BOOL)animated
                completion:(void (^)(UINavigationController *navigationController, UIViewController *viewController))completion;
{
    dispatch_once(&_pushSpawn, ^{
        _pushQueue = dispatch_queue_create("com.LBXNavigationController.push", DISPATCH_QUEUE_SERIAL);
        _pushGroup = dispatch_group_create();
    });
    
    UINavigationController *__weak weakNavigation = self;
    UIViewController *__weak weakController = viewController;
    
    /** 
     Use a private serial queue and semaphore to prevent execution of the completion handler until the transition has completed.
     Use a dispatch group to prevent subsequent blocks from executing until the previous block has completed asynchronously.
     
     See tests for detailed walkthrough.
     
     */

    dispatch_async(_pushQueue, ^{
        dispatch_group_enter(_pushGroup);
        self->_pushSema = dispatch_semaphore_create(0);
        dispatch_semaphore_wait(_pushSema, DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(weakNavigation, weakController);
            dispatch_group_leave(_pushGroup);
        });
    });
    
    [super pushViewController:viewController animated:animated];
}

#pragma mark UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated;
{
    if (_pushSema) {
        dispatch_semaphore_signal(_pushSema);
    }
    if ([self.externalDelegate respondsToSelector:_cmd]) {
        [self.externalDelegate navigationController:navigationController didShowViewController:viewController animated:animated];
    }
}

#pragma mark Utilties

BOOL lbx_protocol_includesSelector(Protocol *aProtocol, SEL aSelector)
{
    // Check that protocol includes method.
    
    BOOL (^includesSelectorWithOptions)(Protocol*, SEL, BOOL, BOOL) =
    ^BOOL(Protocol *pro, SEL sel, BOOL req, BOOL inst)
    {
        unsigned int protocolMethodCount = 0;
        BOOL isRequiredMethod = req;
        BOOL isInstanceMethod = inst;
        struct objc_method_description *protocolMethodList;
        BOOL includesSelector = NO;
        protocolMethodList = protocol_copyMethodDescriptionList(aProtocol, isRequiredMethod, isInstanceMethod, &protocolMethodCount);
        for (NSUInteger m = 0; m < protocolMethodCount; m++)
        {
            struct objc_method_description aMethodDescription = protocolMethodList[m];
            SEL aMethodSelector = aMethodDescription.name;
            if (aMethodSelector == aSelector)
            {
                includesSelector = YES;
                break;
            }
        }
        free(protocolMethodList);
        return includesSelector;
    };
    
    // Check for required and non-required methods of class and instance methods.

    if (includesSelectorWithOptions(aProtocol, aSelector, YES, YES)) {
        return YES;
    }
    if (includesSelectorWithOptions(aProtocol, aSelector, YES, NO)) {
        return YES;
    }
    if (includesSelectorWithOptions(aProtocol, aSelector, NO, NO)) {
        return YES;
    }
    if (includesSelectorWithOptions(aProtocol, aSelector, NO, YES)) {
        return YES;
    }
    return NO;
}

@end
