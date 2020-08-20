//
//  OACoordinatesFormatViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 02.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OACoordinatesFormatViewController.h"
#import "OASettingsTitleTableViewCell.h"
#import "OAAppSettings.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OsmAndApp.h"
#import "OALocationConvert.h"
#import "OATableViewCustomFooterView.h"

#import "Localization.h"
#import "OAColors.h"

#define kCellTypeTitleCheck @"OASettingsTitleCell"
#define kFooterId @"TableViewSectionFooter"

@interface OACoordinatesFormatViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OACoordinatesFormatViewController
{
    NSArray<NSDictionary *> *_data;
    OAAppSettings *_settings;
}

- (instancetype) initWithMode:(OAApplicationMode *)applicationMode
{
    self = [super initWithAppMode:applicationMode];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
    }
    return self;
}

- (void) applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"coords_format");
    self.subtitleLabel.text = self.appMode.toHumanString;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:OATableViewCustomFooterView.class forHeaderFooterViewReuseIdentifier:kFooterId];
    [self setupView];
}

- (void) setupView
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    CLLocation *location = [OsmAndApp instance].locationServices.lastKnownLocation;
    if (!location)
        location = mapPanel.mapViewController.getMapLocation;
    double lat = location.coordinate.latitude;
    double lon = location.coordinate.longitude;
    _data = @[
        @{
        @"name" : @"navigate_point_format_D",
        @"title" : OALocalizedString(@"navigate_point_format_D"),
        @"selected" : @([_settings.settingGeoFormat get:self.appMode] == MAP_GEO_FORMAT_DEGREES),
        @"description" : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"coordinates_example"), [OALocationConvert formatLocationCoordinates:lat lon:lon format:FORMAT_DEGREES]],
        @"type" : kCellTypeTitleCheck,
    },
    @{
        @"name" : @"navigate_point_format_DM",
        @"title" : OALocalizedString(@"navigate_point_format_DM"),
        @"selected" : @([_settings.settingGeoFormat get:self.appMode] == MAP_GEO_FORMAT_MINUTES),
        @"description" : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"coordinates_example"), [OALocationConvert formatLocationCoordinates:lat lon:lon format:FORMAT_MINUTES]],
        @"type" : kCellTypeTitleCheck,
    },
    @{
       @"name" : @"navigate_point_format_DMS",
       @"title" : OALocalizedString(@"navigate_point_format_DMS"),
       @"selected" : @([_settings.settingGeoFormat get:self.appMode] == MAP_GEO_FORMAT_SECONDS),
       @"description" : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"coordinates_example"), [OALocationConvert formatLocationCoordinates:lat lon:lon format:FORMAT_SECONDS]],
       @"type" : kCellTypeTitleCheck,
    },
    @{
        @"name" : @"utm_format",
        @"title" : OALocalizedString(@"UTM"),
        @"selected" : @([_settings.settingGeoFormat get:self.appMode] == MAP_GEO_UTM_FORMAT),
        @"description" : [NSString stringWithFormat:@"%@: %@\n%@\n%@\n", OALocalizedString(@"coordinates_example"), [OALocationConvert getUTMCoordinateString:lat lon:lon], OALocalizedString(@"utm_description"), OALocalizedString(@"shared_string_read_more")],
        @"url" : @"https://en.wikipedia.org/wiki/Universal_Transverse_Mercator_coordinate_system",
        @"type" : kCellTypeTitleCheck,
    },
    @{
       @"name" : @"olc_format",
       @"title" : OALocalizedString(@"navigate_point_format_OLC"),
       @"selected" : @([_settings.settingGeoFormat get:self.appMode] == MAP_GEO_OLC_FORMAT),
       @"description" : [NSString stringWithFormat:@"%@: %@. %@\n", OALocalizedString(@"coordinates_example"), [OALocationConvert getLocationOlcName:lat lon:lon], OALocalizedString(@"shared_string_read_more")],
       @"url" : @"https://en.wikipedia.org/wiki/Open_Location_Code",
       @"icon" : @"ic_custom_direction_compass",
       @"type" : kCellTypeTitleCheck,
    }];
}

- (NSDictionary *) getItem:(NSInteger )section
{
    return _data[section];
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = [self getItem:indexPath.section];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:kCellTypeTitleCheck])
    {
        static NSString* const identifierCell = kCellTypeTitleCheck;
        OASettingsTitleTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.iconView.image = [[UIImage imageNamed:@"ic_checkmark_default"]  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.iconView.hidden = ![item[@"selected"] boolValue];
        }
        return cell;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 17.0;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSDictionary *item = [self getItem:section];
    NSString *text = item[@"description"];
    NSString *url = item[@"url"];
    OATableViewCustomFooterView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kFooterId];
    if (url)
    {
        NSURL *URL = [NSURL URLWithString:url];
        UIFont *textFont = [UIFont systemFontOfSize:13];
        NSMutableAttributedString * str = [[NSMutableAttributedString alloc] initWithString:url attributes:@{NSFontAttributeName : textFont}];
        [str addAttribute:NSLinkAttributeName value:URL range: NSMakeRange(0, str.length)];
        text = [text stringByAppendingString:@""];
        NSMutableAttributedString *textStr = [[NSMutableAttributedString alloc] initWithString:text
                                                                                    attributes:@{NSFontAttributeName : textFont,
                                                                                                 NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer)}];
        [textStr appendAttributedString:str];
        vw.label.attributedText = textStr;
    }
    else
    {
        vw.label.text = text;
    }
    return vw;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    NSDictionary *item = [self getItem:section];
    NSString *text = item[@"description"];
    NSString *url = item[@"url"];
    return [OATableViewCustomFooterView getHeight:url ? [NSString stringWithFormat:@"%@ %@", text, url] : text width:tableView.bounds.size.width];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath.section];
    [self selectSettingGeoCode:item[@"name"]];
    [self setupView];
    [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self backButtonClicked:self];
}

- (void) selectSettingGeoCode:(NSString *)name
{
    if ([name isEqualToString:@"navigate_point_format_D"])
        [_settings.settingGeoFormat set:MAP_GEO_FORMAT_DEGREES mode:self.appMode];
    else if ([name isEqualToString:@"navigate_point_format_DM"])
        [_settings.settingGeoFormat set:MAP_GEO_FORMAT_MINUTES mode:self.appMode];
    else if ([name isEqualToString:@"navigate_point_format_DMS"])
        [_settings.settingGeoFormat set:MAP_GEO_FORMAT_SECONDS mode:self.appMode];
    else if ([name isEqualToString:@"utm_format"])
        [_settings.settingGeoFormat set:MAP_GEO_UTM_FORMAT mode:self.appMode];
    else if ([name isEqualToString:@"olc_format"])
        [_settings.settingGeoFormat set:MAP_GEO_OLC_FORMAT mode:self.appMode];
}

@end
