//
//  OAMapStyleAction.m
//  OsmAnd
//
//  Created by Paul on 8/13/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAMapStyleAction.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OAMapSource.h"
#import "Localization.h"
#import "OAIAPHelper.h"
#import "OAApplicationMode.h"
#import "OAQuickActionSelectionBottomSheetViewController.h"
#import "OAMapStyleTitles.h"

#include <OsmAndCore/Map/IMapStylesCollection.h>
#include <OsmAndCore/Map/UnresolvedMapStyle.h>
#include <OsmAndCore/ResourcesManager.h>

#define KEY_STYLES @"styles"

@implementation OAMapStyleAction
{
    NSArray<OAMapSource *> *_offlineMapSources;
}

- (instancetype) init
{
    self = [super initWithType:EOAQuickActionTypeMapStyle];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    NSDictionary *stylesTitlesOffline = [OAMapStyleTitles getMapStyleTitles];
    
    OsmAndAppInstance app = [OsmAndApp instance];
    OAIAPHelper *iapHelper = [OAIAPHelper sharedInstance];
    OAApplicationMode *mode = [OAAppSettings sharedManager].applicationMode;
    NSMutableArray<OAMapSource *> *arr = [NSMutableArray new];
    QList< std::shared_ptr<const OsmAnd::ResourcesManager::Resource> > mapStyles;
    const auto localResources = app.resourcesManager->getLocalResources();
    for(const auto& localResource : localResources)
        if (localResource->type == OsmAnd::ResourcesManager::ResourceType::MapStyle)
            mapStyles.push_back(localResource);
    
    for(const auto& resource : mapStyles)
    {
        const auto& mapStyle = std::static_pointer_cast<const OsmAnd::ResourcesManager::MapStyleMetadata>(resource->metadata)->mapStyle;
        
        NSString* resourceId = resource->id.toNSString();
        
        
        OAMapSource *mapSource = [app.data lastMapSourceByResourceId:resourceId];
        if (mapSource == nil)
            mapSource = [[OAMapSource alloc] initWithResource:resourceId andVariant:mode.variantKey];
        
        NSString *caption = mapStyle->title.toNSString();
        if ([caption isEqualToString:@"Ski-map"] && ![iapHelper.skiMap isActive])
            continue;
        if ([caption isEqualToString:@"nautical"] && ![iapHelper.nautical isActive])
            continue;
        
        NSString *newCaption = [stylesTitlesOffline objectForKey:caption];
        if (newCaption)
            caption = newCaption;
        
        mapSource.name = caption;
        [arr addObject:mapSource];
    }
    _offlineMapSources = [NSArray arrayWithArray:arr];
}

- (void)execute
{
    NSArray<NSString *> *mapStyles = [self getFilteredStyles];
    if (mapStyles.count > 0)
    {
        BOOL showBottomSheetStyles = [self.getParams[KEY_DIALOG] boolValue];
        if (showBottomSheetStyles)
        {
            OAQuickActionSelectionBottomSheetViewController *bottomSheet = [[OAQuickActionSelectionBottomSheetViewController alloc] initWithAction:self type:EOAMapSourceTypeStyle];
            [bottomSheet show];
            return;
        }
        // Currently using online map as a source
        if ([_offlineMapSources indexOfObject:[OsmAndApp instance].data.lastMapSource] == NSNotFound)
            return;
        
        NSInteger index = -1;
        NSString *name = [OsmAndApp instance].data.lastMapSource.name;
        
        NSInteger idx = [mapStyles indexOfObject:name];
        if (idx != NSNotFound)
            index = idx;
        
        NSString *nextStyle = mapStyles[0];
        
        if (index >= 0 && index < mapStyles.count - 1)
            nextStyle = mapStyles[index + 1];
        
        [self executeWithParams:nextStyle];
    }
}

- (void)executeWithParams:(NSString *)params
{
    OsmAndAppInstance app = [OsmAndApp instance];
    
    OAMapSource *newMapSource = nil;
    for (OAMapSource *mapSource in _offlineMapSources)
    {
        if ([mapSource.name isEqualToString:params])
        {
            newMapSource = mapSource;
            break;
        }
    }
    if (newMapSource)
        app.data.lastMapSource = newMapSource;
    
    // indicate change with toast?
}

- (NSArray<NSString *> *) getFilteredStyles
{
    NSMutableArray *list = [NSMutableArray arrayWithArray:self.getParams[self.getListKey]];
    OAIAPHelper *iapHelper = [OAIAPHelper sharedInstance];
    if (![iapHelper.skiMap isActive])
    {
        [list removeObject:@"Ski map"];
    }
    if (![iapHelper.nautical isActive])
    {
        [list removeObject:@"Nautical"];
    }
    return [NSArray arrayWithArray:list];
}

- (NSString *)getTranslatedItemName:(NSString *)item
{
    return item;
}

-(NSString *) getAddBtnText
{
    return OALocalizedString(@"add_map_style");
}

- (NSString *)getDescrHint
{
    return OALocalizedString(@"quick_action_list_descr");
}

- (NSString *)getDescrTitle
{
    return OALocalizedString(@"change_map_style");
}

- (NSString *)getListKey
{
    return KEY_STYLES;
}

- (OrderedDictionary *)getUIModel
{
    MutableOrderedDictionary *data = [[MutableOrderedDictionary alloc] init];
    [data setObject:@[@{
                          @"type" : @"OASwitchTableViewCell",
                          @"key" : KEY_DIALOG,
                          @"title" : OALocalizedString(@"quick_actions_show_dialog"),
                          @"value" : @([self.getParams[KEY_DIALOG] boolValue]),
                          },
                      @{
                          @"footer" : OALocalizedString(@"quick_action_dialog_descr")
                          }] forKey:OALocalizedString(@"quick_action_dialog")];
    
    NSArray<NSString *> *sources = self.getParams[self.getListKey];
    NSMutableArray *arr = [NSMutableArray new];
    for (NSString *source in sources)
    {
        [arr addObject:@{
                         @"type" : @"OATitleDescrDraggableCell",
                         @"title" : source,
                         @"img" : @"ic_custom_show_on_map"
                         }];
    }
    [arr addObject:@{
                     @"title" : OALocalizedString(@"add_map_style"),
                     @"type" : @"OAButtonCell",
                     @"target" : @"addMapStyle"
                     }];
    [data setObject:[NSArray arrayWithArray:arr] forKey:OALocalizedString(@"map_styles")];
    return data;
}

- (BOOL)fillParams:(NSDictionary *)model
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.getParams];
    NSMutableArray *sources = [NSMutableArray new];
    for (NSArray *arr in model.allValues)
    {
        for (NSDictionary *item in arr)
        {
            if ([item[@"key"] isEqualToString:KEY_DIALOG])
                [params setValue:item[@"value"] forKey:KEY_DIALOG];
            else if ([item[@"type"] isEqualToString:@"OATitleDescrDraggableCell"])
                     [sources addObject:item[@"title"]];
        }
    }
    [params setObject:sources forKey:KEY_STYLES];
    [self setParams:[NSDictionary dictionaryWithDictionary:params]];
    return sources.count > 0;
}

- (NSArray *)getOfflineMapSources
{
    return _offlineMapSources;
}

- (NSString *)getTitle:(NSArray *)filters
{
    if (filters.count == 0)
        return @"";
    
    return filters.count > 1
    ? [NSString stringWithFormat:@"%@ +%ld", filters[0], filters.count - 1]
    : filters[0];
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_poi_add_descr");
}

@end
