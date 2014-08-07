//
//  Task.m
//  Tasks
//
//  Created by Pof on 05/08/2014.
//  Copyright (c) 2014 Pof Magicfingers. All rights reserved.
//

#import "Task.h"
#import "Task.h"
#import "TaskList.h"
#import "GTLTasksTask.h"

@implementation Task

@dynamic completed_at;
@dynamic etag;
@dynamic identifier;
@dynamic notes;
@dynamic synced_at;
@dynamic title;
@dynamic trashed;
@dynamic updated_at;
@dynamic children_tasks;
@dynamic list;
@dynamic parent;

- (NSString *)sectionName {
    [self willAccessValueForKey:@"sectionName"];
    [self didAccessValueForKey:@"sectionName"];
    
    return ([self.completed_at isKindOfClass:[NSDate class]] ? @"Done" : @"To Do");
}

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

- (GTLTasksTask *)convertToGTLTasksTask {
    GTLTasksTask *task = [GTLTasksTask object];
    
    if ([self.completed_at isKindOfClass:[NSDate class]]) {
        task.completed = [GTLDateTime dateTimeWithDate:self.completed_at timeZone:[NSTimeZone systemTimeZone]];
        task.status = @"completed";
    } else {
        // Not quite elegant, but the simpliest way to make tha Google API to accept the patch. GTL is not up to date, it's not fully compatible with the API.
        task.completed = [NSNull null];
        task.status = @"needsAction";
    }
    
    task.notes = self.notes;
    task.title = self.title;
    task.updated = [GTLDateTime dateTimeWithDate:self.updated_at timeZone:[NSTimeZone systemTimeZone]];;
    return task;
}

@end
