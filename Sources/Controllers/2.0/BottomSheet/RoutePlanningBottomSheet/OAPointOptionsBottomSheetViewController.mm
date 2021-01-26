//
//  OAPointOptionsBottomSheetViewController.m
//  OsmAnd
//
//  Created by Paul on 31.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAPointOptionsBottomSheetViewController.h"
#import "OATitleIconRoundCell.h"
#import "Localization.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAColors.h"
#import "OAApplicationMode.h"

#define kIconTitleIconRoundCell @"OATitleIconRoundCell"

@interface OAPointOptionsBottomSheetViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAPointOptionsBottomSheetViewController
{
    OAGpxTrkPt *_point;
    NSInteger _pointIndex;
    NSArray<NSArray<NSDictionary *> *> *_data;
    
    OAMeasurementEditingContext *_editingCtx;
}

- (instancetype) initWithPoint:(OAGpxTrkPt *)point index:(NSInteger)pointIndex editingContext:(OAMeasurementEditingContext *)editingContext
{
    self = [super init];
    if (self) {
        _point = point;
        _pointIndex = pointIndex;
        _editingCtx = editingContext;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.sectionHeaderHeight = 16.;
    [self.rightButton removeFromSuperview];
    [self.leftIconView setImage:[UIImage imageNamed:@"ic_custom_routes"]];
}

- (void) applyLocalization
{
    self.titleView.text = [NSString stringWithFormat:OALocalizedString(@"point_num"), _pointIndex + 1];
    [self.leftButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray new];
    [data addObject:@[
        @{
            @"type" : kIconTitleIconRoundCell,
            @"title" : OALocalizedString(@"move_point"),
            @"img" : @"ic_custom_change_object_position",
            @"key" : @"move_point"
        }
    ]];
    
    [data addObject:@[
        @{
            @"type" : kIconTitleIconRoundCell,
            @"title" : OALocalizedString(@"add_before"),
            @"img" : @"ic_custom_add_point_before",
            @"key" : @"add_points",
            @"value" : @(EOAAddPointModeBefore)
        },
        @{
            @"type" : kIconTitleIconRoundCell,
            @"title" : OALocalizedString(@"add_after"),
            @"img" : @"ic_custom_add_point_after",
            @"key" : @"add_points",
            @"value" : @(EOAAddPointModeAfter)
        }
    ]];
    
    [data addObject:@[
        @{
            @"type" : kIconTitleIconRoundCell,
            @"title" : OALocalizedString(@"trim_before"),
            @"img" : @"ic_custom_trim_before",
            @"key" : @"trim",
            @"value" : @(EOAClearPointsModeBefore)
        },
        @{
            @"type" : kIconTitleIconRoundCell,
            @"title" : OALocalizedString(@"trim_after"),
            @"img" : @"ic_custom_trim_after",
            @"key" : @"trim",
            @"value" : @(EOAClearPointsModeAfter)
        }
    ]];
    
    if ([_editingCtx isFirstPointSelected:YES])
    {
        // skip
    }
    else if ([_editingCtx isLastPointSelected:YES])
    {
        [data addObject:@[
            @{
                @"type" : kIconTitleIconRoundCell,
                @"title" : OALocalizedString(@"track_new_segment"),
                @"img" : @"ic_custom_new_segment",
                @"key" : @"new_segment"
            }
        ]];
    }
    else if ([_editingCtx isFirstPointSelected:NO] || [_editingCtx isLastPointSelected:NO])
    {
        [data addObject:@[
            @{
                @"type" : kIconTitleIconRoundCell,
                @"title" : OALocalizedString(@"join_segments"),
                @"img" : @"ic_custom_straight_line",
                @"key" : @"join_segments"
            }
        ]];
    }
    
    [data addObject:@[
        @{
            @"type" : kIconTitleIconRoundCell,
            @"title" : OALocalizedString(@"change_route_type_before"),
            @"img" : [self getRouteTypeIcon:YES],
            @"key" : @"change_route_before",
        },
        @{
            @"type" : kIconTitleIconRoundCell,
            @"title" : OALocalizedString(@"change_route_type_after"),
            @"img" : [self getRouteTypeIcon:NO],
            @"key" : @"change_route_after",
            
        }
    ]];
    
    [data addObject:@[
        @{
            @"type" : kIconTitleIconRoundCell,
            @"title" : OALocalizedString(@"delete_point"),
            @"img" : @"ic_custom_remove_outlined",
            @"custom_color" : UIColorFromRGB(color_primary_red),
            @"key" : @"delete_point"
        }
    ]];
    _data = data;
}

- (NSString *) getRouteTypeIcon:(BOOL)before
{
    OAApplicationMode *routeAppMode = before ? _editingCtx.getBeforeSelectedPointAppMode : _editingCtx.getSelectedPointAppMode;
    NSString *icon;
    if (OAApplicationMode.DEFAULT == routeAppMode)
        icon = @"ic_custom_straight_line";
    else
        icon = routeAppMode.getIconName;
        
    return icon;
}

- (void) onBottomSheetDismissed
{
    if (self.delegate)
        [self.delegate onClearSelection];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    
    if ([item[@"type"] isEqualToString:kIconTitleIconRoundCell])
    {
        static NSString* const identifierCell = kIconTitleIconRoundCell;
        OATitleIconRoundCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kIconTitleIconRoundCell owner:self options:nil];
            cell = (OATitleIconRoundCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
        }
        if (cell)
        {
            [cell roundCorners:(indexPath.row == 0) bottomCorners:(indexPath.row == _data[indexPath.section].count - 1)];
            cell.titleView.text = item[@"title"];
            
            
            UIColor *tintColor = item[@"custom_color"];
            if (tintColor)
            {
                cell.iconColorNormal = tintColor;
                cell.textColorNormal = tintColor;
                cell.iconView.image = [[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
            else
            {
                cell.textColorNormal = nil;
                cell.iconView.image = [UIImage imageNamed:item[@"img"]];
                cell.titleView.textColor = UIColor.blackColor;
                cell.separatorView.hidden = indexPath.row == _data[indexPath.section].count - 1;
            }
        }
        return cell;
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

#pragma mark - UItableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *key = item[@"key"];
    if ([key isEqualToString:@"move_point"])
    {
        if (self.delegate)
            [self.delegate onMovePoint:_pointIndex];
    }
    else if ([key isEqualToString:@"trim"])
    {
        EOAClearPointsMode mode = (EOAClearPointsMode) [item[@"value"] integerValue];
        if (self.delegate)
            [self.delegate onClearPoints:mode];
    }
    else if ([key isEqualToString:@"add_points"])
    {
        EOAAddPointMode type = (EOAAddPointMode) [item[@"value"] integerValue];
        if (self.delegate)
            [self.delegate onAddPoints:type];
    }
    else if ([key isEqualToString:@"delete_point"])
    {
        if (self.delegate)
            [self.delegate onDeletePoint];
    }
    else if ([key isEqualToString:@"change_route_before"])
    {
        [self dismissViewControllerAnimated:NO completion:nil];
        if (self.delegate)
            [self.delegate onChangeRouteTypeBefore];
        return;
    }
    else if ([key isEqualToString:@"change_route_after"])
    {
        [self dismissViewControllerAnimated:NO completion:nil];
        if (self.delegate)
            [self.delegate onChangeRouteTypeAfter];
        return;
    }
    else if ([key isEqualToString:@"new_segment"])
    {
        [self dismissViewControllerAnimated:NO completion:nil];
        if (self.delegate)
            [self.delegate onSplitPointsAfter];
        return;
    }
    else if ([key isEqualToString:@"join_segments"])
    {
        [self dismissViewControllerAnimated:NO completion:nil];
        if (self.delegate)
            [self.delegate onJoinPoints];
        return;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
