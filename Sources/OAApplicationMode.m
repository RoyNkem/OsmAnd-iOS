//
//  OAApplicationMode.m
//  OsmAnd
//
//  Created by Alexey Kulish on 12/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAApplicationMode.h"
#import "Localization.h"
#import "OAAppSettings.h"
#import "OAAutoObserverProxy.h"
#import "OsmAndApp.h"

@interface OAApplicationMode ()

@property (nonatomic) NSInteger modeId;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *stringKey;
@property (nonatomic) NSString *variantKey;

@property (nonatomic) OAApplicationMode *parent;

@end

@implementation OAApplicationMode

static NSMapTable<NSString *, NSMutableSet<OAApplicationMode *> *> *_widgetsVisibilityMap;
static NSMapTable<NSString *, NSMutableSet<OAApplicationMode *> *> *_widgetsAvailabilityMap;
static NSMutableArray<OAApplicationMode *> *_values;
static NSMutableArray<OAApplicationMode *> *_cachedFilteredValues;
static OAAutoObserverProxy* _listener;


static OAApplicationMode *_DEFAULT;
static OAApplicationMode *_CAR;
static OAApplicationMode *_BICYCLE;
static OAApplicationMode *_PUBLIC_TRANSPORT;
static OAApplicationMode *_PEDESTRIAN;
static OAApplicationMode *_AIRCRAFT;
static OAApplicationMode *_BOAT;
static OAApplicationMode *_SKI;

+ (void) initialize
{
    _widgetsVisibilityMap = [NSMapTable strongToStrongObjectsMapTable];
    _widgetsAvailabilityMap = [NSMapTable strongToStrongObjectsMapTable];
    _values = [NSMutableArray array];
    _cachedFilteredValues = [NSMutableArray array];
    
    _DEFAULT = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"m_style_overview") stringKey:@"default"];
    _DEFAULT.descr = OALocalizedString(@"base_profile_descr");
    [_values addObject:_DEFAULT];
    
    _CAR = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"m_style_car") stringKey:@"car"];
    _CAR.descr = OALocalizedString(@"base_profile_descr_car");
    [_values addObject:_CAR];
    
    _BICYCLE = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"m_style_bicycle") stringKey:@"bicycle"];
    _BICYCLE.descr = OALocalizedString(@"base_profile_descr_bicycle");
    [_values addObject:_BICYCLE];
    
    _PEDESTRIAN = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"m_style_walk") stringKey:@"pedestrian"];
    _PEDESTRIAN.descr = OALocalizedString(@"base_profile_descr_pedestrian");
    [_values addObject:_PEDESTRIAN];
    
    _PUBLIC_TRANSPORT = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"m_style_pulic_transport") stringKey:@"public_transport"];
    _PUBLIC_TRANSPORT.descr = OALocalizedString(@"base_profile_descr_public_transport");
    [_values addObject:_PUBLIC_TRANSPORT];
    
    _AIRCRAFT = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"app_mode_aircraft") stringKey:@"aircraft"];
    _AIRCRAFT.descr = OALocalizedString(@"base_profile_descr_aircraft");
    [_values addObject:_AIRCRAFT];
    
    _BOAT = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"app_mode_boat") stringKey:@"boat"];
    _BOAT.descr = OALocalizedString(@"base_profile_descr_boat");
    [_values addObject:_BOAT];
    
    _SKI = [[OAApplicationMode alloc] initWithName:OALocalizedString(@"app_mode_skiing") stringKey:@"ski"];
    _SKI.descr = OALocalizedString(@"app_mode_skiing");
    [_values addObject:_SKI];
    
    NSArray<OAApplicationMode *> *exceptDefault = @[_CAR, _PEDESTRIAN, _BICYCLE, _PUBLIC_TRANSPORT, _BOAT, _AIRCRAFT, _SKI];
    
    NSArray<OAApplicationMode *> *all = nil;
    NSArray<OAApplicationMode *> *none = @[];
    
    NSArray<OAApplicationMode *> *navigationSet1 = @[_CAR, _BICYCLE, _BOAT, _SKI];
    NSArray<OAApplicationMode *> *navigationSet2 = @[_PEDESTRIAN, _PUBLIC_TRANSPORT, _AIRCRAFT];
    
    // left
    [self regWidgetVisibility:@"next_turn" am:navigationSet1];;
    [self regWidgetVisibility:@"next_turn_small" am:navigationSet2];
    [self regWidgetVisibility:@"next_next_turn" am:navigationSet1];
    [self regWidgetAvailability:@"next_turn" am:exceptDefault];
    [self regWidgetAvailability:@"next_turn_small" am:exceptDefault];
    [self regWidgetAvailability:@"next_next_turn" am:exceptDefault];
    
    // right
    [self regWidgetVisibility:@"intermediate_distance" am:all];
    [self regWidgetVisibility:@"distance" am:all];
    [self regWidgetVisibility:@"time" am:all];
    [self regWidgetVisibility:@"intermediate_time" am:all];
    [self regWidgetVisibility:@"speed" am:@[_CAR, _BICYCLE, _BOAT, _SKI, _PUBLIC_TRANSPORT, _AIRCRAFT]];
    [self regWidgetVisibility:@"max_speed" am:@[_CAR]];
    [self regWidgetVisibility:@"altitude" am:@[_PEDESTRIAN, _BICYCLE]];
    [self regWidgetVisibility:@"gps_info" am:none];
    
    [self regWidgetAvailability:@"intermediate_distance" am:all];
    [self regWidgetAvailability:@"distance" am:all];
    [self regWidgetAvailability:@"time" am:all];
    [self regWidgetAvailability:@"intermediate_time" am:all];
    [self regWidgetAvailability:@"map_marker_1st" am:none];
    [self regWidgetAvailability:@"map_marker_2nd" am:none];
    
    // top
    [self regWidgetVisibility:@"config" am:none];
    [self regWidgetVisibility:@"layers" am:none];
    [self regWidgetVisibility:@"compass" am:none];
    [self regWidgetVisibility:@"street_name" am:@[_CAR, _BICYCLE, _PEDESTRIAN, _PUBLIC_TRANSPORT]];
    [self regWidgetVisibility:@"back_to_location" am:all];
    [self regWidgetVisibility:@"monitoring_services" am:none];
    [self regWidgetVisibility:@"bgService" am:none];
}

