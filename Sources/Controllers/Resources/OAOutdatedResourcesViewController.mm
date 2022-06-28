//
//  OAOutdatedResourcesViewController.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/28/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAOutdatedResourcesViewController.h"
#import <Reachability.h>
#import <UIAlertView+Blocks.h>
#import "Localization.h"
#import "OAColors.h"
#import "OASubscriptionBannerCardView.h"
#import "OAChoosePlanHelper.h"
#import "OAIAPHelper.h"

@interface OAOutdatedResourcesViewController () <UITableViewDelegate, UITableViewDataSource, OASubscriptionBannerCardViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *updateAllButton;

@end

@implementation OAOutdatedResourcesViewController
{
    OsmAndAppInstance _app;
    NSObject* _dataLock;

    QHash< QString, std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource> > _outdatedResources;
    NSMutableArray* _resourcesItems;

    CALayer *_horizontalLine;
    OASubscriptionBannerCardView *_subscriptionBannerView;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _app = [OsmAndApp instance];

        _dataLock = [[NSObject alloc] init];
    }
    return self;
}

- (void)setupWithRegion:(OAWorldRegion*)region
       andOutdatedItems:(NSArray*)items
{
    self.region = region;
    _resourcesItems = [NSMutableArray arrayWithArray:items];
}

-(void)applyLocalization
{
    [super applyLocalization];
    
    _titleView.text = OALocalizedString(@"res_updates");
    [_updateAllButton setTitle:OALocalizedString(@"res_update_all") forState:UIControlStateNormal];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem* refreshAllBarButton = [[UIBarButtonItem alloc] initWithTitle:OALocalizedString(@"res_update_all")
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:self
                                                                           action:@selector(onUpdateAllBarButtonClicked)];
    self.navigationItem.rightBarButtonItem = refreshAllBarButton;
    
    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [UIColorFromRGB(kBottomToolbarTopLineColor) CGColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self applySafeAreaMargins];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:OAIAPProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsRequested:) name:OAIAPProductsRequestSucceedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productRestored:) name:OAIAPProductsRestoredNotification object:nil];

    [self setupSubscriptionBanner];

    [self.tableView reloadData];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    _horizontalLine.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, 0.5);
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self setupSubscriptionBanner];
    } completion:nil];
}

