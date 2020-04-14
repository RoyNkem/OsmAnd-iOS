//
//  OAPublicTransportShieldCell.m
//  OsmAnd
//
//  Created by Paul on 13/03/2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAPublicTransportShieldCell.h"
#import "OAUtilities.h"
#import "Localization.h"
#import "OARouteSegmentShieldView.h"
#import "OAColors.h"
#import "OATransportRoutingHelper.h"
#import "OARouteCalculationResult.h"
#import "OsmAndApp.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"

#include <transportRouteResultSegment.h>
#include <transportRoutingObjects.h>

#define kRowHeight 54
#define kShieldHeight 32
#define kShieldMargin 16.0
#define kShieldY 16.
#define kViewSpacing 3.0
#define kArrowY 25.0

#define MIN_WALK_TIME 120

static UIFont *_shieldFont;

@implementation OAPublicTransportShieldCell
{
    NSArray<UIView *> *_views;
    UIImage *_arrowIcon;
    
    SHARED_PTR<TransportRouteResult> _route;
    OATransportRoutingHelper *_transportHelper;
    
    BOOL _needsSafeAreaInset;
}

-(void) setData:(SHARED_PTR<TransportRouteResult>)data
{
    _transportHelper = OATransportRoutingHelper.sharedInstance;
    _arrowIcon = [[UIImage imageNamed:@"ic_small_arrow_forward"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _route = data;
    [self buildViews];
}

- (void)drawArrowView:(NSMutableArray<UIView *> *)arr {
    UIImageView *arrowView = [self createArrowImageView];
    [arr addObject:arrowView];
    [self addSubview:arrowView];
}

- (void) buildViews
{
    if (_views)
    {
        for (UIView *vw in _views)
        {
            [vw removeFromSuperview];
        }
    }
    
    SHARED_PTR<TransportRouteResultSegment> prevSegment = nullptr;
    NSMutableArray<UIView *> *arr = [NSMutableArray new];
    for (auto it = _route->segments.begin(); it != _route->segments.end(); ++it)
    {
        const auto& s = *it;
        OARouteCalculationResult *walkingSegment = [_transportHelper getWalkingRouteSegment:[[OATransportRouteResultSegment alloc] initWithSegment:prevSegment] s2:[[OATransportRouteResultSegment alloc] initWithSegment:s]];
        if (walkingSegment)
        {
            float walkTime = walkingSegment.routingTime;
            if (walkTime > MIN_WALK_TIME)
            {
                NSString *title = [[OsmAndApp instance] getFormattedTimeInterval:walkTime shortFormat:NO];
                OARouteSegmentShieldView *shield = [[OARouteSegmentShieldView alloc] initWithColor:UIColor.blueColor title:title iconName:@"ic_small_pedestrian" type:EOATransportShiledPedestrian];
                [arr addObject:shield];
                [self addSubview:shield];
                [self drawArrowView:arr];
            }
        }
        else if (s->walkDist > 0)
        {
            float walkTime = s->walkDist / _route->getWalkSpeed();
            if (walkTime > MIN_WALK_TIME)
            {
                CLLocation *start;
                CLLocation *end = [[CLLocation alloc] initWithLatitude:s->getStart()->lat longitude:s->getStart()->lon];
                if (prevSegment != nullptr)
                {
                    start = [[CLLocation alloc] initWithLatitude:prevSegment->getEnd()->lat longitude:prevSegment->getEnd()->lon];
                }
                else
                {
                    start = _transportHelper.startLocation;
                }
                NSString *title = [[OsmAndApp instance] getFormattedTimeInterval:walkTime shortFormat:NO];
                OARouteSegmentShieldView *shield = [[OARouteSegmentShieldView alloc] initWithColor:UIColor.blueColor title:title iconName:@"ic_small_pedestrian" type:EOATransportShiledPedestrian];
                [arr addObject:shield];
                [self addSubview:shield];
                [self drawArrowView:arr];
            }
        }
        
        const auto& r = s->route;
        NSString *title = [NSString stringWithUTF8String:r->getAdjustedRouteRef(true).c_str()];
        NSString *colorName = [NSString stringWithUTF8String:r->color.c_str()];
        // TODO: night mode
        UIColor *color = [OARootViewController.instance.mapPanel.mapViewController getTransportRouteColor:NO renderAttrName:colorName];
        if (!color)
            color = UIColorFromARGB(color_nav_route_default_argb);
        OARouteSegmentShieldView *shield = [[OARouteSegmentShieldView alloc] initWithColor:color title:title iconName:@"ic_small_pedestrian" type:EOATransportShiledTransport];
        [arr addObject:shield];
        [self addSubview:shield];
        
        
        if (_route->segments.end() - it != 1)
        {
            [self drawArrowView:arr];
        }
        else
        {
            walkingSegment = [_transportHelper getWalkingRouteSegment:[[OATransportRouteResultSegment alloc] initWithSegment:s] s2:[[OATransportRouteResultSegment alloc] initWithSegment:nil]];
            if (walkingSegment != nil)
            {
                float walkTime = walkingSegment.routingTime;
                if (walkTime > MIN_WALK_TIME)
                {
                    [self drawArrowView:arr];
                    title = [[OsmAndApp instance] getFormattedTimeInterval:walkTime shortFormat:NO];
                    OARouteSegmentShieldView *shield = [[OARouteSegmentShieldView alloc] initWithColor:UIColor.blueColor title:title iconName:@"ic_small_pedestrian" type:EOATransportShiledPedestrian];
                    [arr addObject:shield];
                    [self addSubview:shield];
                }
            } else {
                float finishWalkDist = _route->finishWalkDist;
                if (finishWalkDist > 0)
                {
                    float walkTime = finishWalkDist / _route->getWalkSpeed();
                    if (walkTime > MIN_WALK_TIME)
                    {
                        CLLocation *start = [[CLLocation alloc] initWithLatitude:s->getEnd()->lat longitude:s->getEnd()->lon];
                        CLLocation *end = _transportHelper.endLocation;
                        [self drawArrowView:arr];
                        title = [[OsmAndApp instance] getFormattedTimeInterval:walkTime shortFormat:NO];
                        OARouteSegmentShieldView *shield = [[OARouteSegmentShieldView alloc] initWithColor:UIColor.blueColor title:title iconName:@"ic_small_pedestrian" type:EOATransportShiledPedestrian];
                        [arr addObject:shield];
                        [self addSubview:shield];
                    }
                }
            }
        }
    }
    _views = [NSArray arrayWithArray:arr];
}

- (void)layoutSubviews
{
    CGFloat margin = _needsSafeAreaInset ? OAUtilities.getLeftMargin : 0.;
    CGFloat width = self.frame.size.width - margin - kShieldMargin * 2;
    CGFloat currWidth = 0.0;
    NSInteger rowsCount = 1;
    
    for (NSInteger i = 0; i < _views.count; i++)
    {
        UIView *currView = _views[i];
        CGRect viewFrame = currView.frame;
        if ([currView isKindOfClass:OARouteSegmentShieldView.class])
        {
            OARouteSegmentShieldView *shieldView = (OARouteSegmentShieldView *) currView;
            viewFrame.size = CGSizeMake([OARouteSegmentShieldView getViewWidth:shieldView.shieldLabel.text], 36.);
        }
        else
        {
            viewFrame.size = CGSizeMake(20., 20.);
        }
        
        currWidth += viewFrame.size.width;
        if (i == 0)
        {
            viewFrame.origin = CGPointMake(margin + kShieldMargin, kShieldY);
        }
        else
        {
            currWidth += kViewSpacing;
            if (currWidth < width)
            {
                CGFloat additionalHeight = kRowHeight * (rowsCount - 1);
                CGRect prevRect = _views[i - 1].frame;
                viewFrame.origin = CGPointMake(CGRectGetMaxX(prevRect) + kViewSpacing, (i % 2) == 0 ? kShieldY + additionalHeight : kArrowY + additionalHeight);
            }
            else
            {
                currWidth = viewFrame.size.width + kViewSpacing;
                rowsCount++;
                CGFloat additionalHeight = kRowHeight * (rowsCount - 1);
                viewFrame.origin = CGPointMake(margin + kShieldMargin, (i % 2) == 0. ? kShieldY + additionalHeight : (kShieldY * 2) + additionalHeight);
            }
        }
        currView.frame = viewFrame;
    }
}

- (UIImageView *) createArrowImageView
{
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0., 0., 20., 20.)];
    imgView.tintColor = UIColorFromRGB(color_tint_gray);
    imgView.image = _arrowIcon;
    return imgView;
}

