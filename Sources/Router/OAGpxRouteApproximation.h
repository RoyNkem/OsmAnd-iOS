//
//  OAGpxRouteApproximation.h
//  OsmAnd Maps
//
//  Created by Paul on 15.06.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <CommonCollections.h>
#include <commonOsmAndCore.h>

NS_ASSUME_NONNULL_BEGIN

struct GpxRouteApproximation;

@interface OAGpxRouteApproximation : NSObject

@property (nonatomic) std::shared_ptr<GpxRouteApproximation> gpxApproximation;

- (instancetype) initWithApproximation:(std::shared_ptr<GpxRouteApproximation> &)gpxApproximation;

@end

NS_ASSUME_NONNULL_END
