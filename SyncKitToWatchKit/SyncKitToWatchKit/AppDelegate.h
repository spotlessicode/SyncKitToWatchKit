//
//  AppDelegate.h
//  SyncKitToWatchKit
//
//  Created by Eva Puskas on 2017. 09. 18..
//  Copyright © 2017. Pepzen Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "QSCloudKitSynchronizer+CoreData.h"
@interface AppDelegate : UIResponder <UIApplicationDelegate, QSCoreDataChangeManagerDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;
@property (nonatomic, strong) QSCloudKitSynchronizer * _Nullable synchronizer;
- (void)saveContext;


@end

