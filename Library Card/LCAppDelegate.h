//
//  LCAppDelegate.h
//  Library Card
//
//  Created by Will Barton on 8/13/11.
//  Copyright (c) 2011 Will Barton. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LCAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic) BOOL useiCloud;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
