//
//  OACloudBackupViewController.m
//  OsmAnd Maps
//
//  Created by Yuliia Stetsenko on 19.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OACloudBackupViewController.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAFilledButtonCell.h"
#import "OATwoFilledButtonsTableViewCell.h"
#import "OALargeImageTitleDescrTableViewCell.h"
#import "OATitleRightIconCell.h"
#import "OAIAPHelper.h"
#import "OABackupHelper.h"
#import "OAButtonRightIconCell.h"
#import "OAMultiIconTextDescCell.h"
#import "OAIconTitleValueCell.h"
#import "OATitleIconProgressbarCell.h"
#import "OAValueTableViewCell.h"
#import "OATitleDescrRightIconTableViewCell.h"
#import "OAMainSettingsViewController.h"
#import "OARestoreBackupViewController.h"
#import "OANetworkSettingsHelper.h"
#import "OAPrepareBackupResult.h"
#import "OABackupInfo.h"
#import "OABackupStatus.h"
#import "OAAppSettings.h"
#import "OAChoosePlanHelper.h"
#import "OAOsmAndFormatter.h"
#import "OABackupError.h"
#import "OASettingsBackupViewController.h"
#import "OAExportSettingsType.h"
#import "OABaseBackupTypesViewController.h"
#import "OAStatusBackupViewController.h"
#import "OAExportBackupTask.h"
#import "OAAppVersionDependentConstants.h"
#import "OsmAndApp.h"

#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface OACloudBackupViewController () <UITableViewDelegate, UITableViewDataSource, OABackupExportListener, OAImportListener, OAOnPrepareBackupListener, OABackupTypesDelegate, MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *navBarBackgroundView;
@property (weak, nonatomic) IBOutlet UILabel *navBarTitle;
@property (weak, nonatomic) IBOutlet UIButton *backImgButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
@property (weak, nonatomic) IBOutlet UITableView *tblView;

@end

@implementation OACloudBackupViewController
{
    NSArray<NSDictionary *> *_data;
    OANetworkSettingsHelper *_settingsHelper;
    OABackupHelper *_backupHelper;
    
    EOACloudScreenSourceType _sourceType;
    OAPrepareBackupResult *_backup;
    OABackupInfo *_info;
    OABackupStatus *_status;
    NSString *_error;
    
    OATitleIconProgressbarCell *_backupProgressCell;
    NSIndexPath *_lastBackupIndexPath;
}

- (instancetype) initWithSourceType:(EOACloudScreenSourceType)type
{
    self = [self init];
    if (self) {
        _sourceType = type;
    }
    return self;
}

- (instancetype)init
{
    self = [super initWithNibName:@"OACloudBackupViewController" bundle:nil];
    if (self) {
        _sourceType = EOACloudScreenSourceTypeDirect;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[OAIAPHelper sharedInstance] checkBackupPurchase];
    _settingsHelper = OANetworkSettingsHelper.sharedInstance;
    _backupHelper = OABackupHelper.sharedInstance;
    self.tblView.refreshControl = [[UIRefreshControl alloc] init];
    [self.tblView.refreshControl addTarget:self action:@selector(onRefresh) forControlEvents:UIControlEventValueChanged];
    if (!_settingsHelper.isBackupExporting)
    {
        [_settingsHelper updateExportListener:self];
        [_settingsHelper updateImportListener:self];
        [_backupHelper addPrepareBackupListener:self];
        [_backupHelper prepareBackup];
    }

    self.tblView.delegate = self;
    self.tblView.dataSource = self;
    self.tblView.estimatedRowHeight = 44.;
    self.tblView.rowHeight = UITableViewAutomaticDimension;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self generateData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_settingsHelper updateExportListener:self];
    [_settingsHelper updateImportListener:self];
    [_backupHelper addPrepareBackupListener:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_settingsHelper updateExportListener:nil];
    [_settingsHelper updateImportListener:nil];
    [_backupHelper removePrepareBackupListener:self];
}

- (void)applyLocalization
{
    self.navBarTitle.text = OALocalizedString(@"backup_and_restore");
}

