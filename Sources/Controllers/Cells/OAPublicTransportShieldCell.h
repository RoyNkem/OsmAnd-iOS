//
//  OAPublicTransportShieldCell.h
//  OsmAnd
//
//  Created by Paul on 12/03/2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#include <CommonCollections.h>
#include <commonOsmAndCore.h>
#include <transportRouteResult.h>

@class OATransportRouteResult;

@interface OAPublicTransportShieldCell : UITableViewCell

-(void) setData:(SHARED_PTR<TransportRouteResult>)data;
-(void) needsSafeAreaInsets:(BOOL)needsInsets;

+ (CGFloat) getCellHeight:(CGFloat)width route:(SHARED_PTR<TransportRouteResult>)route;
+ (CGFloat) getCellHeight:(CGFloat)width route:(SHARED_PTR<TransportRouteResult>)route needsSafeArea:(BOOL)needsSafeArea;

@end
