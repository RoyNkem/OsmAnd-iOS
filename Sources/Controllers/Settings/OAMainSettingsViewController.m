//
//  OAMainSettingsViewController.m
//  OsmAnd
//
//  Created by Paul on 07.30.2020
//  Copyright (c) 2020 OsmAnd. All rights reserved.
//

#import "OAMainSettingsViewController.h"
#import "OAIconTitleValueCell.h"
#import "OAMultiIconTextDescCell.h"
#import "OASwitchTableViewCell.h"
#import "OATitleRightIconCell.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OAApplicationMode.h"
#import "OsmAndApp.h"
#import "OAColors.h"
#import "OAAutoObserverProxy.h"
#import "OAPurchasesViewController.h"
#import "OABackupHelper.h"
#import "OASizes.h"
#import "OACreateProfileViewController.h"
#import "OARearrangeProfilesViewController.h"
#import "OAProfileNavigationSettingsViewController.h"
#import "OAProfileGeneralSettingsViewController.h"
#import "OAGlobalSettingsViewController.h"
#import "OAConfigureProfileViewController.h"
#import "OAExportItemsViewController.h"
#import "OACloudIntroductionViewController.h"
#import "OACloudBackupViewController.h"

#define kAppModesSection 2

@interface OAMainSettingsViewController () <UIDocumentPickerDelegate>

@end

@implementation OAMainSettingsViewController
{
    NSArray<NSArray *> *_data;
    OAAppSettings *_settings;
    
    OAAutoObserverProxy* _appModesAvailabilityChangeObserver;
    OAAutoObserverProxy* _appModeChangedObservable;
    
    OAApplicationMode *_targetAppMode;
    NSString *_targetScreenKey;
}

- (instancetype) initWithTargetAppMode:(OAApplicationMode *)mode targetScreenKey:(NSString *)targetScreenKey
{
    self = [super init];
    if (self)
    {
        _targetAppMode = mode;
        _targetScreenKey = targetScreenKey;
    }
    return self;
}

- (void) applyLocalization
{
    _titleView.text = OALocalizedString(@"sett_settings");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.settingsTableView.rowHeight = UITableViewAutomaticDimension;
    self.settingsTableView.estimatedRowHeight = kEstimatedRowHeight;
    
    _settings = OAAppSettings.sharedManager;
    
    _appModesAvailabilityChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                       withHandler:@selector(onAvailableAppModesChanged)
                                                        andObserve:[OsmAndApp instance].availableAppModesChangedObservable];
    
    _appModeChangedObservable = [[OAAutoObserverProxy alloc] initWith:self
                                                          withHandler:@selector(onAvailableAppModesChanged)
                                                           andObserve:OsmAndApp.instance.data.applicationModeChangedObservable];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.settingsTableView setDataSource: self];
    [self.settingsTableView setDelegate:self];
    self.settingsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.settingsTableView setSeparatorInset:UIEdgeInsetsMake(0.0, 16.0, 0.0, 0.0)];
    [self setupView];

    if (_targetAppMode)
    {
        OAConfigureProfileViewController *profileConf = [[OAConfigureProfileViewController alloc] initWithAppMode:_targetAppMode
                                                                                                  targetScreenKey:_targetScreenKey];
        [self.navigationController pushViewController:profileConf animated:YES];
        _targetAppMode = nil;
        _targetScreenKey = nil;
    }
}

- (void)dealloc
{
    [_appModesAvailabilityChangeObserver detach];
    [_appModeChangedObservable detach];
}

- (void) setupView
{
    OAAppSettings* settings = [OAAppSettings sharedManager];
    OAApplicationMode *appMode = settings.applicationMode.get;
    NSMutableArray *data = [NSMutableArray new];
    
    [data addObject:@[
        @{
            @"name" : @"osmand_settings",
            @"title" : OALocalizedString(@"osmand_settings"),
            @"description" : OALocalizedString(@"global_settings_descr"),
            @"img" : @"left_menu_icon_settings",
            @"type" : [OAIconTitleValueCell getCellIdentifier]
        },
        @{
            @"name" : @"backup_restore",
            @"title" : OALocalizedString(@"osmand_cloud"),
            @"value" : @"", // TODO: insert value
            @"description" : OALocalizedString(@"global_settings_descr"),
            @"img" : @"ic_custom_cloud_upload_colored_day",
            @"type" : [OAIconTitleValueCell getCellIdentifier]
        },
        @{
            @"name" : @"purchases",
            @"title" : OALocalizedString(@"purchases"),
            @"description" : OALocalizedString(@"global_settings_descr"),
            @"img" : @"ic_custom_shop_bag",
            @"type" : [OAIconTitleValueCell getCellIdentifier]
        }
    ]];
    
    [data addObject:@[
        @{
            @"name" : @"current_profile",
            @"app_mode" : appMode,
            @"type" : [OAMultiIconTextDescCell getCellIdentifier],
            @"isColored" : @YES
        }
    ]];
    
    NSMutableArray *profilesSection = [NSMutableArray new];
    for (int i = 0; i < OAApplicationMode.allPossibleValues.count; i++)
    {
        [profilesSection addObject:@{
            @"name" : @"profile_val",
            @"app_mode" : OAApplicationMode.allPossibleValues[i],
            @"type" : i == 0 ? [OAMultiIconTextDescCell getCellIdentifier] : [OASwitchTableViewCell getCellIdentifier],
            @"isColored" : @NO
        }];
    }
    
    [profilesSection addObject:@{
        @"title" : OALocalizedString(@"new_profile"),
        @"img" : @"ic_custom_add",
        @"type" : [OATitleRightIconCell getCellIdentifier],
        @"name" : @"add_profile"
    }];

    [profilesSection addObject:@{
        @"title" : OALocalizedString(@"edit_profile_list"),
        @"img" : @"ic_custom_edit",
        @"type" : [OATitleRightIconCell getCellIdentifier],
        @"name" : @"edit_profiles"
    }];
    
    [data addObject:profilesSection];
    
    [data addObject:[self getLocalBackupSectionData]];
    
    _data = [NSArray arrayWithArray:data];
}

