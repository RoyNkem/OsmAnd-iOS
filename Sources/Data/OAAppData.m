//
//  OAAppData.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAAppData.h"
#import "OAHistoryHelper.h"
#import "OAPointDescription.h"
#import "OAAutoObserverProxy.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"

#include <objc/runtime.h>

#define kLastMapSourceKey @"lastMapSource"
#define kOverlaySourceKey @"overlayMapSource"
#define kUnderlaySourceKey @"underlayMapSource"
#define kLastOverlayKey @"lastOverlayMapSource"
#define kLastUnderlayKey @"lastUnderlayMapSource"
#define kOverlayAlphaKey @"overlayAlpha"
#define kUnderlayAlphaKey @"underlayAlpha"
#define kMapLayersConfigurationKey @"mapLayersConfiguration"

#define kTerrainTypeKey @"terrainType"
#define kLastTerrainTypeKey @"lastTerrainType"
#define kHillshadeAlphaKey @"hillshadeAlpha"
#define kSlopeAlphaKey @"slopeAlpha"
#define kHillshadeMinZoomKey @"hillshadeMinZoom"
#define kHillshadeMaxZoomKey @"hillshadeMaxZoom"
#define kSlopeMinZoomKey @"slopeMinZoom"
#define kSlopeMaxZoomKey @"slopeMaxZoom"
#define kMapillaryKey @"mapillary"

@implementation OAAppData
{
    NSObject* _lock;
    NSMutableDictionary* _lastMapSources;
    
    OAAutoObserverProxy *_applicationModeChangedObserver;
    
    NSMutableArray<OARTargetPoint *> *_intermediates;
    
    OAProfileMapSource *_lastMapSourceProfile;
    OAProfileMapSource *_overlayMapSourceProfile;
    OAProfileMapSource *_lastOverlayMapSourceProfile;
    OAProfileMapSource *_underlayMapSourceProfile;
    OAProfileMapSource  *_lastUnderlayMapSourceProfile;
    OAProfileDouble *_overlayAlphaProfile;
    OAProfileDouble *_underlayAlphaProfile;
    OAProfileMapLayersConfiguartion *_mapLayersConfigurationProfile;
    OAProfileTerrain *_terrainTypeProfile;
    OAProfileTerrain *_lastTerrainTypeProfile;
    OAProfileDouble *_hillshadeAlphaProfile;
    OAProfileInteger *_hillshadeMinZoomProfile;
    OAProfileInteger *_hillshadeMaxZoomProfile;
    OAProfileDouble *_slopeAlphaProfile;
    OAProfileInteger *_slopeMinZoomProfile;
    OAProfileInteger *_slopeMaxZoomProfile;
    OAProfileBoolean *_mapillaryProfile;
}

@synthesize applicationModeChangedObservable = _applicationModeChangedObservable;

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
        [self safeInit];
    }
    return self;
}

- (void) setSettingValue:(NSString *)value forKey:(NSString *)key mode:(OAApplicationMode *)mode
{
    @synchronized (_lock)
    {
        if ([key isEqualToString:@"terrain_mode"])
        {
            [_lastTerrainTypeProfile setValueFromString:value appMode:mode];
        }
        else if ([key isEqualToString:@"hillshade_min_zoom"])
        {
            [_hillshadeMinZoomProfile setValueFromString:value appMode:mode];
        }
        else if ([key isEqualToString:@"hillshade_max_zoom"])
        {
            [_hillshadeMaxZoomProfile setValueFromString:value appMode:mode];
        }
        else if ([key isEqualToString:@"hillshade_transparency"])
        {
            double alpha = [value doubleValue] / 100;
            [_hillshadeAlphaProfile set:alpha mode:mode];
        }
        else if ([key isEqualToString:@"slope_transparency"])
        {
            double alpha = [value doubleValue] / 100;
            [_slopeAlphaProfile set:alpha mode:mode];
        }
        else if ([key isEqualToString:@"slope_min_zoom"])
        {
            [_slopeMinZoomProfile setValueFromString:value appMode:mode];
        }
        else if ([key isEqualToString:@"slope_max_zoom"])
        {
            [_slopeMaxZoomProfile setValueFromString:value appMode:mode];
        }
        else if ([key isEqualToString:@"show_mapillary"])
        {
            [_mapillaryProfile setValueFromString:value appMode:mode];
        }
    }
}