+ (OAApplicationMode *) DEFAULT
{
    return _DEFAULT;
}

+ (OAApplicationMode *) CAR
{
    return _CAR;
}

+ (OAApplicationMode *) BICYCLE;
{
    return _BICYCLE;
}

+ (OAApplicationMode *) PEDESTRIAN;
{
    return _PEDESTRIAN;
}

+ (OAApplicationMode *) AIRCRAFT;
{
    return _AIRCRAFT;
}

+ (OAApplicationMode *) BOAT;
{
    return _BOAT;
}

+ (OAApplicationMode *) PUBLIC_TRANSPORT
{
    return _PUBLIC_TRANSPORT;
}

+ (OAApplicationMode *) SKI
{
    return _SKI;
}

+ (OAApplicationMode *) buildApplicationModeByKey:(NSString *)key
{
    OAAppSettings *settings = OAAppSettings.sharedManager;
    OAApplicationMode *m = [[OAApplicationMode alloc] initWithName:@"" stringKey:key];
    m.name = [settings.userProfileName get:m];
    m.parent = [self valueOfStringKey:[settings.parentAppMode get:m] def:nil];
    return m;
}

- (instancetype)initWithName:(NSString *)name stringKey:(NSString *)stringKey
{
    self = [super init];
    if (self)
    {
        _name = name;
        _stringKey = stringKey;
        _variantKey = [NSString stringWithFormat:@"type_%@", stringKey];
    }
    return self;
}

+ (NSArray<OAApplicationMode *> *) values
{
    if (_cachedFilteredValues.count == 0)
    {
        OAAppSettings *settings = [OAAppSettings sharedManager];
        if (!_listener)
        {
            _listener = [[OAAutoObserverProxy alloc] initWith:self
                                                  withHandler:@selector(onAvailableAppModesChanged)
                                                   andObserve:[OsmAndApp instance].availableAppModesChangedObservable];
        }
        NSString *available = settings.availableApplicationModes;
        _cachedFilteredValues = [NSMutableArray array];
        for (OAApplicationMode *v in _values)
            if ([available containsString:[v.stringKey stringByAppendingString:@","]] || v == _DEFAULT)
                [_cachedFilteredValues addObject:v];
    }
    return [NSArray arrayWithArray:_cachedFilteredValues];
}

