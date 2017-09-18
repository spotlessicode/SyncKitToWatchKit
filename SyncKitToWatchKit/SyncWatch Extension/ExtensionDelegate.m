//
//  ExtensionDelegate.m
//  SyncWatch Extension
//
//  Created by Eva Puskas on 2017. 09. 18..
//  Copyright © 2017. Pepzen Ltd. All rights reserved.
//

#import "ExtensionDelegate.h"

@implementation ExtensionDelegate

- (void)applicationDidFinishLaunching {
    // Perform any final initialization of your application.
}

- (void)applicationDidBecomeActive {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillResignActive {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, etc.
}

- (void)handleBackgroundTasks:(NSSet<WKRefreshBackgroundTask *> *)backgroundTasks {
    // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
    for (WKRefreshBackgroundTask * task in backgroundTasks) {
        // Check the Class of each task to decide how to process it
        if ([task isKindOfClass:[WKApplicationRefreshBackgroundTask class]]) {
            // Be sure to complete the background task once you’re done.
            WKApplicationRefreshBackgroundTask *backgroundTask = (WKApplicationRefreshBackgroundTask*)task;
            [backgroundTask setTaskCompletedWithSnapshot:NO];
        } else if ([task isKindOfClass:[WKSnapshotRefreshBackgroundTask class]]) {
            // Snapshot tasks have a unique completion call, make sure to set your expiration date
            WKSnapshotRefreshBackgroundTask *snapshotTask = (WKSnapshotRefreshBackgroundTask*)task;
            [snapshotTask setTaskCompletedWithDefaultStateRestored:YES estimatedSnapshotExpiration:[NSDate distantFuture] userInfo:nil];
        } else if ([task isKindOfClass:[WKWatchConnectivityRefreshBackgroundTask class]]) {
            // Be sure to complete the background task once you’re done.
            WKWatchConnectivityRefreshBackgroundTask *backgroundTask = (WKWatchConnectivityRefreshBackgroundTask*)task;
            [backgroundTask setTaskCompletedWithSnapshot:NO];
        } else if ([task isKindOfClass:[WKURLSessionRefreshBackgroundTask class]]) {
            // Be sure to complete the background task once you’re done.
            WKURLSessionRefreshBackgroundTask *backgroundTask = (WKURLSessionRefreshBackgroundTask*)task;
            [backgroundTask setTaskCompletedWithSnapshot:NO];
        } else {
            // make sure to complete unhandled task types
            [task setTaskCompletedWithSnapshot:NO];
        }
    }
}
#pragma mark - Core Data stack
@synthesize persistentContainer = _persistentContainer;

- (NSPersistentContainer *)persistentContainer {
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"PurpWatchModel"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                     */
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
            }];
        }
    }
    
    return _persistentContainer;
}

#pragma mark - Core Data Saving support

- (void)saveContext{
    NSLog(@"saveContext");
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    NSLog(@"context %@", context);
    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}
- (void)mergeChangesFromSaveNotification:(NSNotification *)notification
                             intoContext:(NSManagedObjectContext *)context {
    
    // NSManagedObjectContext's merge routine ignores updated objects which aren't
    // currently faulted in. To force it to notify interested clients that such
    // objects have been refreshed (e.g. NSFetchedResultsController) we need to
    // force them to be faulted in ahead of the merge
    
    NSSet *updated = [notification.userInfo objectForKey:NSUpdatedObjectsKey];
    for (NSManagedObject *anObject in updated) {
        // The objects can't be a fault. -existingObjectWithID:error: is a
        // nice easy way to achieve that in a single swoop.
        [context existingObjectWithID:anObject.objectID error:NULL];
    }
    
    [context mergeChangesFromContextDidSaveNotification:notification];
}
#pragma mark - Core Data Synchronizer
#pragma mark - sync
- (void)sync{
    [self.synchronizer synchronizeWithCompletion:^(NSError *error) {
        if (error) {
            NSLog(@"Watch error snyc end: %@", error);
        }else{
            [[NSNotificationCenter defaultCenter]postNotificationName:@"syncCompleteWatch" object:self];
        }
    }];
}
- (QSCloudKitSynchronizer *)synchronizer
{
    if (!_synchronizer) {
        _synchronizer = [QSCloudKitSynchronizer cloudKitSynchronizerWithContainerName:@"iCloud.com.pepzen.purp4" managedObjectContext:self.persistentContainer.viewContext changeManagerDelegate:self];
    }
    return _synchronizer;
}
#pragma mark - QSCoreDataChangeManagerDelegate
- (void)changeManagerRequestsContextSave:(QSCoreDataChangeManager *)changeManager completion:(void (^)(NSError *))completion{
    __block NSError *error = nil;
    [self.persistentContainer.viewContext save:&error];
    completion(error);
}
- (void)changeManager:(QSCoreDataChangeManager *)changeManager didImportChanges:(NSManagedObjectContext *)importContext completion:(void (^)(NSError *))completion
{
    __block NSError *error = nil;
    [importContext performBlockAndWait:^{
        [importContext save:&error];
    }];
    if (!error) {
        NSLog(@"Saved Watch");
        [self.persistentContainer.viewContext save:&error];
        if (error) {
            NSLog(@"persistentContainer save error %@, %@", error, error.userInfo);
        }
    }
    completion(error);
}
@end
