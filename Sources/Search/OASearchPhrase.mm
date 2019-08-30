//
//  OASearchPhrase.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASearchPhrase.h"
#import "OASearchWord.h"
#import "OASearchSettings.h"
#import "OAUtilities.h"
#import "QuadRect.h"
#import "OACollatorStringMatcher.h"
#import "OsmAndApp.h"
#import "OAPOIBaseType.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/Data/ObfMapSectionInfo.h>
#include <OsmAndCore/Search/CommonWords.h>

static NSString *DELIMITER = @" ";
static NSString *ALLDELIMITERS = @" ,";

static NSSet<NSString *> *conjunctions;
static NSCharacterSet *allDelimitersSet;

static const int ZOOM_TO_SEARCH_POI = 16;


@interface OASearchPhrase ()

@property (nonatomic) NSMutableArray<OASearchWord *> *words;
@property (nonatomic) NSMutableArray<NSString *> *unknownWords;
@property (nonatomic) NSMutableArray<OANameStringMatcher *> *unknownWordsMatcher;
@property (nonatomic) NSString *unknownSearchWordTrim;
@property (nonatomic) NSString *unknownSearchPhrase;
@property (nonatomic) NSString *rawUnknownSearchPhrase;
@property (nonatomic) OAPOIBaseType *unknownSearchWordPoiType;
@property (nonatomic) NSArray<OAPOIBaseType *> *unknownSearchWordPoiTypes;

@property (nonatomic) OANameStringMatcher *sm;
@property (nonatomic) OASearchSettings *settings;

@property (nonatomic) QuadRect *cache1kmRect;
@property (nonatomic) BOOL lastUnknownSearchWordComplete;


@end

@implementation OASearchPhrase
{
    NSMutableArray<NSString *> *_indexes;
    OsmAndAppInstance _app;
    NSMapTable<NSString *, NSObject *> *_resourceLocations;
}

+ (void) initialize
{
    if (self == [OASearchPhrase class])
    {
        allDelimitersSet = [NSCharacterSet characterSetWithCharactersInString:ALLDELIMITERS];
        conjunctions = [NSSet setWithObjects:
                        // the
                        @"the",
                        @"der",
                        @"den",
                        @"die",
                        @"das",
                        @"la",
                        @"le",
                        @"el",
                        @"il",
                        // and
                        @"and",
                        @"und",
                        @"en",
                        @"et",
                        @"y",
                        @"и",
                        // short
                        @"f",
                        @"u",
                        @"jl.",
                        @"j",
                        @"sk",
                        @"w",
                        @"a.",
                        @"of",
                        @"k",
                        @"r",
                        @"h",
                        @"mc",
                        @"sw",
                        @"g",
                        @"v",
                        @"m",
                        @"c.",
                        @"r.",
                        @"ct",
                        @"e.",
                        @"dr.",
                        @"j.",		
                        @"in",
                        @"al",
                        @"út",
                        @"per",
                        @"ne",
                        @"p",
                        @"et",
                        @"s.",
                        @"f.",
                        @"t",
                        @"fe",
                        @"à",
                        @"i",
                        @"c",
                        @"le",
                        @"s",
                        @"av.",
                        @"den",
                        @"dr",
                        @"y",
                        nil];
    }
}

- (instancetype) initWithSettings:(OASearchSettings *)settings
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _resourceLocations = [NSMapTable strongToStrongObjectsMapTable];
        
        self.settings = settings;

        self.words = [NSMutableArray array];
        self.unknownWords = [NSMutableArray array];
        self.unknownWordsMatcher = [NSMutableArray array];
        self.unknownSearchPhrase = @"";
        self.rawUnknownSearchPhrase = @"";
    }
    return self;
}