- (void) commonInit
{
    _lock = [[NSObject alloc] init];
    _lastMapSourceChangeObservable = [[OAObservable alloc] init];

    _overlayMapSourceChangeObservable = [[OAObservable alloc] init];
    _overlayAlphaChangeObservable = [[OAObservable alloc] init];
    _underlayMapSourceChangeObservable = [[OAObservable alloc] init];
    _underlayAlphaChangeObservable = [[OAObservable alloc] init];
    _terrainChangeObservable = [[OAObservable alloc] init];
    _terrainResourcesChangeObservable = [[OAObservable alloc] init];
    _terrainAlphaChangeObservable = [[OAObservable alloc] init];
    _mapLayerChangeObservable = [[OAObservable alloc] init];
    _mapillaryChangeObservable = [[OAObservable alloc] init];

    _destinationsChangeObservable = [[OAObservable alloc] init];
    _destinationAddObservable = [[OAObservable alloc] init];
    _destinationRemoveObservable = [[OAObservable alloc] init];
    _destinationShowObservable = [[OAObservable alloc] init];
    _destinationHideObservable = [[OAObservable alloc] init];
    
    _applicationModeChangedObservable = [[OAObservable alloc] init];
    _applicationModeChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                           withHandler:@selector(onAppModeChanged)
                                                            andObserve:_applicationModeChangedObservable];
    // Profile settings
    _lastMapSourceProfile = [OAProfileMapSource withKey:kLastMapSourceKey defValue:[[OAMapSource alloc] initWithResource:@"default.render.xml"
                                                                                                              andVariant:@"type_default"]];
    _overlayMapSourceProfile = [OAProfileMapSource withKey:kOverlaySourceKey defValue:nil];
    _underlayMapSourceProfile = [OAProfileMapSource withKey:kUnderlaySourceKey defValue:nil];
    _lastOverlayMapSourceProfile = [OAProfileMapSource withKey:kLastOverlayKey defValue:nil];
    _lastUnderlayMapSourceProfile = [OAProfileMapSource withKey:kLastUnderlayKey defValue:nil];
    _overlayAlphaProfile = [OAProfileDouble withKey:kOverlayAlphaKey defValue:0.5];
    _underlayAlphaProfile = [OAProfileDouble withKey:kUnderlayAlphaKey defValue:0.5];
    _terrainTypeProfile = [OAProfileTerrain withKey:kTerrainTypeKey defValue:EOATerrainTypeDisabled];
    _lastTerrainTypeProfile = [OAProfileTerrain withKey:kLastTerrainTypeKey defValue:EOATerrainTypeHillshade];
    _hillshadeAlphaProfile = [OAProfileDouble withKey:kHillshadeAlphaKey defValue:0.45];
    _slopeAlphaProfile = [OAProfileDouble withKey:kSlopeAlphaKey defValue:0.35];
    _hillshadeMinZoomProfile = [OAProfileInteger withKey:kHillshadeMinZoomKey defValue:3];
    _hillshadeMaxZoomProfile = [OAProfileInteger withKey:kHillshadeMaxZoomKey defValue:16];
    _slopeMinZoomProfile = [OAProfileInteger withKey:kSlopeMinZoomKey defValue:3];
    _slopeMaxZoomProfile = [OAProfileInteger withKey:kSlopeMaxZoomKey defValue:16];
    _mapillaryProfile = [OAProfileBoolean withKey:kMapillaryKey defValue:NO];
    _mapLayersConfigurationProfile = [OAProfileMapLayersConfiguartion withKey:kMapLayersConfigurationKey defValue:[[OAMapLayersConfiguration alloc] init]];

}

