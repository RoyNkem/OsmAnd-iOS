//
//  OAHistorySettingsViewController.h
//  OsmAnd Maps
//
//  Created by Dmytro Svetlichnyi on 30.01.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseButtonsViewController.h"

typedef enum
{
    EOAHistorySettingsTypeSearch,
    EOAHistorySettingsTypeNavigation,
    EOAHistorySettingsTypeMapMarkers
} EOAHistorySettingsType;

@interface OAHistorySettingsViewController : OABaseButtonsViewController

- (instancetype)initWithSettingsType:(EOAHistorySettingsType)historyType;

@property (nonatomic, readonly) EOAHistorySettingsType historyType;

@end
