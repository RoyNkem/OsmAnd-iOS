//
//  OAImportBackupItemsTask.h
//  OsmAnd Maps
//
//  Created by Paul on 22.06.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol OAImportItemsListener <NSObject>

- (void) onImportFinished:(BOOL)succeed;

@end

@class OASettingsItem, OABackupImporter;

@interface OAImportBackupItemsTask : NSOperation

- (instancetype) initWithImporter:(OABackupImporter *)importer items:(NSArray<OASettingsItem *> *)items listener:(id<OAImportItemsListener>)listener forceReadData:(BOOL)forceReadData;

@end

NS_ASSUME_NONNULL_END
