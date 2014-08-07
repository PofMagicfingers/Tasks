//
//  TaskTests.m
//  Tasks
//
//  Created by Pof on 07/08/2014.
//  Copyright (c) 2014 Pof Magicfingers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "LocalTaskManager.h"

#import "Task.h"
#import "GTLTasksTask.h"

#import "NSString+UUID.h"

@interface TaskTests : XCTestCase

@property (nonatomic, readonly) NSManagedObjectContext *context;

- (Task *)makeTask;

@end

@implementation TaskTests

@synthesize context = _context;

- (void)setUp {
    [super setUp];
    _context = [LocalTaskManager sharedManagedObjectContext];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testingIsNewTask {
    // Simple new Task
    Task *task = [self makeTask];
    task.identifier = [@"local_" stringByAppendingString:[NSString UUID]];
    
    XCTAssert(task.isNew, @"New task is not seen as new");

    // Simple new Task but trashed
    Task *task2 = [self makeTask];
    task2.identifier = [@"local_" stringByAppendingString:[NSString UUID]];
    task2.trashed = [NSNumber numberWithBool:YES];
    
    XCTAssertFalse(task2.isNew, @"New task (trashed) is seen as new");

    // Simple new Task from server
    Task *task3 = [self makeTask];
    task3.identifier = [NSString UUID];
    
    XCTAssertFalse(task3.isNew, @"New task from server is seen as new");

    // Simple new Task from server but trashed
    Task *task4 = [self makeTask];
    task4.identifier = [NSString UUID];
    task4.trashed = [NSNumber numberWithBool:YES];
    
    XCTAssertFalse(task3.isNew, @"New task from server is seen as new");

}

- (void)testConvertingToGTLTasksTask {

    // Setting some variables
    NSDate *date = [NSDate date];
    
    // Creating a new task with no completion status
    Task *task = [self makeTask];
    task.title = @"Hello I'm a task";
    task.notes = @"...";
    task.updated_at = date;
    
    // Creating the expected GTL Task
    GTLTasksTask *expected_gtlTask = [GTLTasksTask new];
    expected_gtlTask.title = @"Hello I'm a task";
    expected_gtlTask.notes = @"...";
    expected_gtlTask.updated = [GTLDateTime dateTimeWithDate:date timeZone:[NSTimeZone systemTimeZone]];
    expected_gtlTask.status = @"needsAction";
    expected_gtlTask.completed = [NSNull null];
    
    // Converting it
    GTLTasksTask *converted_gtlTask = [task convertToGTLTasksTask];
    
    XCTAssertEqualObjects([converted_gtlTask JSON], [expected_gtlTask JSON], @"Task with a no status: converted GTLTask is not equal to expected GTLTask!");

    
    // Creating a new task with a completed status
    Task *task2 = [self makeTask];
    task2.title = @"Hello I'm a completed task";
    task2.notes = @"...";
    task2.updated_at = task2.completed_at = date;
    
    // Creating the expected GTL Task
    GTLTasksTask *expected_gtlTask2 = [GTLTasksTask new];
    expected_gtlTask2.title = @"Hello I'm a completed task";
    expected_gtlTask2.notes = @"...";
    expected_gtlTask2.updated = expected_gtlTask2.completed = [GTLDateTime dateTimeWithDate:date timeZone:[NSTimeZone systemTimeZone]];
    expected_gtlTask2.status = @"completed";
    
    // Converting it
    GTLTasksTask *converted_gtlTask2 = [task2 convertToGTLTasksTask];
    
    XCTAssertEqualObjects([converted_gtlTask2 JSON], [expected_gtlTask2 JSON], @"Task with a completed status: converted GTLTask is not equal to expected GTLTask!");

    // Creating a new task with an ucompleted status
    Task *task3 = [self makeTask];
    task3.title = @"Hello I'm an uncompleted task";
    task3.notes = @"...";
    task3.updated_at = date;
    task2.completed_at = nil;
    
    // Creating the expected GTL Task
    GTLTasksTask *expected_gtlTask3 = [GTLTasksTask new];
    expected_gtlTask3.title = @"Hello I'm an uncompleted task";
    expected_gtlTask3.notes = @"...";
    expected_gtlTask3.updated =[GTLDateTime dateTimeWithDate:date timeZone:[NSTimeZone systemTimeZone]];
    expected_gtlTask3.completed = [NSNull null];
    expected_gtlTask3.status = @"needsAction";
    
    // Converting it
    GTLTasksTask *converted_gtlTask3 = [task3 convertToGTLTasksTask];
    
    XCTAssertEqualObjects([converted_gtlTask3 JSON], [expected_gtlTask3 JSON], @"Task with a uncompleted status: converted GTLTask is not equal to expected GTLTask!");
    
}

- (void)testSyncDate {
    NSDate *aDate = [NSDate date];
    
    // Testing Task with a sync date
    Task *task = [self makeTask];
    task.synced_at = task.updated_at = aDate;
    
    XCTAssertEqualObjects(task.synced_at, aDate, @"synced_at is not equal to setted date");

    // Testing Task with no sync date
    Task *task2 = [self makeTask];
    task2.updated_at = aDate;
    
    XCTAssertEqualObjects(task2.synced_at, [NSDate dateWithTimeIntervalSince1970:0], @"synced_at should equal reference date (1970)");
}

#pragma mark - Utilities

- (Task *)makeTask {
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Task" inManagedObjectContext:self.context];
    return [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:self.context];
}

@end