+ (void) onAvailableAppModesChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _cachedFilteredValues = [NSMutableArray array];
    });
}

+ (NSArray<OAApplicationMode *> *) allPossibleValues
{
    return [NSArray arrayWithArray:_values];
}

+ (NSArray<OAApplicationMode *> *) getModesDerivedFrom:(OAApplicationMode *)am
{
    NSMutableArray<OAApplicationMode *> *list = [NSMutableArray array];
    for (OAApplicationMode *a in _values)
        if (a == am || a.parent == am)
            [list addObject:a];

    return list;
}

- (BOOL) hasFastSpeed
{
    return [self getDefaultSpeed] > 10;
}

- (NSInteger) getOffRouteDistance
{
    // used to be: 50/14 - 350 m, 10/2.7 - 50 m, 4/1.11 - 20 m
    double speed = MAX([self getDefaultSpeed], 0.3f);
    // become: 50 kmh - 280 m, 10 kmh - 55 m, 4 kmh - 22 m
    return (NSInteger) (speed * 20);
}

- (NSInteger) getMinDistanceForTurn
{
    // used to be: 50 kmh - 35 m, 10 kmh - 15 m, 4 kmh - 5 m, 10 kmh - 20 m, 400 kmh - 100 m,
    float speed = MAX([self getDefaultSpeed], 0.3f);
    // 2 sec + 7 m: 50 kmh - 35 m, 10 kmh - 12 m, 4 kmh - 9 m, 400 kmh - 230 m
    return (int) (7 + speed * 2);
}

- (BOOL) isCustomProfile
{
    return _parent != nil;
}

- (OAApplicationMode *) getParent
{
    return _parent ? _parent : [OAApplicationMode buildApplicationModeByKey:[OAAppSettings.sharedManager.parentAppMode get:self]];
}

- (void) setParent:(OAApplicationMode *)parent
{
    _parent = parent;
    [OAAppSettings.sharedManager.parentAppMode set:parent.stringKey mode:self];
}

- (UIImage *) getIcon
{
    return [UIImage imageNamed:self.getIconName];
}

- (NSString *) getIconName
{
    return [OAAppSettings.sharedManager.profileIconName get:self];
}

- (void) setIconName:(NSString *)iconName
{
    return [OAAppSettings.sharedManager.profileIconName set:iconName mode:self];
}

- (double) getDefaultSpeed
{
    return [OAAppSettings.sharedManager.defaultSpeed get:self];
}

- (void) setDefaultSpeed:(double) defaultSpeed
{
    [OAAppSettings.sharedManager.defaultSpeed set:defaultSpeed mode:self];
}

- (void) resetDefaultSpeed
{
    [OAAppSettings.sharedManager.defaultSpeed resetModeToDefault:self];
}

- (double) getMinSpeed
{
    return [OAAppSettings.sharedManager.minSpeed get:self];
}

- (void) setMinSpeed:(double) minSpeed
{
    [OAAppSettings.sharedManager.minSpeed set:minSpeed mode:self];
}

- (double) getMaxSpeed
{
    return [OAAppSettings.sharedManager.maxSpeed get:self];
}

- (void) setMaxSpeed:(double) maxSpeed
{
    [OAAppSettings.sharedManager.maxSpeed set:maxSpeed mode:self];
}

- (double) getStrAngle
{
    return [OAAppSettings.sharedManager.routeStraightAngle get:self];
}

- (void) setStrAngle:(double) straightAngle
{
    [OAAppSettings.sharedManager.routeStraightAngle set:straightAngle mode:self];
}

- (NSString *) getUserProfileName
{
    return [OAAppSettings.sharedManager.userProfileName get:self];
}

- (void) setUserProfileName:(NSString *)userProfileName
{
    if (userProfileName.length > 0)
        [OAAppSettings.sharedManager.userProfileName set:userProfileName mode:self];
}

- (NSString *) getRoutingProfile
{
    return [OAAppSettings.sharedManager.routingProfile get:self];
}

