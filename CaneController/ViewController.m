//
//  ViewController.m
//  CaneController
//
//  Created by Gustavo Ambrozio on 4/14/16.
//  Copyright © 2016 Gustavo Ambrozio. All rights reserved.
//

#import "ViewController.h"

#import "AppDelegate.h"
#import "PTDBeanManager.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *labelVoltage;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentMode;

@end

@implementation ViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(beanDidUpdateBatteryVoltage:)
                                                 name:@"beanDidUpdateBatteryVoltage"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(beanDidUpdateScratchBank:)
                                                 name:@"beanDidUpdateScratchBank"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(beanSerialDataReceived:)
                                                 name:@"beanSerialDataReceived"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userDefaultsDidChange:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
}

- (void)beanDidUpdateBatteryVoltage:(NSNotification *)notification {
    NSNumber *voltage = notification.userInfo[@"voltage"];
    self.labelVoltage.text = [NSString stringWithFormat:@"%.3fV", voltage.doubleValue];
}

- (void)beanDidUpdateScratchBank:(NSNotification *)notification {
    NSNumber *bank = notification.userInfo[@"bank"];
    NSData *data = notification.userInfo[@"data"];

    switch (bank.integerValue) {
        case 1: {
            char mode = ((char *)data.bytes)[0];
            self.segmentMode.selectedSegmentIndex = mode;
            break;
        }

        default:
            break;
    }
}

- (void)beanSerialDataReceived:(NSNotification *)notification {
    NSData *data = notification.userInfo[@"data"];
    NSString *received = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([received hasPrefix:@"Mode:"] && received.length >= 6) {
        char mode = [received characterAtIndex:5] - '0';
        self.segmentMode.selectedSegmentIndex = mode;
    }
}

- (void)userDefaultsDidChange:(NSNotification *)notification {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.br.eng.gustavo.CaneController"];
    NSInteger mode = [defaults integerForKey:@"mode"];
    if (self.segmentMode.selectedSegmentIndex != mode) {
        self.segmentMode.selectedSegmentIndex = mode;
        [self segmentModeChanged:nil];
    }
}

- (IBAction)segmentModeChanged:(id)sender {
    [APP_DELEGATE.bean sendSerialString:[[NSString alloc] initWithFormat:@"M%ld\n", (long)self.segmentMode.selectedSegmentIndex]];
    if (sender) {
        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.br.eng.gustavo.CaneController"];
        [defaults setInteger:self.segmentMode.selectedSegmentIndex forKey:@"mode"];
        [defaults synchronize];
    }
}

@end
