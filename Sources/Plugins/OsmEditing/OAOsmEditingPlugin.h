//
//  OAOsmEditingPlugin.h
//  OsmAnd
//
//  Created by Paul on 1/18/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAPlugin.h"
#import "OAOpenStreetMapUtilsProtocol.h"
#import "OAOsmBugsUtilsProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class OAOsmBugsDBHelper, OAOpenstreetmapsDbHelper;

@interface OAOsmEditingPlugin : OAPlugin

- (id<OAOpenStreetMapUtilsProtocol>)getPoiModificationUtil;
- (id<OAOpenStreetMapUtilsProtocol>)getPoiModificationLocalUtil;
- (id<OAOpenStreetMapUtilsProtocol>)getPoiModificationRemoteUtil;

- (id<OAOsmBugsUtilsProtocol>)getOsmNotesLocalUtil;
- (id<OAOsmBugsUtilsProtocol>)getOsmNotesRemoteUtil;

- (OAOsmBugsDBHelper *) getDBBug;
- (OAOpenstreetmapsDbHelper *) getDBPOI;

-(void) openOsmNote:(double)latitude longitude:(double)longitude message:(NSString *)message autoFill:(BOOL)autofill;

+ (NSString *) getCategory:(OAOsmPoint *)point;

@end

NS_ASSUME_NONNULL_END
