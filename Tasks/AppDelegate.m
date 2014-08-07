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
    [self googleAutoSignIn];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
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
                                  [[GTSyncManager sharedInstance].tasksService setAuthorizer:_googleAuth];
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