- (NSArray *)getLocalBackupSectionData
{
    return @[
        @{
            @"type": OATitleRightIconCell.getCellIdentifier,
            @"name": @"backupIntoFile",
            @"title": OALocalizedString(@"backup_into_file"),
            @"img": @"ic_custom_save_to_file",
            @"regular_text": @(YES)
        },
        @{
            @"type": OATitleRightIconCell.getCellIdentifier,
            @"name": @"restoreFromFile",
            @"title": OALocalizedString(@"restore_from_file"),
            @"img": @"ic_custom_read_from_file",
            @"regular_text": @(YES)
        }
    ];
}

- (NSString *) getProfileDescription:(OAApplicationMode *)am
{
    return am.isCustomProfile ? OALocalizedString(@"profile_type_custom_string") : OALocalizedString(@"profile_type_base_string");
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (void) onAppModeSwitchChanged:(UISwitch *)sender
{
    if (sender.tag < OAApplicationMode.allPossibleValues.count)
    {
        OAApplicationMode *am = OAApplicationMode.allPossibleValues[sender.tag];
        [OAApplicationMode changeProfileAvailability:am isSelected:sender.isOn];
    }
}

- (void)onAvailableAppModesChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupView];
        [self.settingsTableView reloadData];
    });
}

- (void)onBackupIntoFilePressed
{
    OAExportItemsViewController *exportController = [[OAExportItemsViewController alloc] init];
    [self.navigationController pushViewController:exportController animated:YES];
}

