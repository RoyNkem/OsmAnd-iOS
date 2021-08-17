//
//  OACollapsableNearestPoiTypeView.h
//  OsmAnd
//
//  Created by nnngrach on 17.08.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACollapsableView.h"

@class OAPOIType;
@class OAPOI;
@class OAPOIUIFilter;

@interface OACollapsableNearestPoiTypeView : OACollapsableView

@property (nonatomic, readonly) NSMutableArray<OAPOIType *> *poiTypes;
@property (nonatomic, readonly) BOOL hasItems;

- (void)setData:(NSMutableArray<OAPOIType *> *)poiTypes lat:(double)lat lon:(double)lon isPoiAdditional:(BOOL)isPoiAdditional;

@end
