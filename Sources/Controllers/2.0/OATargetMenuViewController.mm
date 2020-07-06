//
//  OATargetMenuViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"
#import "OAUtilities.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "Localization.h"

#import "OAFavoriteItem.h"
#import "OAFavoriteViewController.h"
#import "OATargetDestinationViewController.h"
#import "OATargetHistoryItemViewController.h"
#import "OAParkingViewController.h"
#import "OAPOIViewController.h"
#import "OAWikiMenuViewController.h"
#import "OAGPXItemViewController.h"
#import "OAGPXEditItemViewController.h"
#import "OAGPXEditWptViewController.h"
#import "OAGPXWptViewController.h"
#import "OARouteTargetViewController.h"
#import "OARouteTargetSelectionViewController.h"
#import "OAImpassableRoadViewController.h"
#import "OAImpassableRoadSelectionViewController.h"
#import "OARouteDetailsViewController.h"
#import "OAGPXRouteViewController.h"
#import "OAMyLocationViewController.h"
#import "OATransportStopViewController.h"
#import "OATransportStopRoute.h"
#import "OATransportRouteController.h"
#import "OAOsmEditTargetViewController.h"
#import "OAOsmNotesOnlineTargetViewController.h"
#import "OARouteDetailsGraphViewController.h"
#import "OAChangePositionViewController.h"
#import "OATrsansportRouteDetailsViewController.h"
#import "OASizes.h"
#import "OAPointDescription.h"
#import "OAWorldRegion.h"
#import "OAManageResourcesViewController.h"
#import "OAResourcesUIHelper.h"
#import "Reachability.h"
#import "OAIAPHelper.h"
#import "OARootViewController.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

@implementation OATargetMenuViewControllerState

@end

@implementation OATargetMenuControlButton

@end

@interface OATargetMenuViewController ()

@property (nonatomic) RepositoryResourceItem *localMapIndexItem;

@end

@implementation OATargetMenuViewController
{
    OsmAndAppInstance _app;
    
    
    
    OAAutoObserverProxy* _downloadTaskProgressObserver;
    OAAutoObserverProxy* _downloadTaskCompletedObserver;
}

