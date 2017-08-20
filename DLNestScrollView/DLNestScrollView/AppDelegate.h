//
//  AppDelegate.h
//  DLNestScrollView
//
//  Created by Dalong on 2017/8/20.
//  Copyright © 2017年 Dalong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

