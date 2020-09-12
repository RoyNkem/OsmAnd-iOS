//
//  OAObjectType.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/search/core/ObjectType.java
//  git revision 78e7bb4d3d7ae61759c68be3eea8cdc7d27d60a4

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, EOAObjectType)
{
    CITY = 0,
    VILLAGE,
    POSTCODE,
    STREET,
    HOUSE,
    STREET_INTERSECTION,
    // POI
    POI_TYPE,
    POI,
    // LOCATION
    LOCATION,
    PARTIAL_LOCATION,
    // UI OBJECTS
    FAVORITE,
    FAVORITE_GROUP,
    WPT,
    RECENT_OBJ,

    REGION,
    
    SEARCH_STARTED,
    SEARCH_FINISHED,
    FILTER_FINISHED,
    SEARCH_API_FINISHED,
    SEARCH_API_REGION_FINISHED,
    UNKNOWN_NAME_FILTER
};

@interface OAObjectType : NSObject

@property (nonatomic, readonly) EOAObjectType type;

+ (instancetype)withType:(EOAObjectType)type;

+ (BOOL) hasLocation:(EOAObjectType)objecType;
+ (BOOL) isAddress:(EOAObjectType)objecType;
+ (BOOL) isTopVisible:(EOAObjectType)objecType;
+ (NSString *) toString:(EOAObjectType)objecType;
+ (OAObjectType *) getExclusiveSearchType:(EOAObjectType)objectType;
+ (double) getTypeWeight:(EOAObjectType)objectType;

+ (OAObjectType *)valueOf:(NSString *)type;

@end
