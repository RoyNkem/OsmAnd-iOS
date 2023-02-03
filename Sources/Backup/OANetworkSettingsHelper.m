//
//  OANetworkSettingsHelper.m
//  OsmAnd Maps
//
//  Created by Paul on 08.04.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OANetworkSettingsHelper.h"
#import "OABackupHelper.h"
#import "OAImportBackupTask.h"
#import "OAExportBackupTask.h"
#import "OASyncBackupTask.h"
#import "OASettingsItem.h"
#import "OALocalFile.h"
#import "OARemoteFile.h"
#import "OASyncBackupTask.h"
#import "OAUtilities.h"
#import "OABackupHelper.h"
#import "OARootViewController.h"

@implementation OANetworkSettingsHelper
{
    OABackupHelper *_backupHelper;
}

+ (OANetworkSettingsHelper *) sharedInstance
{
    static OANetworkSettingsHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OANetworkSettingsHelper alloc] init];
    });
    return _sharedInstance;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        _backupHelper = [OABackupHelper sharedInstance];
        _importAsyncTasks = [NSMutableDictionary dictionary];
        _exportAsyncTasks = [NSMutableDictionary dictionary];
        _syncBackupTasks = [NSMutableDictionary dictionary];
    }
    return self;
}

- (OAImportBackupTask *)getImportTask:(NSString *)key
{
    return _importAsyncTasks[key];
}

- (OAExportBackupTask *)getExportTask:(NSString *)key
{
    return _exportAsyncTasks[key];
}

- (EOAImportType) getImportTaskType:(NSString *)key
{
    OAImportBackupTask *importTask = [self getImportTask:key];
    return importTask != nil ? importTask.importType : EOAImportTypeUndefined;
}

- (BOOL) cancelExport
{
    BOOL cancelled = NO;
    for (OAExportBackupTask *exportTask in self.exportAsyncTasks.allValues)
    {
        [exportTask cancel];
        cancelled |= exportTask.isCancelled;
    }
    return cancelled;
}

- (BOOL) cancelImport
{
    BOOL cancelled = NO;
    for (OAImportBackupTask *importTask in self.importAsyncTasks.allValues)
    {
        [importTask cancel];
        cancelled |= importTask.isCancelled;
    }
    return cancelled;
}

- (BOOL) cancelSyncTasks
{
    BOOL cancelled = YES;
    for (OASyncBackupTask *syncTask in self.syncBackupTasks.allValues)
        [syncTask cancel];
    return cancelled;
}

- (void) cancelSync
{
    [self cancelImport];
    [self cancelExport];
    [self cancelSyncTasks];
}

- (BOOL) isBackupExporting
{
    return self.exportAsyncTasks.count > 0;
}

- (BOOL) isBackupImporting
{
    return self.importAsyncTasks.count > 0;
}

- (BOOL) isBackupSyncing
{
    return self.syncBackupTasks[kSyncItemsKey] != nil;
}

- (void) updateExportListener:(id<OABackupExportListener>)listener
{
    for (OAExportBackupTask *exportTask in self.exportAsyncTasks.allValues)
    {
        exportTask.listener = listener;
    }
}

- (void) updateImportListener:(id<OAImportListener>)listener
{
    for (OAImportBackupTask *importTask in self.importAsyncTasks.allValues)
        importTask.importListener = listener;
}

- (void) finishImport:(id<OAImportListener>)listener success:(BOOL)success items:(NSArray<OASettingsItem *> *)items
{
    NSString *error = [self collectFormattedWarnings:items];
    if (error.length > 0)
        [OAUtilities showToast:error details:nil duration:4 inView:OARootViewController.instance.view];
    if (listener)
        [listener onImportFinished:success needRestart:NO items:items];
}

- (NSString *) collectFormattedWarnings:(NSArray<OASettingsItem *> *)items
{
    NSMutableArray<NSString *> *warnings = [NSMutableArray array];
    for (OASettingsItem *item in items)
        [warnings addObjectsFromArray:item.warnings];
    NSString *error = nil;
    if (warnings.count > 0)
        error = [OAUtilities formatWarnings:warnings];
    
    return error;
}

- (void) collectSettings:(NSString *)key readData:(BOOL)readData
                listener:(id<OABackupCollectListener>)listener
{
    if (!_importAsyncTasks[key])
    {
        OAImportBackupTask *importTask = [[OAImportBackupTask alloc] initWithKey:key collectListener:listener readData:readData];
        self.importAsyncTasks[key] = importTask;
        
        [OABackupHelper.sharedInstance.executor addOperation:importTask];
    }
    else
    {
        @throw [NSException exceptionWithName:@"IllegalStateException" reason:[@"Already importing " stringByAppendingString:key] userInfo:nil];
    }
}

