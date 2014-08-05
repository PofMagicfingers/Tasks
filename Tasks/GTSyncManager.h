//
//  GTSyncManger.h
//  From GTaskMaster_Mac
//
//  Created by Kurt Hardin on 6/21/12.
//  Adapted by Pof on 8/5/14
//  Copyright (c) 2012 Kurt Hardin. All rights reserved.
//

#import "LocalTaskManager.h"
#import "GTLTasks.h"

@interface GTSyncManager : NSObject {
    NSInteger incompleteQueryCount;
}

@property (readonly, nonatomic) BOOL isSyncing;
@property (readonly, nonatomic) BOOL isRepeating;
@property (nonatomic) double delayInSeconds;

@property (readonly, strong, nonatomic) NSTimer *syncTimer;

@property (readonly, strong, nonatomic) LocalTaskManager *taskManager;
@property (readonly, strong, nonatomic) GTLServiceTasks *tasksService;
@property (readonly, copy, nonatomic) NSMutableSet *activeServiceTickets;

+ (GTSyncManager *)sharedInstance;

+ (void)setSyncDelay:(double)seconds;
+ (BOOL)startSyncing;
+ (BOOL)startSyncingWithInterval:(double)seconds;
+ (BOOL)stopSyncing;
+ (BOOL)syncNow;

- (BOOL)addTaskList:(TaskList *)taskList;
- (BOOL)updateTaskList:(TaskList *)taskList;
- (BOOL)removeTaskList:(TaskList *)taskList;

- (BOOL)addTask:(Task *)task;
- (BOOL)updateTask:(Task *)task;

@end
