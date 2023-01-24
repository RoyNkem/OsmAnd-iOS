//
//  OAOptionsPanelBlackViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 04.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAOptionsPanelBlackViewController.h"
#import "OAMapSettingsViewController.h"
#import "OAMainSettingsViewController.h"
#import "OAFavoriteListViewController.h"
#import "OAGPXListViewController.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OAHelpViewController.h"
#import "OAPluginsViewController.h"
#import "OAColors.h"
#import "OAMapHudViewController.h"
#import "OAWeatherPlugin.h"
#import "OAAutoObserverProxy.h"

#import "OARoutePlanningHudViewController.h"
#import "InitialRoutePlanningBottomSheetViewController.h"

#import <JASidePanelController.h>
#import <UIViewController+JASidePanel.h>

#import "OARootViewController.h"
#import "OAAnalyticsHelper.h"

#import "OACloudAccountLoginViewController.h"
#import "OACloudAccountCreateViewController.h"
#import "OACloudAccountVerificationViewController.h"

@interface OAOptionsPanelBlackViewController () <UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonMaps;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonMyData;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonMyWaypoints;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonNavigation;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonPlanRoute;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonWeather;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonSettings;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonMapsAndResources;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonConfigureScreen;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonHelp;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonPlugins;

@end

@implementation OAOptionsPanelBlackViewController
{
    CALayer *_menuButtonMapsDiv;
    CALayer *_menuButtonMyDataDiv;
    CALayer *_menuButtonMyWaypointsDiv;
    CALayer *_menuButtonNavigationDiv;
    CALayer *_menuButtonPlanRouteDiv;
    CALayer *_menuButtonWeatherDiv;
    CALayer *_menuButtonConfigureScreenDiv;
    CALayer *_menuButtonSettingsDiv;
    CALayer *_menuButtonPluginsDiv;
    CALayer *_menuButtonMapsAndResourcesDiv;

    OAAutoObserverProxy *_weatherChangeObserver;
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    [self updateLayout];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _weatherChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                       withHandler:@selector(onWeatherChanged)
                                                        andObserve:[OsmAndApp instance].data.weatherChangeObservable];
}

- (void)onWeatherChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateLayout];
    });
}