+ (OATargetMenuViewController *) createMenuController:(OATargetPoint *)targetPoint activeTargetType:(OATargetPointType)activeTargetType activeViewControllerState:(OATargetMenuViewControllerState *)activeViewControllerState headerOnly:(BOOL)headerOnly
{
    double lat = targetPoint.location.latitude;
    double lon = targetPoint.location.longitude;
    OATargetMenuViewController *controller = nil;
    switch (targetPoint.type)
    {
        case OATargetFavorite:
        {
            OAFavoriteItem *item = [[OAFavoriteItem alloc] init];
            for (const auto& favLoc : [OsmAndApp instance].favoritesCollection->getFavoriteLocations())
            {
                double favLon = OsmAnd::Utilities::get31LongitudeX(favLoc->getPosition31().x);
                double favLat = OsmAnd::Utilities::get31LatitudeY(favLoc->getPosition31().y);
                
                if ([OAUtilities isCoordEqual:lat srcLon:lon destLat:favLat destLon:favLon])
                {
                    item.favorite = favLoc;
                    break;
                }
            }
            
            if (item.favorite)
                controller = [[OAFavoriteViewController alloc] initWithItem:item headerOnly:headerOnly];
            
            break;
        }
            
        case OATargetDestination:
        {
            controller = [[OATargetDestinationViewController alloc] initWithDestination:targetPoint.targetObj];
            break;
        }
            
        case OATargetHistoryItem:
        {
            controller = [[OATargetHistoryItemViewController alloc] initWithHistoryItem:targetPoint.targetObj];
            break;
        }
            
        case OATargetParking:
        {
            if (targetPoint.targetObj)
                controller = [[OAParkingViewController alloc] initWithParking:targetPoint.targetObj];
            else
                controller = [[OAParkingViewController alloc] initWithCoordinate:CLLocationCoordinate2DMake(lat, lon)];
            break;
        }
            
        case OATargetMyLocation:
        {
            controller = [[OAMyLocationViewController alloc] init];
            break;
        }
            
        case OATargetPOI:
        {
            controller = [[OAPOIViewController alloc] initWithPOI:targetPoint.targetObj];
            break;
        }

        case OATargetTransportStop:
        {
            controller = [[OATransportStopViewController alloc] initWithTransportStop:targetPoint.targetObj];
            break;
        }

        case OATargetTransportRoute:
        {
            controller = [[OATransportRouteController alloc] initWithTransportRoute:targetPoint.targetObj];
            break;
        }
        case OATargetOsmNote:
        case OATargetOsmEdit:
        {
            controller = [[OAOsmEditTargetViewController alloc] initWithOsmPoint:targetPoint.targetObj icon:targetPoint.icon];
            break;
        }
        case OATargetOsmOnlineNote:
        {
            controller = [[OAOsmNotesOnlineTargetViewController alloc] initWithNote:targetPoint.targetObj icon:nil];
            break;
        }
        case OATargetWiki:
        {
            NSString *contentLocale = [[OAAppSettings sharedManager] settingPrefMapLanguage];
            if (!contentLocale)
                contentLocale = [OAUtilities currentLang];
            
            NSString *content = [targetPoint.localizedContent objectForKey:contentLocale];
            if (!content)
            {
                contentLocale = @"";
                content = [targetPoint.localizedContent objectForKey:contentLocale];
            }
            if (!content && targetPoint.localizedContent.count > 0)
            {
                contentLocale = targetPoint.localizedContent.allKeys[0];
                content = [targetPoint.localizedContent objectForKey:contentLocale];
            }
            
            if (content)
                controller = [[OAWikiMenuViewController alloc] initWithPOI:targetPoint.targetObj content:content];
            break;
        }
            
        case OATargetWpt:
        {
            if (activeTargetType == OATargetGPXEdit)
                controller = [[OAGPXEditWptViewController alloc] initWithItem:targetPoint.targetObj headerOnly:headerOnly];
            else
                controller = [[OAGPXWptViewController alloc] initWithItem:targetPoint.targetObj headerOnly:headerOnly];
            break;
        }
            
        case OATargetGPX:
        {
            OAGPXItemViewControllerState *state = activeViewControllerState ? (OAGPXItemViewControllerState *)activeViewControllerState : nil;
            
            if (targetPoint.targetObj)
            {
                if (state)
                {
                    if (state.showCurrentTrack)
                        controller = [[OAGPXItemViewController alloc] initWithCurrentGPXItem:state];
                    else
                        controller = [[OAGPXItemViewController alloc] initWithGPXItem:targetPoint.targetObj ctrlState:state];
                }
                else
                {
                    controller = [[OAGPXItemViewController alloc] initWithGPXItem:targetPoint.targetObj];
                }
            }
            else
            {
                controller = [[OAGPXItemViewController alloc] initWithCurrentGPXItem];
                targetPoint.targetObj = ((OAGPXItemViewController *)controller).gpx;
            }
            break;
        }
            
        case OATargetGPXEdit:
        {
            OAGPXEditItemViewControllerState *state = activeViewControllerState ? (OAGPXEditItemViewControllerState *)activeViewControllerState : nil;
            if (targetPoint.targetObj)
            {
                if (state)
                {
                    if (state.showCurrentTrack)
                        controller = [[OAGPXEditItemViewController alloc] initWithCurrentGPXItem:state];
                    else
                        controller = [[OAGPXEditItemViewController alloc] initWithGPXItem:targetPoint.targetObj ctrlState:state];
                }
                else
                {
                    controller = [[OAGPXEditItemViewController alloc] initWithGPXItem:targetPoint.targetObj];
                }
            }
            else
            {
                controller = [[OAGPXEditItemViewController alloc] initWithCurrentGPXItem];
                targetPoint.targetObj = ((OAGPXItemViewController *)controller).gpx;
            }
            break;
        }
            
        case OATargetRouteStart:
        case OATargetRouteFinish:
        case OATargetRouteIntermediate:
        {
            controller = [[OARouteTargetViewController alloc] initWithTargetPoint:targetPoint.targetObj];
            break;
        }
            
        case OATargetRouteStartSelection:
        {
            controller = [[OARouteTargetSelectionViewController alloc] initWithTargetPointType:OATargetRouteStartSelection];
            break;
        }
            
        case OATargetRouteFinishSelection:
        {
            controller = controller = [[OARouteTargetSelectionViewController alloc] initWithTargetPointType:OATargetRouteFinishSelection];
            break;
        }
            
        case OATargetRouteIntermediateSelection:
        {
            controller = controller = [[OARouteTargetSelectionViewController alloc] initWithTargetPointType:OATargetRouteIntermediateSelection];
            break;
        }
        case OATargetHomeSelection:
        {
            controller = controller = [[OARouteTargetSelectionViewController alloc] initWithTargetPointType:OATargetHomeSelection];
            break;
        }
        case OATargetWorkSelection:
        {
            controller = controller = [[OARouteTargetSelectionViewController alloc] initWithTargetPointType:OATargetWorkSelection];
            break;
        }
        case OATargetImpassableRoad:
        {
            OAAvoidRoadInfo *roadInfo = targetPoint.targetObj;
            controller = [[OAImpassableRoadViewController alloc] initWithRoadInfo:roadInfo];
            break;
        }
            
        case OATargetImpassableRoadSelection:
        {
            controller = [[OAImpassableRoadSelectionViewController alloc] init];
            break;
        }
            
        case OATargetRouteDetails:
        {
            controller = [[OARouteDetailsViewController alloc] initWithGpxData:targetPoint.targetObj];
            break;
        }
            
        case OATargetRouteDetailsGraph:
        {
            controller = [[OARouteDetailsGraphViewController alloc] initWithGpxData:targetPoint.targetObj];
            break;
        }
            
        case OATargetGPXRoute:
        {
            OAGPXRouteViewControllerState *state = activeViewControllerState ? (OAGPXRouteViewControllerState *)activeViewControllerState : nil;
            OAGpxRouteSegmentType segmentType = (OAGpxRouteSegmentType)targetPoint.segmentIndex;
            if (state)
                controller = [[OAGPXRouteViewController alloc] initWithCtrlState:state];
            else
                controller = [[OAGPXRouteViewController alloc] initWithSegmentType:segmentType];
            
            break;
        }
        case OATargetChangePosition:
        {
            controller = [[OAChangePositionViewController alloc] initWithTargetPoint:targetPoint.targetObj];
            break;
        }
        case OATargetTransportRouteDetails:
        {
            controller = [[OATrsansportRouteDetailsViewController alloc] initWithRouteIndex:[targetPoint.targetObj integerValue]];
            break;
        }
            
        default:
        {
        }
    }
    if (controller &&
        targetPoint.type != OATargetImpassableRoad &&
        targetPoint.type != OATargetRouteFinishSelection &&
        targetPoint.type != OATargetRouteStartSelection &&
        targetPoint.type != OATargetRouteIntermediateSelection &&
        targetPoint.type != OATargetWorkSelection &&
        targetPoint.type != OATargetHomeSelection &&
        targetPoint.type != OATargetGPXEdit &&
        targetPoint.type != OATargetGPXRoute &&
        targetPoint.type != OATargetRouteDetails &&
        targetPoint.type != OATargetRouteDetailsGraph &&
        targetPoint.type != OATargetImpassableRoadSelection &&
        targetPoint.type != OATargetChangePosition &&
        targetPoint.type != OATargetTransportRouteDetails)
    {
        [OAResourcesUIHelper requestMapDownloadInfo:targetPoint.location
                                       resourceType:OsmAnd::ResourcesManager::ResourceType::MapRegion
                                         onComplete:^(NSArray<ResourceItem *>* res) {
            if (res.count > 0)
            {
                for (ResourceItem * item in res)
                {
                    if ([item isKindOfClass:LocalResourceItem.class])
                    {
                        controller.localMapIndexItem = nil;
                        [controller createMapDownloadControls];
                        return ;
                    }
                }
                RepositoryResourceItem *item = (RepositoryResourceItem *)res[0];
                BOOL isDownloading = [[OsmAndApp instance].downloadsManager.keysOfDownloadTasks containsObject:[NSString stringWithFormat:@"resource:%@", item.resourceId.toNSString()]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (controller.delegate && [controller.delegate respondsToSelector:@selector(showProgressBar)] && isDownloading)
                        [controller.delegate showProgressBar];
                    else if (controller.delegate && [controller.delegate respondsToSelector:@selector(hideProgressBar)])
                        [controller.delegate hideProgressBar];
                });
                
                if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable || isDownloading)
                    controller.localMapIndexItem = item;
            }
            [controller createMapDownloadControls];
        }];
    }
    return controller;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _topToolbarType = ETopToolbarTypeFixed;
        _app = [OsmAndApp instance];
    }
    return self;
}

