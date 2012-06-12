//
//  LCBookGridViewController.m
//  Library Card
//
//  Created by Will Barton on 10/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "LCBookGridViewController.h"
#import "LCBookGridViewCell.h"


@interface LCBookGridViewController () <NSFetchedResultsControllerDelegate>
@property (strong, nonatomic) NSFetchedResultsController * fetchedResultsController;
@end

@interface LCBookGridViewController (private)

- (void)updateCell:(LCBookGridViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (IBAction)statusControlChanged:(id)sender;
- (void)reloadFetchedResults:(NSNotification*)notification;

@end



@implementation LCBookGridViewController

@synthesize gridView = _gridView;

@synthesize detailViewController = _detailViewController;
@synthesize managedObjectContext = _managedObjectContext;

@synthesize fetchedResultsController = _fetchedResultsController;

@synthesize statusControl = _statusControl;
@synthesize statusBarButtonItem = _statusBarButtonItem;

@synthesize cacheName = _cacheName;

@synthesize searching = _searching;

@dynamic predicate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.statusBarButtonItem setCustomView:self.statusControl]; 
    self.statusControl.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"BookListTabSelection"];

    // Set up the grid view
    
    self.gridView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.gridView.autoresizesSubviews = YES;
	self.gridView.delegate = self;
	self.gridView.dataSource = self;
    self.gridView.layoutDirection = AQGridViewLayoutDirectionVertical;
    // self.gridView.separatorColor = [UIColor redColor];
    
    self.gridView.backgroundView = [[UIView alloc] init];
    self.gridView.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"shelf.png"]];
    
    [self reloadFetchedResults:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(reloadFetchedResults:) 
                                                 name:@"RefetchAllDatabaseData" 
                                               object:[[UIApplication sharedApplication] delegate]];
    
    
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return YES;
    
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
    
    [self.gridView reloadData];
    
    // Select the current book
    /*
    NSIndexPath * selectedIndexPath = [self.fetchedResultsController indexPathForObject:self.detailViewController.book];
    [self.gridView selectItemAtIndex:selectedIndexPath.row 
                            animated:YES 
                      scrollPosition:AQGridViewScrollPositionMiddle];
    */
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
        UINavigationController * navigationController = [segue destinationViewController];
        LCBookTableViewController * detailViewController = [navigationController.viewControllers objectAtIndex:0];
        detailViewController.book = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:[self.gridView indexOfSelectedItem] 
                                                                                                        inSection:0]];
    }
}

- (IBAction)addBook:(id)sender {
    // phone devices should just use the segue, since they're not using a split view controller.
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        return;
    
    // De-select the existing book
    Book * selectedBook = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:[self.gridView indexOfSelectedItem] 
                                                                                              inSection:0]];
    if (selectedBook == self.detailViewController.book)
        [self.gridView deselectItemAtIndex:[self.gridView indexOfSelectedItem] animated:YES];
    
    self.detailViewController.book = nil;
    // [self.detailViewController performSegueWithIdentifier:@"scanBarcode" sender:self];
}

#pragma mark - Fetched Results Controller 

// because the app delegate now loads the NSPersistentStore into the NSPersistentStoreCoordinator asynchronously
// we will see the NSManagedObjectContext set up before any persistent stores are registered
// we will need to fetch again after the persistent store is loaded
- (void)reloadFetchedResults:(NSNotification*)notification {
    NSError * error = nil;
    
    DEBUG(@"Reloading Fetched Results");
    
	if (![[self fetchedResultsController] performFetch:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}		
    
    if (notification) {
        [self.gridView reloadData];
    }
}

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSManagedObjectContext * managedObjectContext = self.managedObjectContext;
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
            [self.gridView insertItemsAtIndices:[NSIndexSet indexSetWithIndex:newIndexPath.row] 
                                  withAnimation:AQGridViewItemAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.gridView deleteItemsAtIndices:[NSIndexSet indexSetWithIndex:newIndexPath.row] 
                                   withAnimation:AQGridViewItemAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self updateCell:(LCBookGridViewCell *)[self.gridView cellForItemAtIndex:indexPath.row] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            // [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
            //                      withRowAnimation:UITableViewRowAnimationFade];
            [self.gridView reloadItemsAtIndices:[NSIndexSet indexSetWithIndex:newIndexPath.row] 
                                  withAnimation:AQGridViewItemAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller 
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo 
           atIndex:(NSUInteger)sectionIndex 
     forChangeType:(NSFetchedResultsChangeType)type {

    // Don't support trying to change sections
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    if (self.searching)
        [self.searchDisplayController.searchResultsTableView beginUpdates];
    
    [self.gridView beginUpdates];
    
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    
    if (self.searching)
        [self.searchDisplayController.searchResultsTableView endUpdates];
    
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.gridView endUpdates];
}


#pragma mark - Table view data source

- (void)updateCell:(LCBookGridViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
    Book * book = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.titleLabel.text = book.title;
    cell.authorLabel.text = book.authors;
    
    NSString * coverPath = pathToCoverForISBN(book.isbn13);
    if ([[NSFileManager defaultManager] fileExistsAtPath:coverPath])
        cell.image = [UIImage imageWithContentsOfFile:coverPath];
    else
        cell.image = [UIImage imageNamed:@"cover.png"];
    
}

- (NSUInteger)numberOfItemsInGridView:(AQGridView *)gridView {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:0];
    NSLog(@"Number of objects: %d", [sectionInfo numberOfObjects]);
    return [sectionInfo numberOfObjects];
}

- (AQGridViewCell *)gridView:(AQGridView *)gridView cellForItemAtIndex:(NSUInteger)index {
    static NSString * CellIdentifier = @"BookGridCell";
    
    LCBookGridViewCell * cell;
    NSIndexPath * indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    Book * book = [self.fetchedResultsController objectAtIndexPath:indexPath];
   
    /*
    if (gridView == self.searchDisplayController.searchResultsTableView) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        }
        
        cell.textLabel.text = book.title;
        cell.detailTextLabel.text = book.authors;
    }
    else {
     */
    
    cell = (LCBookGridViewCell *)[gridView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[LCBookGridViewCell alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 150.0)
                                          reuseIdentifier:CellIdentifier];
    }
    [self updateCell:cell atIndexPath:indexPath];
    
    cell.selectionStyle = AQGridViewCellSelectionStyleGlow;
    cell.selectionGlowColor = [UIColor whiteColor];
    cell.selectionGlowShadowRadius = 5.0;
    
    if (book.objectID == self.detailViewController.book.objectID)
        cell.selected = YES;
    
    return cell;
}

- (CGSize)portraitGridCellSizeForGridView:(AQGridView *)aGridView {
    return CGSizeMake(144.0, 216.0);
}

#pragma mark - Table view delegate

- (void)gridView:(AQGridView *)gridView didSelectItemAtIndex:(NSUInteger)index
{
    /*
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.detailViewController.book = [self.fetchedResultsController objectAtIndexPath:[self.tableView indexPathForSelectedRow]];
    }
     */
    [self performSegueWithIdentifier:@"showBook" sender:self];
    [gridView deselectItemAtIndex:index animated:YES];
    
}

/*
#pragma mark - Search Display Controller

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    
    NSPredicate * filterPredicate;
    if ([scope isEqualToString:@"Author"]) {
        filterPredicate = [NSPredicate predicateWithFormat:@"authors contains[cd] %@", searchText];
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
*/

@end
