//
//  LBXNavigationController.h
//  LBXNavigationController
//
//  Created by Nicholas Zeltzer on 3/1/14.
//  Copyright (c) 2014 LawBox. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LBXNavigationController : UINavigationController

/** 
 Internally, the navigation controller is set to its own delegate. Setting the delegate, externally, will cause the externalDelegate to be set.
 */

@property (nonatomic, readwrite, weak) id <UINavigationControllerDelegate> externalDelegate;

- (void)pushViewController:(UIViewController *)viewController
                  animated:(BOOL)animated
                completion:(void (^)(UINavigationController *navigationController, UIViewController *viewController))completion;

@end
