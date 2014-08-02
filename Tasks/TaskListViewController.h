//
//  MasterViewController.h
//  Tasks
//
//  Created by Pof on 31/07/2014.
//  Copyright (c) 2014 Pof Magicfingers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

//@class TaskDetailsViewController;

@interface TaskListViewController : UITableViewController <NSFetchedResultsControllerDelegate, UIAlertViewDelegate>

//@property (strong, nonatomic) TaskDetailsController *detailViewController;

@property (strong, nonatomic) NSManagedObject *list;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;


@end

