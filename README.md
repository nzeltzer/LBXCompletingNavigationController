LBXCompletingNavigationController
=================================

UINavigationController subclass with added method providing completion block execution on pushed view controllers.

This class is intended as an example of extending the behavior of a UIKit base class without swizzling rocket launchers. 

    - (void)pushViewController:(UIViewController *)viewController
                  animated:(BOOL)animated
                completion:(void (^)(UINavigationController *navigationController, UIViewController *viewController))completion;
                
