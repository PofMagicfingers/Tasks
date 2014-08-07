//
//  MasterViewController.m
//  Tasks
//
//  Created by Pof on 31/07/2014.
//  Copyright (c) 2014 Pof Magicfingers. All rights reserved.
//

#import "TaskListViewController.h"
#import "NSString+UUID.h"

#import "AppDelegate.h"
#import "Task.h"
#import "TaskList.h"

#import "DetailViewController.h"

@interface TaskListViewController ()


@end

@implementation TaskListViewController

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.toolbarItems = [NSArray
                         arrayWithObject:[[UIBarButtonItem alloc]
                                          initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                          target:self
                                          action:@selector(insertNewObject:)]];
    
    self.navigationController.toolbarHidden = NO;
    
    if(self.list) {
        self.title = self.list.title;
    } else {
        [self.navigationController popViewControllerAnimated:YES];
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                   message:@"Something went wrong!"
                                  delegate:nil
                         cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setTaskCompleted:(UITapGestureRecognizer *)tapRecognizer {
    CGPoint tapLocation = [tapRecognizer locationInView:self.tableView];
    NSIndexPath *tappedIndexPath = [self.tableView indexPathForRowAtPoint:tapLocation];
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    Task *task = [self.fetchedResultsController objectAtIndexPath:tappedIndexPath];

    task.completed_at = (task.completed_at == nil) ? [NSDate date] : nil;
    
    task.updated_at = ((TaskList *)self.list).updated_at = [NSDate date];

    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        [[[UIAlertView alloc]
          initWithTitle:@"Error!"
          message:@"An unexpected error happened. Sorry for inconvenience."
          delegate:nil
          cancelButtonTitle:@"Okay :("
          otherButtonTitles:nil] show];
    }
}

- (void)insertNewObject:(id)sender {
    UIAlertView *newTask = [[UIAlertView alloc]
                                initWithTitle:@"New Task"
                                message:@""
                                delegate:self
                                cancelButtonTitle:@"Cancel"
                                otherButtonTitles:@"Create", nil];
    newTask.alertViewStyle = UIAlertViewStylePlainTextInput;
    [[newTask textFieldAtIndex:0] setPlaceholder:@"A task"];
    newTask.tag = 202;
    [newTask show];
}

- (void)createTask:(NSString *)name {
    if(name == nil || [[name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
        UIAlertView *noName = [[UIAlertView alloc]
                                initWithTitle:@"New Task"
                                message:@"It's impossible to create a task without a name!"
                                delegate:self
                                cancelButtonTitle:@"I won't do it again..."
                                otherButtonTitles:nil];
        
        noName.tag = 400;
        [noName show];
    } else {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
        Task *newTask = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
        
        newTask.identifier = [@"local_" stringByAppendingString:[NSString UUID]];
        newTask.title = name;
        newTask.list = self.list;
        newTask.trashed = [NSNumber numberWithBool:NO];
        newTask.updated_at = self.list.updated_at = [NSDate date];
        
        // Save the context.
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            [[[UIAlertView alloc]
              initWithTitle:@"Error!"
              message:@"An unexpected error happened. Sorry for inconvenience."
              delegate:nil
              cancelButtonTitle:@"Okay :("
              otherButtonTitles:nil] show];
        }
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        Task *task = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        DetailViewController *details = (DetailViewController *)[[segue destinationViewController] topViewController];
        [details setTask:task];
        [details setFetchedResultsController:self.fetchedResultsController];
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> theSection = [[self.fetchedResultsController sections] objectAtIndex:section];
    
    return [theSection name];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        Task *task = [self.fetchedResultsController objectAtIndexPath:indexPath];

        task.trashed = [NSNumber numberWithBool:YES];
        task.list.updated_at = [NSDate date];
        
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            [[[UIAlertView alloc]
              initWithTitle:@"Error!"
              message:@"An unexpected error happened. Sorry for inconvenience."
              delegate:nil
              cancelButtonTitle:@"Okay :("
              otherButtonTitles:nil] show];
        }
    }
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Task *task = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if (task.completed_at == nil) {
        cell.imageView.image = [UIImage imageNamed:@"unchecked"];
    } else {
        cell.imageView.image = [UIImage imageNamed:@"checked"];
    }

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(setTaskCompleted:)];
    [cell.imageView addGestureRecognizer:tap];
    cell.imageView.userInteractionEnabled = YES; //added based on @John 's comment
    
    cell.textLabel.text = task.title;
    NSString *last_modified = [NSDateFormatter localizedStringFromDate:task.updated_at dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
    
    cell.detailTextLabel.text = last_modified;
    if([((AppDelegate *)[UIApplication sharedApplication].delegate) googleIsSignedIn]) {
        if([task isNew])
            cell.detailTextLabel.text = [@"(Never synced) - " stringByAppendingString: last_modified];
        else if([task.updated_at timeIntervalSince1970] > [task.synced_at timeIntervalSince1970])
            cell.detailTextLabel.text = [@"(Need sync) - " stringByAppendingString:last_modified];
    }
    NSLog(@"Task %@ has detail : %@", task.title, cell.detailTextLabel.text);
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    if (self.list && self.list.identifier) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        // Edit the entity name as appropriate.
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Task" inManagedObjectContext:[LocalTaskManager sharedManagedObjectContext]];
        [fetchRequest setEntity:entity];
        
        // Set the batch size to a suitable number.
        [fetchRequest setFetchBatchSize:20];
        
        // Edit the sort key as appropriate.
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"updated_at" ascending:NO];
        NSSortDescriptor *sectionSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"completed_at" ascending:YES]; // Since completed_at is nil when task is not checked, sorting by completed_at makes unchecked records go first, and first section is determined by the first record.
        
        NSArray *sortDescriptors = @[sectionSortDescriptor, sortDescriptor];
        
        [fetchRequest setSortDescriptors:sortDescriptors];
        [fetchRequest setPredicate:[NSPredicate
                                    predicateWithFormat:@"list.identifier == %@ AND trashed == FALSE", self.list.identifier]];
        
        NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[LocalTaskManager sharedManagedObjectContext] sectionNameKeyPath:@"sectionName" cacheName:[@"Tasks_" stringByAppendingString:self.list.identifier]];
        aFetchedResultsController.delegate = self;
        self.fetchedResultsController = aFetchedResultsController;
        
        NSError *error = nil;
        if (![self.fetchedResultsController performFetch:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            [[[UIAlertView alloc]
              initWithTitle:@"Error!"
              message:@"An unexpected error happened. Sorry for inconvenience."
              delegate:nil
              cancelButtonTitle:@"Okay :("
              otherButtonTitles:nil] show];
        }
        return _fetchedResultsController;
    }

    return nil;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            if (((Task *)anObject).trashed.boolValue) {
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            } else {
                [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            }
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

#pragma mark - Alert View

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(alertView.tag == 202) {
        if(buttonIndex != alertView.cancelButtonIndex)
            [self createTask:[[alertView textFieldAtIndex:0] text]];
    } else if(alertView.tag == 400) {
        [self insertNewObject:self];
    }
}

@end