//
//  GTSyncManger.m
//  From GTaskMaster_Mac
//
//  Created by Kurt Hardin on 6/21/12.
//  Adapted by Pof on 8/5/14
//  Copyright (c) 2012 Kurt Hardin. All rights reserved.
//

#import "GTSyncManager.h"

@interface GTSyncManager ()

- (BOOL)startRepeatedSyncing;
- (BOOL)cancelRepeatedSyncing;
- (BOOL)sync;

- (BOOL)performSyncTask:(void (^)())taskBlock;
- (void)performQuery:(GTLQuery *)query completionHandler:(void (^)(GTLServiceTicket *ticket, id object, NSError *error))handler;

- (void)processServerTaskLists;
- (void)addTaskListToServer:(TaskList *)localTaskList;
- (void)updateTaskListOnServer:(TaskList *)localTaskList;
- (void)removeTaskListFromServer:(TaskList *)localTaskList;

- (void)processServerTasksForTaskList:(GTLTasksTaskList *)serverTaskList;
- (void)addTaskToServer:(Task *)localTask;
- (void)updateTaskOnServer:(Task *)localTask;

@end


int const kDefaultSyncIntervalSec = 300;


@implementation GTSyncManager

@synthesize isSyncing=_isSyncing;
@synthesize isRepeating=_isRepeating;
@synthesize delayInSeconds=_delayInSeconds;
@synthesize syncTimer=_syncTimer;
@synthesize taskManager=_taskManager;
@synthesize tasksService=_tasksService;
@synthesize activeServiceTickets=_activeServiceTickets;

+ (GTSyncManager *)sharedInstance {
    __strong static id _sharedObject = nil;
    
    static dispatch_once_t pred = 0;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    
    return _sharedObject;
}

+ (void)setSyncDelay:(double)seconds {
    GTSyncManager *syncer = [GTSyncManager sharedInstance];
    [syncer setDelayInSeconds:seconds];
    if (syncer.isRepeating) {
        [syncer cancelRepeatedSyncing];
        [syncer startRepeatedSyncing];
    }
}

+ (BOOL)startSyncing {
    return [[GTSyncManager sharedInstance] startRepeatedSyncing];
}

+ (BOOL)startSyncingWithInterval:(double)seconds {
    GTSyncManager *syncer = [GTSyncManager sharedInstance];
    if (!syncer.isRepeating) {
        syncer.delayInSeconds = seconds;
        [syncer startRepeatedSyncing];
        return YES;
    }
    return NO;
}

+ (BOOL)stopSyncing {
    return [[GTSyncManager sharedInstance] cancelRepeatedSyncing];
}

+ (BOOL)syncNow {
    return [[GTSyncManager sharedInstance] sync];
}

- (id)init {
    self = [super init];
    if (self) {
        _isSyncing = NO;
        _isRepeating = NO;
        _delayInSeconds = kDefaultSyncIntervalSec;
        
        _activeServiceTickets = [NSMutableSet setWithCapacity:25];
    }
    return self;
}

- (LocalTaskManager *)taskManager {
    if (_taskManager == nil) {
        _taskManager = [[LocalTaskManager alloc] init];
    }
    return _taskManager;
}

- (GTLServiceTasks *)tasksService {
    if (!_tasksService) {
        _tasksService = [[GTLServiceTasks alloc] init];
        _tasksService.shouldFetchNextPages = YES;
        _tasksService.retryEnabled = YES;
    }
    return _tasksService;
}

- (BOOL)startRepeatedSyncing {
    if (!self.isRepeating) {
        _isRepeating = YES;
        [self sync];
        _syncTimer = [NSTimer scheduledTimerWithTimeInterval:self.delayInSeconds
                                                      target:self
                                                    selector:@selector(sync)
                                                    userInfo:nil
                                                     repeats:YES];
        return YES;
    }
    return NO;
}

- (BOOL)cancelRepeatedSyncing {
    if (self.isRepeating) {
        if (self.syncTimer) {
            [self.syncTimer invalidate];
            _syncTimer = nil;
        }
        _isRepeating = NO;
        return YES;
    }
    return NO;
}

- (BOOL)sync {
    return [self performSyncTask:^{
        incompleteQueryCount = 0;
        [self processServerTaskLists];
    }];
}

- (BOOL)performSyncTask:(void (^)())taskBlock {
    if (!self.isSyncing) {
        [self.taskManager.managedObjectContext performBlock:^{
            _isSyncing = YES;
            taskBlock();
        }];
        return YES;
    }
    return NO;
}