- (void) setLocation:(CLLocationCoordinate2D)location
{
    _location = location;
    _formattedCoords = [OAPointDescription getLocationName:location.latitude lon:location.longitude sh:YES];
}

- (UIImage *) getIcon
{
    return nil;
}

- (BOOL) needAddress
{
    return YES;
}

-(UIView *) getTopView
{
    return _navBar;
}

-(UIView *) getMiddleView
{
    return _contentView;
}

-(CGFloat) getToolBarHeight
{
    return defaultToolBarHeight;
}

- (NSString *) getTypeStr
{
    return [self getCommonTypeStr];
}

- (NSString *) getCommonTypeStr
{
    return OALocalizedString(@"sett_arr_loc");
}

- (NSAttributedString *) getAttributedTypeStr
{
    return nil;
}

- (NSAttributedString *) getAttributedCommonTypeStr
{
    return nil;
}

- (NSAttributedString *) getAttributedTypeStr:(NSString *)group
{
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
    UIFont *font = [UIFont fontWithName:@"AvenirNext-Regular" size:15.0];
    
    NSMutableAttributedString *stringGroup = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@", group]];
    NSTextAttachment *groupAttachment = [[NSTextAttachment alloc] init];
    groupAttachment.image = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"map_small_group.png"] color:UIColorFromRGB(0x808080)];
    
    NSAttributedString *groupStringWithImage = [NSAttributedString attributedStringWithAttachment:groupAttachment];
    [stringGroup replaceCharactersInRange:NSMakeRange(0, 1) withAttributedString:groupStringWithImage];
    [stringGroup addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-2.0] range:NSMakeRange(0, 1)];
    
    [string appendAttributedString:stringGroup];
    
    [string addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, string.length)];
    
    return string;
}