- (void) onRefresh
{
    if (!_settingsHelper.isBackupExporting)
    {
        [_settingsHelper updateExportListener:self];
        [_settingsHelper updateImportListener:self];
        [_backupHelper addPrepareBackupListener:self];
        [_backupHelper prepareBackup];
    }
    else
    {
        [self.tblView.refreshControl endRefreshing];
    }
}

- (void)generateData
{
    NSMutableArray<NSDictionary *> *result = [NSMutableArray array];
    
    if (!_status)
        _status = [OABackupStatus getBackupStatus:_backup];
    
    BOOL backupSaved = _backup.remoteFiles.count != 0;
    BOOL showIntroductionItem = _info != nil && ((_sourceType == EOACloudScreenSourceTypeSignUp && !backupSaved)
                    || (_sourceType == EOACloudScreenSourceTypeSignIn && (backupSaved || _backup.localFiles.count > 0)));
    
    if (showIntroductionItem)
    {
        if (_sourceType == EOACloudScreenSourceTypeSignIn)
        {
            // Existing backup case
            NSMutableArray<NSDictionary *> *existingBackupRows = [NSMutableArray array];
            [existingBackupRows addObject:@{
                @"cellId": OALargeImageTitleDescrTableViewCell.getCellIdentifier,
                @"name": @"existingOnlineBackup",
                @"title": OALocalizedString(@"cloud_welcome_back"),
                @"description": OALocalizedString(@"cloud_description"),
                @"image": @"ic_action_cloud_smile_face_colored"
            }];
            BOOL showBothButtons = [self shouldShowBackupButton] && [self shouldShowRestoreButton];
            if (showBothButtons)
            {
                [existingBackupRows addObject:@{
                    @"cellId": OATwoFilledButtonsTableViewCell.getCellIdentifier,
                    @"name": @"backupAndRestore",
                    @"topTitle": OALocalizedString(@"cloud_restore_now"),
                    @"bottomTitle": OALocalizedString(@"cloud_set_up_backup")
                }];
            }
            if ([self shouldShowRestoreButton] && !showBothButtons)
            {
                [existingBackupRows addObject:@{
                    @"cellId": OAFilledButtonCell.getCellIdentifier,
                    @"name": @"onRestoreButtonPressed",
                    @"title": OALocalizedString(@"cloud_restore_now")
                }];
            }
            if ([self shouldShowBackupButton] && !showBothButtons)
            {
                [existingBackupRows addObject:@{
                    @"cellId": OAFilledButtonCell.getCellIdentifier,
                    @"name": @"onSetUpBackupButtonPressed",
                    @"title": OALocalizedString(@"cloud_set_up_backup")
                }];
            }
            NSDictionary *backupSection = @{
                @"sectionHeader": OALocalizedString(@"cloud_backup"),
                @"rows": existingBackupRows
            };
            [result addObject:backupSection];
        }
        else if (_sourceType == EOACloudScreenSourceTypeSignUp)
        {
            // No backup case
            NSMutableArray<NSDictionary *> *noBackupRows = [NSMutableArray array];
            [noBackupRows addObject:@{
                @"cellId": OALargeImageTitleDescrTableViewCell.getCellIdentifier,
                @"name": @"noOnlineBackup",
                @"title": OALocalizedString(@"cloud_no_online_backup"),
                @"description": OALocalizedString(@"cloud_no_online_backup_descr"),
                @"image": @"ic_custom_cloud_neutral_face_colored"
            }];
            
            if ([self shouldShowBackupButton])
            {
                [noBackupRows addObject:@{
                    @"cellId": OAFilledButtonCell.getCellIdentifier,
                    @"name": @"onSetUpBackupButtonPressed",
                    @"title": OALocalizedString(@"cloud_set_up_backup")
                }];
            }
            NSDictionary *backupSection = @{
                @"sectionHeader": OALocalizedString(@"cloud_backup"),
                @"rows": noBackupRows
            };
            [result addObject:backupSection];
        }
    }
    else
    {
        NSMutableArray<NSDictionary *> *backupRows = [NSMutableArray array];
        NSDictionary *backupSection = @{
            @"sectionHeader": OALocalizedString(@"cloud_backup"),
            @"rows": backupRows
        };
        [result addObject:backupSection];

        OAExportBackupTask *exportTask = [_settingsHelper getExportTask:kBackupItemsKey];
        if (exportTask)
        {
            // TODO: show progress from HeaderStatusViewHolder.java
            _backupProgressCell = [self getProgressBarCell];
            NSDictionary *backupProgressCell = @{
                @"cellId": OATitleIconProgressbarCell.getCellIdentifier,
                @"cell": _backupProgressCell
            };
            [backupRows addObject:backupProgressCell];
        }
        else
        {
            NSString *backupTime = [OAOsmAndFormatter getFormattedPassedTime:OAAppSettings.sharedManager.backupLastUploadedTime.get def:OALocalizedString(@"shared_string_never")];
            NSDictionary *lastBackupCell = @{
                @"cellId": OAMultiIconTextDescCell.getCellIdentifier,
                @"name": @"lastBackup",
                @"title": _status.statusTitle,
                @"description": backupTime,
                @"image": _status.statusIconName,
                @"imageColor": @(_status.iconColor)
            };
            [backupRows addObject:lastBackupCell];
            _lastBackupIndexPath = [NSIndexPath indexPathForRow:backupRows.count - 1 inSection:result.count - 1];

            if (_status.warningTitle != nil || _error.length > 0)
            {
                BOOL hasWarningStatus = _status.warningTitle != nil;
                BOOL hasDescr = _error || _status.warningDescription;
                NSString *descr = hasDescr && hasWarningStatus ? _status.warningDescription : [_error stringByAppendingFormat:@"\n%@", OALocalizedString(@"error_contact_support")];
                NSInteger color = _status == OABackupStatus.CONFLICTS || _status == OABackupStatus.ERROR ? _status.iconColor
                        : _status == OABackupStatus.MAKE_BACKUP ? profile_icon_color_green_light : -1;
                NSDictionary *makeBackupWarningCell = @{
                    @"cellId": OATitleDescrRightIconTableViewCell.getCellIdentifier,
                    @"name": @"makeBackupWarning",
                    @"title": hasWarningStatus ? _status.warningTitle : OALocalizedString(@"osm_failed_uploads"),
                    @"description": descr ? descr : @"",
                    @"imageColor": @(color),
                    @"image": _status.warningIconName
                };
                [backupRows addObject:makeBackupWarningCell];
            }
        }
        BOOL hasInfo = _info != nil;
        BOOL noConflicts = _status == OABackupStatus.CONFLICTS && (!hasInfo || _info.filteredFilesToMerge.count == 0);
        BOOL noChanges = _status == OABackupStatus.MAKE_BACKUP && (!hasInfo || (_info.filteredFilesToUpload.count == 0 && _info.filteredFilesToDelete.count == 0));
        BOOL actionButtonHidden = _status == OABackupStatus.BACKUP_COMPLETE || noConflicts || noChanges;
        if (!actionButtonHidden)
        {
            if (_settingsHelper.isBackupExporting)
            {
                NSDictionary *cancellCell = @{
                    @"cellId": OAButtonRightIconCell.getCellIdentifier,
                    @"name": @"cancellBackupPressed",
                    @"title": OALocalizedString(@"shared_string_cancel"),
                    @"image": @"ic_custom_cancel"
                };
                [backupRows addObject:cancellCell];
            }
            else if (_status == OABackupStatus.MAKE_BACKUP)
            {
                NSDictionary *backupNowCell = @{
                    @"cellId": OAButtonRightIconCell.getCellIdentifier,
                    @"name": @"onSetUpBackupButtonPressed",
                    @"title": OALocalizedString(@"cloud_backup_now"),
                    @"image": @"ic_custom_cloud_upload"
                };
                [backupRows addObject:backupNowCell];
            }
            else if (_status == OABackupStatus.CONFLICTS)
            {
                NSDictionary *conflictsCell = @{
                    @"cellId": OAValueTableViewCell.getCellIdentifier,
                    @"name": @"viewConflictsCell",
                    @"title": OALocalizedString(@"cloud_view_conflicts"),
                    @"value": @(_info.filteredFilesToMerge.count)
                };
                [backupRows addObject:conflictsCell];
            }
            else if (_status == OABackupStatus.NO_INTERNET_CONNECTION)
            {
                NSDictionary *retryCell = @{
                    @"cellId": OAButtonRightIconCell.getCellIdentifier,
                    @"name": @"onRetryPressed",
                    @"title": _status.actionTitle,
                    @"image": @"ic_custom_reset"
                };
                [backupRows addObject:retryCell];
            }
            else if (_status == OABackupStatus.ERROR)
            {
                NSDictionary *retryCell = @{
                    @"cellId": OAButtonRightIconCell.getCellIdentifier,
                    @"name": @"onSupportPressed",
                    @"title": _status.actionTitle,
                    @"image": @"ic_custom_letter_outlined"
                };
                [backupRows addObject:retryCell];
            }
            else if (_status == OABackupStatus.SUBSCRIPTION_EXPIRED)
            {
                NSDictionary *purchaseCell = @{
                    @"cellId": OAButtonRightIconCell.getCellIdentifier,
                    @"name": @"onSubscriptionExpired",
                    @"title": _status.actionTitle,
                    @"image": @"ic_custom_osmand_pro_logo_colored"
                };
                [backupRows addObject:purchaseCell];
            }
        }
    }
    NSDictionary *restoreSection = @{
        @"sectionHeader" : OALocalizedString(@"restore"),
        @"sectionFooter" : OALocalizedString(@"restore_backup_descr"),
        @"rows" : @[@{
            @"cellId": OAButtonRightIconCell.getCellIdentifier,
            @"name": @"onRestoreButtonPressed",
            @"title": OALocalizedString(@"restore_data"),
            @"image": @"ic_custom_restore"
        }]
    };
    [result addObject:restoreSection];

//    // View conflicts cell
//    NSDictionary *viewConflictsCell = @{
//        @"cellId": OAIconTitleValueCell.getCellIdentifier,
//        @"name": @"viewConflicts",
//        @"title": OALocalizedString(@"cloud_view_conflicts"),
//        @"value": @"13" // TODO: insert conflicts count
//    };
    [result addObject:[self getLocalBackupSectionData]];
    _data = result;
}