- (void)setupSubscriptionBanner
{
    BOOL isPaid = [OAIAPHelper isPaidVersion];
    if (!isPaid && !_subscriptionBannerView)
    {
        _subscriptionBannerView = [[OASubscriptionBannerCardView alloc] initWithType:EOASubscriptionBannerUpdates];
        _subscriptionBannerView.delegate = self;

        _subscriptionBannerView.titleLabel.text = OALocalizedString(@"subscription_banner_osmand_pro_title");
        _subscriptionBannerView.iconView.image = [UIImage templateImageNamed:@"ic_custom_osmand_pro_logo_monotone_big"];
        _subscriptionBannerView.iconView.tintColor = UIColorFromRGB(color_banner_button);

        NSMutableAttributedString *buttonTitle = [[NSMutableAttributedString alloc] initWithString:OALocalizedString(@"purchase_get")];
        [buttonTitle addAttribute:NSForegroundColorAttributeName
                            value:UIColorFromRGB(color_primary_purple)
                            range:NSMakeRange(0, buttonTitle.string.length)];
        [buttonTitle addAttribute:NSFontAttributeName
                            value:[UIFont systemFontOfSize:15. weight:UIFontWeightSemibold]
                            range:NSMakeRange(0, buttonTitle.string.length)];
        [_subscriptionBannerView.buttonView setAttributedTitle:buttonTitle forState:UIControlStateNormal];
    }
    else if (isPaid)
    {
        _subscriptionBannerView = nil;
    }

    if (_subscriptionBannerView)
        [_subscriptionBannerView layoutSubviews];

    self.tableView.tableHeaderView = _subscriptionBannerView ? _subscriptionBannerView : [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
}

-(UIView *) getTopView
{
    return _navBarView;
}

-(UIView *) getMiddleView
{
    return _tableView;
}

-(IBAction)backButtonClicked:(id)sender;
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (UITableView *)getTableView
{
    return self.tableView;
}

- (void)updateContent
{
    [self obtainDataAndItems];
    [self refreshContent:YES];
}

- (void)refreshContent:(BOOL)update;
{
    @synchronized(_dataLock)
    {
        [self.tableView reloadData];
    }
}

- (void)obtainDataAndItems
{
    @synchronized(_dataLock)
    {
        [self prepareData];
        [self collectResourcesDataAndItems];
    }
}

- (void)prepareData
{
    // Obtain all resources separately

    // IOS-199
    _outdatedResources = _app.resourcesManager->getOutdatedInstalledResources();
}

- (void)collectResourcesDataAndItems
{
    [_resourcesItems removeAllObjects];
    for (const auto& resource : _outdatedResources)
    {
        OAWorldRegion *match = [OAResourcesUIHelper findRegionOrAnySubregionOf:self.region
                                                          thatContainsResource:resource->id];
        if (!match)
            continue;

        OAOutdatedResourceItem* item = [[OAOutdatedResourceItem alloc] init];
        item.resourceId = resource->id;
        item.title = [OAResourcesUIHelper titleOfResource:resource
                                                 inRegion:match
                                           withRegionName:YES
                                         withResourceType:NO];
        item.resource = resource;
        item.downloadTask = [self getDownloadTaskFor:resource->id.toNSString()];
        item.worldRegion = match;
        item.resourceType = resource->type;

        const auto resourceInRepository = _app.resourcesManager->getResourceInRepository(item.resourceId);
        item.size = resourceInRepository->size;
        item.sizePkg = resourceInRepository->packageSize;
        item.date = [NSDate dateWithTimeIntervalSince1970:(resourceInRepository->timestamp / 1000)];

        if (item.title == nil)
            continue;

        [_resourcesItems addObject:item];
    }
    [_resourcesItems sortUsingComparator:self.resourceItemsComparator];
}

- (void)offerDownloadAndUpdateMultiple:(NSArray*)items
{
    uint64_t totalDownloadSize = 0;
    uint64_t totalSpaceNeeded = 0;
    for (OAOutdatedResourceItem* item in items)
    {
        const auto resourceInRepository = _app.resourcesManager->getResourceInRepository(item.resourceId);

        totalDownloadSize += resourceInRepository->packageSize;
        totalSpaceNeeded += resourceInRepository->packageSize + resourceInRepository->size;
    }

    if (_app.freeSpaceAvailableOnDevice < totalSpaceNeeded)
    {
        NSString* stringifiedSize = [NSByteCountFormatter stringFromByteCount:totalSpaceNeeded
                                                                   countStyle:NSByteCountFormatterCountStyleFile];

        [[[UIAlertView alloc] initWithTitle:nil
                                    message:[NSString stringWithFormat:OALocalizedString(@"res_updates_no_space"),
                                                              [items count],
                                                              stringifiedSize]
                           cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_ok")]
                           otherButtonItems:nil] show];
        return;
    }

    NSString* stringifiedSize = [NSByteCountFormatter stringFromByteCount:totalDownloadSize
                                                               countStyle:NSByteCountFormatterCountStyleFile];

    NSMutableString* message  = [[NSString stringWithFormat:@"%d %@",
                                  [items count],
                                  OALocalizedString(@"res_updates_avail_q")] mutableCopy];
    
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == ReachableViaWWAN)
    {
        [message appendString:@" "];
        [message appendString:[NSString stringWithFormat:OALocalizedString(@"prch_nau_q2_cell"), stringifiedSize]];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"incur_high_charges")];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"proceed_q")];
    }
    else
    {
        [message appendString:@" "];
        [message appendString:[NSString stringWithFormat:OALocalizedString(@"prch_nau_q2_wifi"), stringifiedSize]];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"proceed_q")];
    }

    [[[UIAlertView alloc] initWithTitle:nil
                                message:message
                       cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_cancel")]
                       otherButtonItems:[RIButtonItem itemWithLabel:OALocalizedString(@"res_update_all")
                                                             action:^{
                                                                 for (OAOutdatedResourceItem* item in items)
                                                                 {
                                                                     const auto resourceInRepository = _app.resourcesManager->getResourceInRepository(item.resourceId);
                                                                     
                                                                     NSString *resourceName = [OAResourcesUIHelper titleOfResource:item.resource inRegion:item.worldRegion withRegionName:YES withResourceType:YES];

                                                                     [self startDownloadOf:resourceInRepository resourceName:resourceName];
                                                                 }
                                                             }], nil] show];
}

