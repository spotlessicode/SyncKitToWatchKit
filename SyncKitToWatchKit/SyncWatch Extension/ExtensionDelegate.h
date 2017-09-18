//
//  ExtensionDelegate.h
//  SyncWatch Extension
//
//  Created by Eva Puskas on 2017. 09. 18..
//  Copyright © 2017. Pepzen Ltd. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import "QSCloudKitSynchronizer+CoreData.h"
#import <CoreData/CoreData.h>
@interface ExtensionDelegate : NSObject <WKExtensionDelegate, QSCoreDataChangeManagerDelegate>
@property (nonatomic, strong) QSCloudKitSynchronizer * _Nullable synchronizer;
@property (readonly, strong) NSPersistentContainer * _Nullable persistentContainer;
- (void)saveContext;
@end