- (OATitleIconProgressbarCell *) getProgressBarCell
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleIconProgressbarCell getCellIdentifier] owner:self options:nil];
    OATitleIconProgressbarCell *resultCell = (OATitleIconProgressbarCell *)[nib objectAtIndex:0];
    [resultCell.progressBar setProgress:0.0 animated:NO];
    [resultCell.progressBar setProgressTintColor:UIColorFromRGB(color_primary_purple)];
    resultCell.textView.text = [OALocalizedString(@"osm_edit_uploading") stringByAppendingString:[NSString stringWithFormat:@"%i%%", 0]];
    resultCell.imgView.image = [UIImage templateImageNamed:@"ic_custom_cloud_upload"];
    resultCell.imgView.tintColor = UIColorFromRGB(color_primary_purple);
    resultCell.selectionStyle = UITableViewCellSelectionStyleNone;
    resultCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return resultCell;
}

- (BOOL) shouldShowBackupButton
{
    return _backup.localFiles.count > 0;
}

- (BOOL) shouldShowRestoreButton
{
    return _backup.remoteFiles.count > 0;
}

- (void) refreshContent
{
    [self generateData];
    [self.tblView reloadData];
}

- (IBAction)onBackButtonPressed
{
    for (UIViewController *controller in self.navigationController.viewControllers)
    {
        if ([controller isKindOfClass:[OAMainSettingsViewController class]])
        {
            [self.navigationController popToViewController:controller animated:YES];
            return;
        }
    }

    [self dismissViewController];
}

