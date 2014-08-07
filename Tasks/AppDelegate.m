//
//  AppDelegate.m
//  Tasks
//
//  Created by Pof on 31/07/2014.
//  Copyright (c) 2014 Pof Magicfingers. All rights reserved.
//

#import "AppDelegate.h"
#import "MasterViewController.h"
#import "GTSyncManager.h"

@interface AppDelegate ()
            

@end

@implementation AppDelegate

@synthesize taskManager = _taskManager;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    UINavigationController *masterNavigationController = self.window.rootViewController;

    MasterViewController *controller = (MasterViewController *)masterNavigationController.topViewController;
    controller.managedObjectContext = self.taskManager.managedObjectContext;

    [self googleAutoSignIn];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self.taskManager saveContext];
}

#pragma mark - Google OAuth

- (void)googleAutoSignIn {
    if (![self googleIsSignedIn]) {
        _googleAuth = [GTMOAuth2ViewControllerTouch
                       authForGoogleFromKeychainForName:kKeychainItemName
                       clientID:kMyClientID
                       clientSecret:kMyClientSecret];
        [[GTSyncManager sharedInstance].tasksService setAuthorizer:_googleAuth];
    }
}

- (void)googleSignIn:(void (^)(GTMOAuth2ViewControllerTouch *viewController, GTMOAuth2Authentication *auth, NSError *error))handler {
    if(![self googleIsSignedIn]) {
        // Show the OAuth 2 sign-in controller
        GTMOAuth2ViewControllerTouch *authViewController;
        authViewController = [GTMOAuth2ViewControllerTouch
                              controllerWithScope:kGTLAuthScopeTasks
                              clientID:kMyClientID
                              clientSecret:kMyClientSecret
                              keychainItemName:kKeychainItemName
                              completionHandler:^(GTMOAuth2ViewControllerTouch *viewController, GTMOAuth2Authentication *auth, NSError *error) {
                                  _googleAuth = auth;
                                  handler(viewController, _googleAuth, error);
                              }];
        authViewController.hidesBottomBarWhenPushed = YES;
        [(UINavigationController *)self.window.rootViewController pushViewController:authViewController animated:YES];

    }
}

- (void)googleSignOut {
    if ([self googleIsSignedIn]) {
        [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kKeychainItemName];
        [GTMOAuth2ViewControllerTouch revokeTokenForGoogleAuthentication:self.googleAuth];
        [self googleAutoSignIn]; // Auto SignIn when no credentials to reset _googleAuth
    }
}

- (BOOL)googleIsSignedIn {
    return (self.googleAuth && self.googleAuth.canAuthorize);
}

- (LocalTaskManager *)taskManager {
    if (_taskManager == nil) {
        _taskManager = [[LocalTaskManager alloc] init];
    }
    return _taskManager;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


@end
