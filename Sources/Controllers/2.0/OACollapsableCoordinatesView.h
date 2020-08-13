//
//  OACollapsableCoordinatesView.h
//  OsmAnd
//
//  Created by Paul on 07/1/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OACollapsableView.h"

@class OAPOI;

@interface OACollapsableCoordinatesView : OACollapsableView

@property (nonatomic) double lat;
@property (nonatomic) double lon;
@property (nonatomic, readonly) NSDictionary<NSNumber *, NSString *> *coordinates;

- (void) setupWithLat:(double)lat lon:(double)lon;

@end
