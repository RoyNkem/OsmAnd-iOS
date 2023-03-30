//
//  OAExportItemsViewController.h
//  OsmAnd
//
//  Created by Paul on 08.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseSettingsListViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class OAApplicationMode;

@interface OAExportItemsViewController : OABaseSettingsListViewController

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode;
- (instancetype) initWithTracks:(NSArray<NSString *> *)tracks;
- (instancetype) initWithType:(OAExportSettingsType *)type selectedItems:(NSArray *)selectedItems;

@end

NS_ASSUME_NONNULL_END