- (void) dealloc
{
    if (_applicationModeChangedObserver)
    {
        [_applicationModeChangedObserver detach];
        _applicationModeChangedObserver = nil;
    }
}

- (void) onAppModeChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_overlayAlphaChangeObservable notifyEventWithKey:self andValue:@(self.overlayAlpha)];
        [_underlayAlphaChangeObservable notifyEventWithKey:self andValue:@(self.underlayAlpha)];
        [_terrainChangeObservable notifyEventWithKey:self andValue:@YES];
        if (self.terrainType != EOATerrainTypeDisabled)
            [_terrainAlphaChangeObservable notifyEventWithKey:self andValue:self.terrainType == EOATerrainTypeHillshade ? @(self.hillshadeAlpha) : @(self.slopeAlpha)];
        [_lastMapSourceChangeObservable notifyEventWithKey:self andValue:self.lastMapSource];
        [self setLastMapSourceVariant:[OAAppSettings sharedManager].applicationMode.variantKey];
    });
}

- (void) safeInit
{
    if (_lastMapSources == nil)
        _lastMapSources = [[NSMutableDictionary alloc] init];
    if (_mapLastViewedState == nil)
        _mapLastViewedState = [[OAMapViewState alloc] init];
    if (_destinations == nil)
        _destinations = [NSMutableArray array];
    if (_intermediates == nil)
        _intermediates = [NSMutableArray array];
    
    if (isnan(_mapLastViewedState.zoom) || _mapLastViewedState.zoom < 1.0f || _mapLastViewedState.zoom > 23.0f)
        _mapLastViewedState.zoom = 3.0f;
    
    if (_mapLastViewedState.target31.x < 0 || _mapLastViewedState.target31.y < 0)
    {
        Point31 p;
        p.x = 1073741824;
        p.y = 1073741824;
        _mapLastViewedState.target31 = p;
        _mapLastViewedState.zoom = 3.0f;
    }
    
}

- (OAMapSource*) lastMapSource
{
    @synchronized(_lock)
    {
        return [_lastMapSourceProfile get];
    }
}

- (OAMapSource *) getLastMapSource:(OAApplicationMode *)mode
{
    @synchronized (_lock)
    {
        return [_lastMapSourceProfile get:mode];
    }
}

- (void) setLastMapSource:(OAMapSource *)lastMapSource mode:(OAApplicationMode *)mode
{
    @synchronized(_lock)
    {
        if (![lastMapSource isEqual:[_lastMapSourceProfile get:mode]])
        {
            OAMapSource *savedSource = [_lastMapSourceProfile get:mode];
            // Store previous, if such exists
            if (savedSource != nil)
            {
                [_lastMapSources setObject:savedSource.variant != nil ? savedSource.variant : [NSNull null]
                                    forKey:savedSource.resourceId];
            }
            [_lastMapSourceProfile set:[lastMapSource copy] mode:mode];
        }
    }
}

- (void) setLastMapSource:(OAMapSource*)lastMapSource
{
    @synchronized(_lock)
    {
        if (![lastMapSource isEqual:self.lastMapSource])
        {
            OAMapSource *savedSource = [_lastMapSourceProfile get];
            // Store previous, if such exists
            if (savedSource != nil)
            {
                [_lastMapSources setObject:savedSource.variant != nil ? savedSource.variant : [NSNull null]
                                    forKey:savedSource.resourceId];
            }
            
            // Save new one
            [_lastMapSourceProfile set:[lastMapSource copy]];
            [_lastMapSourceChangeObservable notifyEventWithKey:self andValue:self.lastMapSource];
        }
    }
}

