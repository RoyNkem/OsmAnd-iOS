//
//  OARouteProvider.h
//  OsmAnd
//
//  Created by Alexey Kulish on 27/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/plus/routing/RouteProvider.java
//  git revision c8ccf21c737e239dda267c89ef2edf504ad9d3e6

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OALocationPoint.h"
#import "OAAppSettings.h"

#include <OsmAndCore.h>

@class OAGPXDocument, OARouteCalculationResult, OAApplicationMode;
struct RoutingConfiguration;
struct RoutingConfigurationBuilder;
struct GeneralRouter;

@interface OARouteService : NSObject

@property (nonatomic, readonly) EOARouteService service;

+ (instancetype)withService:(EOARouteService)service;

+ (NSString *)getName:(EOARouteService)service;
+ (BOOL) isOnline:(EOARouteService)service;
+ (BOOL) isAvailable:(EOARouteService)service;
+ (NSArray<OARouteService *> *) getAvailableRouters;

@end

@class OALocationMark, OARouteDirectionInfo, OARouteCalculationParams;

@interface OAGPXRouteParams : NSObject

@property (nonatomic) NSArray<CLLocation *> *points;
@property (nonatomic) NSArray<OARouteDirectionInfo *> *directions;
@property (nonatomic) BOOL calculateOsmAndRoute;
@property (nonatomic) BOOL passWholeRoute;
@property (nonatomic) BOOL calculateOsmAndRouteParts;
@property (nonatomic) BOOL useIntermediatePointsRTE;
@property (nonatomic) NSArray<id<OALocationPoint>> *wpt;
    
@property (nonatomic) BOOL addMissingTurns;
    
@end

@interface OAGPXRouteParamsBuilder : NSObject

@property (nonatomic, readonly) OAGPXDocument *file;

@property (nonatomic) BOOL calculateOsmAndRoute;
@property (nonatomic) BOOL reverse;
@property (nonatomic, readonly) BOOL leftSide;
@property (nonatomic) BOOL passWholeRoute;
@property (nonatomic) BOOL calculateOsmAndRouteParts;
@property (nonatomic) BOOL useIntermediatePointsRTE;

- (instancetype)initWithDoc:(OAGPXDocument *)document;

- (OAGPXRouteParams *) build:(CLLocation *)start;
- (NSArray<CLLocation *> *) getPoints;

@end

@interface OARouteProvider : NSObject

- (OARouteCalculationResult *) calculateRouteImpl:(OARouteCalculationParams *)params;
- (OARouteCalculationResult *) recalculatePartOfflineRoute:(OARouteCalculationResult *)res params:(OARouteCalculationParams *)params;

- (void) checkInitialized:(int)zoom leftX:(int)leftX rightX:(int)rightX bottomY:(int)bottomY topY:(int)topY;

- (std::shared_ptr<RoutingConfiguration>) initOsmAndRoutingConfig:(std::shared_ptr<RoutingConfigurationBuilder>)config params:(OARouteCalculationParams *)params generalRouter:(std::shared_ptr<GeneralRouter>)generalRouter;
- (std::shared_ptr<GeneralRouter>) getRouter:(OAApplicationMode *)am;

@end
