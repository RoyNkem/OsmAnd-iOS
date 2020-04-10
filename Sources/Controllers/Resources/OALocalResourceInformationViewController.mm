//
//  OALocalResourceInformationViewController.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/17/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OALocalResourceInformationViewController.h"

#import "OsmAndApp.h"
#include "Localization.h"
#import "OALocalResourceInfoCell.h"
#import "OAButtonCell.h"
#import "OAPurchasesViewController.h"
#import "OAPluginsViewController.h"
#import "OAUtilities.h"
#import "OAMapCreatorHelper.h"
#import "OASQLiteTileSource.h"
#import "OASizes.h"
#import "OAOnlineTilesEditingViewController.h"

typedef OsmAnd::ResourcesManager::LocalResource OsmAndLocalResource;

@interface OALocalResourceInformationViewController ()<UITableViewDelegate, UITableViewDataSource, OATilesEditingViewControllerDelegate> {
    
    NSArray *tableKeys;
    NSArray *tableValues;
    NSArray *tableButtons;
    
    NSDateFormatter *formatter;
    
    NSString *_resourceId;
}

@end

@implementation OALocalResourceInformationViewController
{
    CALayer *_horizontalLine;
}

-(void)applyLocalization
{
    _titleView.text = OALocalizedString(@"res_details");
    
    [_btnToolbarMaps setTitle:OALocalizedString(@"maps") forState:UIControlStateNormal];
    [_btnToolbarPlugins setTitle:OALocalizedString(@"plugins") forState:UIControlStateNormal];
    [_btnToolbarPurchases setTitle:OALocalizedString(@"purchases") forState:UIControlStateNormal];
    [OAUtilities layoutComplexButton:self.btnToolbarMaps];
    [OAUtilities layoutComplexButton:self.btnToolbarPlugins];
    [OAUtilities layoutComplexButton:self.btnToolbarPurchases];
}

-(void)viewDidLoad
{
    [super viewDidLoad];

    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [UIColorFromRGB(kBottomToolbarTopLineColor) CGColor];
    self.toolbarView.backgroundColor = UIColorFromRGB(kBottomToolbarBackgroundColor);
    [self.toolbarView.layer addSublayer:_horizontalLine];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    _horizontalLine.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, 0.5);
    self.tableView.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + 16.0, 0., 0.);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.backButton setImage:self.backButton.imageView.image.imageFlippedForRightToLeftLayoutDirection forState:UIControlStateNormal];
    if (self.regionTitle)
        self.titleView.text = self.regionTitle;

    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self applySafeAreaMargins];
}

-(UIView *) getTopView
{
    return _navBarView;
}

-(UIView *) getMiddleView
{
    return _tableView;
}

-(UIView *) getBottomView
{
    return _toolbarView;
}

-(CGFloat) getToolBarHeight
{
    return defaultToolBarHeight;
}

-(IBAction)backButtonClicked:(id)sender;
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) deleteClicked
{
    if (!_localItem)
        return;
    
    [self.baseController offerDeleteResourceOf:self.localItem executeAfterSuccess:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });
    }];
}

- (void) clearCacheClicked
{
    if (!_localItem)
           return;
       
   [self.baseController offerClearCacheOf:self.localItem executeAfterSuccess:^{
       dispatch_async(dispatch_get_main_queue(), ^{
           if ([_localItem isKindOfClass:[OnlineTilesResourceItem class]])
           {
               [self calculateSizeAndUpdate:(OnlineTilesResourceItem *)_localItem];
           }
           if ([_localItem isKindOfClass:[SqliteDbResourceItem class]])
           {
               [self updateLocalSqliteDbItem:(SqliteDbResourceItem *)_localItem];
           }
       });
   }];
}

- (void) editClicked
{
    OAOnlineTilesEditingViewController *editViewController = [[OAOnlineTilesEditingViewController alloc] initWithLocalItem:_localItem baseController:self.baseController];
    editViewController.delegate = self;
    [self.navigationController pushViewController:editViewController animated:YES];
}

- (void)initWithLocalSqliteDbItem:(SqliteDbResourceItem *)item;
{
    self.localItem = item;
    BOOL isOnlineSql = [OASQLiteTileSource isOnlineTileSource:item.path];
    
    NSMutableArray *tKeys = [NSMutableArray array];
    NSMutableArray *tValues = [NSMutableArray array];
    NSMutableArray *tButtons = [NSMutableArray array];
    
    // Type
    [tKeys addObject:OALocalizedString(@"res_type")];
    [tValues addObject:isOnlineSql ? OALocalizedString(@"online_raster_map") : OALocalizedString(@"offline_raster_map")];
    
    // Size
    [tKeys addObject:OALocalizedString(@"res_size")];
    [tValues addObject:[NSByteCountFormatter stringFromByteCount:item.size countStyle:NSByteCountFormatterCountStyleFile]];
    
    // Timestamp
    NSError *error;
    NSURL *fileUrl = [NSURL fileURLWithPath:item.path];
    NSDate *d;
    [fileUrl getResourceValue:&d forKey:NSURLCreationDateKey error:&error];
    if (!error)
    {
        [tKeys addObject:OALocalizedString(@"res_created_on")];
        
        if (!formatter) {
            formatter = [[NSDateFormatter alloc] init];
            [formatter setDateStyle:NSDateFormatterShortStyle];
            [formatter setTimeStyle:NSDateFormatterShortStyle];
        }
        
        [tValues addObject:[NSString stringWithFormat:@"%@", [formatter stringFromDate:d]]];
        
        if (isOnlineSql)
            [tButtons addObject:@"clear_cache"];
        
        [tButtons addObject:@"edit"];
        [tButtons addObject:@"delete"];
    }
    
    tableKeys = tKeys;
    tableValues = tValues;
    tableButtons = tButtons;
}

