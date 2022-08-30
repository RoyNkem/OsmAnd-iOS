//
//  OASelectedGPXHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 24/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <OsmAndCore.h>
#include <OsmAndCore/GpxDocument.h>

@class OAGPXDocument, OAWptPt;

@interface OASelectedGPXHelper : NSObject

// Active gpx
@property (nonatomic, readonly) QHash< QString, std::shared_ptr<const OsmAnd::GpxDocument> > activeGpx;

+ (OASelectedGPXHelper *)instance;

- (BOOL)buildGpxList;
- (void) markTrackForReload:(NSString *)filePath;
- (OAGPXDocument *)getSelectedGpx:(OAWptPt *)gpxWpt;
- (BOOL)isShowingAnyGpxFiles;

-(void)clearAllGpxFilesToShow:(BOOL) backupSelection;
-(void)restoreSelectedGpxFiles;

+ (void)renameVisibleTrack:(NSString *)oldPath newPath:(NSString *) newPath;


@end