+ (NSArray<NSString *> *)generateTitlesForFoute:(SHARED_PTR<TransportRouteResult>)route
{
    NSMutableArray<NSString *> *titles = [NSMutableArray new];
    
    SHARED_PTR<TransportRouteResultSegment> prevSegment = nullptr;
    for (auto it = route->segments.begin(); it != route->segments.end(); ++it)
    {
        const auto& s = *it;
        OARouteCalculationResult *walkingSegment = [OATransportRoutingHelper.sharedInstance getWalkingRouteSegment:[[OATransportRouteResultSegment alloc] initWithSegment:prevSegment] s2:[[OATransportRouteResultSegment alloc] initWithSegment:s]];
        if (walkingSegment)
        {
            float walkTime = walkingSegment.routingTime;
            if (walkTime > MIN_WALK_TIME)
            {
                NSString *title = [[OsmAndApp instance] getFormattedTimeInterval:walkTime shortFormat:NO];
                [titles addObject:title];
            }
        }
        else if (s->walkDist > 0)
        {
            float walkTime = s->walkDist / route->getWalkSpeed();
            if (walkTime > MIN_WALK_TIME)
            {
                NSString *title = [[OsmAndApp instance] getFormattedTimeInterval:walkTime shortFormat:NO];
                [titles addObject:title];
            }
        }
        const auto& r = s->route;
        NSString *title = [NSString stringWithUTF8String:r->getAdjustedRouteRef(true).c_str()];
        [titles addObject:title];
        if (route->segments.end() - it == 1)
        {
            walkingSegment = [OATransportRoutingHelper.sharedInstance getWalkingRouteSegment:[[OATransportRouteResultSegment alloc] initWithSegment:s] s2:[[OATransportRouteResultSegment alloc] initWithSegment:nil]];
            if (walkingSegment != nil)
            {
                float walkTime = walkingSegment.routingTime;
                if (walkTime > MIN_WALK_TIME)
                {
                    title = [[OsmAndApp instance] getFormattedTimeInterval:walkTime shortFormat:NO];
                    [titles addObject:title];
                }
            } else {
                float finishWalkDist = route->finishWalkDist;
                if (finishWalkDist > 0)
                {
                    float walkTime = finishWalkDist / route->getWalkSpeed();
                    if (walkTime > MIN_WALK_TIME)
                    {
                        title = [[OsmAndApp instance] getFormattedTimeInterval:walkTime shortFormat:NO];
                        [titles addObject:title];
                    }
                }
            }
        }
    }
    return [NSArray arrayWithArray:titles];
}

