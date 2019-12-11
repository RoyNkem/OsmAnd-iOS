//
//  OAOptionsPanelBlackViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 04.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAOptionsPanelBlackViewController.h"
#import "OAMapSettingsViewController.h"
#import "OASettingsViewController.h"
#import "OAFavoriteListViewController.h"
#import "OAGPXListViewController.h"
#import "OAWebViewController.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OAHelpViewController.h"
#import "OAColors.h"

#import <JASidePanelController.h>
#import <UIViewController+JASidePanel.h>

#import "OARootViewController.h"
#import "OAAnalyticsHelper.h"

@interface OAOptionsPanelBlackViewController () <UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonMaps;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonMyData;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonMyWaypoints;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonNavigation;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonSettings;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonMapsAndResources;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonConfigureScreen;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonHelp;

@end

@implementation OAOptionsPanelBlackViewController
{
    CALayer *_menuButtonMapsDiv;
    CALayer *_menuButtonMyDataDiv;
    CALayer *_menuButtonMyWaypointsDiv;
    CALayer *_menuButtonNavigationDiv;
    CALayer *_menuButtonConfigureScreenDiv;
    CALayer *_menuButtonSettingsDiv;
    CALayer *_menuButtonMapsAndResourcesDiv;
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    [self updateLayout:self.interfaceOrientation];
}

- (void) updateLayout:(UIInterfaceOrientation)interfaceOrientation
{
    CGFloat big;
    CGFloat small;
    
    CGRect rect = self.view.bounds;
    if (rect.size.width > rect.size.height)
    {
        big = rect.size.width;
        small = rect.size.height;
    }
    else
    {
        big = rect.size.height;
        small = rect.size.width;
    }
    
    CGFloat topY = [OAUtilities getStatusBarHeight];
    CGFloat buttonHeight = 50.0;
    CGFloat width = kDrawerWidth + [OAUtilities getLeftMargin];

    _menuButtonNavigationDiv.hidden = NO;
    
    NSArray<UIButton *> *topButtons = @[ self.menuButtonMaps,
                                         self.menuButtonMyData,
                                         self.menuButtonMyWaypoints,
                                         self.menuButtonMapsAndResources,
                                         self.menuButtonNavigation
                                         ];
    
    NSArray<UIButton *> *bottomButtons = @[ self.menuButtonConfigureScreen,
                                            self.menuButtonSettings,
                                            self.menuButtonHelp
                                            ];
    
    CALayer *bottomDiv = _menuButtonNavigationDiv;
    
    NSInteger buttonsCount = topButtons.count + bottomButtons.count;
    CGFloat buttonsHeight = buttonHeight * buttonsCount;

    CGFloat scrollHeight;
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation))
        scrollHeight = big - topY;
    else
        scrollHeight = small - topY;

    self.scrollView.frame = CGRectMake(0.0, topY, width, scrollHeight);
    self.scrollView.contentSize = CGSizeMake(width, buttonsHeight < scrollHeight ? scrollHeight : buttonsHeight);
    CGFloat sideMargin = [OAUtilities getLeftMargin];
    if (buttonsHeight < scrollHeight)
    {
        for (NSInteger i = 0; i < topButtons.count; i++)
        {
            UIButton *btn = topButtons[i];
            btn.frame = CGRectMake(sideMargin, buttonHeight * i, width, buttonHeight);
        }
        CGFloat lastIndex = bottomButtons.count - 1;
        CGFloat bottomMargin = [OAUtilities getBottomMargin];
        for (NSInteger i = 0; i <= lastIndex; i++)
        {
            UIButton *btn = bottomButtons[i];
            BOOL lastButton = i == lastIndex;
            btn.frame = CGRectMake(sideMargin, scrollHeight - buttonHeight * (bottomButtons.count - i) - bottomMargin, width, buttonHeight + (lastButton ? bottomMargin : 0.0));
            if (lastButton)
                [self adjustContentBy:bottomMargin btn:btn];
        }
        bottomDiv.hidden = NO;
    }
    else
    {
        NSArray *buttons = [topButtons arrayByAddingObjectsFromArray:bottomButtons];
        CGFloat lastIndex = buttons.count - 1;
        for (NSInteger i = 0; i <= lastIndex; i++)
        {
            UIButton *btn = buttons[i];
            btn.frame = CGRectMake(sideMargin, buttonHeight * i, width, buttonHeight);
            if (i == lastIndex)
                [self adjustContentBy:0.0 btn:btn];
        }
        bottomDiv.hidden = YES;
    }
    
    CGFloat divX = 60.0;
    CGFloat divY = 49.5;
    CGFloat divW = width - divX;
    CGFloat divH = 0.5;

    _menuButtonMapsDiv.frame = CGRectMake(divX, divY, divW, divH);
    _menuButtonMyDataDiv.frame = CGRectMake(divX, divY, divW, divH);
    _menuButtonMyWaypointsDiv.frame = CGRectMake(divX, divY, divW, divH);
    _menuButtonNavigationDiv.frame = CGRectMake(divX, divY, divW, divH);
    _menuButtonMapsAndResourcesDiv.frame = CGRectMake(divX, divY, divW, divH);
    _menuButtonConfigureScreenDiv.frame = CGRectMake(divX, divY, divW, divH);
    _menuButtonSettingsDiv.frame = CGRectMake(divX, divY, divW, divH);
    
