//
//  OASearchUICore.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASearchUICore.h"

#import "OASearchPhrase.h"
#import "OASearchWord.h"
#import "OASearchSettings.h"
#import "OAAtomicInteger.h"
#import "OASearchCoreAPI.h"
#import "OAPOIHelper.h"
#import "OAUtilities.h"
#import "OASearchResultMatcher.h"
#import "OASearchCoreFactory.h"
#import "OACustomSearchPoiFilter.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/ICU.h>

static const double TIMEOUT_BETWEEN_CHARS = 0.7;  // seconds
static const double TIMEOUT_BEFORE_SEARCH = 0.05; // seconds
static const double TIMEOUT_BEFORE_FILTER = 0.02; // seconds
static const int DEPTH_TO_CHECK_SAME_SEARCH_RESULTS = 20;

@interface OASearchUICore ()

@end


@interface OASearchResultComparator ()

@property (nonatomic) NSComparator comparator;
@property (nonatomic) OASearchPhrase *phrase;
@property (nonatomic) CLLocation *loc;
@property (nonatomic) BOOL sortByName;

@end

@implementation OASearchResultComparator

- (instancetype) initWithPhrase:(OASearchPhrase *)phrase
{
    self = [super init];
    if (self)
    {
        _phrase = phrase;
        _loc = [phrase getLastTokenLocation];
        _sortByName = [phrase isSortByName];
    
        __weak OASearchResultComparator *weakSelf = self;
        _comparator = ^NSComparisonResult(OASearchResult * _Nonnull o1, OASearchResult * _Nonnull o2)
        {
            BOOL topVisible1 = [OAObjectType isTopVisible:o1.objectType];
            BOOL topVisible2 = [OAObjectType isTopVisible:o2.objectType];
            if (topVisible1 != topVisible2)
            {
                // -1 - means 1st is less than 2nd
                return topVisible1 ? NSOrderedAscending : NSOrderedDescending;
            }
            if (o1.unknownPhraseMatchWeight != o2.unknownPhraseMatchWeight)
                return [OAUtilities compareDouble:o2.unknownPhraseMatchWeight y:o1.unknownPhraseMatchWeight];

            if (o1.getFoundWordCount != o2.getFoundWordCount)
                return [OAUtilities compareInt:o2.getFoundWordCount y:o1.getFoundWordCount];

            if (!weakSelf.sortByName)
            {
                double s1 = [o1 getSearchDistance:weakSelf.loc];
                double s2 = [o2 getSearchDistance:weakSelf.loc];
                if (s1 != s2)
                    return [OAUtilities compareDouble:s1 y:s2];
            }
            QString o1name = QString::fromNSString(o1.localeName);
            QString o2name = QString::fromNSString(o2.localeName);
            int st1 = OsmAnd::Utilities::extractFirstInteger(o1name);
            int st2 = OsmAnd::Utilities::extractFirstInteger(o2name);
            if (st1 != st2)
                return [OAUtilities compareInt:st1 y:st2];
            
            double s1 = [o1 getSearchDistance:weakSelf.loc pd:1];
            double s2 = [o2 getSearchDistance:weakSelf.loc pd:1];
            double ps1 = !o1.parentSearchResult ? 0 : [o1.parentSearchResult getSearchDistance:weakSelf.loc];
            double ps2 = !o2.parentSearchResult ? 0 : [o2.parentSearchResult getSearchDistance:weakSelf.loc];
            if (ps1 != ps2)
                return [OAUtilities compareDouble:ps1 y:ps2];
            
            NSComparisonResult cmp = (NSComparisonResult)OsmAnd::ICU::ccompare(o1name, o2name);
            if (cmp != NSOrderedSame)
                return cmp;
            if (s1 != s2)
                return [OAUtilities compareDouble:s1 y:s2];
            
            BOOL am1 = std::dynamic_pointer_cast<const OsmAnd::Amenity>(o1.amenity) != nullptr;
            BOOL am2 = std::dynamic_pointer_cast<const OsmAnd::Amenity>(o2.amenity) != nullptr;
            if (am1 != am2)
            {
                return am1 ? NSOrderedDescending : NSOrderedAscending;
            }
            else if (am1 && am2)
            {
                const auto& a1 = std::dynamic_pointer_cast<const OsmAnd::Amenity>(o1.amenity);
                const auto& a2 = std::dynamic_pointer_cast<const OsmAnd::Amenity>(o2.amenity);
                cmp = (NSComparisonResult)OsmAnd::ICU::ccompare(a1->type, a2->type);
                if (cmp != NSOrderedSame)
                    return cmp;
                
                cmp = (NSComparisonResult)OsmAnd::ICU::ccompare(a1->subType, a2->subType);
                if (cmp != NSOrderedSame)
                    return cmp;
            }
            return NSOrderedSame;
        };
    }
    return self;
}

