//
//  AppDelegate.m
//  CaneController
//
//  Created by Gustavo Ambrozio on 4/14/16.
//  Copyright © 2016 Gustavo Ambrozio. All rights reserved.
//

#import "AppDelegate.h"

#import "PTDBeanManager.h"

#define kUserPreferencesLastBatteryLevel @"UserPreferencesLastBatteryLevel"

@interface AppDelegate () <PTDBeanManagerDelegate, PTDBeanDelegate>

@property (nonatomic, strong) PTDBeanManager *beanManager;
@property (nonatomic, strong) PTDBean *bean;
@property (nonatomic, assign) BOOL waitingToReportDisconnect;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@property (nonatomic, assign) double lastBatteryLevel;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;

    [DDLog addLogger:[DDTTYLogger sharedInstance]]; // TTY = Xcode console

    DDFileLogger *fileLogger = [[DDFileLogger alloc] init]; // File Logger
    fileLogger.rollingFrequency = 60 * 60 * 24 * 7;         // 1 week rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 8;
    [DDLog addLogger:fileLogger];

    self.beanManager = [[PTDBeanManager alloc] initWithDelegate:self
                                     stateRestorationIdentifier:@"myBeanManager"];

    UIUserNotificationType types = (UIUserNotificationTypeAlert |
                                    UIUserNotificationTypeBadge |
                                    UIUserNotificationTypeSound);

    [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:types
                                                                                                          categories:nil]];

    self.lastBatteryLevel = [[NSUserDefaults standardUserDefaults] doubleForKey:kUserPreferencesLastBatteryLevel];

    DDLogDebug(@"App started");

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    DDLogDebug(@"applicationWillTerminate");
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
}

#pragma mark - User Notifications

- (void)postNotificationWithText:(NSString *)text {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.fireDate = [NSDate date];
    notification.alertBody = text;
    notification.alertTitle = @"Something happened";
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

#pragma mark - PTDBeanManagerDelegate

// check to make sure we're on
- (void)beanManagerDidUpdateState:(PTDBeanManager *)beanManager {
    if (beanManager.state == BeanManagerState_PoweredOn) {
        // if we're on, scan for advertisting beans
        NSError *scanError;
        [beanManager startScanningForBeans_error:&scanError];
        if (scanError) {
            DDLogDebug(@"Error starting to scan: %@", [scanError localizedDescription]);
        }
    } else if (beanManager.state == BeanManagerState_PoweredOff) {
        // do something else
    }
}

// bean discovered
- (void)beanManager:(PTDBeanManager *)beanManager didDiscoverBean:(PTDBean *)bean error:(NSError *)error {
    if (error) {
        DDLogDebug(@"Error discovering Bean: %@", [error localizedDescription]);
        return;
    }
    DDLogDebug(@"Discovered Bean: %@, ID: %@", bean.name, bean.identifier);
    if (self.bean == nil && [bean.name isEqualToString:@"Cane"]) {
        NSError *connectError;
        [beanManager connectToBean:bean error:&connectError];
        if (connectError) {
            DDLogDebug(@"Error connecting Bean: %@", [connectError localizedDescription]);
        }
    }
}

// bean connected
- (void)beanManager:(PTDBeanManager *)beanManager didConnectBean:(PTDBean *)bean error:(NSError *)error {
    if (error) {
        DDLogDebug(@"Error connecting Bean: %@", [error localizedDescription]);
        return;
    }
    DDLogDebug(@"Connected Bean: %@, ID: %@", bean.name, bean.identifier);
    if ([bean.name isEqualToString:@"Cane"]) {
        self.bean = bean;
        self.bean.delegate = self;
        self.bean.autoReconnect = YES;
        [self.bean readScratchBank:1];
        if (!self.waitingToReportDisconnect) {
            [self postNotificationWithText:@"Cane Connected!!"];
        }
    }
}

- (void)beanManager:(PTDBeanManager *)beanManager didDisconnectBean:(PTDBean *)bean error:(NSError *)error {
    DDLogDebug(@"Disconnected Bean: %@, ID: %@", bean.name, bean.identifier);
    if (!self.waitingToReportDisconnect) {
        self.waitingToReportDisconnect = YES;
        self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"waiting"
                                                                                     expirationHandler:^{
                                                                                         if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                                                                                             [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
                                                                                             self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
                                                                                         }
                                                                                     }];
    }
    self.bean.delegate = nil;
    self.bean = nil;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.bean == nil) {
            [self postNotificationWithText:@"Cane Disconnected... :("];
            self.waitingToReportDisconnect = NO;
            if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
                self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
            }
        }
    });
}

#pragma mark - PTDBeanDelegate

- (void)beanDidUpdateBatteryVoltage:(PTDBean *)bean error:(NSError *)error {
    DDLogDebug(@"Battery = %.3f", bean.batteryVoltage.doubleValue);
    if (bean.batteryVoltage.doubleValue > 0.0) {
        double diff = fabs(bean.batteryVoltage.doubleValue - self.lastBatteryLevel);
        if (diff >= 0.02) {
            self.lastBatteryLevel = bean.batteryVoltage.doubleValue;
            [[NSUserDefaults standardUserDefaults] setDouble:self.lastBatteryLevel forKey:kUserPreferencesLastBatteryLevel];
            [self postNotificationWithText:[[NSString alloc] initWithFormat:@"Battery level: %.3f", self.lastBatteryLevel]];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"beanDidUpdateBatteryVoltage"
                                                            object:nil
                                                          userInfo:@{ @"voltage" : bean.batteryVoltage }];
    }
}

- (void)bean:(PTDBean *)bean didUpdateScratchBank:(NSInteger)bank data:(NSData *)data {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"beanDidUpdateScratchBank"
                                                        object:nil
                                                      userInfo:@{ @"bank" : @(bank),
                                                                  @"data" : data }];
}

- (void)bean:(PTDBean *)bean serialDataReceived:(NSData *)data {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"beanSerialDataReceived"
                                                        object:nil
                                                      userInfo:@{ @"data" : data }];
}

@end
