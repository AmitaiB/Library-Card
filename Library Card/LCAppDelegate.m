//
//  LCAppDelegate.m
//  Library Card
//
//  Created by Will Barton on 8/13/11.
//  Copyright (c) 2011 Will Barton. All rights reserved.
//

#import "LCAppDelegate.h"
#import "ZBarSDK.h"
#import "Book.h"

#import "LCBookListTableViewController.h"
#import "LCBookTableViewController.h"

NSString * const GoogleAPIKey = @"AIzaSyDUhHq98cL-S1rNOGdSjiPXMbdoWMXhjXk";
NSString * const BookSourceGoogle = @"BookSourceGoogle";

NSString * pathToCoverForISBN(NSString * isbn) {
    NSString * strippedISBN = [[isbn componentsSeparatedByCharactersInSet:
                                [[NSCharacterSet decimalDigitCharacterSet] invertedSet]] 
                               componentsJoinedByString:@""];
    NSString * documentsPath = [((LCAppDelegate *)[UIApplication sharedApplication].delegate)applicationDocumentsDirectory].path;
    NSString * filename = [NSString stringWithFormat:@"%@.jpg", strippedISBN];
    NSString * pathString = [NSString pathWithComponents:
                             [NSArray arrayWithObjects:documentsPath, @"covers", filename, nil]];
    return pathString;
}


@implementation LCAppDelegate

@synthesize window = _window;

@synthesize managedObjectContext=managedObjectContext__;

@synthesize managedObjectModel=managedObjectModel__;

@synthesize persistentStoreCoordinator=persistentStoreCoordinator__;

@synthesize useiCloud = _useiCloud;


+ (void)initialize {
    [super initialize];
    
    // Set up app defaults
    NSMutableDictionary * defaults = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"]];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults]; 
    
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    [ZBarReaderView class];
    
    // Make the covers folder exist
    NSString * documentsPath = [((LCAppDelegate *)[UIApplication sharedApplication].delegate)applicationDocumentsDirectory].path;
    NSString * coversPath = [NSString pathWithComponents:
                             [NSArray arrayWithObjects:documentsPath, @"covers", nil]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:coversPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:coversPath 
                                  withIntermediateDirectories:YES 
                                                   attributes:nil 
                                                        error:nil];
    }
    
    UINavigationController * navigationController = (UINavigationController *)self.window.rootViewController;
    LCBookListTableViewController * controller = (LCBookListTableViewController *)navigationController.topViewController;
    controller.managedObjectContext = self.managedObjectContext;
    
    [self.window addSubview:navigationController.view];
    [self.window makeKeyAndVisible];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self saveContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    
    [self saveContext];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self saveContext];
}

- (void)saveContext {
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
    if (managedObjectContext__ != nil) {
        return managedObjectContext__;
    }
    
    NSPersistentStoreCoordinator * coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        NSManagedObjectContext * moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        
        [moc performBlockAndWait:^{
            [moc setPersistentStoreCoordinator:coordinator];
            [[NSNotificationCenter defaultCenter]addObserver:self 
                                                    selector:@selector(mergeChangesFrom_iCloud:) 
                                                        name:NSPersistentStoreDidImportUbiquitousContentChangesNotification 
                                                      object:coordinator];

        }];        
        managedObjectContext__ = moc;
    }
    
    return managedObjectContext__;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel__ != nil) {
        return managedObjectModel__;
    }
    
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"LibraryCard" withExtension:@"momd"];
    managedObjectModel__ = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    
    // NSLog(@"Managed Object Model: %@", __managedObjectModel);
    
    return managedObjectModel__;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (persistentStoreCoordinator__ != nil) {
        return persistentStoreCoordinator__;
    }
    
    // assign the PSC to our app delegate ivar before adding the persistent store in the background
    // this leverages a behavior in Core Data where you can create NSManagedObjectContext and fetch requests
    // even if the PSC has no stores.  Fetch requests return empty arrays until the persistent store is added
    // so it's possible to bring up the UI and then fill in the results later
    persistentStoreCoordinator__ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    
    // prep the store path and bundle stuff here since NSBundle isn't totally thread safe
    NSPersistentStoreCoordinator * psc = persistentStoreCoordinator__;
	NSString * storePath = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"LibraryCard.sqlite"].path;
    
    // do this asynchronously since if this is the first time this particular device is syncing with preexisting
    // iCloud content it may take a long long time to download
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        NSURL * storeUrl = [NSURL fileURLWithPath:storePath];
        // this needs to match the entitlements and provisioning profile
        NSURL * cloudURL = [fileManager URLForUbiquityContainerIdentifier:nil];
        
        NSMutableDictionary * options = [NSMutableDictionary dictionary];
        [options setObject:[NSNumber numberWithBool:YES] forKey:NSMigratePersistentStoresAutomaticallyOption];
        [options setObject:[NSNumber numberWithBool:YES] forKey:NSInferMappingModelAutomaticallyOption];
        
        if (cloudURL != nil) {
            NSLog(@"Cloud URL: %@", cloudURL);
            
            NSString* coreDataCloudContent = [[cloudURL path] stringByAppendingPathComponent:@"librarycard_v1"];
            cloudURL = [NSURL fileURLWithPath:coreDataCloudContent];
            
            NSLog(@"Cloud URL: %@", cloudURL);
            
            //  The API to turn on Core Data iCloud support here.
            [options setObject:@"com.water-powered.data.librarycard.1" forKey:NSPersistentStoreUbiquitousContentNameKey];
            [options setObject:cloudURL forKey:NSPersistentStoreUbiquitousContentURLKey];
        }
        
        NSError *error = nil;
        
        [psc lock];
        
        if (![psc addPersistentStoreWithType:NSSQLiteStoreType 
                               configuration:nil 
                                         URL:storeUrl 
                                     options:options 
                                       error:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }    
        
        [psc unlock];
        
        // tell the UI on the main thread we finally added the store and then
        // post a custom notification to make your views do whatever they need to such as tell their
        // NSFetchedResultsController to -performFetch again now there is a real store
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"asynchronously added persistent store!");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RefetchAllDatabaseData" object:self userInfo:nil];
        });
    });
    
    return persistentStoreCoordinator__;
}


