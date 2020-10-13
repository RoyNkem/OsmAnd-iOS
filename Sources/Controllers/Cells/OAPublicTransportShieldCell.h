//
//  OAPublicTransportShieldCell.h
//  OsmAnd
//
//  Created by Paul on 12/03/2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OATransportDetailsTableViewController.h"

#include <CommonCollections.h>
#include <commonOsmAndCore.h>
#include <transportRouteResult.h>

@class OATransportRouteResult;

@interface OAPublicTransportShieldCell : UITableViewCell

@property (nonatomic) id<OATransportDetailsControllerDelegate> delegate;

-(void) setData:(SHARED_PTR<TransportRouteResult>)data;
-(void) needsSafeAreaInsets:(BOOL)needsInsets;

@end