- (UIColor *) getAdditionalInfoColor
{
    return nil;
}

- (NSAttributedString *) getAdditionalInfoStr
{
    return nil;
}

- (UIImage *) getAdditionalInfoImage
{
    return nil;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    _downloadTaskProgressObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                              withHandler:@selector(onDownloadTaskProgressChanged:withKey:andValue:)
                                                               andObserve:_app.downloadsManager.progressCompletedObservable];
    _downloadTaskCompletedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                               withHandler:@selector(onDownloadTaskFinished:withKey:andValue:)
                                                                andObserve:_app.downloadsManager.completedObservable];
    
    _navBar.hidden = YES;
    _actionButtonPressed = NO;
    
    if ([self hasTopToolbarShadow])
    {
        // drop shadow
        [self.navBar.layer setShadowColor:[UIColor blackColor].CGColor];
        [self.navBar.layer setShadowOpacity:0.3];
        [self.navBar.layer setShadowRadius:3.0];
        [self.navBar.layer setShadowOffset:CGSizeMake(0.0, 0.0)];
    }
    [self applySafeAreaMargins];
    [self adjustBackButtonPosition];
}

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self applySafeAreaMargins];
        [self adjustBackButtonPosition];
        // Refresh the offset on iPads to avoid broken animations
        if (self.delegate && OAUtilities.isIPad)
            [self.delegate contentChanged];
    } completion:nil];
}

