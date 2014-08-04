//
//  MasterViewController.m
//  Tasks
//
//  Created by Pof on 31/07/2014.
//  Copyright (c) 2014 Pof Magicfingers. All rights reserved.
//

#import "TaskListViewController.h"
#import "NSString+UUID.h"

#import "DetailViewController.h"

@interface TaskListViewController ()


@end

@implementation TaskListViewController

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
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.toolbarItems = [NSArray
                         arrayWithObject:[[UIBarButtonItem alloc]
                                          initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                          target:self
                                          action:@selector(insertNewObject:)]];
    
    self.navigationController.toolbarHidden = NO;
    
    if(self.list) {
        self.title = [self.list valueForKey:@"title"];
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
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:tappedIndexPath];

    if([object valueForKey:@"completed_at"] == nil) {
        [object setValue:[NSDate date] forKey:@"completed_at"];
    } else {
        [object setValue:nil forKey:@"completed_at"];
    }
    
    
    [object setValue:[NSDate date] forKey:@"updated_at"];
    [self.list setValue:[NSDate date] forKey:@"updated_at"];
    
    // Save the context.
    NSError *error = nil;
    if ([context save:&error]) {
        [self.tableView
         reloadRowsAtIndexPaths:[NSArray
                                 arrayWithObject:tappedIndexPath]
         withRowAnimation: UITableViewRowAnimationNone];
    } else {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
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
        NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
        
        // If appropriate, configure the new managed object.
        // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
        [newManagedObject setValue:[@"local_"
                                    stringByAppendingString:[NSString UUID]]
                            forKey:@"id"];
        [newManagedObject setValue:name forKey:@"title"];
        [newManagedObject setValue:self.list forKey:@"list"];
        [newManagedObject setValue:[NSDate date] forKey:@"updated_at"];
        [newManagedObject setValue:[NSNumber numberWithBool:NO] forKey:@"trashed"];
        [self.list setValue:[NSDate date] forKey:@"updated_at"];
        
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
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        DetailViewController *details = (DetailViewController *)[[segue destinationViewController] topViewController];
        [details setTask:object];
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
        NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];

        [[object valueForKey:@"list"]
         setValue:[NSDate date]
         forKey:@"updated_at"];
        [object
         setValue:[NSNumber numberWithBool:YES]
         forKey:@"trashed"];
        
//        [NSFetchedResultsController deleteCacheWithName:[@"Tasks_" stringByAppendingString:[self.list valueForKey:@"id"]]];
        
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
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
//        self.detailViewController.detailItem = object;
    }
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if ([object valueForKey:@"completed_at"] == nil) {
        cell.imageView.image = [UIImage imageNamed:@"unchecked"];
    } else {
        cell.imageView.image = [UIImage imageNamed:@"checked"];
    }

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(setTaskCompleted:)];
    [cell.imageView addGestureRecognizer:tap];
    cell.imageView.userInteractionEnabled = YES; //added based on @John 's comment
    
    cell.textLabel.text = [object valueForKey:@"title"];
    cell.detailTextLabel.text = [[object valueForKey:@"updated_at"] description];
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    if (self.list && [self.list valueForKey:@"id"]) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        // Edit the entity name as appropriate.
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Task" inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        
        // Set the batch size to a suitable number.
        [fetchRequest setFetchBatchSize:20];
        
        // Edit the sort key as appropriate.
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"updated_at" ascending:NO];
        NSArray *sortDescriptors = @[sortDescriptor];
        
        [fetchRequest setSortDescriptors:sortDescriptors];
        [fetchRequest setPredicate:[NSPredicate
                                    predicateWithFormat:@"list.id == %@ AND trashed == FALSE", [self.list valueForKey:@"id"]]];
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:[@"Tasks_" stringByAppendingString:[self.list valueForKey:@"id"]]];
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
            if ([[anObject valueForKey:@"trashed"] boolValue]) {
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
            [self createTask:[[alertView textFieldAtIndex:0] text]];
    } else if(alertView.tag == 400) {
        [self insertNewObject:self];
    }
}

@end