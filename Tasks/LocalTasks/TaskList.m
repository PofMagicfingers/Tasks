//
//  TaskList.m
//  Tasks
//
//  Created by Pof on 05/08/2014.
//  Copyright (c) 2014 Pof Magicfingers. All rights reserved.
//

#import "TaskList.h"
#import "GTLTasksTaskList.h"


@implementation TaskList

@dynamic etag;
@dynamic identifier;
@dynamic synced_at;
@dynamic title;
@dynamic trashed;
@dynamic updated_at;
@dynamic tasks;

- (BOOL)isNew {
    return [self.identifier hasPrefix:@"local_"];
}

- (GTLTasksTaskList *)convertToGTLTasksTaskList {
    GTLTasksTaskList *tasklist = [GTLTasksTaskList object];
    tasklist.title = self.title;
    return tasklist;
}

@end