-(void) adjustBackButtonPosition
{
    CGRect buttonFrame = self.buttonBack.frame;
    buttonFrame.origin.x = 16.0 + [OAUtilities getLeftMargin];
    buttonFrame.origin.y = [OAUtilities getStatusBarHeight] + 7.;
    self.buttonBack.frame = buttonFrame;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)onDownloadTaskProgressChanged:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;
    
    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"] || task.state != OADownloadTaskStateRunning)
        return;
    
    if (!task.silentInstall)
        task.silentInstall = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_localMapIndexItem && [_localMapIndexItem.resourceId.toNSString() isEqualToString:[task.key stringByReplacingOccurrencesOfString:@"resource:" withString:@""]])
        {
            NSMutableString *progressStr = [NSMutableString string];
            [progressStr appendString:[NSByteCountFormatter stringFromByteCount:(_localMapIndexItem.size * [value floatValue]) countStyle:NSByteCountFormatterCountStyleFile]];
            [progressStr appendString:@" "];
            [progressStr appendString:OALocalizedString(@"shared_string_of")];
            [progressStr appendString:@" "];
            [progressStr appendString:[NSByteCountFormatter stringFromByteCount:_localMapIndexItem.size countStyle:NSByteCountFormatterCountStyleFile]];
            if (self.delegate && [self.delegate respondsToSelector:@selector(setDownloadProgress:text:)])
                [self.delegate setDownloadProgress:[value floatValue] text:progressStr];
        }
    });
}

- (void) onDownloadCancelled
{
    if (_localMapIndexItem)
    {
        [OAResourcesUIHelper offerCancelDownloadOf:_localMapIndexItem onTaskStop:^(id<OADownloadTask>  _Nonnull task) {
            if ([[task.key stringByReplacingOccurrencesOfString:@"resource:" withString:@""] isEqualToString:_localMapIndexItem.resourceId.toNSString()])
            {
                [self.delegate hideProgressBar];
                _localMapIndexItem = nil;
                
                [OAResourcesUIHelper requestMapDownloadInfo:self.location
                                               resourceType:OsmAnd::ResourcesManager::ResourceType::MapRegion
                                                 onComplete:^(NSArray<ResourceItem *>* res) {
                    RepositoryResourceItem *item = (RepositoryResourceItem *)res[0];
                    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable && item)
                        self.localMapIndexItem = item;
                }];
            }
        }];
    }
}

- (void)onDownloadTaskFinished:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;
    
    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"])
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (task.progressCompleted < 1.0)
        {
            if ([_app.downloadsManager.keysOfDownloadTasks count] > 0)
            {
                if (self.delegate && [self.delegate respondsToSelector:@selector(showProgressBar)])
                    [self.delegate showProgressBar];
            }
        }
        else if (_localMapIndexItem && [_localMapIndexItem.resourceId.toNSString() isEqualToString:[task.key stringByReplacingOccurrencesOfString:@"resource:" withString:@""]])
        {
            _localMapIndexItem = nil;
            _downloadControlButton = nil;
            if (self.delegate && [self.delegate respondsToSelector:@selector(hideProgressBar)])
                [self.delegate hideProgressBar];
        }
    });
}

- (void) createMapDownloadControls
{
    if (_localMapIndexItem)
    {
        self.downloadControlButton = [[OATargetMenuControlButton alloc] init];
        self.downloadControlButton.title = _localMapIndexItem.title;
        [self.delegate contentChanged];
    }
    else if (self.delegate && [self.delegate respondsToSelector:@selector(hideProgressBar)])
        [self.delegate hideProgressBar];
}