- (void) setLastMapSourceVariant:(NSString *)variant
{
    OAMapSource *lastSource = self.lastMapSource;
    if ([lastSource.resourceId isEqualToString:@"online_tiles"])
        return;
    
    OAMapSource *mapSource = [[OAMapSource alloc] initWithResource:lastSource.resourceId andVariant:variant name:lastSource.name];
    [_lastMapSourceProfile set:mapSource];
}

@synthesize lastMapSourceChangeObservable = _lastMapSourceChangeObservable;

- (OAMapSource*) lastMapSourceByResourceId:(NSString*)resourceId
{
    @synchronized(_lock)
    {
        OAMapSource *lastMapSource = self.lastMapSource;
        if (lastMapSource != nil && [lastMapSource.resourceId isEqualToString:resourceId])
            return lastMapSource;

        NSNull* variant = [_lastMapSources objectForKey:resourceId];
        if (variant == nil || variant == [NSNull null])
            return nil;

        return [[OAMapSource alloc] initWithResource:resourceId
                                          andVariant:(NSString*)variant];
    }
}

@synthesize overlayMapSourceChangeObservable = _overlayMapSourceChangeObservable;
@synthesize overlayAlphaChangeObservable = _overlayAlphaChangeObservable;
@synthesize underlayMapSourceChangeObservable = _underlayMapSourceChangeObservable;
@synthesize underlayAlphaChangeObservable = _underlayAlphaChangeObservable;
@synthesize destinationsChangeObservable = _destinationsChangeObservable;
@synthesize destinationAddObservable = _destinationAddObservable;
@synthesize destinationRemoveObservable = _destinationRemoveObservable;
@synthesize terrainChangeObservable = _terrainChangeObservable;
@synthesize terrainResourcesChangeObservable = _terrainResourcesChangeObservable;
@synthesize terrainAlphaChangeObservable = _terrainAlphaChangeObservable;
@synthesize mapLayerChangeObservable = _mapLayerChangeObservable;
@synthesize mapillaryChangeObservable = _mapillaryChangeObservable;

- (OAMapSource*) overlayMapSource
{
    @synchronized(_lock)
    {
        return [_overlayMapSourceProfile get];
    }
}

- (void) setOverlayMapSource:(OAMapSource*)overlayMapSource
{
    @synchronized(_lock)
    {
        [_overlayMapSourceProfile set:[overlayMapSource copy]];
        [_overlayMapSourceChangeObservable notifyEventWithKey:self andValue:self.overlayMapSource];
    }
}

- (OAMapSource*) lastOverlayMapSource
{
    @synchronized(_lock)
    {
        return [_lastOverlayMapSourceProfile get];
    }
}

- (void) setLastOverlayMapSource:(OAMapSource*)lastOverlayMapSource
{
    @synchronized(_lock)
    {
        [_lastOverlayMapSourceProfile set:[lastOverlayMapSource copy]];
    }
}

- (OAMapSource*) underlayMapSource
{
    @synchronized(_lock)
    {
        return [_underlayMapSourceProfile get];
    }
}

- (void) setUnderlayMapSource:(OAMapSource*)underlayMapSource
{
    @synchronized(_lock)
    {
        [_underlayMapSourceProfile set:[underlayMapSource copy]];
        [_underlayMapSourceChangeObservable notifyEventWithKey:self andValue:self.underlayMapSource];
    }
}

- (OAMapSource*) lastUnderlayMapSource
{
    @synchronized(_lock)
    {
        return [_lastUnderlayMapSourceProfile get];
    }
}

- (void) setLastUnderlayMapSource:(OAMapSource*)lastUnderlayMapSource
{
    @synchronized(_lock)
    {
        [_lastUnderlayMapSourceProfile set:[lastUnderlayMapSource copy]];
    }
}

- (double) overlayAlpha
{
    @synchronized (_lock)
    {
        return [_overlayAlphaProfile get];
    }
}

- (void) setOverlayAlpha:(double)overlayAlpha
{
    @synchronized(_lock)
    {
        [_overlayAlphaProfile set:overlayAlpha];
        [_overlayAlphaChangeObservable notifyEventWithKey:self andValue:@(self.overlayAlpha)];
    }
}

