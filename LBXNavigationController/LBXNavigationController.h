//
//  LBXNavigationController.h
//  LBXNavigationController
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

#import <UIKit/UIKit.h>

/** 
 UINavigationController subclass that adds completion block support to view controller transitions.
 */

@interface LBXNavigationController : UINavigationController

/** 
 Object conforming to the UINavigationControllerDelegate protocol. This accessor should be used en lieu of the UINavigationController delegate property.
 
 @Note Both 'setDelegate:' and 'setExternalDelegate:' will set the 'externalDelegate' property. The 'delegate' property will always return the navigation controller.
 */

@property (nonatomic, readwrite, weak) id <UINavigationControllerDelegate> externalDelegate;

/** Performs a standard push with the added benefit of calling a completion block */

- (void)pushViewController:(UIViewController *)viewController
                  animated:(BOOL)animated
                completion:(void (^)(UINavigationController *navigationController, UIViewController *viewController))completion;

@end
