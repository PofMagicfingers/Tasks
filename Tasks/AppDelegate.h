//
//  AppDelegate.h
//  Tasks
//
//  Created by Pof on 31/07/2014.
//  Copyright (c) 2014 Pof Magicfingers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "LocalTaskManager.h"
#import "GoogleAPI.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) GTMOAuth2Authentication *googleAuth;
@property (readonly, strong, nonatomic) LocalTaskManager *taskManager;

- (NSURL *)applicationDocumentsDirectory;

- (void)googleAutoSignIn;
- (void)googleSignIn:(void (^)(GTMOAuth2ViewControllerTouch *viewController, GTMOAuth2Authentication *auth, NSError *error))handler;
- (void)googleSignOut;
- (BOOL)googleIsSignedIn;


@end