- (OASearchPhrase *) generateNewPhrase:(NSString *)text settings:(OASearchSettings *)settings
{
    OASearchPhrase *sp = [[OASearchPhrase alloc] initWithSettings:settings];
    NSString *restText = text;
    NSMutableArray<OASearchWord *> *leftWords = self.words;
    NSString *thisTxt = [self getText:YES];
    if ([text hasPrefix:thisTxt])
    {
        // string is longer
        restText = [text substringFromIndex:[self getText:NO].length];
        sp.words = [NSMutableArray arrayWithArray:self.words];
        leftWords = nil;
    }
    for (OASearchWord *w in leftWords)
    {
        if ([restText hasPrefix:[w.word stringByAppendingString:DELIMITER]])
        {
            [sp.words addObject:w];
            restText = [[restText substringFromIndex:w.word.length + DELIMITER.length] trim];
        }
        else
        {
            break;
        }
    }
    sp.rawUnknownSearchPhrase = text;
    sp.unknownSearchPhrase = restText;
    [sp.unknownWords removeAllObjects];
    [sp.unknownWordsMatcher removeAllObjects];
    
    NSArray<NSString *> *ws = [restText componentsSeparatedByCharactersInSet:allDelimitersSet];
    if (ws.count < 2)
    {
        sp.unknownSearchWordTrim = [sp.unknownSearchPhrase trim];
    }
    else
    {
        sp.unknownSearchWordTrim = @"";
        BOOL first = YES;
        for (NSString *w in ws)
        {
            NSString *wd = [w trim];
            if (wd.length > 0 && ![conjunctions containsObject:[wd lowerCase]])
            {
                if (first)
                {
                    sp.unknownSearchWordTrim = wd;
                    first = NO;
                }
                else
                {
                    [sp.unknownWords addObject:wd];
                }
            }
        }
    }
    sp.lastUnknownSearchWordComplete = [OAUtilities isWordComplete:text];
    
    return sp;
}

- (NSMutableArray<OASearchWord *> *) getWords
{
    return self.words;
}

- (BOOL) isUnknownSearchWordComplete
{
    return self.lastUnknownSearchWordComplete || self.unknownWords.count > 0 || self.unknownSearchWordPoiType;
}

- (BOOL) isLastUnknownSearchWordComplete
{
    return self.lastUnknownSearchWordComplete;
}


- (NSMutableArray<NSString *> *) getUnknownSearchWords
{
    return self.unknownWords;
}

- (NSMutableArray<NSString *> *) getUnknownSearchWords:(NSSet<NSString *> *)exclude
{
    if (!exclude || self.unknownWords.count == 0 || exclude.count == 0)
        return self.unknownWords;

    NSMutableArray<NSString *> *l = [NSMutableArray array];
    for (NSString *uw in self.unknownWords)
    {
        if (!exclude || ![exclude containsObject:uw])
            [l addObject:uw];
    }
    return l;
}

- (NSString *) getUnknownSearchWord
{
    return self.unknownSearchWordTrim;
}

- (NSString *) getRawUnknownSearchPhrase
{
    return self.rawUnknownSearchPhrase;
}

- (NSString *) getUnknownSearchPhrase
{
    return self.unknownSearchPhrase;
}

- (BOOL) isUnknownSearchWordPresent
{
    return self.unknownSearchWordTrim.length > 0;
}

- (int) getUnknownSearchWordLength
{
    return (int)self.unknownSearchWordTrim.length;
}

- (OAPOIBaseType *) getUnknownSearchWordPoiType
{
    return self.unknownSearchWordPoiType;
}

- (void) setUnknownSearchWordPoiType:(OAPOIBaseType *)unknownSearchWordPoiType
{
    _unknownSearchWordPoiType = unknownSearchWordPoiType;
}

- (BOOL) hasUnknownSearchWordPoiType
{
    return self.unknownSearchWordPoiType != nil;
}

- (NSArray<OAPOIBaseType *> *) getUnknownSearchWordPoiTypes
{
    return self.unknownSearchWordPoiTypes;
}

- (void) setUnknownSearchWordPoiTypes:(NSArray<OAPOIBaseType *> *)unknownSearchWordPoiTypes
{
    _unknownSearchWordPoiTypes = unknownSearchWordPoiTypes;
    for (OAPOIBaseType *pt in _unknownSearchWordPoiTypes)
    {
        if ([self getPoiNameFilter:pt])
        {
            [self setUnknownSearchWordPoiType:pt];
            break;
        }
    }
}

- (BOOL) hasUnknownSearchWordPoiTypes
{
    return self.unknownSearchWordPoiTypes.count > 0;
}

- (NSString *) getPoiNameFilter
{
    return [self getPoiNameFilter:self.unknownSearchWordPoiType];
}