- (void)performQuery:(GTLQuery *)query completionHandler:(void (^)(GTLServiceTicket *ticket, id object, NSError *error))handler {
        
    incompleteQueryCount++;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [_activeServiceTickets addObject:[self.tasksService executeQuery:query
                                                   completionHandler:^(GTLServiceTicket *ticket,
                                                                       id item, NSError *error) {
                                                       
                                                       [_activeServiceTickets removeObject:ticket];
                                                       
                                                       [self.taskManager.managedObjectContext performBlock:^{
                                                           
                                                           handler(ticket, item, error);
                                                           
                                                           incompleteQueryCount--;
                                                           if (incompleteQueryCount == 0) {
                                                               _isSyncing = NO;
                                                           }
                                                           
                                                       }];
                                                       
                                                   }]];
        
    });
    
}

#pragma mark - TaskList methods

- (void)processServerTaskLists {
    
    [self performQuery:[GTLQueryTasks queryForTasklistsList] completionHandler:^(GTLServiceTicket *ticket,
                                                                                 id serverTaskLists, NSError *error) {
        
        if (error) {
            NSLog(@"Error fetching task lists from server:\n  %@", error);
        } else {
            NSMutableArray *localTaskLists = [NSMutableArray arrayWithArray:[self.taskManager taskLists]];
            
            if (serverTaskLists) {
                for (GTLTasksTaskList *serverTaskList in serverTaskLists) {
                    
                    NSDate *serverModDate = serverTaskList.updated.date;
                    TaskList *localTaskList = [self.taskManager taskListWithId:serverTaskList.identifier];
                    
                    BOOL shouldProcessTasksForTaskList = YES;
                    if (localTaskList == nil) {
                        [self.taskManager addTaskList:serverTaskList];
                        
                    } else if (localTaskList.trashed.boolValue) {
                        [self removeTaskListFromServer:localTaskList];
                        shouldProcessTasksForTaskList = NO;
                        
                    } else {
                        NSDate *localSyncDate = localTaskList.synced_at;
                        NSDate *localModDate = localTaskList.updated_at;
                        if (![localSyncDate isEqualToDate:localModDate]) {
                            if ([localSyncDate isEqualToDate:serverModDate]) {
                                [self updateTaskListOnServer:localTaskList];
                            } else {
#pragma mark TODO: Resolve conflict
                            }
                            
                        } else if (![localSyncDate isEqualToDate:serverModDate]) {
                            [self.taskManager updateTaskList:serverTaskList];
                            
                        } else {
                            shouldProcessTasksForTaskList = NO;
                            
                        }
                        
                    }
                    
                    if (shouldProcessTasksForTaskList) {
                        [self processServerTasksForTaskList:serverTaskList];
                    }
                    
                    [localTaskLists removeObject:localTaskList];
                }
            }
            
            if (localTaskLists.count > 0) {
                for (TaskList *localTaskList in localTaskLists) {
                    if ([localTaskList isNew]) {
                        [self addTaskListToServer:localTaskList];
                    } else {
                        [self.taskManager removeTaskList:localTaskList];
                    }
                }
            }
        }
        
    }];
}

- (BOOL)addTaskList:(TaskList *)taskList {
    return [self performSyncTask:^{
        [self addTaskListToServer:taskList];
    }];
}

- (void)addTaskListToServer:(TaskList *)localTaskList {
    if ([localTaskList.title length] > 0) {
        
        GTLTasksTaskList *tasklist = [localTaskList convertToGTLTasksTaskList];
        GTLQueryTasks *query = [GTLQueryTasks queryForTasklistsInsertWithObject:tasklist];
        
        [self performQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                     id newTaskList, NSError *error) {
            
            if (error) {
                NSLog(@"Error adding task to server:\n  %@", error);
                
            } else {
                [self.taskManager updateManagedTaskList:localTaskList withServerTaskList:newTaskList];
                [self processServerTasksForTaskList:newTaskList];
                
            }
            
        }];
    }
}

- (BOOL)updateTaskList:(TaskList *)taskList {
    return [self performSyncTask:^{
        [self updateTaskListOnServer:taskList];
    }];
}

- (void)updateTaskListOnServer:(TaskList *)localTaskList {
    
    if ([localTaskList.title length] > 0) {
        
        GTLTasksTaskList *patchObject = [localTaskList convertToGTLTasksTaskList];
        GTLQueryTasks *query = [GTLQueryTasks queryForTasklistsPatchWithObject:patchObject tasklist:localTaskList.identifier];
        
        [self performQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                     id updatedTaskList, NSError *error) {
            
            if (error) {
                NSLog(@"Error updating task list:\n  %@", error);
                
            } else {
                [self.taskManager updateTaskList:updatedTaskList];
                
            }
            
        }];
    }
}

