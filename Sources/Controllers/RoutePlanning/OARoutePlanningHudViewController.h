//
//  OARoutePlanningHudViewController.h
//  OsmAnd
//
//  Created by Paul on 10/16/20.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "OABaseScrollableHudViewController.h"

@class OAMeasurementEditingContext;

@interface OARoutePlanningHudViewController : OABaseScrollableHudViewController

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *optionButtonWidthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *addButtonWidthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *optionButtonLandscapeWidthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *addButtonLandscapeWidthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonsStackLandscapeRightConstraint;

- (instancetype) initWithFileName:(NSString *)fileName;
- (instancetype) initWithInitialPoint:(CLLocation *)latLon;
- (instancetype) initWithEditingContext:(OAMeasurementEditingContext *)editingCtx followTrackMode:(BOOL)followTrackMode showSnapWarning:(BOOL)showSnapWarning;

- (void) cancelModes;

@end
