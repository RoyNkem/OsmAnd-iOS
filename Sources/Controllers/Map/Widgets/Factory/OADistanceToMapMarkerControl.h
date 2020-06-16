//
//  OADistanceToMapMarkerControl.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 27.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OATextInfoWidget.h"

@interface OADistanceToMapMarkerControl : OATextInfoWidget

- (instancetype) initWithIcons:(NSString *)dayIconId nightIconId:(NSString *)nightIconId firstMarker:(BOOL)firstMarker;

@end