- (void) setRoutingProfile:(NSString *) routingProfile
{
    if (routingProfile.length > 0)
        [OAAppSettings.sharedManager.routingProfile set:routingProfile mode:self];
}

- (NSInteger) getRouterService
{
    return [OAAppSettings.sharedManager.routerService get:self];
}

- (void) setRouterService:(NSInteger) routerService
{
    [OAAppSettings.sharedManager.routerService set:(int) routerService mode:self];
}

- (EOANavigationIcon) getNavigationIcon
{
    return [OAAppSettings.sharedManager.navigationIcon get:self];
}

- (void) setNavigationIcon:(EOANavigationIcon) navIcon
{
    [OAAppSettings.sharedManager.navigationIcon set:(int)navIcon mode:self];
}

- (EOALocationIcon) getLocationIcon
{
    return [OAAppSettings.sharedManager.locationIcon get:self];
}

- (void) setLocationIcon:(EOALocationIcon) locIcon
{
    [OAAppSettings.sharedManager.locationIcon set:(int)locIcon mode:self];
}

- (int) getIconColor
{
    return [OAAppSettings.sharedManager.profileIconColor get:self];
}

- (void) setIconColor:(int)iconColor
{
    [OAAppSettings.sharedManager.profileIconColor set:iconColor mode:self];
}

- (int) getOrder
{
    return [OAAppSettings.sharedManager.appModeOrder get:self];
}

- (void) setOrder:(int)order
{
    [OAAppSettings.sharedManager.appModeOrder set:order mode:self];
}

- (NSString *) getProfileDescription
{
    return _descr && _descr.length > 0 ? _descr : OALocalizedString(@"custom_profile");
}

+ (void) onApplicationStart
{
    [self initCustomModes];
//    [self initModesParams];
//    [self initRegVisibility];
    [self reorderAppModes];
}

+ (void) initCustomModes
{
    OAAppSettings *settings = OAAppSettings.sharedManager;
    if (settings.customAppModes.length == 0)
        return;
    
    for (NSString *appModeKey in [settings getCustomAppModesKeys])
    {
        OAApplicationMode *m = [OAApplicationMode buildApplicationModeByKey:appModeKey];
        [_values addObject:m];
    }
}

+ (NSComparisonResult) compareModes:(OAApplicationMode *)obj1 obj2:(OAApplicationMode *) obj2
{
    return (obj1.getOrder < obj2.getOrder) ? NSOrderedAscending : ((obj1.getOrder == obj2.getOrder) ? NSOrderedSame : NSOrderedDescending);
}

+ (void) reorderAppModes
{
    [_values sortUsingComparator:^NSComparisonResult(OAApplicationMode *obj1, OAApplicationMode *obj2) {
        return [self compareModes:obj1 obj2:obj2];
    }];
    [_cachedFilteredValues sortUsingComparator:^NSComparisonResult(OAApplicationMode *obj1, OAApplicationMode *obj2) {
        return [self compareModes:obj1 obj2:obj2];
    }];

    [self updateAppModesOrder];
}

+ (void) updateAppModesOrder
{
    for (int i = 0; i < _values.count; i++)
    {
        [_values[i] setOrder:i];
    }
}

+ (void) saveCustomAppModesToSettings
{
    OAAppSettings *settings = OAAppSettings.sharedManager;
    NSMutableString *res = [[NSMutableString alloc] init];
    
    NSArray<OAApplicationMode *> * modes = [self getCustomAppModes];
    [modes enumerateObjectsUsingBlock:^(OAApplicationMode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [res appendString:obj.stringKey];
        if (idx != modes.count - 1)
            [res appendString:@","];
    }];
    
    if (![res isEqualToString:settings.customAppModes])
        settings.customAppModes = res;
}

+ (NSArray<OAApplicationMode *> *) getCustomAppModes
{
    NSMutableArray<OAApplicationMode *> *customModes = [NSMutableArray new];
    for (OAApplicationMode *mode in _values)
    {
        if (mode.isCustomProfile)
            [customModes addObject:mode];
        
    }
    return customModes;
}