- (void)updateLocalSqliteDbItem:(SqliteDbResourceItem *)item
{
    [item updateSize];
    
    NSMutableArray *tKeys = [NSMutableArray array];
    NSMutableArray *tValues = [NSMutableArray array];
    
    [tKeys addObject:OALocalizedString(@"res_type")];
    [tValues addObject:[OASQLiteTileSource isOnlineTileSource:item.path] ? OALocalizedString(@"online_raster_map") : OALocalizedString(@"offline_raster_map")];
    
    [tKeys addObject:OALocalizedString(@"res_size")];
    [tValues addObject:[NSByteCountFormatter stringFromByteCount:item.size countStyle:NSByteCountFormatterCountStyleFile]];
    
    NSError *error;
    NSURL *fileUrl = [NSURL fileURLWithPath:item.path];
    NSDate *d;
    [fileUrl getResourceValue:&d forKey:NSURLCreationDateKey error:&error];
    if (!error)
    {
        [tKeys addObject:OALocalizedString(@"res_created_on")];
        
        if (!formatter) {
            formatter = [[NSDateFormatter alloc] init];
            [formatter setDateStyle:NSDateFormatterShortStyle];
            [formatter setTimeStyle:NSDateFormatterShortStyle];
        }
        
        [tValues addObject:[NSString stringWithFormat:@"%@", [formatter stringFromDate:d]]];
    }
    
    tableKeys = tKeys;
    tableValues = tValues;
    
    [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)initWithLocalOnlineSourceItem:(OnlineTilesResourceItem *)item
{
    self.localItem = item;
    
    NSMutableArray *tKeys = [NSMutableArray array];
    NSMutableArray *tValues = [NSMutableArray array];
    NSMutableArray *tButtons = [NSMutableArray array];
    
    // Type
    [tKeys addObject:OALocalizedString(@"res_type")];
    [tValues addObject:OALocalizedString(@"online_map")];
    
    // Size
    [tKeys addObject:OALocalizedString(@"res_size")];
    [tValues addObject:OALocalizedString(@"calculating_progress")];
    
    [tButtons addObject:@"clear_cache"];
    [tButtons addObject:@"edit"];
    [tButtons addObject:@"delete"];
    
    tableKeys = tKeys;
    tableValues = tValues;
    tableButtons = tButtons;
    
    [self calculateSizeAndUpdate:item];
}

- (void) calculateSizeAndUpdate:(OnlineTilesResourceItem *)item
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSString *size = [NSByteCountFormatter stringFromByteCount:[OAUtilities folderSize:item.path] countStyle:NSByteCountFormatterCountStyleFile];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            NSMutableArray *tKeys = [NSMutableArray array];
            NSMutableArray *tValues = [NSMutableArray array];
            
            // Type
            [tKeys addObject:OALocalizedString(@"res_type")];
            [tValues addObject:OALocalizedString(@"online_map")];
            
            // Size
            [tKeys addObject:OALocalizedString(@"res_size")];
            [tValues addObject:size];
            
            tableKeys = tKeys;
            tableValues = tValues;
            
            [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        });
    });
}

- (void)initWithLocalResourceId:(NSString*)resourceId
{
    [self inflateRootWithLocalResourceId:resourceId forRegion:nil];
}

- (void)initWithLocalResourceId:(NSString*)resourceId
                              forRegion:(OAWorldRegion*)region
{
    [self inflateRootWithLocalResourceId:resourceId forRegion:region];
}


