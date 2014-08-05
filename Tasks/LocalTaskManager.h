//
//  LocalTaskManager.h
//  GTaskMaster_Mac
//
//  Created by Kurt Hardin on 6/26/12.
//  Copyright (c) 2012 Kurt Hardin. All rights reserved.
//

#import "GTLTasks.h"
#import "Task.h"
#import "TaskList.h"

@interface LocalTaskManager : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

#pragma mark - Local task list methods

// Get local task list(s):
- (NSArray *)taskLists;                                                     // Gets all the local task lists
- (TaskList *)taskListWithId:(NSString *)taskListId;      // Gets the task list with the specified identifier

// Creates a new task list with the specified title:
- (TaskList *)newTaskListWithTitle:(NSString *)title;

// Remove a task list locally:
- (void)flagTaskListForRemoval:(TaskList *)localTaskList; // Flags specified task list for removal during next sync


#pragma mark - Server task list methods

// Handle changes to a task list from the server:
- (void)addTaskList:(GTLTasksTaskList *)serverTaskList;                     // Adds a new task list from server
- (void)updateTaskList:(GTLTasksTaskList *)serverTaskList;                  // Updates a task list with new data from server
- (void)updateManagedTaskList:(TaskList *)managedTaskList
           withServerTaskList:(GTLTasksTaskList *)serverTaskList;
- (void)removeTaskList:(TaskList *)localTaskList;         // Removes the specified task list


#pragma mark - Local task methods
// Get a local task:
- (Task *)taskWithId:(NSString *)taskId;                  // Gets the task with the specified identifier

// Create a new task with the specified information:
- (Task *)newTaskWithTitle:(NSString *)title
                inTaskList:(TaskList *)taskList;
- (Task *)newTaskWithTitle:(NSString *)title
                inTaskList:(TaskList *)taskList;
- (Task *)newTaskWithTitle:(NSString *)title
                  andNotes:(NSString *)notes
                inTaskList:(TaskList *)taskList;

#pragma mark - Server task methods

// Handle changes to a task from the server:
- (void)addTask:(GTLTasksTask *)serverTask toList:(NSString *)taskListId;   // Adds a new task from server
- (void)updateTask:(GTLTasksTask *)serverTask;                              // Updates a task with new data from server
- (void)updateManagedTask:(Task *)managedTask
           withServerTask:(GTLTasksTask *)serverTask;


#pragma mark - Utility methods

- (void)saveContext;                                                        // Saves changes made in the current ManagedObjectContext
- (void)presentError:(NSError *)error;                                      // Presents a standard error to user

#pragma mark - CoreData Stack

+ (NSManagedObjectContext *)sharedManagedObjectContext;

@end