@end


@interface OASearchResultCollection ()

@end

@implementation OASearchResultCollection
{
    NSMutableArray<OASearchResult *> *_searchResults;
}

- (instancetype)initWithPhrase:(OASearchPhrase *)phrase
{
    self = [super init];
    if (self)
    {
        _searchResults = [NSMutableArray array];
        _phrase = phrase;
        
    }
    return self;
}

- (NSMutableArray<OASearchResult *> *) getSearchResults
{
    return _searchResults;
}

- (OASearchResultCollection *) combineWithCollection:(OASearchResultCollection *)collection resort:(BOOL)resort removeDuplicates:(BOOL)removeDuplicates
{
    OASearchResultCollection *src = [[OASearchResultCollection alloc] initWithPhrase:_phrase];
    [src addSearchResults:_searchResults resortAll:false removeDuplicates:false];
    [src addSearchResults:[collection getSearchResults] resortAll:resort removeDuplicates:removeDuplicates];
    return src;
}

- (OASearchResultCollection *) addSearchResults:(NSArray<OASearchResult *> *)sr resortAll:(BOOL)resortAll removeDuplicates:(BOOL)removeDuplicates
{
    if (resortAll)
    {
        [_searchResults addObjectsFromArray:sr];
        [self sortSearchResults];
        if (removeDuplicates)
            [self filterSearchDuplicateResults];
    }
    else
    {
        if (!removeDuplicates)
        {
            [_searchResults addObjectsFromArray:sr];
        }
        else
        {
            NSMutableArray<OASearchResult *> *addedResults = [NSMutableArray arrayWithArray:sr];
            OASearchResultComparator *cmp = [[OASearchResultComparator alloc] initWithPhrase:_phrase];
            [addedResults sortUsingComparator:cmp.comparator];
            [self filterSearchDuplicateResults:addedResults];
            int i = 0;
            int j = 0;
            while(j < addedResults.count)
            {
                OASearchResult *addedResult = addedResults[j];
                if (i >= _searchResults.count)
                {
                    int k = 0;
                    bool same = false;
                    while (_searchResults.count > k && k < DEPTH_TO_CHECK_SAME_SEARCH_RESULTS)
                    {
                        if ([self sameSearchResult:addedResult r2:_searchResults[_searchResults.count - k - 1]])
                        {
                            same = true;
                            break;
                        }
                        k++;
                    }
                    if (!same)
                        [_searchResults addObject:addedResult];
                    
                    j++;
                    continue;
                }
                OASearchResult *existingResult = _searchResults[i];
                if ([self sameSearchResult:addedResult r2:existingResult])
                {
                    j++;
                    continue;
                }
                int compare = cmp.comparator(existingResult, addedResult);
                if (compare == 0)
                {
                    // existingResult == addedResult
                    j++;
                }
                else if(compare > 0)
                {
                    // existingResult > addedResult
                    [_searchResults addObject:addedResults[j]];
                    j++;
                }
                else
                {
                    // existingResult < addedResult
                    i++;
                }
            }
        }
    }
    return self;
}

