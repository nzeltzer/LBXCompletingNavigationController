//
//  LBXNavigationControllerDemoAppDelegate.m
//  LBXNavigationController
//
//  Created by Nicholas Zeltzer on 3/1/14.
//  Copyright (c) 2014 LawBox. All rights reserved.
//

#import "LBXNavigationControllerDemoAppDelegate.h"
#import "LBXNavigationController.h"

@interface LBXNavigationControllerDemoAppDelegate() <UINavigationControllerDelegate>

@property (nonatomic, readwrite, strong) LBXNavigationController *navigationController;

@end

@implementation LBXNavigationControllerDemoAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Set up a root view controller with a blue background.
    
    UIViewController *rootViewController = [[UIViewController alloc] initWithNibName:nil bundle:nil];
    rootViewController.view.backgroundColor = [UIColor blueColor];
    
    // Set up the navigation controller.
    
    self.navigationController = [[LBXNavigationController alloc] initWithRootViewController:rootViewController];
    
    // Assign self as delegate for demonstration purposes.
    // Note: Assigning self as 'externalDelegate' would be better practice, see 'LBXNavigationController' header.
    
    self.navigationController.delegate = self;
    
    [self addPushButtonToViewController:rootViewController];
    
    // Assign the navigation controller.
    
    self.window.rootViewController = self.navigationController;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}

#pragma mark - UINavigationControllerDelegate

/** This method is implemented to demonstrate that the navigation controller still calls its delegate methods on the external delegate.*/

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated;
{
    NSLog(@"(%@)[%@]", [self class], NSStringFromSelector(_cmd));
}

#pragma mark - Demonstration Methods

- (void)addPushButtonToViewController:(UIViewController*)viewController;
{
    // Add a button for test purposes.
    UIBarButtonItem *testButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"button.title.push", nil) style:0 target:self action:@selector(pushNextLevel:)];
    [viewController.navigationItem setRightBarButtonItem:testButton animated:YES];
}

- (void)pushNextLevel:(id)sender;
{
    // Create a new view controller with a randomly colored background
    UIViewController *nextViewController = [[UIViewController alloc] initWithNibName:nil bundle:nil];
    CGFloat red = arc4random() % 255; CGFloat green = arc4random() % 255; CGFloat blue = arc4random() % 255;
    UIColor *randomColor = [UIColor colorWithRed:red/255 green:green/255 blue:blue/255 alpha:1];
    nextViewController.view.backgroundColor = randomColor;
    
    NSString *title = [NSString stringWithFormat:@"%ld", (long)[[self.navigationController viewControllers] count]];
    
    // Push the view controller.
    [self.navigationController pushViewController:nextViewController
                                         animated:YES
                                       completion:^(UINavigationController *navigationController, UIViewController *viewController)
     {
         // Assign the button to the view controller.
         [self addPushButtonToViewController:viewController];
         [viewController setTitle:title];
     }];
}


@end
