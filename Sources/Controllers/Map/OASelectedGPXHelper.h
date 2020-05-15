//
//  OASelectedGPXHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 24/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <OsmAndCore.h>
#include <OsmAndCore/GeoInfoDocument.h>

@interface OASelectedGPXHelper : NSObject

// Active gpx
@property (nonatomic, readonly) QHash< QString, std::shared_ptr<const OsmAnd::GeoInfoDocument> > activeGpx;

+ (OASelectedGPXHelper *)instance;

- (BOOL) buildGpxList;
- (BOOL) isShowingAnyGpxFiles;

-(void) clearAllGpxFilesToShow:(BOOL) backupSelection;
-(void) restoreSelectedGpxFiles;

+ (void) renameVisibleTrack:(NSString *)oldName newName:(NSString *) newName;


@end
