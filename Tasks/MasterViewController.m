//
//  MasterViewController.m
//  Tasks
//
//  Created by Pof on 31/07/2014.
//  Copyright (c) 2014 Pof Magicfingers. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "TaskListViewController.h"
#import "NSString+UUID.h"

#import "AppDelegate.h"
#import "GTSyncManager.h"

@interface MasterViewController ()

@property (strong, nonatomic) TaskList *_renaming_object;

@end

@implementation MasterViewController
            
- (void)awakeFromNib {
    [super awakeFromNib];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    [self updateToolbar];
}

- (void)updateToolbar {
    if ([[self appDelegate] googleIsSignedIn]) {
        [GTSyncManager startSyncing];
        self.toolbarItems = [NSArray arrayWithObjects:
                             [[UIBarButtonItem alloc]
                              initWithTitle:@"Sync"
                              style:UIBarButtonItemStyleBordered
                              target:self
                              action:@selector(syncWithGoogle:)],
                             [[UIBarButtonItem alloc]
                              initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                              target:nil action:NULL],
                             [[UIBarButtonItem alloc]
                              initWithTitle:@"Log out from Google"
                              style:UIBarButtonItemStylePlain
                              target:self
                              action:@selector(disconnectGoogle:)],
                             nil];
    } else {
        self.toolbarItems = [NSArray arrayWithObjects:
                             [[UIBarButtonItem alloc]
                              initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                              target:nil action:NULL],
                             [[UIBarButtonItem alloc]
                              initWithTitle:@"Login with Google"
                              style:UIBarButtonItemStylePlain
                              target:self
                              action:@selector(connectGoogle:)],
                             nil];
    }
    self.navigationController.toolbarHidden = NO;
}

- (void)connectGoogle:(id)sender {
    [[self appDelegate] googleSignIn:^(GTMOAuth2ViewControllerTouch *viewController, GTMOAuth2Authentication *auth, NSError *error) {
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Error!"
                                       message:[error.userInfo objectForKey:@"NSLocalizedDescription"]
                                      delegate:nil
                             cancelButtonTitle:@"Okay"
                              otherButtonTitles:nil] show];
        } else {
            [self updateToolbar];
            [[GTSyncManager sharedInstance].tasksService setAuthorizer:auth];
            [self syncWithGoogle:self];
        }
    }];
}

- (void)disconnectGoogle:(id)sender {
    [[self appDelegate] googleSignOut];
    [self updateToolbar];
}

- (void)syncWithGoogle:(id)sender {
    if([[self appDelegate] googleIsSignedIn]) {
        [GTSyncManager syncNow];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender {
    UIAlertView *newTaskList = [[UIAlertView alloc]
                                    initWithTitle:@"New Task List"
                                    message:@""
                                    delegate:self
                                    cancelButtonTitle:@"Cancel"
                                    otherButtonTitles:@"Create", nil];
    newTaskList.alertViewStyle = UIAlertViewStylePlainTextInput;
    [[newTaskList textFieldAtIndex:0] setPlaceholder:@"My list"];
    [[newTaskList textFieldAtIndex:0] setReturnKeyType:UIReturnKeyDone];
    newTaskList.tag = 202;
    [newTaskList show];
}

- (void)renameTaskList:(NSManagedObject *)taskList {
    self._renaming_object = (TaskList *)taskList;
    UIAlertView *renameTaskList = [[UIAlertView alloc]
                                initWithTitle:@"Rename Task List"
                                message:@""
                                delegate:self
                                cancelButtonTitle:@"Cancel"
                                otherButtonTitles:@"Rename", nil];
    renameTaskList.alertViewStyle = UIAlertViewStylePlainTextInput;
    [[renameTaskList textFieldAtIndex:0] setPlaceholder:self._renaming_object.title];
    [[renameTaskList textFieldAtIndex:0] setText:self._renaming_object.title];
    [[renameTaskList textFieldAtIndex:0] setReturnKeyType:UIReturnKeyDone];
    renameTaskList.tag = 102;
    [renameTaskList show];
}

- (void)createTaskList:(NSString *)title {
    if(title == nil || [[title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
        UIAlertView *noTitle = [[UIAlertView alloc]
                                initWithTitle:@"New Task List"
                                message:@"It's impossible to create a task list without a title!"
                                delegate:self
                                cancelButtonTitle:@"I won't do it again..."
                                otherButtonTitles:nil];
        
        noTitle.tag = 400;
        [noTitle show];
    } else {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
        TaskList *newList = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
        
        // If appropriate, configure the new managed object.
        // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
        newList.identifier = [@"local_"
                                    stringByAppendingString:[NSString UUID]];
        newList.title = title;
        newList.updated_at = [NSDate date];
        newList.trashed = [NSNumber numberWithBool:NO];
        
        // Save the context.
        NSError *error = nil;
        if (![context save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        [(DetailViewController *)[segue destinationViewController] setTask:object];
    } else if ([[segue identifier] isEqualToString:@"show"]) {
        [(TaskListViewController *)[segue destinationViewController] setList:object];
        [(TaskListViewController *)[segue destinationViewController] setManagedObjectContext:self.managedObjectContext];
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
        TaskList *list = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        list.trashed = [NSNumber numberWithBool:YES];
        
        NSError *error = nil;
        if (![context save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
//
//    TaskListViewController *taskList = [[TaskListViewController alloc] init];
//    
//    taskList.list = [object valueForKey:@"identifier"];
//    taskList.managedObjectContext = self.managedObjectContext;
//    
//    [self.navigationController pushViewController:taskList animated:YES];
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
//        self.detailViewController.detailItem = object;
//    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    [self renameTaskList:object];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    TaskList *list = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = list.title;

    NSString *last_modified = [NSDateFormatter localizedStringFromDate:list.updated_at dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
    cell.detailTextLabel.text = last_modified;
    
    if([[self appDelegate] googleIsSignedIn]) {
        if([list isNew])
            cell.detailTextLabel.text = [@"(Never synced) - " stringByAppendingString: last_modified];
        else if(list.updated_at > list.synced_at)
            cell.detailTextLabel.text = [@"(Need sync) - " stringByAppendingString:last_modified];
    }
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"TaskList" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"updated_at" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    [fetchRequest
     setPredicate:[NSPredicate predicateWithFormat:@"trashed == NO"]];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"TaskLists"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	     // Replace this implementation with code to handle the error appropriately.
	     // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
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
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
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

/*
// Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}
 */

#pragma mark - Alert View

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(alertView.tag == 202) {
        if(buttonIndex != alertView.cancelButtonIndex)
            [self createTaskList:[[alertView textFieldAtIndex:0] text]];
    } else if(alertView.tag == 400) {
        [self insertNewObject:self];
    } else if(alertView.tag == 102) {
        if(buttonIndex != alertView.cancelButtonIndex) {
            NSString *new_title = [[alertView textFieldAtIndex:0] text];
            if ([new_title respondsToSelector:@selector(isEqualToString:)] &&
                ![[new_title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
                NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
                
                // If appropriate, configure the new managed object.
                // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
                self._renaming_object.title = new_title;
                self._renaming_object.updated_at = [NSDate date];
                
                // Save the context.
                NSError *error = nil;
                if (![context save:&error]) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                    abort();
                }
            }
        }
        self._renaming_object = nil;
    }
}

#pragma mark - Utils

- (AppDelegate *)appDelegate {
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
}

@end
