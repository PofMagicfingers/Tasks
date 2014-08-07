//
//  TaskListTests.m
//  Tasks
//
//  Created by Pof on 07/08/2014.
//  Copyright (c) 2014 Pof Magicfingers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "LocalTaskManager.h"

#import "TaskList.h"
#import "GTLTasksTaskList.h"

#import "NSString+UUID.h"

@interface TaskListTests : XCTestCase

@property (nonatomic, readonly) NSManagedObjectContext *context;

- (TaskList *)makeTaskList;

@end

@implementation TaskListTests

@synthesize context = _context;

- (void)setUp {
    [super setUp];
    _context = [LocalTaskManager sharedManagedObjectContext];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testingIsNewTaskList {
    // Simple new TaskList
    TaskList *taskList = [self makeTaskList];
    taskList.identifier = [@"local_" stringByAppendingString:[NSString UUID]];
    
    XCTAssert(taskList.isNew, @"New task list is not seen as new");
    
    // Simple new Task but trashed
    TaskList *taskList2 = [self makeTaskList];
    taskList2.identifier = [@"local_" stringByAppendingString:[NSString UUID]];
    taskList2.trashed = [NSNumber numberWithBool:YES];
    
    XCTAssertFalse(taskList2.isNew, @"New task (trashed) is seen as new");
    
    // Simple new Task from server
    TaskList *taskList3 = [self makeTaskList];
    taskList3.identifier = [NSString UUID];
    
    XCTAssertFalse(taskList3.isNew, @"New task from server is seen as new");
    
    // Simple new Task from server but trashed
    TaskList *taskList4 = [self makeTaskList];
    taskList4.identifier = [NSString UUID];
    taskList4.trashed = [NSNumber numberWithBool:YES];
    
    XCTAssertFalse(taskList3.isNew, @"New task from server is seen as new");
    
}

- (void)testConvertingToGTLTasksTaskList {
    
    // Setting some variables
    NSDate *date = [NSDate date];
    
    // Creating a new task list
    TaskList *taskList = [self makeTaskList];
    taskList.title = @"Hello I'm a task list";
    taskList.updated_at = date;
    
    // Creating the expected GTL Task List
    GTLTasksTaskList *expected_gtlTaskList = [GTLTasksTaskList new];
    expected_gtlTaskList.title = @"Hello I'm a task list";
    expected_gtlTaskList.updated = [GTLDateTime dateTimeWithDate:date timeZone:[NSTimeZone systemTimeZone]];
    
    // Converting it
    GTLTasksTaskList *converted_gtlTaskList = [taskList convertToGTLTasksTaskList];
    
    XCTAssertEqualObjects([converted_gtlTaskList JSON], [expected_gtlTaskList JSON], @"Converted GTLTaskList is not equal to expected GTLTaskList!");
}

- (void)testSyncDate {
    NSDate *aDate = [NSDate date];
    
    // Testing Task with a sync date
    TaskList *taskList = [self makeTaskList];
    taskList.synced_at = taskList.updated_at = aDate;
    
    XCTAssertEqualObjects(taskList.synced_at, aDate, @"synced_at is not equal to setted date");
    
    // Testing Task with no sync date
    TaskList *taskList2 = [self makeTaskList];
    taskList2.updated_at = aDate;
    
    XCTAssertEqualObjects(taskList2.synced_at, [NSDate dateWithTimeIntervalSince1970:0], @"synced_at should equal reference date (1970)");
}

#pragma mark - Utilities

- (Task *)makeTaskList {
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"TaskList" inManagedObjectContext:self.context];
    return [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:self.context];
}

@end