//
//  OAMapSettingsRoutesScreen.mm
//  OsmAnd
//
//  Created by Skalii on 16.08.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAMapSettingsRoutesScreen.h"
#import "OAMapSettingsViewController.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"
#import "OATableViewCustomFooterView.h"
#import "OASettingSwitchCell.h"
#import "OASettingsTitleTableViewCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OASizes.h"
#import "OAMapStyleSettings.h"

typedef NS_ENUM(NSInteger, EOAMapSettingsRoutesSection)
{
    EOAMapSettingsRoutesSectionVisibility = 0,
    EOAMapSettingsRoutesSectionColors
};

typedef NS_ENUM(NSInteger, ERoutesSettingType)
{
    ERoutesSettingCycle = 0,
    ERoutesSettingMountain,
    ERoutesSettingHiking,
    ERoutesSettingTravel

};

@implementation OAMapSettingsRoutesScreen
{
    OsmAndAppInstance _app;
    OAMapViewController *_mapViewController;

    OAMapStyleSettings *_styleSettings;
    OAMapStyleParameter *_routesParameter;
    NSArray<OAMapStyleParameter *> *_routesParameters;
    ERoutesSettingType _routesSettingType;

    NSArray<NSArray <NSDictionary *> *> *_data;
    BOOL _routesEnabled;
}

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;

- (id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _styleSettings = [OAMapStyleSettings sharedInstance];
        tblView = tableView;
        settingsScreen = EMapSettingsScreenRoutes;

        if ([param isKindOfClass:NSArray.class])
        {
            NSArray<NSString *> *parameters = (NSArray *) param;
            if ([parameters containsObject:SHOW_MTB_ROUTES_ATTR])
                _routesSettingType = ERoutesSettingMountain;

            NSMutableArray<OAMapStyleParameter *> *routesParameters = [NSMutableArray array];
            for (NSString *parameter in parameters)
            {
                [routesParameters addObject:[_styleSettings getParameter:parameter]];
            }
            _routesParameters = routesParameters;
        }
        else
        {
            _routesParameter = [_styleSettings getParameter:param];
            if ([param isEqualToString:SHOW_CYCLE_ROUTES_ATTR])
            {
                _routesSettingType = ERoutesSettingCycle;
                _routesEnabled = _routesParameter.storedValue.length > 0 && [_routesParameter.storedValue isEqualToString:@"true"];
            }
            else if ([param isEqualToString:HIKING_ROUTES_OSMC_ATTR])
            {
                _routesSettingType = ERoutesSettingHiking;
                _routesEnabled = _routesParameter.storedValue.length > 0 && ![_routesParameter.storedValue isEqualToString:@"disabled"];
            }
            else
            {
                _routesSettingType = ERoutesSettingTravel;
                _routesEnabled = _routesParameter.storedValue.length > 0;
            }
        }
        
        vwController = viewController;
        
        _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
        [self initData];
    }
    return self;
}

- (void)initData
{
    NSMutableArray *dataArr = [NSMutableArray new];

    if (_routesParameters)
    {
        for (OAMapStyleParameter *parameter in _routesParameters)
        {
            [dataArr addObject:@[@{
                @"type": [OASettingSwitchCell getCellIdentifier],
                @"value": @(parameter.storedValue.length > 0 && [parameter.storedValue isEqualToString:@"true"]),
                @"title": parameter.title,
                @"icon": @"ic_action_bicycle_dark"
            }]];
        }
    }
    else
    {
        [dataArr addObject:@[@{@"type": [OASettingSwitchCell getCellIdentifier]}]];

        NSMutableArray *colorsArr = [NSMutableArray new];
        if (_routesSettingType == ERoutesSettingCycle)
        {
            [colorsArr addObject:@{
                @"type": [OASettingsTitleTableViewCell getCellIdentifier],
                @"value": @"false",
                @"title": OALocalizedString(@"gpx_route")
            }];
            [colorsArr addObject:@{
                @"type": [OASettingsTitleTableViewCell getCellIdentifier],
                @"value": @"true",
                @"title": OALocalizedString(@"rendering_value_walkingRoutesOSMCNodes_name")
            }];
        }
        else if (_routesSettingType != ERoutesSettingMountain)
        {
            for (OAMapStyleParameterValue *value in _routesParameter.possibleValuesUnsorted)
            {
                if (value.name.length != 0)
                {
                    [colorsArr addObject:@{
                        @"type": [OASettingsTitleTableViewCell getCellIdentifier],
                        @"value": value.name,
                        @"title": value.title
                    }];
                }
            }
        }
        [dataArr addObject:colorsArr];
    }

    _data = dataArr;
}

