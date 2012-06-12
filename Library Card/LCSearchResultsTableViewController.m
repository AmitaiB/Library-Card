//
//  LCSearchResultsTableViewController.m
//  Library Card
//
//  Created by Will Barton on 9/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "LCSearchResultsTableViewController.h"
#import "LCBookCell.h"

@implementation LCSearchResultsTableViewController

@synthesize bookLookup = _bookLookup;
@synthesize delegate = _delegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
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

    self.clearsSelectionOnViewWillAppear = NO;
 
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return YES;
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)bookLookupGotResults:(LCBookLookup *)bookLookup {
    [self.tableView reloadData];
}

- (void)bookLookup:(LCBookLookup *)bookLookup downloadedCoverAtIndex:(NSInteger)index {
    if (index >= [self.bookLookup.results count])
        return;
    
    NSIndexPath * indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:UITableViewRowAnimationNone];

}

- (IBAction)cancel:(id)sender {
    [self.delegate searchResultsControllerCanceled];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    DEBUG(@"Number of Books: %d", [self.bookLookup.results count]);
    DEBUG(@"Number of Results: %d", self.bookLookup.numberOfResults);
    
    // Add one to the number of available results if the total number of items in Google Books
    // exceeds the available number we've downloaded so far.
    if ([self.bookLookup.results count] < self.bookLookup.numberOfResults)
        return [self.bookLookup.results count] + 1;
    
    return [self.bookLookup.results count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * BookCellIdentifier = @"BookSearchListCell";
    static NSString * ActivityCellIndicator = @"LoadingResultsCell";
    
    if ([self.bookLookup.results count] == indexPath.row) {
        // we do not have this row in our results. Fetch it and display an activity row.
        UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:ActivityCellIndicator];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ActivityCellIndicator];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;

    }
    
    NSDictionary * bookInfo = [self.bookLookup.results objectAtIndex:indexPath.row];

    LCBookCell * cell = (LCBookCell *)[tableView dequeueReusableCellWithIdentifier:BookCellIdentifier];
    if (cell == nil) {
        cell = (LCBookCell *)[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:BookCellIdentifier];
    }
    
    cell.titleLabel.text = [bookInfo objectForKey:@"title"];
    cell.authorLabel.text = [bookInfo objectForKey:@"authors"];
    
    if ([bookInfo objectForKey:@"publishedDate"] != nil) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"YYYY";
        
        NSString * formattedDateString = [dateFormatter stringFromDate:[bookInfo objectForKey:@"publishedDate"]];
        cell.publishedLabel.text = formattedDateString;
    }
    
    NSString * coverPath = pathToCoverForISBN([bookInfo objectForKey:@"isbn13"]);
    if ([[NSFileManager defaultManager] fileExistsAtPath:coverPath])
        cell.coverImageView.image = [UIImage imageWithContentsOfFile:coverPath];
    else {
        cell.coverImageView.image = [UIImage imageNamed:@"cover.png"];
        [self.bookLookup downloadCoverImageForIndex:indexPath.row];
    }
    
    return cell;

}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary * bookInfo = [self.bookLookup.results objectAtIndex:indexPath.row];
    [self.delegate searchResultsControllerSelectedBook:bookInfo];
}

#pragma mark - Scroll View Delegate

// http://stackoverflow.com/questions/5137943/how-to-know-when-uitableview-did-scroll-to-bottom
- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
    CGPoint offset = aScrollView.contentOffset;
    CGRect bounds = aScrollView.bounds;
    CGSize size = aScrollView.contentSize;
    UIEdgeInsets inset = aScrollView.contentInset;
    float y = offset.y + bounds.size.height - inset.bottom;
    float h = size.height;
    // NSLog(@"offset: %f", offset.y);   
    // NSLog(@"content.height: %f", size.height);   
    // NSLog(@"bounds.height: %f", bounds.size.height);   
    // NSLog(@"inset.top: %f", inset.top);   
    // NSLog(@"inset.bottom: %f", inset.bottom);   
    // NSLog(@"pos: %f of %f", y, h);
    
    float reload_distance = 10;
    if(y > h + reload_distance) {
        // NSLog(@"load more rows");
        [self.bookLookup loadMoreResults];
    }
    
}


@end