- (void) updateLayout
{
    CGFloat topY = [OAUtilities getStatusBarHeight];
    CGFloat buttonHeight = 50.0;
    CGFloat width = kDrawerWidth;
    BOOL isWeatherPluginEnabled = [[OAPlugin getPlugin:OAWeatherPlugin.class] isEnabled];

    if (isWeatherPluginEnabled)
        _menuButtonWeatherDiv.hidden = NO;
    else
        _menuButtonPlanRouteDiv.hidden = NO;
    
    NSMutableArray<UIButton *> *topButtons = [NSMutableArray arrayWithObjects:
                                              self.menuButtonMaps,
                                              self.menuButtonMyData,
                                              self.menuButtonMyWaypoints,
                                              self.menuButtonMapsAndResources,
                                              self.menuButtonNavigation,
                                              self.menuButtonPlanRoute,
                                              nil
                                             ];
    if (isWeatherPluginEnabled)
    {
        self.menuButtonWeather.hidden = NO;
        [topButtons addObject:self.menuButtonWeather];
    }
    else
    {
        self.menuButtonWeather.hidden = YES;
    }
    
    NSArray<UIButton *> *bottomButtons = @[ self.menuButtonConfigureScreen,
                                            self.menuButtonPlugins,
                                            self.menuButtonSettings,
                                            self.menuButtonHelp
                                            ];
    
    CALayer *bottomDiv = _menuButtonWeatherDiv;
    
    NSInteger buttonsCount = topButtons.count + bottomButtons.count;
    CGFloat buttonsHeight = buttonHeight * buttonsCount;

    CGFloat scrollHeight = DeviceScreenHeight - topY;

    self.scrollView.frame = CGRectMake(0.0, topY, width, scrollHeight);
    self.scrollView.contentSize = CGSizeMake(width, buttonsHeight < scrollHeight ? scrollHeight : buttonsHeight);
    if (buttonsHeight < scrollHeight)
    {
        for (NSInteger i = 0; i < topButtons.count; i++)
        {
            UIButton *btn = topButtons[i];
            btn.frame = CGRectMake(0, buttonHeight * i, width, buttonHeight);
            [self adjustButtonInsets:btn];
        }
        CGFloat lastIndex = (CGFloat) bottomButtons.count - 1;
        CGFloat bottomMargin = [OAUtilities getBottomMargin];
        for (NSInteger i = 0; i <= lastIndex; i++)
        {
            UIButton *btn = bottomButtons[i];
            BOOL lastButton = i == lastIndex;
            btn.frame = CGRectMake(0, scrollHeight - buttonHeight * (bottomButtons.count - i) - bottomMargin, width, buttonHeight + (lastButton ? bottomMargin : 0.0));
            [self adjustButtonInsets:btn];
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
            btn.frame = CGRectMake(0, buttonHeight * i, width, buttonHeight);
            [self adjustButtonInsets:btn];
            if (i == lastIndex)
                [self adjustContentBy:0.0 btn:btn];
        }
        bottomDiv.hidden = YES;
    }
    
    CGFloat divX = ([self.scrollView isDirectionRTL]) ? 0 : 60.0;
    CGFloat divY = 49.5;
    CGFloat divW = width - 60;
    CGFloat divH = 0.5;

    _menuButtonMapsDiv.frame = CGRectMake(divX, divY, divW, divH);
    _menuButtonMyDataDiv.frame = CGRectMake(divX, divY, divW, divH);
    _menuButtonMyWaypointsDiv.frame = CGRectMake(divX, divY, divW, divH);
    _menuButtonNavigationDiv.frame = CGRectMake(divX, divY, divW, divH);
    _menuButtonPlanRouteDiv.frame = CGRectMake(divX, divY, divW, divH);
    _menuButtonWeatherDiv.frame = CGRectMake(divX, divY, divW, divH);
    _menuButtonMapsAndResourcesDiv.frame = CGRectMake(divX, divY, divW, divH);
    _menuButtonConfigureScreenDiv.frame = CGRectMake(divX, divY, divW, divH);
    _menuButtonSettingsDiv.frame = CGRectMake(divX, divY, divW, divH);
    _menuButtonPluginsDiv.frame = CGRectMake(divX, divY, divW, divH);
}

