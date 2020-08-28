//
//  OASearchPhrase.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/search/core/SearchPhrase.java
//  git revision 727b6ba399858098c30125a4d4b8d4ec46a0013e

#import <Foundation/Foundation.h>
#import "OANameStringMatcher.h"
#import "OAObjectType.h"
#import <CoreLocation/CoreLocation.h>
#import "OASearchResult.h"

#include <OsmAndCore/Data/DataCommonTypes.h>

typedef NS_ENUM(NSInteger, EOASearchPhraseDataType)
{
    P_DATA_TYPE_MAP = 0,
    P_DATA_TYPE_ADDRESS,
    P_DATA_TYPE_ROUTING,
    P_DATA_TYPE_POI
};

@class OASearchSettings, OASearchPhrase, QuadRect, OASearchWord, OAPOIBaseType;

@interface OASearchPhrase : NSObject

- (instancetype) initWithSettings:(OASearchSettings *)settings;

- (OASearchPhrase *) generateNewPhrase:(NSString *)text settings:(OASearchSettings *)settings;
- (NSMutableArray<OASearchWord *> *) getWords;

- (BOOL) isUnknownSearchWordComplete;
- (BOOL) isLastUnknownSearchWordComplete;

- (NSMutableArray<NSString *> *) getUnknownSearchWords;
- (NSMutableArray<NSString *> *) getUnknownSearchWords:(NSSet<NSString *> *)exclude;
- (NSString *) getUnknownSearchWord;
- (NSString *) getUnknownSearchPhrase;
- (BOOL) isUnknownSearchWordPresent;
- (int) getUnknownSearchWordLength;

- (QuadRect *) getRadiusBBoxToSearch:(int)radius;
- (QuadRect *) get1km31Rect;
- (OASearchSettings *) getSettings;
- (int) getRadiusLevel;

- (OASearchPhrase *) selectWord:(OASearchResult *)res;
- (OASearchPhrase *) selectWord:(OASearchResult *)res unknownWords:(NSArray<NSString *> *)unknownWords lastComplete:(BOOL)lastComplete;
- (BOOL) isLastWord:(EOAObjectType)p;
- (OAObjectType *) getExclusiveSearchType;

- (OANameStringMatcher *) getNameStringMatcher;
- (OANameStringMatcher *) getNameStringMatcher:(NSString *)word complete:(BOOL)complete;

- (BOOL) hasObjectType:(EOAObjectType)p;
- (void) syncWordsWithResults;

- (NSString *) getText:(BOOL)includeUnknownPart;
- (NSString *) getTextWithoutLastWord;
- (NSString *) getStringRerpresentation;
- (NSString *) toString;

- (BOOL) isNoSelectedType;
- (BOOL) isEmpty;

- (OASearchWord *) getLastSelectedWord;
- (CLLocation *) getWordLocation;
- (CLLocation *) getLastTokenLocation;
- (void) countUnknownWordsMatch:(OASearchResult *)sr;
- (void) countUnknownWordsMatch:(OASearchResult *)sr localeName:(NSString *)localeName otherNames:(NSMutableArray<NSString *> *)otherNames;

- (int) getRadiusSearch:(int)meters;
- (int) getNextRadiusSearch:(int) meters;

- (NSArray<OAObjectType *> *) getSearchTypes;
- (BOOL) isCustomSearch;
- (BOOL) isSearchTypeAllowed:(EOAObjectType)searchType;
- (BOOL) isSearchTypeAllowed:(EOAObjectType)searchType exclusive:(BOOL)exclusive;
- (BOOL) isEmptyQueryAllowed;
- (BOOL) isSortByName;
- (BOOL) isInAddressSearch;

- (NSString *) getUnknownWordToSearchBuilding;
- (NSString *) getUnknownWordToSearch;

- (NSString *) getRawUnknownSearchPhrase;
- (OAPOIBaseType *) getUnknownSearchWordPoiType;
- (void) setUnknownSearchWordPoiType:(OAPOIBaseType *)unknownSearchWordPoiType;
- (BOOL) hasUnknownSearchWordPoiType;

- (NSArray<OAPOIBaseType *> *) getUnknownSearchWordPoiTypes;
- (void) setUnknownSearchWordPoiTypes:(NSArray<OAPOIBaseType *> *)unknownSearchWordPoiTypes;
- (BOOL) hasUnknownSearchWordPoiTypes;

- (NSString *) getPoiNameFilter;
- (NSString *) getPoiNameFilter:(OAPOIBaseType *)pt;

- (NSArray<NSString *> *) getRadiusOfflineIndexes:(int)meters dt:(EOASearchPhraseDataType)dt;
- (NSArray<NSString *> *) getOfflineIndexes:(QuadRect *)rect dt:(EOASearchPhraseDataType)dt;
- (NSArray<NSString *> *) getOfflineIndexes;

- (void) selectFile:(NSString *)resourceId;
- (void) sortFiles;

+ (NSComparisonResult) icompare:(int)x y:(int)y;


@end
