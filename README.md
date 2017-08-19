##Synckit to watchkit:
  Created by SpotlessIcode on 2017. 08. 19..
  Copyright © 2017. Pepzen Ltd. All rights reserved.
 Tested:
-- 1. Xcode Version 8.3.3, Model : iPhone 6 iOS 10.3.3, and Apple Watch Series 2 Watch OS 3.2.3
-- 2. in progress: Xcode Version 9.0 beta 5, Model: iPhone 6 iOS 11.0 beta 6, and Apple Watch Series 2 Watch OS 4.0 beta 6
Warning! - for Watch OS 3.1. CloudKit usage is blocked in watchOS Simulator. Running any test will throw a “Not Authenticated” error even though you are signed in via the paired iOS Simulator.

## I. IOS side
---1. use SyncKit or other CloudKit settings
---2. add WCSession delegate in Appdelegate
---3. updateContext after syncComplete (post Notification in self.synchronizer synchronizeWithCompletion:^(NSError *error) {)
and send dictionary to Watch, if it should make a new download from CloudKit
```Objective-C
-(void)syncCompleteDo{
    NSLog(@"syncComplete");
    [self updateAppContext];
    //and do other suff
}
- (void)updateAppContext{
    NSLog(@"updateAppContext");
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUserDefaults *iCloudTokenSignedIn = [NSUserDefaults standardUserDefaults];
        NSUserDefaults *iCloudEnabled = [NSUserDefaults standardUserDefaults];
        NSUserDefaults *pairedAndinstalled = [NSUserDefaults standardUserDefaults];
        //set these in appdelegate
        NSLog([iCloudTokenSignedIn boolForKey:@"iCloudTokenSignedIn"] ? @"iCloudTokenSignedIn YES":@"iCloudTokenSignedIn NO");
        NSLog([iCloudEnabled boolForKey:@"iCloudEnabled"] ? @"iCloudEnabled YES":@"iCloudEnabled NO");
        NSLog([pairedAndinstalled boolForKey:@"pairedAndinstalled"] ? @"pairedAndinstalled YES":@"pairedAndinstalled NO");
        if (([iCloudTokenSignedIn boolForKey:@"iCloudTokenSignedIn"]) && ([iCloudEnabled boolForKey:@"iCloudEnabled"]) && ([pairedAndinstalled boolForKey:@"pairedAndinstalled"])){
            //add date to dict, didReceiveApplicationContext: at WatchKit will be called just if the Context changed!
            NSDateFormatter *dateformat = [[NSDateFormatter alloc]init];
            NSString *now =[dateformat stringFromDate:[NSDate date]];
            NSDictionary *finaldict = @{@"ShouldDownloadCloud":@"YES",@"date":now};
            NSError *error = nil;
            [[WCSession defaultSession] updateApplicationContext:finaldict error:&error];
            NSLog(@"WCSession updateApplicationContex");
            if(error){
                NSLog(@"Problem sending dictonary: @%@", error);
            }else{
                NSLog(@"sent dictionary");
            }
        }
    });
}
```
---4. set didRecieve messages from Watch
```Objective-C
#pragma mark - WCSession
-(void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message replyHandler:(void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler{
    NSLog(@"didReceiveMessage: ");
    NSLog(@"[message objectForKey:%@", [message objectForKey:@"mykey"]);
    if ([message objectForKey:@"mykey"]){
        NSLog(@"appdelegate recieve message");
        replyHandler(@{@"response":@"didRecieveMessage"});
    }
}
-(void)session:(WCSession *)session didReceiveUserInfo:(nonnull NSDictionary<NSString *,id> *)userInfo{
    NSLog(@"didReceiveUserInfo: ");
    if ([userInfo objectForKey:@"mykey"]){
        //update CoreData objects attributes, which changed by WatchOS
    }
}
##II. WatchKit Settings
---1. WCSession delegate
---2. Check, if it should download data:
```Objective-C
- (void)session:(WCSession *)session didReceiveApplicationContext:(NSDictionary<NSString *,id> *)applicationContext{
    NSLog (@"didReceiveApplicationContext applicationContext");
    NSString *shouldDownloadCloud = [applicationContext objectForKey:@"ShouldDownloadCloud"];
    if([shouldDownloadCloud isEqualToString:@"YES"]){
        [self sync];
    }
}
```
---3. CoreData model with the same objects and attributes as in IOS
---4. turn on iCloud at Watch Extension target Capabilities  - and add CloudKit custom container with IOS target container's name, so it will download from that container.
---5. Copy SyncKit library (CoreData and QSSynchronizer folders) into WatchKit Extension, and make changes:
---in QSCloudKitSynchronizer.h comment out: because CKSubscription and CKNotificationInfo is not available on WatchOS
row 97 and 104:
```Objective-C
- (void)subscribeForUpdateNotificationsWithCompletion:(void(^)(NSError *error))completion;
- (void)deleteSubscriptionWithCompletion:(void(^)(NSError *error))completion;
```
---in QSCloudKitSynchronizer.m set the SyncMode to download, and comment out the subscriptions:
```
                self.syncMode = QSCloudKitSynchronizeModeDownload;
```
comment out: //row 592-680:
```Objective-C
- (void)subscribeForChangesInRecordZoneWithCompletion:(void(^)(NSError *error))completion
- (void)cancelSubscriptionForChangesInRecordZoneWithCompletion:(void(^)(NSError *error))completion
- (void)cancelSubscriptionWithID:(NSString *)subscriptionID withCompletion:(void(^)(NSError *error))completion
- (NSString *)subscriptionID
```
row 208-218:
```
- (void)subscribeForUpdateNotificationsWithCompletion:(void(^)(NSError *error))completion
- (void)deleteSubscriptionWithCompletion:(void(^)(NSError *error))completion
```          
---so [self synchronizationUploadChanges]; & [self synchronizationUpdateServerToken]; never be called
---6. Implement sync and changemanager into ExtensionDelegate.h:
```Objective-C
#import "QSCloudKitSynchronizer+CoreData.h"
@interface ExtensionDelegate : NSObject <WKExtensionDelegate, WCSessionDelegate, QSCoreDataChangeManagerDelegate>
@property (nonatomic, strong) QSCloudKitSynchronizer * _Nullable synchronizer;
```
--- and implement sync and changemanager into ExtensionDelegate.m:
```Objective-C
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
```
---7. update UI after sync
```Objective-C
-(void)syncCompleteDo{
    [self configureFetch];
    [self configureTableWithData:_myArray];
}
```
---8. If you made changes with objects on Watch, add those objects to an NSMutableArray, and create from attributes NSDictionary, which could  send with sendMessage replyhandler, if th IOS side isReachable, or with transferUserInfo. didReceiveUserInfo will be called at IOS App launch.
```Objective-C
-(void)dataChanged{
    NSLog(@"DATAChanged!");
    NSMutableArray *changedObjects = [[NSMutableArray alloc]init];
    [changedObjects addObject:goal];
    NSMutableArray *alldicts = [[NSMutableArray alloc]init];
    NSEntityDescription *entityDescription = [MyObject entity];
    NSArray *attributeKeys = entityDescription.attributesByName.allKeys;
    for(int i=0;i<changedObjects.count;i++){
        MyObject *obj =[changedObjects objectAtIndex:i];
        NSMutableDictionary *dicta = [NSMutableDictionary dictionaryWithDictionary:[obj dictionaryWithValuesForKeys:attributeKeys]];
        [alldicts addObject:dicta];
    }
    NSData *serialized = [NSKeyedArchiver archivedDataWithRootObject:alldicts];
    NSDictionary *dict = [[NSDictionary alloc] initWithObjects:@[serialized] forKeys:@[@"myKey"]];
    
    if([WCSession defaultSession].isReachable){
        NSLog(@"isReachable - data sent");
        [[WCSession defaultSession] sendMessage:dict
                                   replyHandler:^(NSDictionary *replyHandler) {
                                       NSLog(@"[replyHandler valueForKey: %@", [replyHandler valueForKey:@"response"]);
                                   }
                                   errorHandler:^(NSError *error) {
                                       NSLog(@"error %@", error);
                                   }];
        
    }else{
        NSLog(@"userinfo - data sent");
        [[WCSession defaultSession] transferUserInfo:dict];
    }
}
```
## III. TEST

 1. Run App on IOS device
 --- check icloud and WCSession delegate Watch should be paired and installed
 --- check that the dictionary sent
 2. Run App on WatchOS
 --- check sync log and don1t forget update UI
 3. MAke changes with objects on Watch
 --- send data back to IOS