- (void)inflateRootWithLocalResourceId:(NSString*)resourceId
                                      forRegion:(OAWorldRegion*)region
{
    _resourceId = resourceId;
    
    NSMutableArray *tKeys = [NSMutableArray array];
    NSMutableArray *tValues = [NSMutableArray array];
    NSMutableArray *tButtons = [NSMutableArray array];
    
    const auto& resource = [OsmAndApp instance].resourcesManager->getLocalResource(QString::fromNSString(resourceId));
    const auto localResource = std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::LocalResource>(resource);
    if (!resource || !localResource)
        return;
    
    const auto installedResource = std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::InstalledResource>(localResource);

    // Type
    [tKeys addObject:OALocalizedString(@"res_type")];
    [tValues addObject:[OAResourcesUIHelper resourceTypeLocalized:localResource->type]];

    // Size
    [tKeys addObject:OALocalizedString(@"res_size")];
    [tValues addObject:[NSByteCountFormatter stringFromByteCount:localResource->size countStyle:NSByteCountFormatterCountStyleFile]];

    if (installedResource)
    {
        // Timestamp
        NSDate *d = [NSDate dateWithTimeIntervalSince1970:installedResource->timestamp / 1000];
        
        if (!formatter) {
            formatter = [[NSDateFormatter alloc] init];
            [formatter setDateStyle:NSDateFormatterShortStyle];
            [formatter setTimeStyle:NSDateFormatterShortStyle];
        }

        NSString *dateStr = [formatter stringFromDate:d];
        if (dateStr.length > 0)
        {
            [tKeys addObject:OALocalizedString(@"res_created_on")];
            [tValues addObject:[NSString stringWithFormat:@"%@", dateStr]];
        }
        [tButtons addObject:@"delete"];
    }
    
    tableKeys = tKeys;
    tableValues = tValues;
    tableButtons = tButtons;
}

- (OAButtonCell *) getButtonCell:(NSString *)type
{
    static NSString* const identifierCell = @"OAButtonCell";
    OAButtonCell* cell = nil;
    
    cell = [self.tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAButtonCell" owner:self options:nil];
        cell = (OAButtonCell *)[nib objectAtIndex:0];
        [cell showImage:NO];
        [cell.button setTitleColor:[UIColor colorWithRed:87.0/255.0 green:20.0/255.0 blue:204.0/255.0 alpha:1] forState:UIControlStateNormal];
    }
    if (cell)
    {
        [cell.button removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
        if ([type isEqual:@"delete"])
        {
            [cell.button setTitle:OALocalizedString(@"shared_string_delete") forState:UIControlStateNormal];
            [cell.button addTarget:self action:@selector(deleteClicked) forControlEvents:UIControlEventTouchDown];
        }
        else if ([type isEqual:@"clear_cache"])
        {
            [cell.button setTitle:OALocalizedString(@"shared_string_clear_cache") forState:UIControlStateNormal];
            [cell.button addTarget:self action:@selector(clearCacheClicked) forControlEvents:UIControlEventTouchDown];
        }
        else if ([type isEqual:@"edit"])
        {
            [cell.button setTitle:OALocalizedString(@"shared_string_edit") forState:UIControlStateNormal];
            [cell.button addTarget:self action:@selector(editClicked) forControlEvents:UIControlEventTouchDown];
        }
    }
    return cell;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return tableKeys.count;
    else
        return tableButtons.count;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return OALocalizedStringUp(@"res_details");
    else
        return OALocalizedStringUp(@"actions");
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        static NSString* const detailsCell = @"detailsCell";
        
        NSString* title = [tableKeys objectAtIndex:indexPath.row];
        NSString* subtitle = [tableValues objectAtIndex:indexPath.row];
        
        // Obtain reusable cell or create one
        OALocalResourceInfoCell* cell = [tableView dequeueReusableCellWithIdentifier:detailsCell];
        if (cell == nil)
        {
            cell = [[OALocalResourceInfoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:detailsCell];
        }
            
        // Fill cell content
        cell.leftLabelView.text = title;
        cell.rightLabelView.text = subtitle;
        
        return cell;
    }
    else
    {
        return [self getButtonCell:tableButtons[indexPath.row]];
    }
}

#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (IBAction)btnToolbarMapsClicked:(id)sender
{
}

- (IBAction)btnToolbarPluginsClicked:(id)sender
{
    OAPluginsViewController *pluginsViewController = [[OAPluginsViewController alloc] init];
    pluginsViewController.openFromSplash = _openFromSplash;
    [self.navigationController pushViewController:pluginsViewController animated:NO];
}

- (IBAction)btnToolbarPurchasesClicked:(id)sender
{
    OAPurchasesViewController *purchasesViewController = [[OAPurchasesViewController alloc] init];
    purchasesViewController.openFromSplash = _openFromSplash;
    [self.navigationController pushViewController:purchasesViewController animated:NO];
}

#pragma mark - OATilesEditingViewControllerDelegate

- (void) onTileSourceSaved:(LocalResourceItem *)item
{
    if ([item isKindOfClass:SqliteDbResourceItem.class])
    {
        SqliteDbResourceItem *sqlite = (SqliteDbResourceItem *)item;
        self.regionTitle = sqlite.fileName;
        [self initWithLocalSqliteDbItem:sqlite];
    }
    else if ([item isKindOfClass:OnlineTilesResourceItem.class])
    {
        OnlineTilesResourceItem *tileSource = (OnlineTilesResourceItem *)item;
        self.regionTitle = tileSource.title;
        [self initWithLocalOnlineSourceItem:tileSource];
    }
    
    [self.tableView reloadData];
}

@end
