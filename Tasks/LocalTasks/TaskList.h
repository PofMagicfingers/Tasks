//
//  TaskList.h
//  Tasks
//
//  Created by Pof on 05/08/2014.
//  Copyright (c) 2014 Pof Magicfingers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GTLTasksTaskList;

@interface TaskList : NSManagedObject

@property (nonatomic, retain) NSString * etag;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSDate * synced_at;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * trashed;
@property (nonatomic, retain) NSDate * updated_at;
@property (nonatomic, retain) NSSet *tasks;
@end

@interface TaskList (CoreDataGeneratedAccessors)

- (void)addTasksObject:(NSManagedObject *)value;
- (void)removeTasksObject:(NSManagedObject *)value;
- (void)addTasks:(NSSet *)values;
- (void)removeTasks:(NSSet *)values;

- (BOOL)isNew;
- (GTLTasksTaskList *)convertToGTLTasksTaskList;

@end