- (void)setupView
{
    title = _routesSettingType == ERoutesSettingMountain ? OALocalizedString(@"mountain_bike") : _routesParameter.title;

    tblView.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);
    [tblView.tableFooterView removeFromSuperview];
    tblView.tableFooterView = nil;
    [tblView registerClass:OATableViewCustomFooterView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (NSString *)getRenderingStringPropertyDescription:(NSString *)propertyValue
{
    if (!propertyValue)
        return @"";

    NSString *propertyValueReplaced = [propertyValue stringByReplacingOccurrencesOfString:@"\\s+" withString:@"_"];
    NSString *value = OALocalizedString([NSString stringWithFormat:@"rendering_value_%@_description", propertyValueReplaced]);
    return value ? value : propertyValue;
}

- (NSString *)getTextForFooter:(NSInteger)section
{
    if ((_routesSettingType != ERoutesSettingMountain && !_routesEnabled) || section == EOAMapSettingsRoutesSectionVisibility)
        return @"";

    if (_routesSettingType == ERoutesSettingCycle)
    {
        OAMapStyleParameter *cycleNode = [_styleSettings getParameter:CYCLE_NODE_NETWORK_ROUTES_ATTR];
        return [cycleNode.value isEqualToString:@"true"] ? [self getRenderingStringPropertyDescription:@"walkingRoutesOSMCNodes"] : OALocalizedString(@"walking_route_osmc_description");
    }
    else if (_routesParameters)
    {
        if (_routesSettingType == ERoutesSettingMountain)
            return [self getRenderingStringPropertyDescription:_routesParameters[section].name];
    }

    return [self getRenderingStringPropertyDescription:_routesParameter.value];
}

- (CGFloat)getFooterHeightForSection:(NSInteger)section
{
    return [OATableViewCustomFooterView getHeight:[self getTextForFooter:section] width:tblView.frame.size.width];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_routesSettingType != ERoutesSettingMountain && section != EOAMapSettingsRoutesSectionVisibility && !_routesEnabled)
        return 0;

    return _data[section].count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OASettingSwitchCell getCellIdentifier]])
    {
        OASettingSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASettingSwitchCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingSwitchCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingSwitchCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.descriptionView.hidden = YES;
        }
        if (cell)
        {
            BOOL isMountain = _routesSettingType == ERoutesSettingMountain;
            BOOL enabled = isMountain ? [item[@"value"] boolValue] : _routesEnabled;
            cell.textView.text = isMountain ? item[@"title"] : enabled ? OALocalizedString(@"shared_string_enabled") : OALocalizedString(@"rendering_value_disabled_name");
            NSString *imgName = isMountain ? item[@"icon"] : enabled ? @"ic_custom_show.png" : @"ic_custom_hide.png";
            cell.imgView.image = [UIImage templateImageNamed:imgName];
            cell.imgView.tintColor = enabled ? isMountain ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_dialog_buttons_dark) : UIColorFromRGB(color_tint_gray);

            [cell.switchView setOn:enabled];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OASettingsTitleTableViewCell getCellIdentifier]])
    {
        OASettingsTitleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTitleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTitleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingsTitleTableViewCell *) nib[0];
        }
        if (cell)
        {
            BOOL selected;
            if (_routesSettingType == ERoutesSettingCycle)
            {
                OAMapStyleParameter *cycleNode = [_styleSettings getParameter:CYCLE_NODE_NETWORK_ROUTES_ATTR];
                selected = [cycleNode.value isEqualToString:item[@"value"]];
            }
            else
            {
                selected = [_routesParameter.value isEqualToString:item[@"value"]];
            }

            cell.textView.text = item[@"title"];
            [cell.iconView setImage:selected ? [UIImage imageNamed:@"menu_cell_selected"] : nil];
        }
        return cell;
    }

    return nil;
}

