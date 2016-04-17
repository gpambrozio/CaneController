//
//  ViewController.m
//  CaneController
//
//  Created by Gustavo Ambrozio on 4/14/16.
//  Copyright © 2016 Gustavo Ambrozio. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *labelVoltage;
@property (nonatomic, strong) id beanDidUpdateBatteryVoltageObserver;

@end

@implementation ViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self.beanDidUpdateBatteryVoltageObserver];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.beanDidUpdateBatteryVoltageObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"beanDidUpdateBatteryVoltage"
                                                                                                 object:nil
                                                                                                  queue:[NSOperationQueue mainQueue]
                                                                                             usingBlock:^(NSNotification *_Nonnull note) {
                                                                                                 NSNumber *voltage = note.userInfo[@"voltage"];
                                                                                                 self.labelVoltage.text = [NSString stringWithFormat:@"%.3fV", voltage.doubleValue];
                                                                                             }];
}

@end
