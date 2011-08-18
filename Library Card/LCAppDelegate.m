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

NSString * const GoogleAPIKey = @"AIzaSyDUhHq98cL-S1rNOGdSjiPXMbdoWMXhjXk";
NSString * const BookSourceGoogle = @"BookSourceGoogle";

NSString * pathToCoverForISBN(NSString * isbn) {
    NSString * documentsPath = [[((LCAppDelegate *)[UIApplication sharedApplication].delegate)applicationDocumentsDirectory] path];
    NSString * filename = [NSString stringWithFormat:@"%@.jpg", isbn];
    NSString * pathString = [NSString pathWithComponents:
                             [NSArray arrayWithObjects:documentsPath, @"covers", filename, nil]];
    return pathString;
}


@implementation LCAppDelegate

@synthesize window = _window;

@synthesize managedObjectContext=__managedObjectContext;

@synthesize managedObjectModel=__managedObjectModel;

@synthesize persistentStoreCoordinator=__persistentStoreCoordinator;


+ (void)initialize {
    [super initialize];
    
    // Set up app defaults
    NSMutableDictionary * defaults = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"]];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults]; 
    
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [ZBarReaderView class];
    
    // Make the covers folder exist
    
    NSString * documentsPath = [[((LCAppDelegate *)[UIApplication sharedApplication].delegate)applicationDocumentsDirectory] path];
    NSString * coversPath = [NSString pathWithComponents:
                             [NSArray arrayWithObjects:documentsPath, @"covers", nil]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:coversPath isDirectory:YES]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:coversPath 
                                  withIntermediateDirectories:YES 
                                                   attributes:nil 
                                                        error:nil];
    }

    NSURL * storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"LibraryCard.sqlite"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:storeURL.path]) {
        Book * catch22 = [NSEntityDescription insertNewObjectForEntityForName:@"Book" 
                                                       inManagedObjectContext:self.managedObjectContext];
        catch22.title = @"Catch-22";
        catch22.authors = @"Joseph Heller";
        catch22.publisher = @"Simon & Schuster";
        catch22.placeOfPublication = @"New York";
        catch22.isbn13 = @"978-1451626650";
        catch22.isbn = @"1451626657";
        
        NSDateComponents * components = [[NSDateComponents alloc] init];
        components.day = 5;
        components.month = 4;
        components.year = 2011;
        catch22.publishedDate = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] dateFromComponents:components];
                      
        Book * karamazov = [NSEntityDescription insertNewObjectForEntityForName:@"Book" 
                                                       inManagedObjectContext:self.managedObjectContext];
        karamazov.title = @"The Brothers Karamazov";
        karamazov.authors = @"Fyodor Dostoevsky";
        karamazov.publisher = @"Farrar, Straus and Giroux";
        karamazov.placeOfPublication = @"New York";
        karamazov.isbn13 = @"978-0374528379";
        karamazov.isbn = @"0374528373";
        
        components = [[NSDateComponents alloc] init];
        components.day = 14;
        components.month = 6;
        components.year = 2002;
        karamazov.publishedDate = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] dateFromComponents:components];

    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
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
    if (__managedObjectContext != nil) {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel {
    if (__managedObjectModel != nil) {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"LibraryCard" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil) {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"LibraryCard.sqlite"];
    
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return __persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