- (NSString *) getPoiNameFilter:(OAPOIBaseType *)pt
{
    NSString *nameFilter = nil;
    if (pt)
    {
        OANameStringMatcher *nm = [self getNameStringMatcher:[self getUnknownSearchWord] complete:YES];
        NSString *unknownSearchPhrase = [self getUnknownSearchPhrase];
        NSString *enTranslation = pt.nameLocalizedEN;
        NSString *translation = pt.nameLocalized;
        NSString *synonyms = pt.nameSynonyms;
        if (unknownSearchPhrase.length > enTranslation.length && [nm matches:enTranslation])
            nameFilter = [[unknownSearchPhrase substringFromIndex:enTranslation.length] trim];
        else if (unknownSearchPhrase.length > translation.length && [nm matches:translation])
            nameFilter = [[unknownSearchPhrase substringFromIndex:translation.length] trim];
        else if (unknownSearchPhrase.length > synonyms.length && [nm matches:synonyms])
            nameFilter = [[unknownSearchPhrase substringFromIndex:synonyms.length] trim];
    }
    return nameFilter;
}

- (QuadRect *) getRadiusBBoxToSearch:(int)radius
{
    int radiusInMeters = [self getRadiusSearch:radius];
    QuadRect *cache1kmRect = [self get1km31Rect];
    if (!cache1kmRect)
        return nil;

    long max = ((long)1 << 31) - 1;
    double dx = (cache1kmRect.width / 2) * radiusInMeters / 1000;
    double dy = (cache1kmRect.height / 2) * radiusInMeters / 1000;
    double topLeftX = MAX(0, cache1kmRect.left - dx);
    double topLeftY = MAX(0, cache1kmRect.top - dy);
    double bottomRightX = MIN(max, cache1kmRect.right + dx);
    double bottomRightY = MIN(max, cache1kmRect.bottom + dy);
    return [[QuadRect alloc] initWithLeft:topLeftX top:topLeftY right:bottomRightX bottom:bottomRightY];
}

- (QuadRect *) get1km31Rect
{
    if (self.cache1kmRect)
        return self.cache1kmRect;
    
    CLLocation *l = [self getLastTokenLocation];
    if (!l)
        return nil;
    
    float coeff = (float) (1000 / OsmAnd::Utilities::getTileDistanceWidth(ZOOM_TO_SEARCH_POI));
    double tx = OsmAnd::Utilities::getTileNumberX(ZOOM_TO_SEARCH_POI, l.coordinate.longitude);
    double ty = OsmAnd::Utilities::getTileNumberY(ZOOM_TO_SEARCH_POI, l.coordinate.latitude);
    double topLeftX = MAX(0, tx - coeff);
    double topLeftY = MAX(0, ty - coeff);
    int max = (1 << ZOOM_TO_SEARCH_POI)  - 1;
    double bottomRightX = MIN(max, tx + coeff);
    double bottomRightY = MIN(max, ty + coeff);
    double pw = OsmAnd::Utilities::getPowZoom(31 - ZOOM_TO_SEARCH_POI);
    self.cache1kmRect = [[QuadRect alloc] initWithLeft:topLeftX * pw top:topLeftY * pw right:bottomRightX * pw bottom:bottomRightY * pw];
    return self.cache1kmRect;
}

- (NSArray<NSString *> *) getRadiusOfflineIndexes:(int)meters dt:(EOASearchPhraseDataType)dt
{
    QuadRect *rect = meters > 0 ? [self getRadiusBBoxToSearch:meters] : nil;
    return [self getOfflineIndexes:rect dt:dt];
    
}

- (BOOL) containsData:(NSString *)localResourceId rect:(QuadRect *)rect desiredDataTypes:(OsmAnd::ObfDataTypesMask)desiredDataTypes
{
    return [self containsData:localResourceId rect:rect desiredDataTypes:desiredDataTypes zoomLevel:OsmAnd::InvalidZoomLevel];
}