- (NSArray<OASearchResult *> *) getCurrentSearchResults
{
    return [NSArray arrayWithArray:_searchResults];
}

- (void) sortSearchResults
{
    OASearchResultComparator *cmp = [[OASearchResultComparator alloc] initWithPhrase:_phrase];
    [_searchResults sortUsingComparator:cmp.comparator];
}

- (void) filterSearchDuplicateResults
{
    [self filterSearchDuplicateResults:_searchResults];
}

- (void) filterSearchDuplicateResults:(NSMutableArray<OASearchResult *> *)lst
{
    NSMutableArray<OASearchResult *> *remove = [NSMutableArray array];
    NSMutableArray<OASearchResult *> *lstUnique = [NSMutableArray array];
    for (OASearchResult *r in lst)
    {
        bool same = false;
        for (OASearchResult *rs in lstUnique)
        {
            same = [self sameSearchResult:rs r2:r];
            if (same)
                break;
        }
        if (same)
        {
            [remove addObject:r];
        }
        else
        {
            [lstUnique addObject:r];
            if (lstUnique.count > DEPTH_TO_CHECK_SAME_SEARCH_RESULTS)
                [lstUnique removeObjectAtIndex:0];
        }
    }
    [lst removeObjectsInArray:remove];
}

- (BOOL) sameSearchResult:(OASearchResult *)r1 r2:(OASearchResult *)r2
{
    if (r1.location && r2.location && ![OAObjectType isTopVisible:r1.objectType] && ![OAObjectType isTopVisible:r2.objectType])
    {
        std::shared_ptr<const OsmAnd::Amenity> a1;
        if (r1.objectType == POI)
            a1 = r1.amenity;

        std::shared_ptr<const OsmAnd::Amenity> a2;
        if (r2.objectType == POI)
            a2 = r2.amenity;

        if ([r1.localeName isEqualToString:r2.localeName])
        {
            double similarityRadius = 30;
            if (a1 && a2)
            {
                // here 2 points are amenity
                if (a1->id.id == a2->id.id && (a1->subType == QStringLiteral("building") || a2->subType == QStringLiteral("building")))
                    return true;
                
                if (a1->type != a2->type)
                    return false;
                
                if (a1->type == QStringLiteral("natural"))
                {
                    similarityRadius = 50000;
                }
                else if (a1->subType == a2->subType)
                {
                    if (a1->subType.contains(QStringLiteral("cn_ref")) || a1->subType.contains(QStringLiteral("wn_ref"))
                        || (a1->subType.startsWith(QStringLiteral("route_hiking_")) && a1->subType.endsWith(QStringLiteral("n_poi"))))
                    {
                        similarityRadius = 50000;
                    }
                }
            }
            else if([OAObjectType isAddress:r1.objectType] && [OAObjectType isAddress:r2.objectType])
            {
                similarityRadius = 100;
            }
            return [r1.location distanceFromLocation:r2.location] < similarityRadius;
        }
    }
    else if (r1.object && r2.object)
    {
        return r1.object == r2.object;
    }
    return false;
}

@end


@implementation OASearchUICore
{
    OASearchPhrase *_phrase;
    OASearchResultCollection *_currentSearchResult;
    
    dispatch_queue_t _taskQueue;
    OAAtomicInteger *_requestNumber;
    int totalLimit; // -1 unlimited - not used
    
    NSMutableArray<OASearchCoreAPI *> *_apis;
    OASearchSettings *_searchSettings;
    OAPOIHelper *_poiTypes;
}