+ (CGFloat) getCellHeight:(CGFloat)width route:(SHARED_PTR<TransportRouteResult>)route
{
    return [self getCellHeight:width route:route needsSafeArea:YES];
}

+ (CGFloat) getCellHeight:(CGFloat)width route:(SHARED_PTR<TransportRouteResult>)route needsSafeArea:(BOOL)needsSafeArea
{
    NSArray<NSString *> *shields = [self generateTitlesForFoute:route];
    CGFloat margin = needsSafeArea ? OAUtilities.getLeftMargin : 0.;
    width = width - margin - kShieldMargin * 2;
    if (!_shieldFont)
        _shieldFont = [UIFont systemFontOfSize:15];
    
    CGFloat currWidth = 0.0;
    NSInteger rowsCount = 1;
    
    for (NSInteger i = 0; i < shields.count; i++)
    {
        NSString *shieldTitle = shields[i];
        currWidth += [OARouteSegmentShieldView getViewWidth:shieldTitle];
        
        if (i != shields.count - 1)
        {
            currWidth += 20.;
        }
        
        currWidth += kViewSpacing;
        if (currWidth >= width)
        {
            rowsCount++;
            currWidth = 0.;
        }
    }
    return kRowHeight * rowsCount;
}

/*
 This method is required because auto-layout doesn't take safe area into consideration
 when the tableview is embedded into UIPageViewController
 */

- (void) needsSafeAreaInsets:(BOOL)needsInsets
{
    _needsSafeAreaInset = needsInsets;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    _needsSafeAreaInset = YES;
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end