- (BOOL)removeTaskList:(TaskList *)taskList {
    return [self performSyncTask:^{
        [self removeTaskListFromServer:taskList];
    }];
}

- (void)removeTaskListFromServer:(TaskList *)localTaskList {
    
    GTLQueryTasks *query = [GTLQueryTasks queryForTasklistsDeleteWithTasklist:localTaskList.identifier];
    
    [self performQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                 id item, NSError *error) {
        
        if (error) {
            NSLog(@"Error removing task list:\n  %@", error);
            
        } else {
            [self.taskManager removeTaskList:localTaskList];
            
        }
        
    }];
}

#pragma mark - Task methods

- (void)processServerTasksForTaskList:(GTLTasksTaskList *)serverTaskList {
    
    GTLQueryTasks *query = [GTLQueryTasks queryForTasksListWithTasklist:serverTaskList.identifier];
    query.showCompleted = YES;
    query.showHidden = YES;
    query.showDeleted = YES;
    query.maxResults = 2000;
    
    NSLog(@"Fetching tasks for tasklist (%@), query.maxResults=%lld", serverTaskList.identifier, query.maxResults);
    
    [self performQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                 id serverTasks, NSError *error) {
        
        if (error) {
#pragma mark TODO: Present error
        } else {
            NSMutableOrderedSet *localTasks = [NSMutableOrderedSet orderedSetWithOrderedSet:[self.taskManager taskListWithId:serverTaskList.identifier].tasks];
            
            int processedCount = 0;
            int addedCount = 0;
            for (GTLTasksTask *serverTask in serverTasks) {
                
                Task *localTask = [self.taskManager taskWithId:serverTask.identifier];
                if (localTask == nil) {
                    [self.taskManager addTask:serverTask toList:serverTaskList.identifier];
                    addedCount++;
                    
                } else {
                    NSDate *serverModDate = serverTask.updated.date;
                    NSDate *localModDate = localTask.updated_at;
                    NSDate *localSyncDate = localTask.synced_at;
                    if (![localModDate isEqualToDate:localSyncDate]) {
                        if ([localSyncDate isEqualToDate:serverModDate]) {
                            [self updateTaskOnServer:localTask];
                        } else {
# pragma mark TODO: Resolve sync conflict
                        }
                    } else if (![localSyncDate isEqualToDate:serverModDate]) {
                        [self.taskManager updateTask:serverTask];
                    }
                    
                    [localTasks removeObject:localTask];
                }
                
                processedCount++;
            }
            
            NSLog(@"Processed %d tasks from server, %d added\n\n", processedCount, addedCount);
            
            if (localTasks.count > 0) {
                for (Task *task in localTasks) {
                    [self addTaskToServer:task];
                }
            }
        }
     
     }];
}

- (BOOL)addTask:(Task *)task {
    return [self performSyncTask:^{
        [self addTaskToServer:task];
    }];
}

- (void)addTaskToServer:(Task *)localTask {
    
    GTLTasksTask *taskToAdd = [localTask convertToGTLTasksTask];
    
    if (taskToAdd.title.length > 0) {
        
        GTLQueryTasks *query = [GTLQueryTasks queryForTasksInsertWithObject:taskToAdd tasklist:localTask.list.identifier];
        
        [self performQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                     id serverTask, NSError *error) {
            
            if (error) {
                NSLog(@"Error adding task to server:\n  %@", error);
                
            } else {
                [self.taskManager updateManagedTask:localTask withServerTask:serverTask];
                
            }
            
        }];
    }
}

- (BOOL)updateTask:(Task *)task {
    return [self performSyncTask:^{
        [self updateTaskOnServer:task];
    }];
}

- (void)updateTaskOnServer:(Task *)localTask {
    
    GTLTasksTask *taskToPatch = [localTask convertToGTLTasksTask];
    
    if (taskToPatch.title.length > 0) {
        
        GTLQueryTasks *query = [GTLQueryTasks queryForTasksPatchWithObject:taskToPatch
                                                                  tasklist:localTask.list.identifier
                                                                      task:localTask.identifier];
        
        [self performQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                     id serverTask, NSError *error) {
            
            if (error) {
                NSLog(@"Error updating task on server:\n  %@", error);
                
            } else {
                [self.taskManager updateTask:serverTask];
                
            }
            
        }];
    }
}

@end