+ (void) saveProfile:(OAApplicationMode *)appMode
{
    OAApplicationMode *mode = [OAApplicationMode valueOfStringKey:appMode.stringKey def:nil];
    if (mode != nil)
    {
        [mode setParent:appMode.parent];
        [mode setUserProfileName:appMode.getUserProfileName];
        [mode setIconName:appMode.getIconName];
        [mode setRoutingProfile:appMode.getRoutingProfile];
        [mode setRouterService:appMode.getRouterService];
        [mode setIconColor:appMode.getIconColor];
        [mode setLocationIcon:appMode.getLocationIcon];
        [mode setNavigationIcon:appMode.getNavigationIcon];
        [mode setOrder:appMode.getOrder];
    }
    else if (![_values containsObject:appMode])
    {
        [_values addObject:appMode];
    }
    
    [self reorderAppModes];
    [self saveCustomAppModesToSettings];
}

+ (void) deleteCustomModes:(NSArray<OAApplicationMode *> *) modes
{
    [_values removeObjectsInArray:modes];
    
    OAAppSettings *settings = OAAppSettings.sharedManager;
    if ([modes containsObject:settings.applicationMode])
        [settings setApplicationMode:_DEFAULT];
    [_cachedFilteredValues removeObjectsInArray:modes];
    [self saveCustomAppModesToSettings];
}

+ (void) changeProfileAvailability:(OAApplicationMode *) mode isSelected:(BOOL) isSelected
{
    NSMutableSet<OAApplicationMode *> *selectedModes = [NSMutableSet setWithArray:self.values];
    NSMutableString *str = [[NSMutableString alloc] initWithFormat:@"%@,", _DEFAULT.stringKey];
    if ([OAApplicationMode.allPossibleValues containsObject:mode])
    {
        OAAppSettings *settings = OAAppSettings.sharedManager;
        if (isSelected)
        {
            [selectedModes addObject:mode];
        }
        else
        {
            [selectedModes removeObject:mode];
            if (settings.applicationMode == mode)
            {
                [settings setApplicationMode:_DEFAULT];
            }
        }
        for (OAApplicationMode *m in selectedModes)
        {
            [str appendString:m.stringKey];
            [str appendString:@","];
        }
        [settings setAvailableApplicationModes:str];
    }
}

+ (OAApplicationMode *) valueOfStringKey:(NSString *)key def:(OAApplicationMode *)def
{
    for (OAApplicationMode *p in _values)
        if ([p.stringKey isEqualToString:key])
            return p;

    return def;
}

- (BOOL) isDerivedRoutingFrom:(OAApplicationMode *)mode
{
    return self == mode || _parent == mode;
}

// returns modifiable ! Set<ApplicationMode> to exclude non-wanted derived
+ (NSSet<OAApplicationMode *> *) regWidgetVisibility:(NSString *)widgetId am:(NSArray<OAApplicationMode *> *)am
{
    NSMutableSet<OAApplicationMode *> *set = [NSMutableSet set];
    if (!am)
        [set addObjectsFromArray:_values];
    else
        [set addObjectsFromArray:am];
    
    for (OAApplicationMode *m in _values)
    {
        // add derived modes
        if ([set containsObject:m.parent])
            [set addObject:m];
    }
    [_widgetsVisibilityMap setObject:set forKey:widgetId];
    return set;
}

- (BOOL) isWidgetCollapsible:(NSString *)key
{
    return false;
}

- (BOOL) isWidgetVisible:(NSString *)key
{
    NSSet<OAApplicationMode *> *set = [_widgetsVisibilityMap objectForKey:key];
    if (!set)
        return false;
    
    return [set containsObject:self];
}

+ (NSSet<OAApplicationMode *> *) regWidgetAvailability:(NSString *)widgetId am:(NSArray<OAApplicationMode *> *)am
{
    NSMutableSet<OAApplicationMode *> *set = [NSMutableSet set];
    if (!am)
        [set addObjectsFromArray:_values];
    else
        [set addObjectsFromArray:am];
    
    for (OAApplicationMode *m in _values)
        // add derived modes
        if ([set containsObject:m.parent])
            [set addObject:m];
        
    [_widgetsAvailabilityMap setObject:set forKey:widgetId];
    return set;
}

- (BOOL) isWidgetAvailable:(NSString *)key
{
    NSSet<OAApplicationMode *> *set = [_widgetsAvailabilityMap objectForKey:key];
    if (!set)
        return true;
    
    return [set containsObject:self];
}

@end
