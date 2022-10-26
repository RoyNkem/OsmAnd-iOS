//
//  OASearchCoreAPI.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASearchCoreAPI.h"

@implementation OASearchCoreAPI

- (int) getSearchPriority:(OASearchPhrase *)p
{
    // not implemented
    return 0;
}

- (BOOL) search:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher
{
    // not implemented
    return NO;
}

- (BOOL) isSearchMoreAvailable:(OASearchPhrase *)phrase
{
    // not implemented
    return NO;
}

- (BOOL) isSearchAvailable:(OASearchPhrase *)phrase
{
    // not implemented
    return NO;
}

- (BOOL) isSearchDone:(OASearchPhrase *)phrase
{
    // not implemented
    return NO;
}

- (int) getMinimalSearchRadius:(OASearchPhrase *)phrase
{
    return 0;
}

- (int) getNextSearchRadius:(OASearchPhrase *)phrase
{
    return 0;
}

@end
