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

- (NSDate *)synced_at {
    [self willAccessValueForKey:@"synced_at"];
    NSDate *_synced_at = [self primitiveValueForKey:@"synced_at"];
    [self didAccessValueForKey:@"synced_at"];

    if (![_synced_at isKindOfClass:[NSDate class]]) {
        return [NSDate dateWithTimeIntervalSince1970:0];
    } else {
        return _synced_at;
    }
}

- (BOOL)isNew {
    return [self.identifier hasPrefix:@"local_"] && ![self.trashed boolValue];
}

- (GTLTasksTaskList *)convertToGTLTasksTaskList {
    GTLTasksTaskList *tasklist = [GTLTasksTaskList object];
    tasklist.title = self.title;
    return tasklist;
}

@end
