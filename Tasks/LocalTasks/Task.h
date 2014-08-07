//
//  Task.h
//  Tasks
//
//  Created by Pof on 05/08/2014.
//  Copyright (c) 2014 Pof Magicfingers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Task, TaskList, GTLTasksTask;

@interface Task : NSManagedObject

@property (nonatomic, retain) NSDate * completed_at;
@property (nonatomic, retain) NSString * etag;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * notes;
@property (nonatomic, retain) NSDate * synced_at;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * trashed;
@property (nonatomic, retain) NSDate * updated_at;
@property (nonatomic, retain) Task *children_tasks;
@property (nonatomic, retain) TaskList *list;
@property (nonatomic, retain) Task *parent;

- (BOOL)isNew;
- (GTLTasksTask *)convertToGTLTasksTask;
- (NSString *)sectionName;

@end
