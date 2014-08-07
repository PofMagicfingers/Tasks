//
//  LocalTaskManager.m
//  From GTaskMaster_Mac
//
//  Created by Kurt Hardin on 6/26/12.
//  Adapted by Pof on 8/5/14
//  Copyright (c) 2012 Kurt Hardin. All rights reserved.
//

#import <TargetConditionals.h>

#import "LocalTaskManager.h"

#import "AppDelegate.h"
#import "GTSyncManager.h"

@interface LocalTaskManager ()
@end

@implementation LocalTaskManager

@synthesize managedObjectContext = _managedObjectContext;

#pragma mark - Local task list methods

- (NSArray *)taskLists {
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"TaskList" inManagedObjectContext:self.managedObjectContext]];
    NSArray *managedTaskLists = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"%@", error);
        return nil;
    }
    return managedTaskLists;
}

- (TaskList *)taskListWithId:(NSString *)taskListId {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"TaskList" inManagedObjectContext:self.managedObjectContext]];
    if (taskListId && taskListId.length > 0) {
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", taskListId]];
    }
	NSError *error = nil;
    NSArray *managedTaskLists = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"%@", error);
    } else if (managedTaskLists.count == 1) {
        return [managedTaskLists objectAtIndex:0];
    }
    return nil;
}

- (TaskList *)newTaskListWithTitle:(NSString *)title {
    NSLog(@"Create new local task list: '%@'\n", title);
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"TaskList"
                                              inManagedObjectContext:self.managedObjectContext];
    TaskList *newTaskList = [[TaskList alloc] initWithEntity:entity
                              insertIntoManagedObjectContext:self.managedObjectContext];

    [newTaskList setTitle:title];
    [self saveContext];
    
    return newTaskList;
}

- (void)flagTaskListForRemoval:(TaskList *)localTaskList {
    localTaskList.trashed = [NSNumber numberWithBool:YES];
    localTaskList.updated_at = [NSDate date];
    [[GTSyncManager sharedInstance] removeTaskList:localTaskList];
}


#pragma mark - Server task list methods

- (void)updateManagedTaskList:(TaskList *)managedTaskList withServerTaskList:(GTLTasksTaskList *)serverTaskList {
    managedTaskList.etag = serverTaskList.ETag;
    managedTaskList.identifier = serverTaskList.identifier;
    managedTaskList.title = serverTaskList.title;
    managedTaskList.updated_at = managedTaskList.synced_at = serverTaskList.updated.date;
    managedTaskList.trashed = [NSNumber numberWithBool:NO];
    [self saveContext];
}

- (void)addTaskList:(GTLTasksTaskList *)serverTaskList {
    
    NSLog(@"Add new local task list from server: '%@'\n", serverTaskList.title);
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"TaskList"
                                              inManagedObjectContext:self.managedObjectContext];
    TaskList *taskList = [[TaskList alloc] initWithEntity:entity
                                             insertIntoManagedObjectContext:self.managedObjectContext];
    [self updateManagedTaskList:taskList withServerTaskList:serverTaskList];
}

- (void)updateTaskList:(GTLTasksTaskList *)serverTaskList {
    
    NSLog(@"Update local task list from server: '%@'\n", serverTaskList.title);
    
    TaskList *taskList = [self taskListWithId:serverTaskList.identifier];
    [self updateManagedTaskList:taskList withServerTaskList:serverTaskList];
}

- (void)removeTaskList:(TaskList *)localTaskList {
    if (localTaskList) {
        [self.managedObjectContext deleteObject:localTaskList];
        [self saveContext];
    }
}


#pragma mark - Local task methods

- (Task *)taskWithId:(NSString *)taskId {
    NSError *error = nil;
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Task" inManagedObjectContext:self.managedObjectContext]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", taskId]];
    NSArray *managedTaskObjs = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (error) {
        NSLog(@"%@", error);
    } else if (managedTaskObjs.count > 0) {
        return [managedTaskObjs objectAtIndex:0];
    }
    
    return nil;
}

- (Task *)newTaskWithTitle:(NSString *)title
                inTaskList:(TaskList *)taskList {
    
    return [self newTaskWithTitle:title andNotes:nil inTaskList:taskList];
    
}

- (Task *)newTaskWithTitle:(NSString *)title
                  andNotes:(NSString *)notes
                inTaskList:(TaskList *)taskList {
    
    NSLog(@"Creating new local task: '%@' in list: '%@'\n", title, taskList.title);
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Task"
                                              inManagedObjectContext:self.managedObjectContext];
    Task *newTask = [[Task alloc] initWithEntity:entity
                  insertIntoManagedObjectContext:self.managedObjectContext];
    newTask.title = title;
    newTask.notes = notes;
    newTask.list = taskList;
    
    taskList.updated_at = [NSDate date];
    
    [self saveContext];
    
    return newTask;
    
}

- (void)removeTask:(TaskList *)localTask {
    if (localTask) {
        [self.managedObjectContext deleteObject:localTask];
        [self saveContext];
    }
}