// this takes the NSPersistentStoreDidImportUbiquitousContentChangesNotification
// and transforms the userInfo dictionary into something that
// -[NSManagedObjectContext mergeChangesFromContextDidSaveNotification:] can consume
// then it posts a custom notification to let detail views know they might want to refresh.
// The main list view doesn't need that custom notification because the NSFetchedResultsController is
// already listening directly to the NSManagedObjectContext
- (void)mergeiCloudChanges:(NSDictionary*)noteInfo forContext:(NSManagedObjectContext*)moc {    
    NSMutableDictionary *localUserInfo = [NSMutableDictionary dictionary];
    
    NSSet* allInvalidations = [noteInfo objectForKey:NSInvalidatedAllObjectsKey];
    NSNotification* refreshNotification = nil;
    
    if (nil == allInvalidations) {
        // (1) we always materialize deletions to ensure delete propagation happens correctly, especially with 
        // more complex scenarios like merge conflicts and undo.  Without this, future echoes may 
        // erroreously resurrect objects and cause dangling foreign keys
        // (2) we always materialize insertions to make new entries visible to the UI
        NSString* materializeKeys[] = { NSDeletedObjectsKey, NSInsertedObjectsKey };
        int c = (sizeof(materializeKeys) / sizeof(NSString*));
        for (int i = 0; i < c; i++) {
            NSSet* set = [noteInfo objectForKey:materializeKeys[i]];
            if ([set count] > 0) {
                NSMutableSet* objectSet = [NSMutableSet set];
                for (NSManagedObjectID* moid in set) {
                    [objectSet addObject:[moc objectWithID:moid]];
                }
                [localUserInfo setObject:objectSet forKey:materializeKeys[i]];
            }
        }
        
        // (3) we do not materialize updates to objects we are not currently using
        // (4) we do not materialize refreshes to objects we are not currently using
        // (5) we do not materialize invalidations to objects we are not currently using
        NSString* noMaterializeKeys[] = { NSUpdatedObjectsKey, NSRefreshedObjectsKey, NSInvalidatedObjectsKey };
        c = (sizeof(noMaterializeKeys) / sizeof(NSString*));
        for (int i = 0; i < 2; i++) {
            NSSet* set = [noteInfo objectForKey:noMaterializeKeys[i]];
            if ([set count] > 0) {
                NSMutableSet* objectSet = [NSMutableSet set];
                for (NSManagedObjectID* moid in set) {
                    NSManagedObject* realObj = [moc objectRegisteredForID:moid];
                    if (realObj) {
                        [objectSet addObject:realObj];
                    }
                }
                [localUserInfo setObject:objectSet forKey:noMaterializeKeys[i]];
            }
        }
        
        NSNotification *fakeSave = [NSNotification notificationWithName:NSManagedObjectContextDidSaveNotification object:self  userInfo:localUserInfo];
        [moc mergeChangesFromContextDidSaveNotification:fakeSave]; 
        
    } else {
        [localUserInfo setObject:allInvalidations forKey:NSInvalidatedAllObjectsKey];
    }
    
    [moc processPendingChanges];
    
    refreshNotification = [NSNotification notificationWithName:@"RefreshAllViews" object:self  userInfo:localUserInfo];
    
    [[NSNotificationCenter defaultCenter] postNotification:refreshNotification];
}

// NSNotifications are posted synchronously on the caller's thread
// make sure to vector this back to the thread we want, in this case
// the main thread for our views & controller
- (void)mergeChangesFrom_iCloud:(NSNotification *)notification {
    NSDictionary * ui = [notification userInfo];
	NSManagedObjectContext * moc = [self managedObjectContext];
    
    NSLog(@"MERGING CHANGES FROM ICLOUD");
    NSLog(@"User Info: %@", ui);
    
    // this only works if you used NSMainQueueConcurrencyType
    // otherwise use a dispatch_async back to the main thread yourself
    [moc performBlock:^{
        [self mergeiCloudChanges:ui forContext:moc];
    }];
}


#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


- (void)didImportUbiquitousContentChanges:(NSNotification *)sender {
    NSLog(@"Did Import Ubiquitous Content Changes: %@", sender.userInfo);
}

@end
