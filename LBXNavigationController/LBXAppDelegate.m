//
//  LBXAppDelegate.m
//  LBXNavigationController
//
//  Created by Nicholas Zeltzer on 3/1/14.
//  Copyright (c) 2014 LawBox. All rights reserved.
//

#import "LBXAppDelegate.h"
#import "LBXNavigationController.h"

@interface LBXAppDelegate() <UINavigationControllerDelegate>

@property (nonatomic, readwrite, strong) LBXNavigationController *navigationController;

@end

@implementation LBXAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Set up a root view controller with a blue background.
    
    UIViewController *rootViewController = [[UIViewController alloc] initWithNibName:nil bundle:nil];
    rootViewController.view.backgroundColor = [UIColor blueColor];
    
    // Set up the navigation controller.
    
    self.navigationController = ({
        
        LBXNavigationController *controller =
        [[LBXNavigationController alloc]
         initWithRootViewController:rootViewController];
        
        [controller setDelegate:self];
        
        // Add a button for test purposes.
        
        UIBarButtonItem *testButton = [[UIBarButtonItem alloc] initWithTitle:@"Push" style:0 target:self action:@selector(pushNextLevel:)];
        rootViewController.navigationItem.rightBarButtonItem = testButton;
        controller;
    });
    
    // Assign the navigation controller.
    
    self.window.rootViewController = self.navigationController;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)pushNextLevel:(id)sender;
{
    // Create a new view controller with a red background
    UIViewController *nextViewController = [[UIViewController alloc] initWithNibName:nil bundle:nil];
    nextViewController.view.backgroundColor = [UIColor redColor];
    [self.navigationController pushViewController:nextViewController animated:YES completion:^{
        NSLog(@"Finished");
    }];
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated;
{
    NSLog(@"%@ %@", [self class], NSStringFromSelector(_cmd));
}

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated;
{
    NSLog(@"%@ %@", [self class], NSStringFromSelector(_cmd));
}
@end