#pragma mark - Server task methods

- (void)updateManagedTask:(Task *)managedTask withServerTask:(GTLTasksTask *)serverTask {
    managedTask.completed_at = [serverTask.status isEqualToString:@"completed"] ? serverTask.completed.date : nil;
    managedTask.trashed = [NSNumber numberWithBool:(serverTask.deleted != nil && [serverTask.deleted boolValue])];
    managedTask.etag = serverTask.ETag;
    managedTask.identifier = serverTask.identifier;
    managedTask.notes = serverTask.notes;
    managedTask.title = serverTask.title;
    managedTask.updated_at = managedTask.synced_at = serverTask.updated.date;
    
    NSString *parentTaskId = serverTask.parent;
    if (parentTaskId) {
        Task *parentTask = [self taskWithId:parentTaskId];
        managedTask.parent = parentTask;
    }
    
    [self saveContext];
}

- (void)addTask:(GTLTasksTask *)serverTask toList:(NSString *)taskListId {
    NSLog(@"Adding new local task from server: '%@'\n", serverTask.title);
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Task"
                                              inManagedObjectContext:self.managedObjectContext];
    Task *task = [[Task alloc] initWithEntity:entity
                insertIntoManagedObjectContext:self.managedObjectContext];
    task.list = [self taskListWithId:taskListId];
    [self updateManagedTask:task withServerTask:serverTask];
}

- (void)updateTask:(GTLTasksTask *)serverTask {
    NSLog(@"Updating local task from server: '%@'\n", serverTask.title);
    Task *task = [self taskWithId:serverTask.identifier];
    [self updateManagedTask:task withServerTask:serverTask];
}

#pragma mark - Core Data stack

- (void)saveContext {
    [self.managedObjectContext performBlockAndWait:^{
        
        NSLog(@"Saving managedObjectContext");
        NSError *error = nil;
        NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
        if (managedObjectContext != nil) {
            if ([[self managedObjectContext] hasChanges] && ![[self managedObjectContext] save:&error]) {
                NSLog(@"Unresolved error saving context: %@, %@", error, [error userInfo]);
                //            abort();
            }
        }
    }];
}


// Returns the directory the application uses to store the Core Data store file.
+ (NSURL *)applicationStoreDirectory {
    return [(AppDelegate *)[UIApplication sharedApplication].delegate applicationDocumentsDirectory];
}

// Creates if necessary and returns the managed object model for the application.
+ (NSManagedObjectModel *)sharedManagedObjectModel {
    
    __strong static NSManagedObjectModel *_sharedManagedObjectModel = nil;
    
    static dispatch_once_t pred = 0;
    dispatch_once(&pred, ^{
        
        NSURL *modelURL = [[NSBundle mainBundle]
                           URLForResource:@"Tasks"
                           withExtension:@"momd"];
        _sharedManagedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        
    });
    
    return _sharedManagedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
+ (NSPersistentStoreCoordinator *)sharedPersistentStoreCoordinator {
    
    __strong static NSPersistentStoreCoordinator * _sharedPersistentStoreCoordinator = nil;
    
    static dispatch_once_t pred = 0;
    dispatch_once(&pred, ^{
        {
            NSURL *storeURL = [[LocalTaskManager applicationStoreDirectory] URLByAppendingPathComponent:@"Tasks.sqlite"];
            
            NSError *error = nil;
            _sharedPersistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[LocalTaskManager sharedManagedObjectModel]];
            if (![_sharedPersistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
                /*
                 Replace this implementation with code to handle the error appropriately.
                 
                 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                 Typical reasons for an error here include:
                 * The persistent store is not accessible;
                 * The schema for the persistent store is incompatible with current managed object model.
                 Check the error message to determine what the actual problem was.
                 
                 
                 If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
                 
                 If you encounter schema incompatibility errors during development, you can reduce their frequency by:
                 * Simply deleting the existing store:
                 [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
                 
                 * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
                 @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
                 
                 Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
                 
                 */
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                
                //                abort();
                _sharedPersistentStoreCoordinator = nil;
            }
        }
    });
    
    return _sharedPersistentStoreCoordinator;
}

+ (NSManagedObjectContext *)sharedManagedObjectContext {
    
    __strong static NSManagedObjectContext *_sharedManagedObjectContext = nil;
    
    static dispatch_once_t pred = 0;
    dispatch_once(&pred, ^{
        
        NSPersistentStoreCoordinator *coordinator = [LocalTaskManager sharedPersistentStoreCoordinator];
        if (coordinator != nil) {
            _sharedManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            [_sharedManagedObjectContext setPersistentStoreCoordinator:coordinator];
        }
        
    });
    
    return _sharedManagedObjectContext;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
- (NSManagedObjectContext *)managedObjectContext {
    if (!_managedObjectContext) {
        _managedObjectContext = [LocalTaskManager sharedManagedObjectContext];
    }
    
    return _managedObjectContext;
}

@end