- (instancetype)initWithLang:(NSString *)lang transliterate:(BOOL)transliterate
{
    self = [super init];
    if (self)
    {
        _taskQueue = dispatch_queue_create("OASearchUICore_taskQueue", DISPATCH_QUEUE_SERIAL);
        _requestNumber = [OAAtomicInteger atomicInteger:0];
        totalLimit = -1;
        _apis = [NSMutableArray array];
        _poiTypes = [OAPOIHelper sharedInstance];
        
        _searchSettings = [[OASearchSettings alloc] init];
        _searchSettings = [_searchSettings setLang:lang transliterateIfMissing:transliterate];
        _phrase = [OASearchPhrase emptyPhrase:_searchSettings];
        _currentSearchResult = [[OASearchResultCollection alloc] initWithPhrase:_phrase];
    }
    return self;
}

- (OASearchCoreAPI *) getApiByClass:(Class)cl
{
    for (OASearchCoreAPI *a in _apis)
        if ([a isKindOfClass:cl])
            return a;

    return nil;
}

- (OASearchResultCollection *) shallowSearch:(Class)cl text:(NSString *)text matcher:(OAResultMatcher<OASearchResult *> *)matcher
{
    OASearchCoreAPI *api = [self getApiByClass:cl];
    if (api)
    {
        OASearchPhrase *sphrase = [_phrase generateNewPhrase:text settings:_searchSettings];
        [self preparePhrase:sphrase];
        OAAtomicInteger *ai = [OAAtomicInteger atomicInteger:0];
        OASearchResultMatcher *rm = [[OASearchResultMatcher alloc] initWithMatcher:matcher phrase:sphrase request:[ai get] requestNumber:ai totalLimit:totalLimit];
        [api search:sphrase resultMatcher:rm];
        
        OASearchResultCollection *collection = [[OASearchResultCollection alloc] initWithPhrase:sphrase];
        [collection addSearchResults:[rm getRequestResults] resortAll:YES removeDuplicates:YES];

        NSLog(@">> Shallow Search phrase %@ %d", [_phrase toString], (int)([rm getRequestResults].count));

        return collection;
    }
    return nil;
}

- (void) initApi
{
    [_apis addObject:[[OASearchLocationAndUrlAPI alloc] init]];
    OASearchAmenityTypesAPI *searchAmenityTypesAPI = [[OASearchAmenityTypesAPI alloc] init];
    [_apis addObject:searchAmenityTypesAPI];
    [_apis addObject:[[OASearchAmenityByTypeAPI alloc] initWithTypesAPI:searchAmenityTypesAPI]];
    [_apis addObject:[[OASearchAmenityByNameAPI alloc] init]];
    OASearchBuildingAndIntersectionsByStreetAPI *streetsApi = [[OASearchBuildingAndIntersectionsByStreetAPI alloc] init];
    [_apis addObject:streetsApi];
    OASearchStreetByCityAPI *cityApi = [[OASearchStreetByCityAPI alloc] initWithAPI:streetsApi];
    [_apis addObject:cityApi];
    [_apis addObject:[[OASearchAddressByNameAPI alloc] initWithCityApi:cityApi streetsApi:streetsApi]];
}

- (void) clearCustomSearchPoiFilters
{
    for (OASearchCoreAPI *capi in _apis)
        if ([capi isKindOfClass:[OASearchAmenityTypesAPI class]])
            [((OASearchAmenityTypesAPI *) capi) clearCustomFilters];
}

- (void) addCustomSearchPoiFilter:(OACustomSearchPoiFilter *)poiFilter  priority:(int)priority
{
    for (OASearchCoreAPI *capi in _apis)
        if ([capi isKindOfClass:[OASearchAmenityTypesAPI class]])
            [((OASearchAmenityTypesAPI *) capi) addCustomFilter:poiFilter priority:priority];
}

- (void) setActivePoiFiltersByOrder:(NSArray<NSString *> *)filterOrders
{
    for (OASearchCoreAPI *capi : _apis)
    {
        if ([capi isKindOfClass:[OASearchAmenityTypesAPI class]])
            [((OASearchAmenityTypesAPI *) capi) setActivePoiFiltersByOrder:filterOrders];
    }
}

