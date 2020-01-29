//
//  OARouteBaseViewController.h
//  OsmAnd
//
//  Created by Paul on 28.01.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"
#import "OACommonTypes.h"
#import "OAStatisticsSelectionBottomSheetViewController.h"

#define kMapMargin 20.0

@class OARoutingHelper;
@class LineChartView;
@class OAGPXDocument;
@class OATrackChartPoints;
@class OAGPXTrackAnalysis;
@class OARouteStatisticsModeCell;

@interface OARouteBaseViewController : OATargetMenuViewController

@property (nonatomic, readonly) OARoutingHelper *routingHelper;

@property (nonatomic) OAGPXDocument *gpx;
@property (nonatomic) LineChartView *statisticsChart;
@property (nonatomic) OATrackChartPoints *trackChartPoints;
@property (nonatomic) OAGPXTrackAnalysis *analysis;

- (instancetype) initWithGpxData:(NSDictionary *)data;

- (NSAttributedString *) getFormattedDistTimeString;

- (void) setupRouteInfo;

- (BOOL) isLandscapeIPadAware;

- (void) refreshHighlightOnMap:(BOOL)forceFit;
- (void) adjustViewPort:(BOOL)landscape;

- (void) changeChartMode:(EOARouteStatisticsMode)mode chart:(LineChartView *)chart modeCell:(OARouteStatisticsModeCell *)statsModeCell;

@end

