//
//  OAGpxWptEditingHandler.mm
//  OsmAnd Maps
//
//  Created by Skalii on 02.06.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAGpxWptEditingHandler.h"
#import "OAGpxWptItem.h"
#import "OAFavoriteItem.h"
#import "OADefaultFavorite.h"
#import "OsmAndApp.h"
#import "OARootViewController.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAEditPointViewController.h"
#import "OASavingTrackHelper.h"
#import "OAGPXDocument.h"
#import "Localization.h"

@implementation OAGpxWptEditingHandler
{
    OAGpxWptItem *_gpxWpt;
    OsmAndAppInstance _app;
    NSString *_gpxFileName;
    OAGPXDocument *_gpxDocument;
    NSString *_newGroupTitle;
    UIColor *_newGroupColor;
    NSString *_iconName;
}

- (instancetype)initWithItem:(OAGpxWptItem *)gpxWpt
{
    self = [super init];
    if (self)
    {
        _gpxWpt = gpxWpt;
        _gpxFileName = _gpxWpt.docPath;
        _iconName = _gpxWpt.point.getIcon;

        [self commonInit];
    }
    return self;
}

- (instancetype)initWithLocation:(CLLocationCoordinate2D)location title:(NSString*)formattedLocation gpxFileName:(NSString*)gpxFileName poi:(OAPOI *)poi attributes:(NSMutableArray<OARowInfo *> *)attributes
{
    self = [super init];
    if (self)
    {
        _gpxFileName = gpxFileName;

        OAFavoriteColor *favCol = [OADefaultFavorite builtinColors].firstObject;
        UIColor* color = favCol.color;

        OAGpxWptItem* wpt = [[OAGpxWptItem alloc] init];
        OAWptPt* p = [[OAWptPt alloc] init];
        p.name = formattedLocation;
        CLLocationCoordinate2D loc = location;
        p.position = loc;
        p.time = (long)[[NSDate date] timeIntervalSince1970];
        [p setColor:[OAUtilities colorToNumber:color]];
        p.desc = @"";
        
        _iconName = nil;
        NSString *poiIconName = [self.class getPoiIconName:poi];
        if (poiIconName && poiIconName.length > 0)
            _iconName = poiIconName;

        [p setIcon:_iconName];
        [p setBackgroundIcon:@"circle"];
        [p setExtension:ADDRESS_EXTENSION value:@""];
        
        if (attributes && attributes.count > 0)
        {
            for (OARowInfo *rowInfo in attributes)
            {
                NSString *labelExtensionKey = [NSString stringWithFormat:@"%@_label", rowInfo.key];
                NSString *labelExtensionValue;
                if (rowInfo.textPrefix && rowInfo.textPrefix.length > 0)
                    labelExtensionValue = [NSString stringWithFormat:@"%@ : %@", rowInfo.textPrefix, rowInfo.text];
                else
                    labelExtensionValue = rowInfo.text;
                [p setExtension:labelExtensionKey value:labelExtensionValue];
                
                OAGpxExtension *iconExtension = [[OAGpxExtension alloc] init];
                NSString *iconExtensionkey = [NSString stringWithFormat:@"%@_icon", rowInfo.key];
                NSString *iconExtensionValue = rowInfo.iconName;
                [p setExtension:iconExtensionkey value:iconExtensionValue];
            }
        }

        wpt.color = color;
        wpt.point = p;

        _gpxWpt = wpt;

        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _app = [OsmAndApp instance];
    _gpxDocument = _gpxFileName.length > 0 ? [[OAGPXDocument alloc] initWithGpxFile:_gpxFileName] : (OAGPXDocument *) [[OASavingTrackHelper sharedInstance] currentTrack];
}

- (UIColor *)getColor
{
    return _gpxWpt.color ? _gpxWpt.color : [_gpxWpt.point getColor];
}

- (NSString *)getGroupTitle
{
    return _gpxWpt.point.type && _gpxWpt.point.type.length > 0 ? _gpxWpt.point.type : OALocalizedString(@"gpx_waypoints");
}
- (OAGPXDocument *)getGpxDocument
{
    return _gpxDocument;
}

- (NSArray<NSDictionary<NSString *, NSString *> *> *)getGroups
{
    NSArray<NSDictionary<NSString *, NSString *> *> *groups = [_gpxDocument getWaypointCategoriesWithAllData:YES];

    if (_newGroupTitle)
    {
        NSMutableDictionary<NSString *, NSString *> *newGroup = [NSMutableDictionary new];
        newGroup[@"title"] = _newGroupTitle;
        newGroup[@"color"] = _newGroupColor.toHexString;
        newGroup[@"count"] = @"0";

        NSMutableArray *newGroups = [NSMutableArray arrayWithArray:groups];
        [newGroups addObject:newGroup];
        groups = newGroups;
    }

    BOOL hasDefaultGroup = NO;
    for (NSDictionary<NSString *, NSString *> *group in groups)
    {
        if ([group[@"title"] isEqualToString:@""])
        {
            NSMutableDictionary *newGroup = [group mutableCopy];
            newGroup[@"title"] = OALocalizedString(@"gpx_waypoints");
            NSMutableArray *newGroups = [groups mutableCopy];
            [newGroups removeObject:group];
            [newGroups insertObject:newGroup atIndex:0];
            groups = newGroups;
            hasDefaultGroup = YES;
            break;
        }
    }
    if (!hasDefaultGroup)
    {
        NSMutableDictionary<NSString *, NSString *> *defaultGroup = [NSMutableDictionary new];
        defaultGroup[@"title"] = OALocalizedString(@"gpx_waypoints");
        defaultGroup[@"color"] = [OADefaultFavorite getDefaultColor].toHexString;
        defaultGroup[@"count"] = @"0";
        NSMutableArray *newGroups = [groups mutableCopy];
        [newGroups insertObject:defaultGroup atIndex:0];
        groups = newGroups;
    }

    return groups;
}

- (NSDictionary<NSString *, NSString *> *)getGroupsWithColors
{
    NSDictionary<NSString *, NSString *> *groups = [_gpxDocument getWaypointCategoriesWithColors:NO];

    if (_newGroupTitle)
    {
        NSMutableDictionary<NSString *, NSString *> *newGroups = [NSMutableDictionary dictionaryWithDictionary:groups];
        newGroups[@"title"] = _newGroupTitle;
        newGroups[@"color"] = _newGroupColor.toHexString;
        groups = newGroups;
    }

    return groups;
}

- (NSString *)getName
{
    return _gpxWpt.point.name;
}

- (NSString *)getIcon
{
    return _iconName;
}

- (NSString *)getBackgroundIcon
{
    return [_gpxWpt.point getBackgroundIcon];
}

- (NSString *)getAddress
{
    return [_gpxWpt.point getAddress];
}

- (void)setGroup:(NSString *)groupName color:(UIColor *)color save:(BOOL)save
{
    _gpxWpt.point.type = groupName;
    [_gpxWpt.point setColor:[OAUtilities colorToNumber:color]];
    _gpxWpt.color = color;

    if (![_gpxWpt.groups containsObject:groupName] && groupName.length > 0)
    {
        _gpxWpt.groups = [_gpxWpt.groups arrayByAddingObject:groupName];
        _newGroupTitle = groupName;
        _newGroupColor = color;
    }
    else
    {
        _newGroupTitle = nil;
        _newGroupColor = nil;
    }

    if (save && self.gpxWptDelegate)
        [self.gpxWptDelegate saveItemToStorage:_gpxWpt];
}

- (void)deleteItem
{
    if (self.gpxWptDelegate)
        [self.gpxWptDelegate deleteGpxWpt:_gpxWpt docPath:_gpxFileName];
}

- (void)savePoint:(OAPointEditingData *)data newPoint:(BOOL)newPoint
{
    [_gpxWpt.point setName:data.name];
    [_gpxWpt.point setDesc:data.descr];
    [self setGroup:data.category color:data.color save:NO];
    [_gpxWpt.point setIcon:data.icon];
    [_gpxWpt.point setBackgroundIcon:data.backgroundIcon];
    [_gpxWpt.point setExtension:ADDRESS_EXTENSION value:data.address];
    _gpxWpt.docPath = _gpxFileName;

    if (newPoint)
    {
        if (self.gpxWptDelegate)
            [self.gpxWptDelegate saveGpxWpt:_gpxWpt gpxFileName:_gpxFileName];
    }
    else
    {
        if (self.gpxWptDelegate)
            [self.gpxWptDelegate updateGpxWpt:_gpxWpt docPath:_gpxFileName updateMap:YES];
    }

    if (self.gpxWptDelegate)
        [self.gpxWptDelegate saveItemToStorage:_gpxWpt];
}

@end