- (void) registerAPI:(OASearchCoreAPI *)api
{
    [_apis addObject:api];
}


- (OASearchResultCollection *) getCurrentSearchResult
{
    return _currentSearchResult;
}

- (OASearchPhrase *) getPhrase
{
    return _phrase;
}

- (OASearchSettings *) getSearchSettings
{
    return _searchSettings;
}

- (void) updateSettings:(OASearchSettings *)settings
{
    _searchSettings = settings;
}

- (void) filterCurrentResults:(OASearchPhrase *)phrase matcher:(OAResultMatcher<OASearchResult *> *)matcher
{
    if (!matcher)
        return;
    
    NSArray<OASearchResult *> *l = [_currentSearchResult getSearchResults];
    for (OASearchResult *r in l)
    {
        if ([self filterOneResult:r phrase:phrase])
            [matcher publish:r];
        
        if ([matcher isCancelled])
            return;
    }
}

- (BOOL) filterOneResult:(OASearchResult *)object phrase:(OASearchPhrase *)phrase
{
    OANameStringMatcher *nameStringMatcher = [phrase getFirstUnknownNameStringMatcher];
    return [nameStringMatcher matches:object.localeName] || [nameStringMatcher matchesMap:object.otherNames];
}

- (BOOL) selectSearchResult:(OASearchResult *)r
{
    _phrase = [_phrase selectWord:r];
    return YES;
}

- (OASearchPhrase *) resetPhrase
{
    _phrase = [_phrase generateNewPhrase:@"" settings:_searchSettings];
    return _phrase;
}

- (OASearchPhrase *) resetPhrase:(NSString *)text
{
    _phrase = [_phrase generateNewPhrase:text settings:_searchSettings];
    return _phrase;
}

- (void) cancelSearch
{
    [_requestNumber incrementAndGet];
}

- (void) search:(NSString *)text delayedExecution:(BOOL)delayedExecution matcher:(OAResultMatcher<OASearchResult *> *)matcher
{
    int request = [_requestNumber incrementAndGet];
    OASearchPhrase *phrase = [_phrase generateNewPhrase:text settings:_searchSettings];
    _phrase = phrase;
    NSLog(@"> Search phrase %@", [_phrase toString]);
    
    dispatch_async(_taskQueue, ^{
        try
        {
            if (_onSearchStart)
                _onSearchStart();
            
            OASearchResultMatcher *rm = [[OASearchResultMatcher alloc] initWithMatcher:matcher phrase:phrase request:request requestNumber:_requestNumber totalLimit:totalLimit];
            [rm searchStarted:phrase];
            if (delayedExecution)
            {
                NSTimeInterval startTime = CACurrentMediaTime();
                BOOL filtered = NO;
                while (CACurrentMediaTime() - startTime <= TIMEOUT_BETWEEN_CHARS)
                {
                    if ([rm isCancelled])
                        return;
                    
                    [NSThread sleepForTimeInterval:TIMEOUT_BEFORE_FILTER];
                    
                    if (!filtered)
                    {
                        OASearchResultCollection *quickRes = [[OASearchResultCollection alloc] initWithPhrase:phrase];
                        [self filterCurrentResults:phrase matcher:[[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OASearchResult *__autoreleasing *searchResult) {
                            [[quickRes getSearchResults] addObject:*searchResult];
                            return YES;
                        } cancelledFunc:^BOOL{
                            return [rm isCancelled];
                        }]];
                        
                        if (![rm isCancelled])
                        {
                            _currentSearchResult = quickRes;
                            [rm filterFinished:phrase];
                        }
                        filtered = YES;
                    }
                }
            }
            else
            {
                [NSThread sleepForTimeInterval:TIMEOUT_BEFORE_SEARCH];
            }
            
            if ([rm isCancelled])
                return;
            
            [self searchInBackground:phrase matcher:rm];
            if (![rm isCancelled])
            {
                OASearchResultCollection *collection = [[OASearchResultCollection alloc] initWithPhrase:phrase];
                [collection addSearchResults:[rm getRequestResults] resortAll:YES removeDuplicates:YES];
                NSLog(@">> Search phrase %@ %d", [phrase toString], (int)([rm getRequestResults].count));
                _currentSearchResult = collection;
                [rm searchFinished:phrase];
                if (_onResultsComplete)
                    _onResultsComplete();
            }
        }
        catch (NSException *e)
        {
            NSLog(@"OASearchUICore.search error %@", e);
        }
    });
}

