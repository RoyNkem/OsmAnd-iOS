//
//  OAMapImportHelper.m
//  OsmAnd
//
//  Created by Paul on 17/07/19.
//  Copyright (c) 2019 OsmAnd. All rights reserved.
//

#import "OAFileImportHelper.h"
#import "OALog.h"
#import "OsmAndApp.h"

@implementation OAFileImportHelper
{
    NSFileManager *_fileManager;
    
    OsmAndAppInstance _app;
}

+ (OAFileImportHelper *)sharedInstance
{
    static dispatch_once_t once;
    static OAFileImportHelper * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _fileManager = [NSFileManager defaultManager];
        NSArray *paths = [_fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        NSURL *documentsURL = [paths lastObject];
        _documentsDir = documentsURL.path;
    }
    return self;
}

- (BOOL)importObfFileFromPath:(NSString *)filePath newFileName:(NSString *)newFileName
{
    NSString *fileName;
    if (newFileName)
        fileName = newFileName;
    else
        fileName = [filePath lastPathComponent];
    QString str = QString::fromNSString(fileName);
    QString resourceId = str.toLower().remove(QStringLiteral("_2"));
    if (_app.resourcesManager->isLocalResource(resourceId))
        _app.resourcesManager->uninstallResource(resourceId);
    
    NSString *path = [self.documentsDir stringByAppendingPathComponent:fileName];
    NSError *error;
    [_fileManager moveItemAtPath:filePath toPath:path error:&error];
    if (error)
        OALog(@"Failed to import OBF file: %@", filePath);
    
    [_fileManager removeItemAtPath:filePath error:nil];
    
    if (error)
    {
        return NO;
    }
    else
    {
        [_app.localResourcesChangedObservable notifyEventWithKey:nil];
        return YES;
    }
}

// Used to import routing.xml and .render.xml
- (BOOL)importResourceFileFromPath:(NSString *)filePath
{
    NSString *fileName = [filePath lastPathComponent];
    
    NSString *path = [self.documentsDir stringByAppendingPathComponent:fileName];
    if ([_fileManager fileExistsAtPath:path])
        [_fileManager removeItemAtPath:path error:nil];
    
    NSError *error;
    [_fileManager moveItemAtPath:filePath toPath:path error:&error];
    if (error)
        OALog(@"Failed to import resource: %@", filePath);
    
    [_fileManager removeItemAtPath:filePath error:nil];
    
    if (error)
    {
        return NO;
    }
    else
    {
        [_app.localResourcesChangedObservable notifyEventWithKey:nil];
        return YES;
    }
}

- (NSString *)getNewNameIfExists:(NSString *)fileName
{
    NSString *res;
    QString resourceId = QString::fromNSString(fileName).toLower().remove(QStringLiteral("_2"));
    if (_app.resourcesManager->isLocalResource(resourceId))
    {
        NSString *ext = [fileName pathExtension];
        NSString *newName;
        for (int i = 2; i < 100000; i++) {
            newName = [[NSString stringWithFormat:@"%@-%d", [fileName stringByDeletingPathExtension], i] stringByAppendingPathExtension:ext];
            if (![_fileManager fileExistsAtPath:[self.documentsDir stringByAppendingPathComponent:newName]])
                break;
        }
        res = newName;
    }
    return res;
}

@end
