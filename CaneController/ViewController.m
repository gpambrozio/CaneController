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

@property (nonatomic, assign) BOOL receivingModes;
@property (nonatomic, assign) NSInteger currentMode;

@property (nonatomic, strong) NSMutableArray *modes;

@end

@implementation ViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.modes = [[NSMutableArray alloc] init];
    [self.segmentMode removeAllSegments];
    self.currentMode = -1;
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
            self.currentMode = mode;
            break;
        }

        default:
            break;
    }
}

- (void)beanSerialDataReceived:(NSNotification *)notification {
    NSData *data = notification.userInfo[@"data"];
    NSString *received = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    received = [received stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    if ([received hasPrefix:@"Mode:"] && received.length >= 6) {
        char mode = [received characterAtIndex:5] - '0';
        self.segmentMode.selectedSegmentIndex = mode;
        self.currentMode = mode;
    } else if ([received hasPrefix:@"Modes"]) {
        self.receivingModes = YES;
        [self.modes removeAllObjects];
    } else if (self.receivingModes && received.length) {
        if ([received characterAtIndex:0] == '-') {
            self.receivingModes = NO;
            [self updateModesSegment];
        } else {
            [self.modes addObject:received];
        }
    }
}

- (void)updateModesSegment {
    [self.segmentMode removeAllSegments];
    NSUInteger index = 0;
    for (NSString *mode in self.modes) {
        [self.segmentMode insertSegmentWithTitle:mode atIndex:index++ animated:NO];
    }
    if (self.currentMode >= 0) {
        self.segmentMode.selectedSegmentIndex = self.currentMode;
    }
}

- (IBAction)segmentModeChanged:(id)sender {
    [APP_DELEGATE.bean sendSerialString:[[NSString alloc] initWithFormat:@"M%ld\n", (long)self.segmentMode.selectedSegmentIndex]];
    self.currentMode = self.segmentMode.selectedSegmentIndex;
}

@end