- (void)onRestoreFromFilePressed
{
    UIDocumentPickerViewController *documentPickerVC = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"net.osmand.osf"] inMode:UIDocumentPickerModeImport];
    documentPickerVC.allowsMultipleSelection = NO;
    documentPickerVC.delegate = self;
    [self presentViewController:documentPickerVC animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = item[@"type"];
    if ([type isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.rightIconView.image = [UIImage templateImageNamed:@"ic_custom_arrow_right"].imageFlippedForRightToLeftLayoutDirection;
            cell.rightIconView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.leftIconView.tintColor = UIColorFromRGB(color_primary_purple);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
            cell.leftIconView.image = [item[@"name"] isEqualToString:@"backup_restore"] ? [UIImage imageNamed:item[@"img"]] : [UIImage templateImageNamed:item[@"img"]];
        }
        return cell;
    }
    else if ([type isEqualToString:[OAMultiIconTextDescCell getCellIdentifier]])
    {
        OAMultiIconTextDescCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAMultiIconTextDescCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMultiIconTextDescCell getCellIdentifier] owner:self options:nil];
            cell = (OAMultiIconTextDescCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 62.0, 0.0, 0.0);
            [cell setOverflowVisibility:YES];
            cell.textView.numberOfLines = 3;
            cell.textView.lineBreakMode = NSLineBreakByTruncatingTail;
        }
        OAApplicationMode *am = item[@"app_mode"];
        UIImage *img = am.getIcon;
        cell.iconView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.iconView.tintColor = UIColorFromRGB(am.getIconColor);
        cell.textView.text = am.toHumanString;
        cell.descView.text = [self getProfileDescription:am];
        cell.contentView.backgroundColor = UIColor.clearColor;
        if ([item[@"isColored"] boolValue])
            cell.backgroundColor = [UIColorFromRGB(am.getIconColor) colorWithAlphaComponent:0.1];
        else
            cell.backgroundColor = UIColor.whiteColor;
        return cell;
    }
    else if ([type isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        OAApplicationMode *am = item[@"app_mode"];
        BOOL isEnabled = [OAApplicationMode.values containsObject:am];
        cell.separatorInset = UIEdgeInsetsMake(0.0, indexPath.row < OAApplicationMode.allPossibleValues.count - 1 ? kPaddingToLeftOfContentWithIcon : 0.0, 0.0, 0.0);
        UIImage *img = am.getIcon;
        cell.leftIconView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.leftIconView.tintColor = isEnabled ? UIColorFromRGB(am.getIconColor) : UIColorFromRGB(color_tint_gray);
        cell.titleLabel.text = am.toHumanString;
        cell.descriptionLabel.text = [self getProfileDescription:am];
        cell.switchView.tag = indexPath.row;
        BOOL isDefault = am == OAApplicationMode.DEFAULT;
        [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        if (!isDefault)
        {
            [cell.switchView setOn:isEnabled];
            [cell.switchView addTarget:self action:@selector(onAppModeSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        }
        [cell switchVisibility:!isDefault];
        [cell dividerVisibility:!isDefault];
        return cell;
    }
    else if ([type isEqualToString:[OATitleRightIconCell getCellIdentifier]])
    {
        OATitleRightIconCell* cell = [tableView dequeueReusableCellWithIdentifier:[OATitleRightIconCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleRightIconCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleRightIconCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 16.0, 0.0, 0.0);
            cell.titleView.textColor = UIColorFromRGB(color_primary_purple);
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.titleView.font = [UIFont systemFontOfSize:17. weight:UIFontWeightSemibold];
        }
        if ([item[@"regular_text"] boolValue])
        {
            cell.titleView.textColor = UIColor.blackColor;
            cell.titleView.font = [UIFont systemFontOfSize:17.];
        }
        else
        {
            cell.titleView.textColor = UIColorFromRGB(color_primary_purple);
            cell.titleView.font = [UIFont systemFontOfSize:17. weight:UIFontWeightSemibold];
        }
        cell.titleView.text = item[@"title"];
        [cell.iconView setImage:[UIImage templateImageNamed:item[@"img"]]];
        return cell;
    }
    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1)
        return OALocalizedString(@"selected_profile");
    else if (section == 2)
        return OALocalizedString(@"app_profiles");
    else if (section == 3)
        return OALocalizedString(@"local_backup");
    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0)
        return OALocalizedString(@"global_settings_descr");
    else if (section == 2)
        return OALocalizedString(@"import_profile_descr");
    else if (section == 3)
        return OALocalizedString(@"local_backup_descr");
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
    [footer.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    [self selectSettingMain:item];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) selectSettingMain:(NSDictionary *)item
{
    NSString *name = item[@"name"];
    if ([name isEqualToString:@"osmand_settings"])
    {
        OAGlobalSettingsViewController* globalSettingsViewController = [[OAGlobalSettingsViewController alloc] initWithSettingsType:EOAGlobalSettingsMain];
        [self.navigationController pushViewController:globalSettingsViewController animated:YES];
    }
    else if ([name isEqualToString:@"backup_restore"])
    {
        UIViewController *vc;
        if (OABackupHelper.sharedInstance.isRegistered)
            vc = [[OACloudBackupViewController alloc] init];
        else
            vc = [[OACloudIntroductionViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if ([name isEqualToString:@"purchases"])
    {
        OAPurchasesViewController *purchasesViewController = [[OAPurchasesViewController alloc] init];
        [self.navigationController pushViewController:purchasesViewController animated:YES];
    }
    else if ([name isEqualToString:@"profile_val"] || [name isEqualToString:@"current_profile"])
    {
        OAApplicationMode *mode = item[@"app_mode"];
        OAConfigureProfileViewController *profileConf = [[OAConfigureProfileViewController alloc] initWithAppMode:mode
                                                                                                  targetScreenKey:nil];
        [self.navigationController pushViewController:profileConf animated:YES];
    }
    else if ([name isEqualToString:@"add_profile"])
    {
        OACreateProfileViewController* createProfileViewController = [[OACreateProfileViewController alloc] init];
        [self.navigationController pushViewController:createProfileViewController animated:YES];
    }
    else if ([name isEqualToString:@"edit_profiles"])
    {
        OARearrangeProfilesViewController* rearrangeProfilesViewController = [[OARearrangeProfilesViewController alloc] init];
        [self.navigationController pushViewController:rearrangeProfilesViewController animated:YES];
    }
    else if ([name isEqualToString:@"backupIntoFile"])
    {
        [self onBackupIntoFilePressed];
    }
    else if ([name isEqualToString:@"restoreFromFile"])
    {
        [self onRestoreFromFilePressed];
    }
}

// MARK: UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls
{
    if (urls.count == 0)
        return;
    
    NSString *path = urls[0].path;
    NSString *extension = [[path pathExtension] lowercaseString];
    if ([extension caseInsensitiveCompare:@"osf"] == NSOrderedSame)
        [OASettingsHelper.sharedInstance collectSettings:urls[0].path latestChanges:@"" version:1];
}

@end