- (double) underlayAlpha
{
    @synchronized (_lock)
    {
        return [_underlayAlphaProfile get];
    }
}

- (void) setUnderlayAlpha:(double)underlayAlpha
{
    @synchronized(_lock)
    {
        [_underlayAlphaProfile set:underlayAlpha];
        [_underlayAlphaChangeObservable notifyEventWithKey:self andValue:@(self.underlayAlpha)];
    }
}

- (OAMapLayersConfiguration *)mapLayersConfiguration
{
    @synchronized (_lock)
    {
        return [_mapLayersConfigurationProfile get];
    }
}

- (NSInteger) hillshadeMinZoom
{
    @synchronized(_lock)
    {
        return [_hillshadeMinZoomProfile get];
    }
}

- (void) setHillshadeMinZoom:(NSInteger)hillshadeMinZoom
{
    @synchronized(_lock)
    {
        [_hillshadeMinZoomProfile set:(int)hillshadeMinZoom];
        [_terrainChangeObservable notifyEventWithKey:self andValue:@(YES)];
    }
}

- (NSInteger) hillshadeMaxZoom
{
    @synchronized(_lock)
    {
        return [_hillshadeMaxZoomProfile get];
    }
}

- (void) setHillshadeMaxZoom:(NSInteger)hillshadeMaxZoom
{
    @synchronized(_lock)
    {
        [_hillshadeMaxZoomProfile set:(int)hillshadeMaxZoom];
        [_terrainChangeObservable notifyEventWithKey:self andValue:@(YES)];
    }
}

- (NSInteger) slopeMinZoom
{
    @synchronized(_lock)
    {
        return [_slopeMinZoomProfile get];
    }
}

- (void) setSlopeMinZoom:(NSInteger)slopeMinZoom
{
    @synchronized(_lock)
    {
        [_slopeMinZoomProfile set:(int)slopeMinZoom];
        [_terrainChangeObservable notifyEventWithKey:self andValue:@(YES)];
    }
}

- (NSInteger) slopeMaxZoom
{
    @synchronized(_lock)
    {
        return [_slopeMaxZoomProfile get];
    }
}

- (void) setSlopeMaxZoom:(NSInteger)slopeMaxZoom
{
    @synchronized(_lock)
    {
        [_slopeMaxZoomProfile set:(int)slopeMaxZoom];
        [_terrainChangeObservable notifyEventWithKey:self andValue:@(YES)];
    }
}

- (EOATerrainType) terrainType
{
    @synchronized(_lock)
    {
        return [_terrainTypeProfile get];
    }
}

- (void) setTerrainType:(EOATerrainType)terrainType
{
    @synchronized(_lock)
    {
        [_terrainTypeProfile set:terrainType];
        if (terrainType == EOATerrainTypeHillshade || terrainType == EOATerrainTypeSlope)
            [_terrainChangeObservable notifyEventWithKey:self andValue:@(YES)];
        else
            [_terrainChangeObservable notifyEventWithKey:self andValue:@(NO)];
    }
}

- (EOATerrainType) getTerrainType:(OAApplicationMode *)mode
{
    @synchronized (_lock)
    {
        return [_terrainTypeProfile get:mode];
    }
}

- (void) setTerrainType:(EOATerrainType)terrainType mode:(OAApplicationMode *)mode
{
    @synchronized (_lock)
    {
        [_terrainTypeProfile set:terrainType mode:mode];
    }
}

- (EOATerrainType) getLastTerrainType:(OAApplicationMode *)mode
{
    @synchronized (_lock)
    {
        return [_lastTerrainTypeProfile get:mode];
    }
}

- (void) setLastTerrainType:(EOATerrainType)terrainType mode:(OAApplicationMode *)mode
{
    @synchronized (_lock)
    {
        [_lastTerrainTypeProfile set:terrainType mode:mode];
    }
}

