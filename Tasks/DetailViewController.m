//
//  DetailViewController.m
//  Tasks
//
//  Created by Pof on 31/07/2014.
//  Copyright (c) 2014 Pof Magicfingers. All rights reserved.
//

#import "DetailViewController.h"

#import "TaskList.h"
#import "Task.h"

@interface DetailViewController ()

@end

@implementation DetailViewController
            
#pragma mark - Managing the detail item

- (void)setTask:(id)newTask {
    if (_task != newTask) {
        _task = newTask;
            
        // Update the view.
        [self configureView];
    }

}

- (void)configureView {
    // Update the user interface for the detail item.
    if (self.task) {
        self.taskTitle.text = self.taskTitle.placeholder = self.task.title;
        self.taskCompleted.on = (self.task.completed_at != nil);
        self.taskNotes.text = self.task.notes;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                             target:self
                                             action:@selector(saveAndDissmis:)];

    self.navigationItem.rightBarButtonItem.style = UIBarButtonItemStyleDone;
    
    [self configureView];
}

- (void)saveAndDissmis:(id)sender {

    if([[self.taskTitle text] respondsToSelector:@selector(isEqualToString:)] && ![[[self.taskTitle text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] && ![self.task.title isEqualToString:[self.taskTitle text]]) {
        self.task.title = [self.taskTitle text];
    }

    if (![self.task.notes isEqualToString:[self.taskNotes text]]) {
        self.task.notes = [self.taskNotes text];
    }

    if ([self.taskCompleted isOn] && self.task.completed_at == nil) {
        self.task.completed_at = [NSDate date];
    } else if(![self.taskCompleted isOn] && self.task.completed_at != nil) {
        self.task.completed_at = nil;
    }
    
    if ([self.task hasChanges]) {
        self.task.updated_at = self.task.list.updated_at = [NSDate date];
    }
    
    
    NSError *error = nil;
    if ([[self.fetchedResultsController managedObjectContext] save:&error]) {
        [self.parentViewController dismissViewControllerAnimated:YES completion:NULL];
    } else {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

- (void)deleteTaskAndDissmis:(id)sender {
    self.task.trashed = [NSNumber numberWithBool:YES];
    self.task.list.updated_at = [NSDate date];
    [self saveAndDissmis:sender];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table View

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell setSelected:NO];
    
    if(cell.tag == 410) {
        [[[UIAlertView alloc]
          initWithTitle:@"Delete ?"
          message:@"Are you sure you want to delete this task ?"
          delegate:self
          cancelButtonTitle:@"No!!!"
          otherButtonTitles:@"Yup!", nil] show];
    }
}

#pragma mark - Alert View

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex)
        [self deleteTaskAndDissmis:self];
}

@end