- (BOOL) isSearchMoreAvailable:(OASearchPhrase *)phrase
{
    for (OASearchCoreAPI *api in _apis)
        if ([api isSearchAvailable:phrase] && [api getSearchPriority:phrase] >= 0 && [api isSearchMoreAvailable:phrase])
            return YES;

    return NO;
}

- (int) getMinimalSearchRadius:(OASearchPhrase *)phrase
{
    int radius = INT_MAX;
    for (OASearchCoreAPI *api in _apis)
    {
        if ([api isSearchAvailable:phrase] && [api getSearchPriority:phrase] != -1)
        {
            int apiMinimalRadius = [api getMinimalSearchRadius:phrase];
            if (apiMinimalRadius > 0 && apiMinimalRadius < radius)
                radius = apiMinimalRadius;
        }
    }
    return radius;
}

- (int) getNextSearchRadius:(OASearchPhrase *)phrase
{
    int radius = INT_MAX;
    for (OASearchCoreAPI *api in _apis)
    {
        if ([api isSearchAvailable:phrase] && [api getSearchPriority:phrase] != -1)
        {
            int apiNextSearchRadius = [api getNextSearchRadius:phrase];
            if (apiNextSearchRadius > 0 && apiNextSearchRadius < radius)
                radius = apiNextSearchRadius;
        }
    }
    return radius;
}
    
- (OAPOIBaseType *) getUnselectedPoiType
{
    for (OASearchCoreAPI *capi in _apis)
    {
        if ([capi isKindOfClass:OASearchAmenityByTypeAPI.class]) {
            return [((OASearchAmenityByTypeAPI *) capi) getUnselectedPoiType];
        }
    }
    return nil;
}

- (NSString *) getCustomNameFilter
{
    for (OASearchCoreAPI *capi : _apis)
    {
        if ([capi isKindOfClass:OASearchAmenityByTypeAPI.class]) {
            return [((OASearchAmenityByTypeAPI *) capi) getNameFilter];
        }
    }
    return nil;
}

- (void) searchInBackground:(OASearchPhrase *)phrase matcher:(OASearchResultMatcher *)matcher
{
    [self preparePhrase:phrase];
    NSMutableArray<OASearchCoreAPI *> *lst = [NSMutableArray arrayWithArray:_apis];
    [lst sortUsingComparator:^NSComparisonResult(OASearchCoreAPI * _Nonnull o1, OASearchCoreAPI * _Nonnull o2) {
        return [OAUtilities compareInt:[o1 getSearchPriority:phrase] y:[o2 getSearchPriority:phrase]];
    }];

    for (OASearchCoreAPI *api in lst)
    {
        if ([matcher isCancelled])
            break;
        
        if (![api isSearchAvailable:phrase] || [api getSearchPriority:phrase] == -1)
            continue;
        
        try
        {
            [api search:phrase resultMatcher:matcher];
            
            if (![matcher isCancelled])
                [matcher apiSearchFinished:api phrase:phrase];
        }
        catch (NSException *e)
        {
            NSLog(@"OASearchUICore.searchInBackground error %@", e);
        }
    }
}

- (void) preparePhrase:(OASearchPhrase *)phrase
{
    for (OASearchWord *sw in [phrase getWords])
        if (sw.result && sw.result.resourceId)
            [phrase selectFile:sw.result.resourceId];

    [phrase sortFiles];
}

@end