- (IBAction)onSettingsButtonPressed
{
    OASettingsBackupViewController *settingsBackupViewController = [[OASettingsBackupViewController alloc] init];
    settingsBackupViewController.backupTypesDelegate = self;
    [self.navigationController pushViewController:settingsBackupViewController animated:YES];
}

- (void)onSetUpBackupButtonPressed
{
    @try
    {
        NSArray<OASettingsItem *> *items = _info.itemsToUpload;
        if (items.count > 0 || _info.filteredFilesToDelete.count > 0)
        {
            [_settingsHelper exportSettings:kBackupItemsKey items:items itemsToDelete:_info.itemsToDelete listener:self];
            [self refreshContent];
        }
    }
    @catch (NSException *e)
    {
        NSLog(@"Backup generation error: %@", e.reason);
    }
}

- (void) onViewConflictsPressed
{
    OAStatusBackupViewController *statusBackupViewController = [[OAStatusBackupViewController alloc] initWithBackup:_backup status:_status openConflicts:YES];
    statusBackupViewController.delegate = self;
    [self.navigationController pushViewController:statusBackupViewController animated:YES];
}

- (void)onRetryPressed
{
    [_backupHelper prepareBackup];
}

- (void)onSupportPressed
{
    [self sendEmail];
}

- (void) cancellBackupPressed
{
    [_settingsHelper cancelImport];
    [_settingsHelper cancelExport];
}

