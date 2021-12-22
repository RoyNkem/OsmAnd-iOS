//
//  OAConfigureProfileViewController.h
//  OsmAnd
//
//  Created by Paul on 01.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseBigTitleSettingsViewController.h"

#define kNavigationSettings @"nav_settings"

@class OAApplicationMode;

@interface OAConfigureProfileViewController : OABaseBigTitleSettingsViewController

- (instancetype) initWithAppMode:(OAApplicationMode *)mode targetScreenKey:(NSString *)targetScreenKey;

@end