- (BOOL) containsData:(NSString *)localResourceId rect:(QuadRect *)rect desiredDataTypes:(OsmAnd::ObfDataTypesMask)desiredDataTypes zoomLevel:(OsmAnd::ZoomLevel)zoomLevel
{
    const auto& localResource = _app.resourcesManager->getLocalResource(QString::fromNSString(localResourceId));
    if (localResource)
    {
        const auto& obfMetadata = std::static_pointer_cast<const OsmAnd::ResourcesManager::ObfMetadata>(localResource->metadata);
        if (obfMetadata)
        {
            OsmAnd::AreaI pBbox31 = OsmAnd::AreaI((int)rect.top, (int)rect.left, (int)rect.bottom, (int)rect.right);
            if (zoomLevel == OsmAnd::InvalidZoomLevel)
                return obfMetadata->obfFile->obfInfo->containsDataFor(&pBbox31, OsmAnd::MinZoomLevel, OsmAnd::MaxZoomLevel, desiredDataTypes);
            else
                return obfMetadata->obfFile->obfInfo->containsDataFor(&pBbox31, zoomLevel, zoomLevel, desiredDataTypes);
        }
    }
    return NO;
}

- (NSArray<NSString *> *) getOfflineIndexes:(QuadRect *)rect dt:(EOASearchPhraseDataType)dt
{
    NSArray<NSString *> *indexes = _indexes ? _indexes : [self.settings getOfflineIndexes];
    NSMutableArray<NSString *> *result = [NSMutableArray array];
    if (rect)
    {
        for (NSString *resId in indexes)
        {
            if (dt == P_DATA_TYPE_POI)
            {
                if ([self containsData:resId rect:rect desiredDataTypes:OsmAnd::ObfDataTypesMask().set(OsmAnd::ObfDataType::POI)])
                    [result addObject:resId];
            }
            else if (dt == P_DATA_TYPE_ADDRESS)
            {
                // containsAddressData not all maps supported
                if ([self containsData:resId rect:rect desiredDataTypes:OsmAnd::ObfDataTypesMask().set(OsmAnd::ObfDataType::POI)])
                    [result addObject:resId];
            }
            else if (dt == P_DATA_TYPE_ROUTING)
            {
                if ([self containsData:resId rect:rect desiredDataTypes:OsmAnd::ObfDataTypesMask().set(OsmAnd::ObfDataType::Routing) zoomLevel:OsmAnd::ZoomLevel15])
                    [result addObject:resId];
            }
            else
            {
                if ([self containsData:resId rect:rect desiredDataTypes:OsmAnd::ObfDataTypesMask().set(OsmAnd::ObfDataType::Map) zoomLevel:OsmAnd::ZoomLevel15])
                    [result addObject:resId];
            }
        }
    }
    return result;
}

- (NSArray<NSString *> *) getOfflineIndexes
{
    if (_indexes)
        return _indexes;
    
    return [self.settings getOfflineIndexes];
}

- (OASearchSettings *) getSettings
{
    return self.settings;
}


- (int) getRadiusLevel
{
    return [self.settings getRadiusLevel];
}

- (NSArray<OAObjectType *> *) getSearchTypes
{
    return !self.settings ? nil : [self.settings getSearchTypes];
}

- (BOOL) isCustomSearch
{
    return [self getSearchTypes] != nil;
}

- (BOOL) isSearchTypeAllowed:(EOAObjectType)searchType
{
    if (![self getSearchTypes])
    {
        return YES;
    }
    else
    {
        for (OAObjectType *type in [self getSearchTypes])
        {
            if (type.type == searchType)
            {
                return YES;
            }
        }
        return NO;
    }
}

- (BOOL) isEmptyQueryAllowed
{
    return [self.settings isEmptyQueryAllowed];
}

- (BOOL) isSortByName
{
    return [self.settings isSortByName];
}

- (BOOL) isInAddressSearch
{
    return [self.settings isInAddressSearch];
}

- (OASearchPhrase *) selectWord:(OASearchResult *)res
{
    return [self selectWord:res unknownWords:nil lastComplete:NO];
}

