//
//  AppDelegate.h
//  CaneController
//
//  Created by Gustavo Ambrozio on 4/14/16.
//  Copyright © 2016 Gustavo Ambrozio. All rights reserved.
//

#import <UIKit/UIKit.h>

#define APP_DELEGATE ((AppDelegate *)[[UIApplication sharedApplication] delegate])

@class PTDBean, PTDBeanManager;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, readonly, strong) PTDBeanManager *beanManager;
@property (nonatomic, readonly, strong) PTDBean *bean;

@end