- (EOATerrainType) lastTerrainType
{
    @synchronized(_lock)
    {
        return [_lastTerrainTypeProfile get];
    }
}

- (void) setLastTerrainType:(EOATerrainType)lastTerrainType
{
    @synchronized(_lock)
    {
        [_lastTerrainTypeProfile set:lastTerrainType];
    }
}


- (double)hillshadeAlpha
{
    @synchronized (_lock)
    {
        return [_hillshadeAlphaProfile get];
    }
}

- (void) setHillshadeAlpha:(double)hillshadeAlpha
{
    @synchronized(_lock)
    {
        [_hillshadeAlphaProfile set:hillshadeAlpha];
        [_terrainAlphaChangeObservable notifyEventWithKey:self andValue:[NSNumber numberWithDouble:self.hillshadeAlpha]];
    }
}

- (double)slopeAlpha
{
    @synchronized (_lock)
    {
        return [_slopeAlphaProfile get];
    }
}

- (void) setSlopeAlpha:(double)slopeAlpha
{
    @synchronized(_lock)
    {
        [_slopeAlphaProfile set:slopeAlpha];
        [_terrainAlphaChangeObservable notifyEventWithKey:self andValue:[NSNumber numberWithDouble:self.slopeAlpha]];
    }
}

- (BOOL) mapillary
{
    @synchronized (_lock)
    {
        return [_mapillaryProfile get];
    }
}

- (void) setMapillary:(BOOL)mapillary
{
    @synchronized (_lock)
    {
        [_mapillaryProfile set:mapillary];
        [_mapillaryChangeObservable notifyEventWithKey:self andValue:[NSNumber numberWithBool:self.mapillary]];
    }
}

@synthesize mapLastViewedState = _mapLastViewedState;

- (void) backupTargetPoints
{
    @synchronized (_lock)
    {
        _pointToNavigateBackup = _pointToNavigate;
        _pointToStartBackup = _pointToStart;
        _intermediatePointsBackup = [NSMutableArray arrayWithArray:_intermediates];
    }
}

- (void) restoreTargetPoints
{
    _pointToNavigate = _pointToNavigateBackup;
    _pointToStart = _pointToStartBackup;
    _intermediates = [NSMutableArray arrayWithArray:_intermediatePointsBackup];
}

- (BOOL) restorePointToStart
{
    return (_pointToStartBackup != nil);
}

- (void) setPointToStart:(OARTargetPoint *)pointToStart
{
    _pointToStart = pointToStart;
    [self backupTargetPoints];
}

- (void) setPointToNavigate:(OARTargetPoint *)pointToNavigate
{
    _pointToNavigate = pointToNavigate;
    if (pointToNavigate && pointToNavigate.pointDescription)
    {
        OAHistoryItem *h = [[OAHistoryItem alloc] init];
        h.name = pointToNavigate.pointDescription.name;
        h.latitude = [pointToNavigate getLatitude];
        h.longitude = [pointToNavigate getLongitude];
        h.date = [NSDate date];
        h.hType = [[OAHistoryItem alloc] initWithPointDescription:pointToNavigate.pointDescription].hType;
        
        [[OAHistoryHelper sharedInstance] addPoint:h];
    }
    
    [self backupTargetPoints];
}

- (NSArray<OARTargetPoint *> *) intermediatePoints
{
    return [NSArray arrayWithArray:_intermediates];
}

- (void) setIntermediatePoints:(NSArray<OARTargetPoint *> *)intermediatePoints
{
    _intermediates = [NSMutableArray arrayWithArray:intermediatePoints];
    [self backupTargetPoints];
}

- (void) addIntermediatePoint:(OARTargetPoint *)point
{
    [_intermediates addObject:point];
    [self backupTargetPoints];
}

- (void) insertIntermediatePoint:(OARTargetPoint *)point index:(int)index
{
    [_intermediates insertObject:point atIndex:index];
    [self backupTargetPoints];
}