- (void) onSubscriptionExpired
{
    [OAChoosePlanHelper showChoosePlanScreenWithFeature:OAFeature.OSMAND_CLOUD navController:self.navigationController];
}

- (void)onRestoreButtonPressed
{
    OARestoreBackupViewController *restoreVC = [[OARestoreBackupViewController alloc] init];
    [self.navigationController pushViewController:restoreVC animated:YES];
}

// MARK: UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _data[section][@"sectionHeader"];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return _data[section][@"sectionFooter"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ((NSArray *)_data[section][@"rows"]).count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][@"rows"][indexPath.row];
    NSString *cellId = item[@"cellId"];
    if ([cellId isEqualToString:OATitleRightIconCell.getCellIdentifier])
    {
        OATitleRightIconCell* cell = [tableView dequeueReusableCellWithIdentifier:OATitleRightIconCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleRightIconCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleRightIconCell *)[nib objectAtIndex:0];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.titleView.font = [UIFont systemFontOfSize:17.];
        }
        cell.titleView.text = item[@"title"];
        [cell.iconView setImage:[UIImage templateImageNamed:item[@"image"]]];
        return cell;
    }
    else if ([cellId isEqualToString:OALargeImageTitleDescrTableViewCell.getCellIdentifier])
    {
        OALargeImageTitleDescrTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:OALargeImageTitleDescrTableViewCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OALargeImageTitleDescrTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OALargeImageTitleDescrTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
            [cell showButton:NO];
        }
        cell.titleLabel.text = item[@"title"];
        cell.descriptionLabel.text = item[@"description"];
        [cell.cellImageView setImage:[UIImage imageNamed:item[@"image"]]];

        if (cell.needsUpdateConstraints)
            [cell updateConstraints];

        return cell;
    }
    else if ([cellId isEqualToString:OAValueTableViewCell.getCellIdentifier])
    {
        OAValueTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:OAValueTableViewCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *)[nib objectAtIndex:0];
            cell.titleLabel.textColor = UIColorFromRGB(color_primary_purple);
            cell.titleLabel.font = [UIFont systemFontOfSize:17. weight:UIFontWeightMedium];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        cell.titleLabel.text = item[@"title"];
        cell.valueLabel.text = [item[@"value"] stringValue];

        return cell;
    }
    else if ([cellId isEqualToString:OAFilledButtonCell.getCellIdentifier])
    {
        OAFilledButtonCell* cell = [tableView dequeueReusableCellWithIdentifier:OAFilledButtonCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAFilledButtonCell getCellIdentifier] owner:self options:nil];
            cell = (OAFilledButtonCell *)[nib objectAtIndex:0];
            cell.button.backgroundColor = UIColorFromRGB(color_primary_purple);
            [cell.button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
            cell.button.titleLabel.font = [UIFont systemFontOfSize:15. weight:UIFontWeightSemibold];
            cell.button.layer.cornerRadius = 9.;
            cell.topMarginConstraint.constant = 9.;
            cell.bottomMarginConstraint.constant = 20.;
            cell.heightConstraint.constant = 42.;
            cell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
        }
        [cell.button setTitle:item[@"title"] forState:UIControlStateNormal];
        [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [cell.button addTarget:self action:NSSelectorFromString(item[@"name"]) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
    else if ([cellId isEqualToString:OATwoFilledButtonsTableViewCell.getCellIdentifier])
    {
        OATwoFilledButtonsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:OATwoFilledButtonsTableViewCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATwoFilledButtonsTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATwoFilledButtonsTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
        }
        [cell.topButton setTitle:item[@"topTitle"] forState:UIControlStateNormal];
        [cell.topButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [cell.topButton addTarget:self action:@selector(onRestoreButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [cell.bottomButton setTitle:item[@"bottomTitle"] forState:UIControlStateNormal];
        [cell.bottomButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [cell.bottomButton addTarget:self action:@selector(onSetUpBackupButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
    else if ([cellId isEqualToString:OAMultiIconTextDescCell.getCellIdentifier])
    {
        OAMultiIconTextDescCell* cell = [tableView dequeueReusableCellWithIdentifier:OAMultiIconTextDescCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMultiIconTextDescCell getCellIdentifier] owner:self options:nil];
            cell = (OAMultiIconTextDescCell *)[nib objectAtIndex:0];
            [cell setOverflowVisibility:YES];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        cell.textView.text = item[@"title"];
        cell.descView.text = item[@"description"];
        [cell.iconView setImage:[UIImage templateImageNamed:item[@"image"]]];
        cell.iconView.tintColor = [item.allKeys containsObject:@"imageColor"] ? UIColorFromRGB([item[@"imageColor"] integerValue]) : UIColorFromRGB(color_primary_purple);
        return cell;
    }
    else if ([cellId isEqualToString:OAButtonRightIconCell.getCellIdentifier])
    {
        OAButtonRightIconCell* cell = [tableView dequeueReusableCellWithIdentifier:OAButtonRightIconCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAButtonRightIconCell getCellIdentifier] owner:self options:nil];
            cell = (OAButtonRightIconCell *)[nib objectAtIndex:0];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
        }
        [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [cell.button addTarget:self action:NSSelectorFromString(item[@"name"]) forControlEvents:UIControlEventTouchUpInside];
        [cell.button setTitle:item[@"title"] forState:UIControlStateNormal];
        [cell.iconView setImage:[UIImage templateImageNamed:item[@"image"]]];
        return cell;
    }
    else if ([cellId isEqualToString:OATitleDescrRightIconTableViewCell.getCellIdentifier])
    {
        OATitleDescrRightIconTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:OATitleDescrRightIconTableViewCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleDescrRightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleDescrRightIconTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.titleLabel.text = item[@"title"];
        cell.descriptionLabel.text = item[@"description"];
        NSInteger color = [item[@"imageColor"] integerValue];
        if (color != -1)
        {
            cell.iconView.tintColor = UIColorFromRGB(color);
            [cell.iconView setImage:[UIImage templateImageNamed:item[@"image"]]];
        }
        else
        {
            [cell.iconView setImage:[UIImage imageNamed:item[@"image"]]];
        }
        
        return cell;
    }
    else if ([cellId isEqualToString:OAIconTitleValueCell.getCellIdentifier])
    {
        OAIconTitleValueCell* cell = [tableView dequeueReusableCellWithIdentifier:OAIconTitleValueCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
            cell.textView.font = [UIFont systemFontOfSize:17. weight:UIFontWeightMedium];
            cell.textView.textColor = UIColorFromRGB(color_primary_purple);
            cell.descriptionView.font = [UIFont systemFontOfSize:17.];
            cell.descriptionView.textColor = UIColorFromRGB(color_text_footer);
            cell.rightIconView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.rightIconView.image = [UIImage templateImageNamed:@"ic_custom_arrow_right"];
            [cell showLeftIcon:NO];
            [cell showRightIcon:YES];
        }
        cell.textView.text = item[@"title"];
        cell.descriptionView.text = item[@"value"];
        return cell;
    }
    else if ([cellId isEqualToString:OATitleIconProgressbarCell.getCellIdentifier])
    {
        return item[@"cell"];
    }
    return nil;
}

// MARK: UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][@"rows"][indexPath.row];
    NSString *itemId = item[@"name"];
    if (indexPath == _lastBackupIndexPath)
    {
        OAStatusBackupViewController *statusBackupViewController = [[OAStatusBackupViewController alloc] initWithBackup:_backup status:_status];
        statusBackupViewController.delegate = self;
        [self.navigationController pushViewController:statusBackupViewController animated:YES];
    }
    else if ([itemId isEqualToString:@"backupIntoFile"])
    {
        [self onBackupIntoFilePressed];
    }
    else if ([itemId isEqualToString:@"restoreFromFile"])
    {
        [self onRestoreFromFilePressed];
    }
    else if ([itemId isEqualToString:@"viewConflictsCell"])
    {
        [self onViewConflictsPressed];
    }
    else if ([itemId isEqualToString:@"backupNow"])
    {
        
    }
    else if ([itemId isEqualToString:@"retry"])
    {
        
    }
    else if ([itemId isEqualToString:@"viewConflicts"])
    {
        
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

// MARK: OABackupExportListener

- (void)onBackupExportFinished:(nonnull NSString *)error
{
    if (error != nil)
    {
        [self refreshContent];
        [OAUtilities showToast:nil details:[[OABackupError alloc] initWithError:error].getLocalizedError duration:.4 inView:self.view];
    }
    else if (!_settingsHelper.isBackupExporting)
    {
        [_backupHelper prepareBackup];
    }
}

- (void)onBackupExportItemFinished:(nonnull NSString *)type fileName:(nonnull NSString *)fileName
{
    
}

- (void)onBackupExportItemProgress:(nonnull NSString *)type fileName:(nonnull NSString *)fileName value:(NSInteger)value
{
    
}

- (void)onBackupExportItemStarted:(nonnull NSString *)type fileName:(nonnull NSString *)fileName work:(NSInteger)work
{
    
}

- (void)onBackupExportProgressUpdate:(NSInteger)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        OAExportBackupTask *exportTask = [_settingsHelper getExportTask:kBackupItemsKey];
        if (_backupProgressCell && exportTask)
        {
            float progress = (float) exportTask.generalProgress / exportTask.maxProgress;
            progress = progress > 1 ? 1 : progress;
            OAExportBackupTask *exportTask = [_settingsHelper getExportTask:kBackupItemsKey];
            _backupProgressCell.progressBar.progress = (float) exportTask.generalProgress / exportTask.maxProgress;
            _backupProgressCell.textView.text = [OALocalizedString(@"osm_edit_uploading") stringByAppendingString:[NSString stringWithFormat:@"%i%%", (int) (progress * 100)]];
        }
    });
}

- (void)onBackupExportStarted
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshContent];
    });
}