- (IBAction)updateAllClicked:(id)sender
{
    [self onUpdateAllBarButtonClicked];
}

- (void)onUpdateAllBarButtonClicked
{
    NSMutableArray* resourcesToUpdate = [NSMutableArray array];
    BOOL needPurchaseAny = NO;
    @synchronized(_dataLock)
    {
        for (OAOutdatedResourceItem* item in _resourcesItems)
        {
            BOOL needPurchase = (item.worldRegion.regionId != nil && ![item.worldRegion isInPurchasedArea]);
            if (!needPurchaseAny && needPurchase)
                needPurchaseAny = YES;
            
            if (item.downloadTask != nil || needPurchase)
                continue;

            [resourcesToUpdate addObject:item];
        }
    }
    if ([resourcesToUpdate count] == 0)
    {
        if (needPurchaseAny)
        {
            [[[UIAlertView alloc] initWithTitle:nil message:OALocalizedString(@"res_updates_exp") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles: nil] show];
        }
        return;
    }

    if ([resourcesToUpdate count] == 1)
        [self offerDownloadAndUpdateOf:[resourcesToUpdate firstObject]];
    else
        [self offerDownloadAndUpdateMultiple:resourcesToUpdate];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_resourcesItems count];
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return OALocalizedStringUp(@"res_updates");
}

-(void)updateDownloadingCellAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
    
    OAResourceItem* item = (OAResourceItem*)[_resourcesItems objectAtIndex:indexPath.row];
    if (item.downloadTask == nil)
        return;
    
    if (cell.accessoryView && [cell.accessoryView isKindOfClass:FFCircularProgressView.class])
    {
        FFCircularProgressView* progressView = (FFCircularProgressView*)cell.accessoryView;
        
        float progressCompleted = item.downloadTask.progressCompleted;
        if (progressCompleted >= 0.0f && item.downloadTask.state == OADownloadTaskStateRunning)
        {
            [progressView stopSpinProgressBackgroundLayer];
            progressView.progress = progressCompleted;
        }
        else if (item.downloadTask.state == OADownloadTaskStateFinished)
        {
            [progressView stopSpinProgressBackgroundLayer];
            progressView.progress = 1.0f;
        }
        else
        {
            if (!progressView.isSpinning)
                [progressView startSpinProgressBackgroundLayer];
        }
    }
}


- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const outdatedResourceCell = @"outdatedResourceCell";
    static NSString* const downloadingResourceCell = @"downloadingResourceCell";

    NSString* cellTypeId = nil;
    NSString* title = nil;

    OAResourceItem* item = (OAResourceItem*)[_resourcesItems objectAtIndex:indexPath.row];
    if (item.downloadTask != nil)
        cellTypeId = downloadingResourceCell;
    else if ([item isKindOfClass:[OAOutdatedResourceItem class]])
        cellTypeId = outdatedResourceCell;

    if (item.worldRegion && item.worldRegion.superregion)
    {
        NSString *countryName = [OAResourcesUIHelper getCountryName:item];
        if (countryName)
            title = [NSString stringWithFormat:@"%@ - %@", countryName, item.title];
        else
            title = item.title;
    }
    else
    {
        title = item.title;
    }

    // Obtain reusable cell or create one
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellTypeId];
    if (cell == nil)
    {
        if ([cellTypeId isEqualToString:outdatedResourceCell])
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:cellTypeId];
            cell.textLabel.font = [UIFont systemFontOfSize:17.0];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0];
            cell.detailTextLabel.textColor = [UIColor darkGrayColor];
            UIImage* iconImage = [UIImage templateImageNamed:@"ic_custom_import"];
            cell.accessoryView = [[UIImageView alloc] initWithImage:iconImage];
            [cell.accessoryView setTintColor:UIColorFromRGB(color_primary_purple)];
        }
        else if ([cellTypeId isEqualToString:downloadingResourceCell])
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:cellTypeId];
            cell.textLabel.font = [UIFont systemFontOfSize:17.0];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0];
            cell.detailTextLabel.textColor = [UIColor darkGrayColor];

            FFCircularProgressView* progressView = [[FFCircularProgressView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 25.0f, 25.0f)];
            progressView.iconView = [[UIView alloc] init];

            cell.accessoryView = progressView;
        }
    }

    // Try to allocate cell from own table, since it may be configured there
    if (cell == nil)
        cell = [self.tableView dequeueReusableCellWithIdentifier:cellTypeId];

    // Fill cell content
    cell.textLabel.text = title;
    if (cell.detailTextLabel != nil)
    {
        if (item.sizePkg > 0)
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@  •  %@", [OAResourceType resourceTypeLocalized:item.resourceType], [NSByteCountFormatter stringFromByteCount:item.sizePkg countStyle:NSByteCountFormatterCountStyleFile]];
        else
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [OAResourceType resourceTypeLocalized:item.resourceType]];
    }
    
    //[NSString stringWithFormat:@"%@  •  %@", [OAResourceType resourceTypeLocalized:item.resourceType]
    
    if ([cellTypeId isEqualToString:downloadingResourceCell])
    {
        if (cell.accessoryView && [cell.accessoryView isKindOfClass:FFCircularProgressView.class])
        {
            FFCircularProgressView* progressView = (FFCircularProgressView*)cell.accessoryView;

            float progressCompleted = item.downloadTask.progressCompleted;
            if (progressCompleted >= 0.0f && item.downloadTask.state == OADownloadTaskStateRunning)
            {
                [progressView stopSpinProgressBackgroundLayer];
                progressView.progress = progressCompleted;
            }
            else if (item.downloadTask.state == OADownloadTaskStateFinished)
            {
                [progressView stopSpinProgressBackgroundLayer];
                progressView.progress = 1.0f;
            }
            else
            {
                if (!progressView.isSpinning)
                    [progressView startSpinProgressBackgroundLayer];
            }
        }
    }

    return cell;
}

#pragma mark - UITableViewDelegate

/*
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.1f;
}
*/

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    id item = [_resourcesItems objectAtIndex:indexPath.row];

    if (item == nil)
        return;

    [self onItemClicked:item];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = [_resourcesItems objectAtIndex:indexPath.row];

    if (item != nil)
        [self onItemClicked:item];

    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

#pragma mark -

- (void)refreshDownloadingContent:(NSString *)downloadTaskKey
{
    @synchronized(_dataLock)
    {
        for (int i = 0; i < _resourcesItems.count; i++) {
            if ([_resourcesItems[i] isKindOfClass:[OAWorldRegion class]])
                continue;
            OAResourceItem *item = _resourcesItems[i];
            if ([[item.downloadTask key] isEqualToString:downloadTaskKey]) {
                [self updateDownloadingCellAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                break;
            }
        }
    }
}

- (void) productsRequested:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateContent];
        [self.tableView reloadData];
        CATransition *animation = [CATransition animation];
        [animation setType:kCATransitionPush];
        [animation setSubtype:kCATransitionFromBottom];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        [animation setFillMode:kCAFillModeBoth];
        [animation setDuration:.3];
        [[self.tableView layer] addAnimation:animation forKey:@"UITableViewReloadDataAnimationKey"];
    });
}

- (void) productPurchased:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateContent];
        [self setupSubscriptionBanner];
        [self.tableView reloadData];
    });
}

- (void) productRestored:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateContent];
        [self setupSubscriptionBanner];
        [self.tableView reloadData];
    });
}

#pragma mark - OASubscriptionBannerCardViewDelegate

- (void) onButtonPressed
{
    [OAChoosePlanHelper showChoosePlanScreen:self.navigationController];
}

@end