- (OASearchPhrase *) selectWord:(OASearchResult *)res unknownWords:(NSArray<NSString *> *)unknownWords lastComplete:(BOOL)lastComplete
{
    OASearchPhrase *sp = [[OASearchPhrase alloc] initWithSettings:self.settings];
    [self addResult:res sp:sp];
    OASearchResult *prnt = res.parentSearchResult;
    while (prnt)
    {
        [self addResult:prnt sp:sp];
        prnt = prnt.parentSearchResult;
    }
    int i = 0;
    for (OASearchWord *w in self.words)
        [sp.words insertObject:w atIndex:i++];

    if (unknownWords)
    {
        sp.lastUnknownSearchWordComplete = lastComplete;
        for (int i = 0; i < unknownWords.count; i++)
        {
            if (i == 0)
                sp.unknownSearchWordTrim = unknownWords[0];
            else
                [sp.unknownWords addObject:unknownWords[i]];
        }
    }
    return sp;
}

- (void) addResult:(OASearchResult *)res sp:(OASearchPhrase *)sp
{
    OASearchWord *sw = [[OASearchWord alloc] initWithWord:res.wordsSpan ? res.wordsSpan : [res.localeName trim] res:res];
    [sp.words insertObject:sw atIndex:0];
}

- (BOOL) isLastWord:(EOAObjectType)p
{
    for (NSInteger i = self.words.count - 1; i >= 0; i--)
    {
        OASearchWord *sw = self.words[i];
        if ([sw getType] == p)
            return YES;

        if ([sw getType] != UNKNOWN_NAME_FILTER)
            return NO;
    }
    return NO;
}

- (OAObjectType *) getExclusiveSearchType
{
    OASearchWord *lastWord = [self getLastSelectedWord];
    if (lastWord)
    {
        return [OAObjectType getExclusiveSearchType:[lastWord getType]];
    }
    return nil;
}

- (OANameStringMatcher *) getNameStringMatcher
{
    if (self.sm)
        return self.sm;

    self.sm = [self getNameStringMatcher:self.unknownSearchWordTrim complete:self.lastUnknownSearchWordComplete];
    return self.sm;
}


- (OANameStringMatcher *) getNameStringMatcher:(NSString *)word complete:(BOOL)complete
{
    return [[OANameStringMatcher alloc] initWithLastWord:word mode:complete ? CHECK_EQUALS_FROM_SPACE : CHECK_STARTS_FROM_SPACE];
}

- (BOOL) hasObjectType:(EOAObjectType)p
{
    for (OASearchWord *s in self.words)
    {
        if([s getType] == p)
            return YES;
    }
    return NO;
}

- (void) syncWordsWithResults
{
    for (OASearchWord *w in self.words)
        [w syncWordWithResult];
}

- (NSString *) getText:(BOOL)includeLastWord
{
    NSMutableString *sb = [NSMutableString string];
    for (OASearchWord *s in self.words)
    {
        [sb appendString:s.word];
        [sb appendString:[DELIMITER trim]];
        [sb appendString:@" "];
    }
    if (includeLastWord)
        [sb appendString:self.unknownSearchPhrase];
    
    return [NSString stringWithString:sb];
}

- (NSString *) getTextWithoutLastWord
{
    NSMutableString *sb = [NSMutableString string];
    NSMutableArray<OASearchWord *> *words = [NSMutableArray arrayWithArray:self.words];
    if (self.unknownSearchWordTrim.length == 0 && words.count > 0)
        [words removeObjectAtIndex:words.count - 1];

    for (OASearchWord *s in words)
    {
        [sb appendString:s.word];
        [sb appendString:[DELIMITER trim]];
        [sb appendString:@" "];
    }

    return [NSString stringWithString:sb];
}

- (NSString *) getStringRerpresentation
{
    NSMutableString *sb = [NSMutableString string];
    for (OASearchWord *s in self.words)
    {
        [sb appendString:s.word];
        [sb appendFormat:@" [%@], ", [OAObjectType toString:[s getType]]];
    }
    [sb appendString:self.unknownSearchPhrase];
    return [NSString stringWithString:sb];
}

- (NSString *) toString
{
    return [self getStringRerpresentation];
}

- (BOOL) isNoSelectedType
{
    return self.words.count == 0;
}

- (BOOL) isEmpty
{
    return self.words.count == 0 && self.unknownSearchPhrase.length == 0;
}


- (OASearchWord *) getLastSelectedWord
{
    if (self.words.count == 0)
        return nil;
    
    return self.words[self.words.count - 1];
}


