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

@interface OAOsmEditingPlugin : OAPlugin

- (id<OAOpenStreetMapUtilsProtocol>)getPoiModificationUtil;
- (id<OAOpenStreetMapUtilsProtocol>)getOfflineModificationUtil;
- (id<OAOpenStreetMapUtilsProtocol>)getOnlineModificationUtil;

- (id<OAOsmBugsUtilsProtocol>)getLocalOsmNotesUtil;
- (id<OAOsmBugsUtilsProtocol>)getRemoteOsmNotesUtil;

-(void) openOsmNote:(double)latitude longitude:(double)longitude message:(NSString *)message autoFill:(BOOL)autofill;

+ (NSString *) getCategory:(OAOsmPoint *)point;

@end

NS_ASSUME_NONNULL_END