- (void) syncSettingsItems:(NSString *)key operation:(EOABackupSyncOperationType)operation
{
    if (!_syncBackupTasks[key])
    {
        OASyncBackupTask *syncTask = [[OASyncBackupTask alloc] initWithKey:key operation:operation];
        _syncBackupTasks[key] = syncTask;
        
        [syncTask execute];
    }
    else
    {
        @throw [NSException exceptionWithName:@"IllegalStateException" reason:[@"Already syncing " stringByAppendingString:key] userInfo:nil];
    }
}

- (void) syncSettingsItems:(NSString *)key localFile:(OALocalFile *)localFile remoteFile:(OARemoteFile *)remoteFile operation:(EOABackupSyncOperationType)operation
{
    if (!_syncBackupTasks[key])
    {
        OASyncBackupTask *syncTask = [[OASyncBackupTask alloc] initWithKey:key operation:operation];
        _syncBackupTasks[key] = syncTask;
        
        switch (operation)
        {
            case EOABackupSyncOperationDelete:
            {
                if (remoteFile)
                    [syncTask deleteItem:remoteFile.item];
                else if (localFile)
                    [syncTask deleteLocalItem:localFile.item];
                break;
            }
            case EOABackupSyncOperationUpload:
            {
                if (localFile)
                    [syncTask uploadLocalItem:localFile.item];
                break;
            }
            case EOABackupSyncOperationDownload:
            {
                if (remoteFile)
                    [syncTask downloadRemoteVersion:remoteFile.item];
                break;
            }
            default:
                return;
        }
    }
    else
    {
        @throw [NSException exceptionWithName:@"IllegalStateException" reason:[@"Already syncing " stringByAppendingString:key] userInfo:nil];
    }
}

- (void) checkDuplicates:(NSString *)key
                   items:(NSArray<OASettingsItem *> *)items
           selectedItems:(NSArray<OASettingsItem *> *)selectedItems
                listener:(id<OACheckDuplicatesListener>)listener
{
    if (!_importAsyncTasks[key])
    {
        OAImportBackupTask *importTask = [[OAImportBackupTask alloc] initWithKey:key items:items selectedItems:selectedItems duplicatesListener:listener];
        self.importAsyncTasks[key] = importTask;
        [OABackupHelper.sharedInstance.executor addOperation:importTask];
    }
    else
    {
        @throw [NSException exceptionWithName:@"IllegalStateException" reason:[@"Already importing " stringByAppendingString:key] userInfo:nil];
    }
}

- (void) importSettings:(NSString *)key
                  items:(NSArray<OASettingsItem *> *)items
          forceReadData:(BOOL)forceReadData
               listener:(id<OAImportListener>)listener
{
    if (!self.importAsyncTasks[key])
    {
        OAImportBackupTask *importTask = [[OAImportBackupTask alloc] initWithKey:key items:items importListener:listener forceReadData:forceReadData];
        self.importAsyncTasks[key] = importTask;
        [OABackupHelper.sharedInstance.executor addOperation:importTask];
    }
    else
    {
        @throw [NSException exceptionWithName:@"IllegalStateException" reason:[@"Already importing " stringByAppendingString:key] userInfo:nil];
    }
}

- (void) exportSettings:(NSString *)key
                  items:(NSArray<OASettingsItem *> *)items
          itemsToDelete:(NSArray<OASettingsItem *> *)itemsToDelete
     localItemsToDelete:(NSArray<OASettingsItem *> *)localItemsToDelete
               listener:(id<OABackupExportListener>)listener
{
    if (!_exportAsyncTasks[key])
    {
        OAExportBackupTask *exportTask = [[OAExportBackupTask alloc] initWithKey:key items:items itemsToDelete:itemsToDelete localItemsToDelete:localItemsToDelete listener:listener];
        _exportAsyncTasks[key] = exportTask;
        [OABackupHelper.sharedInstance.executor addOperation:exportTask];
    }
    else
    {
        @throw [NSException exceptionWithName:@"IllegalStateException" reason:[@"Already exporting " stringByAppendingString:key] userInfo:nil];
    }
}

- (void) exportSettings:(NSString *)key
               listener:(id<OABackupExportListener>)listener
                  items:(NSArray<OASettingsItem *> *)items
{
    [self exportSettings:key items:items itemsToDelete:@[] localItemsToDelete:@[] listener:listener];
}

@end
