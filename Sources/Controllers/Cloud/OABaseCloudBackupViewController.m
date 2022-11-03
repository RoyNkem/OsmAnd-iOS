//
//  OABaseCloudBackupViewController.m
//  OsmAnd Maps
//
//  Created by Yuliia Stetsenko on 18.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OABaseCloudBackupViewController.h"
#import "Localization.h"
#import "OASettingsHelper.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"

#import "OATitleRightIconCell.h"
#import "OAExportItemsViewController.h"

@interface OABaseCloudBackupViewController () <UIDocumentPickerDelegate>

@end

@implementation OABaseCloudBackupViewController {
    NSString *_titleText;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.backButton.hidden = YES;
    self.backImageButton.hidden = NO;

}

- (void)applyLocalization
{
    _titleText = OALocalizedString(@"backup_and_restore");
}

// TODO: migrate cloud introduction to new model and remove this method
- (NSDictionary *)getLocalBackupSectionData
{
    return @{
        @"sectionHeader": OALocalizedString(@"local_backup"),
        @"sectionFooter": OALocalizedString(@"local_backup_descr"),
        @"rows": @[
            @{
                @"cellId": OATitleRightIconCell.getCellIdentifier,
                @"name": @"backupIntoFile",
                @"title": OALocalizedString(@"backup_into_file"),
                @"image": @"ic_custom_save_to_file"
            },
            @{
                @"cellId": OATitleRightIconCell.getCellIdentifier,
                @"name": @"restoreFromFile",
                @"title": OALocalizedString(@"restore_from_file"),
                @"image": @"ic_custom_read_from_file"
            }
        ]
    };
}

- (OATableSectionData *)getLocalBackupSectionDataObj
{
    OATableSectionData *section = [OATableSectionData sectionData];
    section.headerText = OALocalizedString(@"local_backup");
    section.footerText = OALocalizedString(@"local_backup_descr");
    [section addRowFromDictionary:@{
        kCellTypeKey: OATitleRightIconCell.getCellIdentifier,
        kCellKeyKey: @"backupIntoFile",
        kCellTitleKey: OALocalizedString(@"backup_into_file"),
        kCellIconNameKey: @"ic_custom_save_to_file"
    }];
    [section addRowFromDictionary:@{
        kCellTypeKey: OATitleRightIconCell.getCellIdentifier,
        kCellKeyKey: @"restoreFromFile",
        kCellTitleKey: OALocalizedString(@"restore_from_file"),
        kCellIconNameKey: @"ic_custom_read_from_file"
    }];
    return section;
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