//    thebutton.titleEdgeInsets = UIEdgeInsetsMake(0, -thebutton.imageView.frame.size.width, 0, thebutton.imageView.frame.size.width);
//    thebutton.imageEdgeInsets = UIEdgeInsetsMake(0, thebutton.titleLabel.frame.size.width, 0, -thebutton.titleLabel.frame.size.width);
//    imageEdgeInsets = UIEdgeInsets(top: 5, left: (bounds.width - 35), bottom: 5, right: 5)
//    titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: (imageView?.frame.width)!)
    CGFloat b = _menuButtonMaps.frame.size.width;
    CGFloat i = _menuButtonMaps.imageView.frame.size.width;
    NSLog(@"aaa %f, %f", b, i);
//    if ([UIView userInterfaceLayoutDirectionForSemanticContentAttribute:super.view.semanticContentAttribute] == UIUserInterfaceLayoutDirectionRightToLeft)
//    {
//        _menuButtonMaps.imageEdgeInsets = UIEdgeInsetsMake(0, /*_menuButtonMaps.frame.size.width - _menuButtonMaps.imageView.frame.size.width*/ 150, 0, 0);
//        //_menuButtonMaps.titleEdgeInsets = UIEdgeInsetsMake(0, <#CGFloat left#>, <#CGFloat bottom#>, <#CGFloat right#>)
//    }

}

