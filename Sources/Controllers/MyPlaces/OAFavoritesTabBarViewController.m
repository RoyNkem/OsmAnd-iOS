//
//  OAFavoritesTabBarViewController.m
//  OsmAnd
//
//  Created by Paul on 4/16/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAFavoritesTabBarViewController.h"
#import "OAIAPHelper.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAFavoritesTabBarViewController

- (void)viewDidLoad
{
    OAIAPHelper *iapHelper = [OAIAPHelper sharedInstance];
    
    if (![[OATravelLocalDataHelper shared] hasSavedArticles])
        [self removeTabAtIndex:3];
    
    if (!iapHelper.osmEditing.isActive)
        [self removeTabAtIndex:2];
    
    [self applyLocalization];
    UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
    [appearance configureWithDefaultBackground];
    self.tabBar.standardAppearance = appearance;
    self.tabBar.scrollEdgeAppearance = appearance;
    [super viewDidLoad];
}

- (void) removeTabAtIndex:(NSInteger)index
{
    NSMutableArray *newTabs = [NSMutableArray arrayWithArray:self.viewControllers];
    [newTabs removeObjectAtIndex: index];
    [self setViewControllers:newTabs];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = UIColor.navBarBgColorPrimary;
    appearance.shadowColor = UIColor.navBarBgColorPrimary;
    appearance.titleTextAttributes = @{
        NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName : UIColor.navBarTextColorPrimary
    };
    UINavigationBarAppearance *blurAppearance = [[UINavigationBarAppearance alloc] init];
    blurAppearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular];
    blurAppearance.backgroundColor = UIColor.navBarBgColorPrimary;
    blurAppearance.shadowColor = UIColor.navBarBgColorPrimary;
    blurAppearance.titleTextAttributes = @{
        NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName : UIColor.navBarTextColorPrimary
    };
    self.navigationController.navigationBar.standardAppearance = blurAppearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    self.navigationController.navigationBar.tintColor = UIColor.navBarTextColorPrimary;
    self.navigationController.navigationBar.prefersLargeTitles = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.tabBarController.navigationItem.searchController = nil;
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

-(void)applyLocalization
{
    [[self.viewControllers objectAtIndex:0] setTitle:OALocalizedString(@"favorites_item")];
    [[self.viewControllers objectAtIndex:1] setTitle: OALocalizedString(@"shared_string_gpx_tracks")];
    
    if ([OAIAPHelper sharedInstance].osmEditing.isActive)
    {
        [[self.viewControllers objectAtIndex:2] setTitle: OALocalizedString(@"osm_edits_title")];
        if ([[OATravelLocalDataHelper shared] hasSavedArticles])
            [[self.viewControllers objectAtIndex:3] setTitle: OALocalizedString(@"shared_string_travel")];
    }
    else
    {
        if ([[OATravelLocalDataHelper shared] hasSavedArticles])
            [[self.viewControllers objectAtIndex:2] setTitle: OALocalizedString(@"shared_string_travel")];
    }
}

@end