- (IBAction) buttonBackPressed:(id)sender
{
    if (self.topToolbarType == ETopToolbarTypeFloating)
    {
        if (self.delegate)
            [self.delegate requestHeaderOnlyMode];
    }

    [self backPressed];
}

- (IBAction) buttonOKPressed:(id)sender
{
    _actionButtonPressed = YES;
    [self okPressed];
}

- (IBAction) buttonCancelPressed:(id)sender
{
    _actionButtonPressed = YES;
    if (self.topToolbarType == ETopToolbarTypeFloating)
    {
        if (self.delegate)
            [self.delegate requestHeaderOnlyMode];
    }
    [self cancelPressed];
}

- (void) backPressed
{
    // override
}

- (void) okPressed
{
    // override
}

- (void) cancelPressed
{
    // override
}

- (BOOL) hasContent
{
    return YES; // override
}

- (CGFloat) contentHeight
{
    return 0.0; // override
}

- (CGFloat) contentHeight:(CGFloat)width
{
    return [self contentHeight];
}

- (void) setContentBackgroundColor:(UIColor *)color
{
    _contentView.backgroundColor = color;
}

- (BOOL) hasInfoView
{
    return [self hasInfoButton] || [self hasRouteButton];
}

- (BOOL) hasInfoButton
{
    return [self hasContent] && ![self isLandscape];
}

- (BOOL) hasRouteButton
{
    return YES;
}

- (BOOL) showTopControls
{
    if (self.delegate)
        return ![self.delegate isInFullMode] && ![self.delegate isInFullScreenMode] && self.topToolbarType != ETopToolbarTypeFixed;
    else
        return NO;
}

- (BOOL) shouldEnterContextModeManually
{
    return NO; // override
}

- (BOOL) supportMapInteraction
{
    return NO; // override
}

- (BOOL) supportsForceClose
{
    return NO; // override
}

- (BOOL) showNearestWiki;
{
    return NO; // override
}

- (BOOL) supportFullMenu
{
    return YES; // override
}

- (BOOL) supportFullScreen
{
    return YES; // override
}

- (void) goHeaderOnly
{
    // override
}

- (void) goFull
{
    // override
}

- (void) goFullScreen
{
    // override
}

- (BOOL) hasTopToolbar
{
    return NO; // override
}

- (BOOL) shouldShowToolbar
{
    return NO; // override
}

- (BOOL) hasTopToolbarShadow
{
    return YES;
}

- (BOOL) hasBottomToolbar
{
    return NO; // override
}

- (BOOL) needsAdditionalBottomMargin
{
    return YES; // override
}

- (BOOL) needsMapRuler
{
    return NO; // override
}

- (CGFloat) additionalContentOffset
{
    return 0.0; // override
}

- (BOOL) needsLayoutOnModeChange
{
    return YES; // override
}

- (void) setTopToolbarType:(ETopToolbarType)topToolbarType
{
    _topToolbarType = topToolbarType;
}

- (void) applyTopToolbarTargetTitle
{
    if (self.delegate)
        self.titleView.text = [self.delegate getTargetTitle];
}

- (void) setTopToolbarAlpha:(CGFloat)alpha
{
    if ([self hasTopToolbar])
    {
        switch (self.topToolbarType)
        {
            case ETopToolbarTypeFloating:
            case ETopToolbarTypeMiddleFixed:
            case ETopToolbarTypeFloatingFixedButton:
                if (self.navBar.alpha != alpha)
                    self.navBar.alpha = alpha;
                break;
                
            case ETopToolbarTypeFixed:
                [self applyGradient:self.topToolbarGradient topToolbarType:ETopToolbarTypeFixed alpha:alpha];
                self.navBar.alpha = 1.0;
                break;

            default:
                break;
        }
    }
}