#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    return [item[@"type"] isEqualToString:[OASettingsTitleTableViewCell getCellIdentifier]] ? indexPath : nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OASettingsTitleTableViewCell getCellIdentifier]])
        [self onItemClicked:indexPath];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if (_routesSettingType != ERoutesSettingMountain && section == EOAMapSettingsRoutesSectionColors && _routesEnabled)
    {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *) view;
        header.textLabel.textColor = UIColorFromRGB(color_text_footer);
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (_routesSettingType == ERoutesSettingMountain)
        return kHeaderHeightDefault;
    else if (!_routesEnabled || section == EOAMapSettingsRoutesSectionVisibility)
        return 0.01;

    return 56.0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (_routesSettingType == ERoutesSettingMountain || !_routesEnabled || section == EOAMapSettingsRoutesSectionVisibility)
        return @"";

    return OALocalizedString(@"routes_color_by_type");
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return [self getFooterHeightForSection:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if ((_routesSettingType != ERoutesSettingMountain && !_routesEnabled) || section == EOAMapSettingsRoutesSectionVisibility)
        return nil;

    OATableViewCustomFooterView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
    NSString *text = [self getTextForFooter:section];
    vw.label.text = text;
    return vw;
}

#pragma mark - Selectors

- (void)applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        [tblView beginUpdates];
        UISwitch *sw = (UISwitch *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        if (_routesSettingType == ERoutesSettingMountain)
        {
            _routesParameters[indexPath.section].value = sw.on ? @"true" : @"false";
            [_styleSettings save:_routesParameters[indexPath.section]];
            [self initData];
        }
        else
        {
            _routesEnabled = sw.on;
            
            if (_routesEnabled)
            {
                if (_routesSettingType == ERoutesSettingCycle)
                    _routesParameter.value = @"true";
                else if (_routesSettingType == ERoutesSettingHiking)
                    _routesParameter.value = @"walkingRoutesOSMC";
            }
            else
            {
                if (_routesSettingType == ERoutesSettingCycle)
                {
                    _routesParameter.value = @"false";
                    OAMapStyleParameter *cycleNode = [_styleSettings getParameter:CYCLE_NODE_NETWORK_ROUTES_ATTR];
                    cycleNode.value = @"false";
                    [_styleSettings save:cycleNode];
                }
                else if (_routesSettingType == ERoutesSettingHiking)
                {
                    _routesParameter.value = @"disabled";
                }
                else if (_routesSettingType == ERoutesSettingTravel)
                {
                }
            }
            [_styleSettings save:_routesParameter];
        }

        [tblView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [tblView reloadSections:[NSIndexSet indexSetWithIndex:EOAMapSettingsRoutesSectionColors] withRowAnimation:UITableViewRowAnimationAutomatic];
        [tblView endUpdates];
    }
}

- (void)onItemClicked:(NSIndexPath *)indexPath
{
    NSString *value = [self getItem:indexPath][@"value"];
    if (_routesSettingType == ERoutesSettingCycle)
    {
        OAMapStyleParameter *cycleNode = [_styleSettings getParameter:CYCLE_NODE_NETWORK_ROUTES_ATTR];
        if (![cycleNode.value isEqualToString:value])
        {
            cycleNode.value = value;
            [_styleSettings save:cycleNode];
        }
        if (![_routesParameter.value isEqualToString:@"true"])
        {
            _routesParameter.value = @"true";
            [_styleSettings save:_routesParameter];
        }
    }
    else
    {
        if (![_routesParameter.value isEqualToString:value])
        {
            _routesParameter.value = value;
            [_styleSettings save:_routesParameter];
        }
    }
    [UIView setAnimationsEnabled:NO];
    [tblView reloadSections:[NSIndexSet indexSetWithIndex:EOAMapSettingsRoutesSectionColors] withRowAnimation:UITableViewRowAnimationNone];
    [UIView setAnimationsEnabled:YES];
}

@end