- (CLLocation *) getWordLocation
{
    for (NSInteger i = self.words.count - 1; i >= 0; i--)
    {
        OASearchWord *sw = self.words[i];
        if ([sw getLocation])
            return [sw getLocation];
    }
    return nil;
}

- (CLLocation *) getLastTokenLocation
{
    for (NSInteger i = self.words.count - 1; i >= 0; i--)
    {
        OASearchWord *sw = self.words[i];
        if ([sw getLocation])
            return [sw getLocation];
    }
    // last token or myLocationOrVisibleMap if not selected
    return self.settings ? [self.settings getOriginalLocation] : nil;
}

- (void) selectFile:(NSString *)resourceId
{
    if (!_indexes)
        _indexes = [NSMutableArray array];
    
    if (![_indexes containsObject:resourceId])
        [_indexes addObject:resourceId];
}

- (CLLocation *) getLocation:(NSString *)resourceId
{
    NSObject *obj = [_resourceLocations objectForKey:resourceId];
    if (obj)
    {
        if ([obj isKindOfClass:[CLLocation class]])
            return (CLLocation *)obj;
        else
            return nil;
    }
    
    CLLocation *location;
    const auto& localResource = _app.resourcesManager->getLocalResource(QString::fromNSString(resourceId));
    if (localResource)
    {
        const auto& obfMetadata = std::static_pointer_cast<const OsmAnd::ResourcesManager::ObfMetadata>(localResource->metadata);
        if (obfMetadata)
        {
            if (!obfMetadata->obfFile->obfInfo->mapSections.empty())
            {
                const auto rc1 = obfMetadata->obfFile->obfInfo->mapSections.first()->getCenterLatLon().getValuePtrOrNullptr();
                if (rc1 != nullptr)
                    location = [[CLLocation alloc] initWithLatitude:rc1->latitude longitude:rc1->longitude];
            }
            else
            {
                const auto rc1 = obfMetadata->obfFile->obfInfo->getRegionCenter().getValuePtrOrNullptr();
                if (rc1 != nullptr)
                    location = [[CLLocation alloc] initWithLatitude:rc1->latitude longitude:rc1->longitude];
            }
        }
    }

    [_resourceLocations setObject:(location ? location : [NSNull null]) forKey:resourceId];
    return location;
}

- (void) sortFiles
{
    if (!_indexes)
        _indexes = [NSMutableArray arrayWithArray:[self getOfflineIndexes]];
    
    CLLocation *ll = [self getLastTokenLocation];
    if (ll)
    {
        [_indexes sortUsingComparator:^NSComparisonResult(NSString * _Nonnull id1, NSString * _Nonnull id2) {
            NSString *first = [[id1 stringByReplacingOccurrencesOfString:@".map.obf" withString:@""] stringByReplacingOccurrencesOfString:@".live.obf" withString:@""];
            NSString *second = [[id2 stringByReplacingOccurrencesOfString:@".map.obf" withString:@""] stringByReplacingOccurrencesOfString:@".live.obf" withString:@""];
            NSRange rangeFirst = [first rangeOfString:@"([0-9]+_){2}[0-9]+" options:NSRegularExpressionSearch];
            NSRange rangeSecond = [second rangeOfString:@"([0-9]+_){2}[0-9]+" options:NSRegularExpressionSearch];
            if (rangeFirst.location != NSNotFound && rangeSecond.location == NSNotFound)
            {
                NSString *base = [first substringToIndex:rangeFirst.location - 1];
                if ([base isEqualToString:second])
                    return NSOrderedAscending;
            }
            else if (rangeFirst.location == NSNotFound && rangeSecond.location != NSNotFound)
            {
                NSString *base = [second substringToIndex:rangeSecond.location - 1];
                if ([base isEqualToString:first])
                    return NSOrderedDescending;
            }
            else if (rangeFirst.location != NSNotFound && rangeSecond.location != NSNotFound)
            {
                return [first compare:second];
            }
            
            CLLocation *rc1 = [self getLocation:id1];
            CLLocation *rc2 = [self getLocation:id2];
            double d1 = !rc1 ? 10000000.0 : [rc1 distanceFromLocation:ll];
            double d2 = !rc2 ? 10000000.0 : [rc2 distanceFromLocation:ll];
            return [[NSNumber numberWithDouble:d1] compare:[NSNumber numberWithDouble:d2]];
            
        }];
    }
}

