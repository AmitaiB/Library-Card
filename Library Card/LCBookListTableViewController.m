//
//  LCBookListTableViewController.m
//  Library Card
//
//  Created by Will Barton on 8/15/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "LCAppDelegate.h"
#import "LCBookListTableViewController.h"
#import "LCBookTableViewController.h"
#import "LCBookCell.h"

@interface LCBookListTableViewController () <NSFetchedResultsControllerDelegate>
@property (strong, nonatomic) NSFetchedResultsController * fetchedResultsController;
@end

@interface LCBookListTableViewController (private)

- (void)updateCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (IBAction)statusControlChanged:(id)sender;

@end


@implementation LCBookListTableViewController

@synthesize fetchedResultsController = _fetchedResultsController;

@synthesize statusControl = _statusControl;
@synthesize statusBarButtonItem = _statusBarButtonItem;

@synthesize cacheName = _cacheName;

@synthesize searching = _searching;

@dynamic predicate;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.cacheName = @"bookCache";
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)setToolbarItems:(NSArray *)toolbarItems animated:(BOOL)animated {
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.statusBarButtonItem setCustomView:self.statusControl]; 
        
    self.statusControl.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"BookListTabSelection"];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setToolbarHidden:NO animated:YES];
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.title = @"Library Card";

}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setToolbarHidden:YES animated:YES];

    self.navigationItem.backBarButtonItem.title = @"Back";
    
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {

    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSPredicate *)predicate {
    NSPredicate * aPredicate;
    
    // "All" is status 3.
    if (self.statusControl.selectedSegmentIndex != 3)
        aPredicate = [NSPredicate predicateWithFormat:@"status == %d", self.statusControl.selectedSegmentIndex];
    
    return aPredicate;
}

- (IBAction)statusControlChanged:(id)sender {
    
    // Store the selected index in the defaults
    [[NSUserDefaults standardUserDefaults] setInteger:self.statusControl.selectedSegmentIndex
                                             forKey:@"BookListTabSelection"];
    
    
    // Update the fetched results by changing the fetch request predicate
    [NSFetchedResultsController deleteCacheWithName:self.cacheName];

    self.fetchedResultsController.fetchRequest.predicate = self.predicate;
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {   
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        Alert(nil, @"There was an error fetching items", @"OK", nil);
    }
    
    [self.tableView reloadData];
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"addBook"]) {
        /*
        NSManagedObjectContext * managedObjectContext = ((LCAppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;

        LCBookTableViewController * detailViewController = [segue destinationViewController];
        detailViewController.book = [NSEntityDescription insertNewObjectForEntityForName:@"Book" 
                                                       inManagedObjectContext:managedObjectContext];
         */

    }
    if ([segue.identifier isEqualToString:@"showBook"]) {
        LCBookTableViewController * detailViewController = [segue destinationViewController];
        detailViewController.book = [self.fetchedResultsController objectAtIndexPath:[self.tableView indexPathForSelectedRow]];
    }
}

#pragma mark - Fetched Results Controller 

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }

    NSManagedObjectContext * managedObjectContext = ((LCAppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;
    NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
    
    // Set the entity
    fetchRequest.entity = [NSEntityDescription entityForName:@"Book" inManagedObjectContext:managedObjectContext];
    
    // Set the sort key
    NSSortDescriptor * sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
    fetchRequest.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    // Set the predicate
    fetchRequest.predicate = self.predicate;
    
    NSFetchedResultsController * aFetchedResultsController = 
        [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
                                            managedObjectContext:managedObjectContext 
                                              sectionNameKeyPath:nil 
                                                       cacheName:self.cacheName];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    NSError * error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error: %@, %@", error, error.userInfo);
        Alert(nil, @"There was an error fetching items", @"OK", nil);
        return nil;
    }

    return _fetchedResultsController;
}

- (void)controller:(NSFetchedResultsController *)controller 
   didChangeObject:(id)anObject 
       atIndexPath:(NSIndexPath *)indexPath 
     forChangeType:(NSFetchedResultsChangeType)type 
      newIndexPath:(NSIndexPath *)newIndexPath {
        
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] 
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self updateCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            // [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
            //                      withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:newIndexPath.section] 
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller 
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo 
           atIndex:(NSUInteger)sectionIndex 
     forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    if (self.searching)
        [self.searchDisplayController.searchResultsTableView beginUpdates];

}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    
    if (self.searching)
        [self.searchDisplayController.searchResultsTableView endUpdates];
    
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
}


#pragma mark - Table view data source

- (void)updateCell:(LCBookCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"Updating Cell");
    Book * book = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.titleLabel.text = book.title;
    cell.authorLabel.text = book.authors;
    
    NSString * coverPath = pathToCoverForISBN(book.isbn13);
    if ([[NSFileManager defaultManager] fileExistsAtPath:coverPath])
        cell.imageView.image = [UIImage imageWithContentsOfFile:coverPath];
    else
        cell.imageView.image = [UIImage imageNamed:@"cover.png"];
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.fetchedResultsController.sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * CellIdentifier = @"BookListCell";
    
    UITableViewCell * cell;
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        }
        
        Book * book = [self.fetchedResultsController objectAtIndexPath:indexPath];
        cell.textLabel.text = book.title;
        cell.detailTextLabel.text = book.authors;
    }
    else {
        cell = (LCBookCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = (LCBookCell *)[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        [self updateCell:cell atIndexPath:indexPath];
    }

    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the managed object for the given index path
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        // Save the context.
        NSError *error;
        if (![context save:&error]) {
            // Update to handle the error appropriately.
            Alert(nil, @"Error deleting item.", @"OK", nil);
            return;
        }

        // [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

#pragma mark - Table view delegate

/*
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
}
*/

#pragma mark - Search Display Controller

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {

    NSPredicate * filterPredicate;
    NSLog(@"Scope: %@, searchText: %@", scope, searchText);
    if ([scope isEqualToString:@"Author"]) {
        filterPredicate = [NSPredicate predicateWithFormat:@"authors contains[cd] %@", searchText];
        NSLog(@"authors contains[cd] %@", searchText);
    } else
        filterPredicate = [NSPredicate predicateWithFormat:@"title beginswith[cd] %@", searchText];
    
    // Update the fetched results by changing the fetch request predicate
    [NSFetchedResultsController deleteCacheWithName:self.cacheName];
    
    self.fetchedResultsController.fetchRequest.predicate = filterPredicate;
    
    NSError * error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {   
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        Alert(nil, @"There was an error fetching items", @"OK", nil);
    }
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] 
                               scope:[controller.searchBar.scopeButtonTitles 
                                      objectAtIndex:controller.searchBar.selectedScopeButtonIndex]];
    
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    return YES;
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    self.searching = YES;
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller  {
    
    [NSFetchedResultsController deleteCacheWithName:self.cacheName];
    
    self.fetchedResultsController.fetchRequest.predicate = self.predicate;
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {   
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        Alert(nil, @"There was an error fetching items", @"OK", nil);
    }
    
    // [self.tableView reloadData];
    
    self.searching = NO;
}


@end