- (void)adjustContentBy:(CGFloat)bottomMargin btn:(UIButton *)btn {
    UIEdgeInsets contentInsets = btn.contentEdgeInsets;
    contentInsets.bottom = bottomMargin;
    btn.contentEdgeInsets = contentInsets;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    

    self.automaticallyAdjustsScrollViewInsets = NO;

    _menuButtonMapsDiv = [[CALayer alloc] init];
    _menuButtonMyDataDiv = [[CALayer alloc] init];
    _menuButtonMyWaypointsDiv = [[CALayer alloc] init];
    _menuButtonNavigationDiv = [[CALayer alloc] init];
    _menuButtonMapsAndResourcesDiv = [[CALayer alloc] init];
    _menuButtonConfigureScreenDiv = [[CALayer alloc] init];
    _menuButtonSettingsDiv = [[CALayer alloc] init];

    UIColor *divColor = UIColorFromRGB(0xe2e1e6);

    _menuButtonMapsDiv.backgroundColor = divColor.CGColor;
    _menuButtonMyDataDiv.backgroundColor = divColor.CGColor;
    _menuButtonMyWaypointsDiv.backgroundColor = divColor.CGColor;
    _menuButtonNavigationDiv.backgroundColor = divColor.CGColor;
    _menuButtonMapsAndResourcesDiv.backgroundColor = divColor.CGColor;
    _menuButtonConfigureScreenDiv.backgroundColor = divColor.CGColor;
    _menuButtonSettingsDiv.backgroundColor = divColor.CGColor;

    self.navigationController.delegate = self;
    
    [_menuButtonMaps setTitle:OALocalizedString(@"map_settings_map") forState:UIControlStateNormal];
    [_menuButtonMyData setTitle:OALocalizedString(@"my_places") forState:UIControlStateNormal];
    [_menuButtonMyWaypoints setTitle:OALocalizedString(@"map_markers") forState:UIControlStateNormal];
    [_menuButtonMapsAndResources setTitle:OALocalizedString(@"res_mapsres") forState:UIControlStateNormal];
    [_menuButtonConfigureScreen setTitle:OALocalizedString(@"layer_map_appearance") forState:UIControlStateNormal];
    [_menuButtonSettings setTitle:OALocalizedString(@"sett_settings") forState:UIControlStateNormal];
    [_menuButtonHelp setTitle:OALocalizedString(@"menu_help") forState:UIControlStateNormal];
    [_menuButtonNavigation setTitle:OALocalizedString(@"routing_settings") forState:UIControlStateNormal];
    
    [_menuButtonMaps.layer addSublayer:_menuButtonMapsDiv];
    [_menuButtonMyData.layer addSublayer:_menuButtonMyDataDiv];
    [_menuButtonMyWaypoints.layer addSublayer:_menuButtonMyWaypointsDiv];
    [_menuButtonMapsAndResources.layer addSublayer:_menuButtonMapsAndResourcesDiv];
    [_menuButtonNavigation.layer addSublayer:_menuButtonNavigationDiv];
    [_menuButtonConfigureScreen.layer addSublayer:_menuButtonConfigureScreenDiv];
    [_menuButtonSettings.layer addSublayer:_menuButtonSettingsDiv];
    
    [_menuButtonMyData setImage:[[UIImage imageNamed:@"ic_custom_my_places.png"]
                                 imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [_menuButtonMyData setTintColor:UIColorFromRGB(color_options_panel_icon)];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) mapsButtonClicked:(id)sender
{
    [self.sidePanelController toggleLeftPanel:self];
    [[OARootViewController instance].mapPanel mapSettingsButtonClick:sender];
}

- (IBAction) myDataButtonClicked:(id)sender
{
    [OAAnalyticsHelper logEvent:@"my_places_open"];
    UIViewController* myPlacesViewController = [[UIStoryboard storyboardWithName:@"MyPlaces" bundle:nil] instantiateInitialViewController];
    [[OARootViewController instance].navigationController pushViewController:myPlacesViewController animated:YES];
}

- (IBAction) myWaypointsButtonClicked:(id)sender
{
    [self.sidePanelController toggleLeftPanel:self];
    [[OARootViewController instance].mapPanel showCards];
}

- (IBAction) navigationButtonClicked:(id)sender
{
    [self.sidePanelController toggleLeftPanel:self];
    [[OARootViewController instance].mapPanel onNavigationClick:NO];
}

- (IBAction) configureScreenButtonClicked:(id)sender
{
    [self.sidePanelController toggleLeftPanel:self];
    [[OARootViewController instance].mapPanel showConfigureScreen];
}

- (IBAction) settingsButtonClicked:(id)sender
{
    [OAAnalyticsHelper logEvent:@"settings_open"];

    OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenMain];
    [self.navigationController pushViewController:settingsViewController animated:YES];
}

- (IBAction) mapsAndResourcesButtonClicked:(id)sender
{
    [OAAnalyticsHelper logEvent:@"download_maps_open"];

    OASuperViewController* resourcesViewController = [[UIStoryboard storyboardWithName:@"Resources" bundle:nil] instantiateInitialViewController];
    [self.navigationController pushViewController:resourcesViewController animated:YES];
}

- (IBAction) helpButtonClicked:(id)sender
{
    [OAAnalyticsHelper logEvent:@"help_open"];

    // Data is powered by OpenStreetMap ODbL, &#169; http://www.openstreetmap.org/copyright
//    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Copyright OsmAnd 2017\n\nData is powered by OpenStreetMap ODbL, ©\nhttp://www.openstreetmap.org/copyright" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
//    [alert show];
    OAHelpViewController *helpViewController = [[OAHelpViewController alloc] init];
    [self.navigationController pushViewController:helpViewController animated:YES];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (BOOL) prefersStatusBarHidden
{
    return NO;
}

- (void) navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [[OARootViewController instance] closeMenuAndPanelsAnimated:NO];
}

@end
