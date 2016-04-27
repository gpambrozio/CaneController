//
//  TodayViewController.m
//  TodayCane
//
//  Created by Gustavo Ambrozio on 4/26/16.
//  Copyright © 2016 Gustavo Ambrozio. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

@interface TodayViewController () <NCWidgetProviding>

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentMode;

@end

@implementation TodayViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userDefaultsDidChange:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateInterface];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateInterface];
}

- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets {
    return UIEdgeInsetsZero;
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.

    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData

    [self updateInterface];

    completionHandler(NCUpdateResultNewData);
}

- (void)userDefaultsDidChange:(NSNotification *)notification {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.br.eng.gustavo.CaneController"];
    NSInteger mode = [defaults integerForKey:@"mode"];
    self.segmentMode.selectedSegmentIndex = mode;
}

- (void)updateInterface {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.br.eng.gustavo.CaneController"];
    NSInteger mode = [defaults integerForKey:@"mode"];
    self.segmentMode.selectedSegmentIndex = mode;
}

- (IBAction)segmentModeChanged:(id)sender {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.br.eng.gustavo.CaneController"];
    [defaults setInteger:self.segmentMode.selectedSegmentIndex forKey:@"mode"];
    [defaults synchronize];
}

@end