// MARK: OAImportListener

- (void)onImportFinished:(BOOL)succeed needRestart:(BOOL)needRestart items:(NSArray<OASettingsItem *> *)items {
    
}

- (void)onImportItemFinished:(NSString *)type fileName:(NSString *)fileName {
    
}

- (void)onImportItemProgress:(NSString *)type fileName:(NSString *)fileName value:(int)value {
    
}

- (void)onImportItemStarted:(NSString *)type fileName:(NSString *)fileName work:(int)work {
    
}

// MARK: OAOnPrepareBackupListener

- (void)onBackupPrepared:(nonnull OAPrepareBackupResult *)backupResult
{
    _backup = backupResult;
    _info = _backup.backupInfo;
    _status = [OABackupStatus getBackupStatus:_backup];
    _error = _backup.error;
    [self refreshContent];
    self.settingsButton.userInteractionEnabled = YES;
    self.settingsButton.tintColor = UIColor.whiteColor;
    [self.tblView.refreshControl endRefreshing];
}

- (void)onBackupPreparing
{
    // Show progress bar
    [self.tblView.refreshControl layoutIfNeeded];
    [self.tblView.refreshControl beginRefreshing];
    self.settingsButton.userInteractionEnabled = NO;
    self.settingsButton.tintColor = UIColorFromRGB(color_tint_gray);
}

#pragma mark - OABackupTypesDelegate

- (void)onCompleteTasks
{
    [self onBackupPrepared:_backupHelper.backup];
}

- (void)setProgressTotal:(NSInteger)total
{
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)sendEmail
{
    if([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailCont = [[MFMailComposeViewController alloc] init];
        mailCont.mailComposeDelegate = self;
        [mailCont setSubject:OALocalizedString(@"backup_and_restore")];
        NSString *body = [NSString stringWithFormat:@"%@\n%@", _backup.error, [OAAppVersionDependentConstants getAppVersionWithBundle]];
        [mailCont setToRecipients:[NSArray arrayWithObject:OALocalizedString(@"login_footer_email_part")]];
        [mailCont setMessageBody:body isHTML:NO];
        [self presentViewController:mailCont animated:YES completion:nil];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