- (void) countUnknownWordsMatch:(OASearchResult *)sr
{
    [self countUnknownWordsMatch:sr localeName:sr.localeName otherNames:sr.otherNames];
}

- (void) countUnknownWordsMatch:(OASearchResult *)sr localeName:(NSString *)localeName otherNames:(NSMutableArray<NSString *> *)otherNames
{
    if (self.unknownWords.count > 0)
    {
        for (int i = 0; i < self.unknownWords.count; i++)
        {
            if (self.unknownWordsMatcher.count == i)
            {
                [self.unknownWordsMatcher addObject:[[OANameStringMatcher alloc] initWithLastWord:self.unknownWords[i] mode:i < self.unknownWords.count - 1 || [self isLastUnknownSearchWordComplete] ? CHECK_EQUALS_FROM_SPACE : CHECK_STARTS_FROM_SPACE]];
            }
            OANameStringMatcher *ms = self.unknownWordsMatcher[i];
            if ([ms matches:localeName] || [ms matchesMap:otherNames])
            {
                if (!sr.otherWordsMatch)
                    sr.otherWordsMatch = [NSMutableSet set];
                
                [sr.otherWordsMatch addObject:self.unknownWords[i]];
            }
        }
    }
    if (!sr.firstUnknownWordMatches)
        sr.firstUnknownWordMatches = [localeName isEqualToString:[self getUnknownSearchWord]]
            || [[self getNameStringMatcher] matches:localeName]
            || [[self getNameStringMatcher] matchesMap:otherNames];
}

- (int) getRadiusSearch:(int)meters
{
    return (1 << ([self getRadiusLevel] - 1)) * meters;
}

- (int) getNextRadiusSearch:(int) meters
{
    return (1 << [self getRadiusLevel]) * meters;
}

+ (NSComparisonResult) icompare:(int)x y:(int)y
{
    return (x < y) ? NSOrderedAscending : ((x == y) ? NSOrderedSame : NSOrderedDescending);
}

- (NSString *) getUnknownWordToSearchBuilding
{
    NSArray<NSString *> *unknownSearchWords = [self getUnknownSearchWords];
    if (unknownSearchWords.count > 0 && [OAUtilities extractFirstIntegerNumber:[self getUnknownSearchWord]] == 0)
    {
        for (NSString *wrd in unknownSearchWords)
        {
            if ([OAUtilities extractFirstIntegerNumber:wrd] != 0)
                return wrd;
        }
    }
    return [self getUnknownSearchWord];
}

- (int) lengthWithoutNumbers:(NSString *)s
{
    int len = 0;
    for(int k = 0; k < s.length; k++)
    {
        if ([s characterAtIndex:k] >= '0' && [s characterAtIndex:k] <= '9')
        {
        }
        else
        {
            len++;
        }
    }
    return len;
}

- (NSString *) getUnknownWordToSearch
{
    NSArray<NSString *> *unknownSearchWords = [self getUnknownSearchWords];
    
    NSString *wordToSearch = [self getUnknownSearchWord];
    if (unknownSearchWords.count > 0)
    {
        NSMutableArray<NSString *> *searchWords = [NSMutableArray arrayWithArray:unknownSearchWords];
        [searchWords insertObject:[self getUnknownSearchWord] atIndex:0];
        [searchWords sortUsingComparator:^NSComparisonResult(NSString * _Nonnull o1, NSString * _Nonnull o2)
        {
            int i1 = OsmAnd::CommonWords::getCommonSearch(QString::fromNSString([o1 lowerCase]));
            int i2 = OsmAnd::CommonWords::getCommonSearch(QString::fromNSString([o2 lowerCase]));
            if (i1 != i2)
                return [self.class icompare:i1 y:i2];
            
            // compare length without numbers to not include house numbers
            return (NSComparisonResult)-[self.class icompare:[self lengthWithoutNumbers:o1] y:[self lengthWithoutNumbers:o2]];
        }];
        for (NSString *s in searchWords)
            if (s.length > 0 && !isdigit([s characterAtIndex:0]))
                return s;
    }
    
    return wordToSearch;
}

@end
