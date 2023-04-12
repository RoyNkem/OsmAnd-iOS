//
//  OAImportComplete.h
//  OsmAnd
//
//  Created by nnngrach on 19.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseButtonsViewController.h"

@class OAExportSettingsType;

@interface OAImportCompleteViewController : OABaseButtonsViewController

- (instancetype) initWithSettingsItems:(NSDictionary<OAExportSettingsType *, NSArray *> *)settingsItems fileName:(NSString *)fileName;

@end