- (void) setMiddleToolbarAlpha:(CGFloat)alpha
{
    if ([self hasTopToolbar])
    {
        CGFloat backButtonAlpha = alpha;
        if (self.topToolbarType != ETopToolbarTypeFloating)
            backButtonAlpha = 0;
        if (self.topToolbarType == ETopToolbarTypeFloatingFixedButton)
            backButtonAlpha = 1;
        
        if (self.buttonBack.alpha != backButtonAlpha)
            self.buttonBack.alpha = backButtonAlpha;
        
        if (self.topToolbarType == ETopToolbarTypeMiddleFixed)
        {
            if (alpha < 1)
            {
                [self applyGradient:self.topToolbarGradient topToolbarType:ETopToolbarTypeMiddleFixed alpha:1.0];
                self.navBar.alpha = alpha;
            }
            else
            {
                [self applyGradient:self.topToolbarGradient topToolbarType:ETopToolbarTypeFixed alpha:alpha - 1.0];
                self.navBar.alpha = 1.0;
            }
        }
    }
}

- (void) applyGradient:(BOOL)gradient alpha:(CGFloat)alpha
{
    [self applyGradient:gradient topToolbarType:self.topToolbarType alpha:alpha];
}

- (void) applyGradient:(BOOL)gradient topToolbarType:(ETopToolbarType)topToolbarType alpha:(CGFloat)alpha
{
    if (self.titleGradient && gradient)
    {
        _topToolbarGradient = YES;
        switch (topToolbarType)
        {
            case ETopToolbarTypeFixed:
                self.titleGradient.alpha = 1.0 - alpha;
                self.navBarBackground.alpha = alpha;
                self.titleGradient.hidden = NO;
                self.navBarBackground.hidden = NO;
                break;
                
            case ETopToolbarTypeMiddleFixed:
                self.titleGradient.alpha = alpha;
                self.navBarBackground.alpha = 0;
                self.titleGradient.hidden = NO;
                self.navBarBackground.hidden = YES;
                break;
                
            default:
                break;
        }
    }
    else
    {
        _topToolbarGradient = NO;
        self.titleGradient.alpha = 0.0;
        self.titleGradient.hidden = YES;
        self.navBarBackground.alpha = 1.0;
        self.navBarBackground.hidden = NO;
    }
}

- (BOOL) disablePanWhileEditing
{
    return NO; // override
}

- (BOOL) disableScroll
{
    return NO; // override
}

- (BOOL) supportEditing
{
    return NO; // override
}

- (void) activateEditing
{
    // override
}

- (BOOL) commitChangesAndExit
{
    return YES; // override
}

- (BOOL) preHide
{
    return YES; // override
}

- (id) getTargetObj
{
    return nil; // override
}

- (OATargetMenuViewControllerState *)getCurrentState
{
    return nil; // override
}

- (BOOL) isLandscape
{
    return OAUtilities.isLandscape;
}

- (BOOL) hasControlButtons
{
    return self.leftControlButton || self.rightControlButton;
}

- (void) leftControlButtonPressed;
{
    // override
}

- (void) rightControlButtonPressed;
{
    // override
}

- (void) downloadControlButtonPressed
{
    if (_localMapIndexItem)
    {
        [OAResourcesUIHelper offerDownloadAndInstallOf:_localMapIndexItem onTaskCreated:^(id<OADownloadTask> task) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(showProgressBar)])
                [self.delegate showProgressBar];
            _localMapIndexItem.downloadTask = task;
        } onTaskResumed:nil];
    }
}

- (void) onMenuSwipedOff
{
    // override
}
- (void) onMenuDismissed
{
    // override
}

- (void) onMenuShown
{
    // override
}

- (void) setupToolBarButtonsWithWidth:(CGFloat)width
{
    // override
}

- (NSArray<OATransportStopRoute *> *) getSubTransportStopRoutes:(BOOL)nearby
{
    return @[];
}

- (NSArray<OATransportStopRoute *> *) getLocalTransportStopRoutes
{
    return [self getSubTransportStopRoutes:false];
}

- (NSArray<OATransportStopRoute *> *) getNearbyTransportStopRoutes
{
    return [self getSubTransportStopRoutes:true];
}

- (void)refreshContent
{
}

@end