- (void) deleteIntermediatePoint:(int)index
{
    [_intermediates removeObjectAtIndex:index];
    [self backupTargetPoints];
}

- (void) clearPointToStart
{
    _pointToStart = nil;
}

- (void) clearPointToNavigate
{
    _pointToNavigate = nil;
}

- (void) clearIntermediatePoints
{
    [_intermediates removeAllObjects];
}

#pragma mark - defaults

+ (OAAppData*) defaults
{
    OAAppData* defaults = [[OAAppData alloc] init];
    
    // Imagine that last viewed location was center of the world
    Point31 centerOfWorld;
    centerOfWorld.x = centerOfWorld.y = INT32_MAX>>1;
    defaults.mapLastViewedState.target31 = centerOfWorld;
    defaults.mapLastViewedState.zoom = 1.0f;
    defaults.mapLastViewedState.azimuth = 0.0f;
    defaults.mapLastViewedState.elevationAngle = 90.0f;

    return defaults;
}

+ (OAMapSource *) defaultMapSource
{
    return [[OAMapSource alloc] initWithResource:@"default.render.xml"
                                      andVariant:@"type_default"];
}

#pragma mark - NSCoding

#define kLastMapSources @"last_map_sources"
#define kMapLastViewedState @"map_last_viewed_state"
#define kDestinations @"destinations"

#define kPointToStart @"pointToStart"
#define kPointToNavigate @"pointToNavigate"
#define kIntermediatePoints @"intermediatePoints"

#define kPointToStartBackup @"pointToStartBackup"
#define kPointToNavigateBackup @"pointToNavigateBackup"
#define kIntermediatePointsBackup @"intermediatePointsBackup"

#define kHomePoint @"homePoint"
#define kWorkPoint @"workPoint"
#define kMyLocationToStart @"myLocationToStart"

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_lastMapSources forKey:kLastMapSources];
    [aCoder encodeObject:_mapLastViewedState forKey:kMapLastViewedState];
    [aCoder encodeObject:_destinations forKey:kDestinations];
    
    [aCoder encodeObject:_pointToStart forKey:kPointToStart];
    [aCoder encodeObject:_pointToNavigate forKey:kPointToNavigate];
    [aCoder encodeObject:_intermediates forKey:kIntermediatePoints];
    [aCoder encodeObject:_pointToStartBackup forKey:kPointToStartBackup];
    [aCoder encodeObject:_pointToNavigateBackup forKey:kPointToNavigateBackup];
    [aCoder encodeObject:_intermediatePointsBackup forKey:kIntermediatePointsBackup];
    [aCoder encodeObject:_homePoint forKey:kHomePoint];
    [aCoder encodeObject:_workPoint forKey:kWorkPoint];
    [aCoder encodeObject:_myLocationToStart forKey:kMyLocationToStart];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self commonInit];
        _lastMapSources = [aDecoder decodeObjectForKey:kLastMapSources];
        _mapLastViewedState = [aDecoder decodeObjectForKey:kMapLastViewedState];
        _destinations = [aDecoder decodeObjectForKey:kDestinations];

        _pointToStart = [aDecoder decodeObjectForKey:kPointToStart];
        _pointToNavigate = [aDecoder decodeObjectForKey:kPointToNavigate];
        _intermediates = [aDecoder decodeObjectForKey:kIntermediatePoints];
        _pointToStartBackup = [aDecoder decodeObjectForKey:kPointToStartBackup];
        _pointToNavigateBackup = [aDecoder decodeObjectForKey:kPointToNavigateBackup];
        _intermediatePointsBackup = [aDecoder decodeObjectForKey:kIntermediatePointsBackup];
        _homePoint = [aDecoder decodeObjectForKey:kHomePoint];
        _workPoint = [aDecoder decodeObjectForKey:kWorkPoint];
        _myLocationToStart = [aDecoder decodeObjectForKey:kMyLocationToStart];
        
        [self safeInit];
    }
    return self;
}

@end
