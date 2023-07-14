//
//  OABearingWidget.h
//  OsmAnd Maps
//
//  Created by Paul on 12.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseWidgetView.h"
#import "OATextInfoWidget.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, EOABearingType) {
    EOABearingTypeRelative = 0,
    EOABearingTypeMagnetic,
    EOABearingTypeTrue
};

@class OAGeomagneticField;

@interface OABearingWidget : OATextInfoWidget

- (instancetype)initWithBearingType:(EOABearingType)bearingType;

- (int)getBearing;
- (CLLocation *) getDestinationLocation;
- (int)getRelativeBearing:(CLLocation *)myLocation magneticBearingToDest:(float)magneticBearingToDest;
- (OAGeomagneticField *) getGeomagneticField:(CLLocation *)location;
- (BOOL)isAngularUnitsDepended;

@end

NS_ASSUME_NONNULL_END