- (void)adjustButtonInsets:(UIButton *)btn
{
    UIEdgeInsets contentInsets = btn.contentEdgeInsets;
    UIEdgeInsets titleInsets = btn.titleEdgeInsets;
    
    if ([btn isDirectionRTL])
    {
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        contentInsets.left = [OAUtilities getLeftMargin];
        contentInsets.right = 10;
        titleInsets.left = 0;
        titleInsets.right = 19;
    }
    else
    {
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        contentInsets.left = [OAUtilities getLeftMargin] + 10;
        contentInsets.right = 0;
        titleInsets.left = 19;
        titleInsets.right = 0;
    }
    
    btn.contentEdgeInsets = contentInsets;
    btn.titleEdgeInsets = titleInsets;
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
    _menuButtonPlanRouteDiv = [[CALayer alloc] init];
    _menuButtonWeatherDiv = [[CALayer alloc] init];
    _menuButtonMapsAndResourcesDiv = [[CALayer alloc] init];
    _menuButtonConfigureScreenDiv = [[CALayer alloc] init];
    _menuButtonSettingsDiv = [[CALayer alloc] init];
    _menuButtonPluginsDiv = [[CALayer alloc] init];

    UIColor *divColor = UIColorFromRGB(0xe2e1e6);

    _menuButtonMapsDiv.backgroundColor = divColor.CGColor;
    _menuButtonMyDataDiv.backgroundColor = divColor.CGColor;
    _menuButtonMyWaypointsDiv.backgroundColor = divColor.CGColor;
    _menuButtonNavigationDiv.backgroundColor = divColor.CGColor;
    _menuButtonPlanRouteDiv.backgroundColor = divColor.CGColor;
    _menuButtonWeatherDiv.backgroundColor = divColor.CGColor;
    _menuButtonMapsAndResourcesDiv.backgroundColor = divColor.CGColor;
    _menuButtonConfigureScreenDiv.backgroundColor = divColor.CGColor;
    _menuButtonSettingsDiv.backgroundColor = divColor.CGColor;
    _menuButtonPluginsDiv.backgroundColor = divColor.CGColor;

    self.navigationController.delegate = self;
    
    [_menuButtonMaps setTitle:OALocalizedString(@"configure_map") forState:UIControlStateNormal];
    [_menuButtonMyData setTitle:OALocalizedString(@"my_places") forState:UIControlStateNormal];
    [_menuButtonMyWaypoints setTitle:OALocalizedString(@"map_markers") forState:UIControlStateNormal];
    [_menuButtonMapsAndResources setTitle:OALocalizedString(@"res_mapsres") forState:UIControlStateNormal];
    [_menuButtonConfigureScreen setTitle:OALocalizedString(@"layer_map_appearance") forState:UIControlStateNormal];
    [_menuButtonSettings setTitle:OALocalizedString(@"shared_string_settings") forState:UIControlStateNormal];
    [_menuButtonHelp setTitle:OALocalizedString(@"menu_help") forState:UIControlStateNormal];
    [_menuButtonNavigation setTitle:OALocalizedString(@"shared_string_navigation") forState:UIControlStateNormal];
    [_menuButtonPlanRoute setTitle:OALocalizedString(@"plan_route") forState:UIControlStateNormal];
    [_menuButtonWeather setTitle:OALocalizedString(@"product_title_weather") forState:UIControlStateNormal];
    [_menuButtonPlugins setTitle:OALocalizedString(@"plugins") forState:UIControlStateNormal];
    
    [_menuButtonMaps.layer addSublayer:_menuButtonMapsDiv];
    [_menuButtonMyData.layer addSublayer:_menuButtonMyDataDiv];
    [_menuButtonMyWaypoints.layer addSublayer:_menuButtonMyWaypointsDiv];
    [_menuButtonMapsAndResources.layer addSublayer:_menuButtonMapsAndResourcesDiv];
    [_menuButtonNavigation.layer addSublayer:_menuButtonNavigationDiv];
    [_menuButtonConfigureScreen.layer addSublayer:_menuButtonConfigureScreenDiv];
    [_menuButtonSettings.layer addSublayer:_menuButtonSettingsDiv];
    [_menuButtonPlanRoute.layer addSublayer:_menuButtonPlanRouteDiv];
    [_menuButtonWeather.layer addSublayer:_menuButtonWeatherDiv];
    [_menuButtonPlugins.layer addSublayer:_menuButtonPluginsDiv];
    
    [_menuButtonMaps setImage:[UIImage templateImageNamed:@"left_menu_icon_map.png"] forState:UIControlStateNormal];
    [_menuButtonMyData setImage:[UIImage templateImageNamed:@"ic_custom_my_places.png"] forState:UIControlStateNormal];
    [_menuButtonMyWaypoints setImage:[UIImage templateImageNamed:@"left_menu_icon_waypoints.png"] forState:UIControlStateNormal];
    [_menuButtonMapsAndResources setImage:[UIImage templateImageNamed:@"left_menu_icon_resources.png"] forState:UIControlStateNormal];
    [_menuButtonConfigureScreen setImage:[UIImage templateImageNamed:@"left_menu_configure_screen.png"] forState:UIControlStateNormal];
    [_menuButtonSettings setImage:[UIImage templateImageNamed:@"left_menu_icon_settings.png"] forState:UIControlStateNormal];
    [_menuButtonHelp setImage:[UIImage templateImageNamed:@"left_menu_icon_about.png"] forState:UIControlStateNormal];
    [_menuButtonNavigation setImage:[UIImage templateImageNamed:@"left_menu_icon_navigation.png"] forState:UIControlStateNormal];
    [_menuButtonPlanRoute setImage:[UIImage templateImageNamed:@"ic_custom_routes.png"] forState:UIControlStateNormal];
    [_menuButtonWeather setImage:[UIImage templateImageNamed:@"ic_custom_umbrella.png"] forState:UIControlStateNormal];
    [_menuButtonPlugins setImage:[UIImage templateImageNamed:@"left_menu_icon_plugins"] forState:UIControlStateNormal];

    [_menuButtonMaps setTintColor:UIColorFromRGB(color_options_panel_icon)];
    [_menuButtonMyData setTintColor:UIColorFromRGB(color_options_panel_icon)];
    [_menuButtonMyWaypoints setTintColor:UIColorFromRGB(color_options_panel_icon)];
    [_menuButtonMapsAndResources setTintColor:UIColorFromRGB(color_options_panel_icon)];
    [_menuButtonConfigureScreen setTintColor:UIColorFromRGB(color_options_panel_icon)];
    [_menuButtonSettings setTintColor:UIColorFromRGB(color_options_panel_icon)];
    [_menuButtonHelp setTintColor:UIColorFromRGB(color_options_panel_icon)];
    [_menuButtonNavigation setTintColor:UIColorFromRGB(color_options_panel_icon)];
    [_menuButtonPlanRoute setTintColor:UIColorFromRGB(color_options_panel_icon)];
    [_menuButtonWeather setTintColor:UIColorFromRGB(color_options_panel_icon)];
    [_menuButtonPlugins setTintColor:UIColorFromRGB(color_options_panel_icon)];
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

- (IBAction)planRouteButtonClicked:(id)sender
{
    [self.sidePanelController toggleLeftPanel:self];
    InitialRoutePlanningBottomSheetViewController *bottomSheet = [[InitialRoutePlanningBottomSheetViewController alloc] init];
    [bottomSheet presentInViewController:OARootViewController.instance.mapPanel.mapViewController];
}

- (IBAction)weatherButtonClicked:(id)sender
{
    [self.sidePanelController toggleLeftPanel:self];
    [[OARootViewController instance].mapPanel.hudViewController changeWeatherToolbarVisible];
}

- (IBAction) configureScreenButtonClicked:(id)sender
{
    [self.sidePanelController toggleLeftPanel:self];
    [[OARootViewController instance].mapPanel showConfigureScreen];
}

- (IBAction) settingsButtonClicked:(id)sender
{
    [OAAnalyticsHelper logEvent:@"settings_open"];

    OAMainSettingsViewController* settingsViewController = [[OAMainSettingsViewController alloc] init];
    [self.navigationController pushViewController:settingsViewController animated:YES];
}

- (IBAction) mapsAndResourcesButtonClicked:(id)sender
{
    [OAAnalyticsHelper logEvent:@"download_maps_open"];

    OASuperViewController* resourcesViewController = [[UIStoryboard storyboardWithName:@"Resources" bundle:nil] instantiateInitialViewController];
    [self.navigationController pushViewController:resourcesViewController animated:YES];
}

- (IBAction)pluginsButtonClicked:(id)sender
{
    OAPluginsViewController *pluginsVC = [[OAPluginsViewController alloc] init];
    [self.navigationController pushViewController:pluginsVC animated:YES];
}

- (IBAction) helpButtonClicked:(id)sender
{
    [OAAnalyticsHelper logEvent:@"help_open"];

    // Data is powered by OpenStreetMap ODbL, &#169; https://www.openstreetmap.org/copyright
//    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Copyright OsmAnd 2017\n\nData is powered by OpenStreetMap ODbL, ©\nhttps://www.openstreetmap.org/copyright" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
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
