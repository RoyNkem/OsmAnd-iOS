//
//  OAGPXDocumentPrimitives.m
//  OsmAnd
//
//  Created by Alexey Kulish on 15/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXDocumentPrimitives.h"
#import "OAGPXTrackAnalysis.h"
#import "OAUtilities.h"
#import "OAPointDescription.h"

#include <routeSegmentResult.h>

#define ICON_NAME_EXTENSION @"icon"
#define DEFAULT_ICON_NAME @"special_star"
#define BACKGROUND_TYPE_EXTENSION @"background"
#define PROFILE_TYPE_EXTENSION @"profile"
#define GAP_PROFILE_TYPE @"gap"
#define TRKPT_INDEX_EXTENSION @"trkpt_idx"

@implementation OARouteSegment

- (instancetype)initWithDictionary:(NSDictionary<NSString *,NSString *> *)dict
{
    self = [super init];
    if (self) {
        _identifier = dict[@"id"];
        _length = dict[@"length"];
        _segmentTime = dict[@"segmentTime"];
        _speed = dict[@"speed"];
        _turnType = dict[@"turnType"];
        _turnAngle = dict[@"turnAngle"];
        _types = dict[@"types"];
        _pointTypes = dict[@"pointTypes"];
        _names = dict[@"names"];
    }
    return self;
}

+ (OARouteSegment *) fromStringBundle:(const std::shared_ptr<RouteDataBundle> &)bundle
{
    OARouteSegment *s = [[OARouteSegment alloc] init];
    s.identifier = [NSString stringWithUTF8String:bundle->getString("id").c_str()];
    s.length = [NSString stringWithUTF8String:bundle->getString("length").c_str()];
    s.segmentTime = [NSString stringWithUTF8String:bundle->getString("segmentTime").c_str()];
    s.speed = [NSString stringWithUTF8String:bundle->getString("speed").c_str()];
    s.turnType = [NSString stringWithUTF8String:bundle->getString("turnType").c_str()];
    s.turnAngle = [NSString stringWithUTF8String:bundle->getString("turnAngle").c_str()];
    s.types = [NSString stringWithUTF8String:bundle->getString("types").c_str()];
    s.pointTypes = [NSString stringWithUTF8String:bundle->getString("pointTypes").c_str()];
    s.names = [NSString stringWithUTF8String:bundle->getString("names").c_str()];
    return s;
}

//public StringBundle toStringBundle() {
//    StringBundle bundle = new StringBundle();
//    bundle.putString("id", id);
//    bundle.putString("length", length);
//    bundle.putString("segmentTime", segmentTime);
//    bundle.putString("speed", speed);
//    bundle.putString("turnType", turnType);
//    bundle.putString("turnAngle", turnAngle);
//    bundle.putString("types", types);
//    bundle.putString("pointTypes", pointTypes);
//    bundle.putString("names", names);
//    return bundle;
//}

- (NSDictionary<NSString *,NSString *> *)toDictionary
{
    NSMutableDictionary<NSString *, NSString *> *res = [NSMutableDictionary new];
    [self addIfValueNotEmpty:res key:@"id" value:_identifier];
    [self addIfValueNotEmpty:res key:@"length" value:_length];
    [self addIfValueNotEmpty:res key:@"segmentTime" value:_segmentTime];
    [self addIfValueNotEmpty:res key:@"speed" value:_speed];
    [self addIfValueNotEmpty:res key:@"turnType" value:_turnType];
    [self addIfValueNotEmpty:res key:@"turnAngle" value:_turnAngle];
    [self addIfValueNotEmpty:res key:@"types" value:_types];
    [self addIfValueNotEmpty:res key:@"pointTypes" value:_pointTypes];
    [self addIfValueNotEmpty:res key:@"names" value:_names];
    return res;
}

- (void) addIfValueNotEmpty:(NSMutableDictionary<NSString *, NSString *> *)dict key:(NSString *)key value:(NSString *)value
{
    if (value.length > 0)
        dict[key] = value;
}

@end

@implementation OARouteType

- (instancetype)initWithDictionary:(NSDictionary<NSString *,NSString *> *)dict
{
    self = [super init];
    if (self) {
        _tag = dict[@"t"];
        _value = dict[@"v"];
    }
    return self;
}

+ (OARouteType *) fromStringBundle:(const std::shared_ptr<RouteDataBundle> &)bundle
{
    OARouteType *t = [[OARouteType alloc] init];
    t.tag = [NSString stringWithUTF8String:bundle->getString("t").c_str()];
    t.value = [NSString stringWithUTF8String:bundle->getString("v").c_str()];
    return t;
}

//public StringBundle toStringBundle() {
//    StringBundle bundle = new StringBundle();
//    bundle.putString("t", tag);
//    bundle.putString("v", value);
//    return bundle;
//}

- (NSDictionary<NSString *,NSString *> *)toDictionary
{
    return @{
        @"t" : _tag,
        @"v" : _value
    };
}

@end

@implementation OAMetadata
@end
@implementation OALink
@end
@implementation OAGpxExtension
@end
@implementation OAGpxExtensions

- (NSArray<OAGpxExtension *> *)extensions
{
    if (!_extensions)
        _extensions = @[];
    return _extensions;
}

- (void) copyExtensions:(OAGpxExtensions *)e
{
    _extensions = e.extensions;
}

@end
@implementation OARoute
@end
@implementation OARoutePoint
@end
@implementation OATrack
@end
@implementation OATrackPoint
@end
@implementation OATrackSegment
@end

@implementation OALocationMark

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        self.elevation = NAN;
    }
    return self;
}

- (BOOL) isEqual:(id)o
{
    if (self == o)
        return YES;
    if (!o || ![self isKindOfClass:[o class]])
        return NO;
    
    OALocationMark *locationMark = (OALocationMark *) o;
    if (!self.name && locationMark.name)
        return NO;
    if (self.name && ![self.name isEqualToString:locationMark.name])
        return NO;

    if (![OAUtilities isCoordEqual:self.position.latitude srcLon:self.position.longitude destLat:locationMark.position.latitude destLon:locationMark.position.longitude])
        return NO;

    if (!self.desc && locationMark.desc)
        return NO;
    if (self.desc && ![self.desc isEqualToString:locationMark.desc])
        return NO;

    if (self.time != locationMark.time)
        return NO;

    if (!self.type && locationMark.type)
        return NO;
    if (self.type && ![self.type isEqualToString:locationMark.type])
        return NO;
    
    return YES;
}

- (NSUInteger) hash
{
    NSUInteger result = self.time;
    result = 31 * result + [@(self.position.latitude) hash];
    result = 31 * result + [@(self.position.longitude) hash];
    result = 31 * result + (self.name ? [self.name hash] : 0);
    result = 31 * result + (self.desc ? [self.desc hash] : 0);
    result = 31 * result + (self.type ? [self.type hash] : 0);
    return result;
}

- (double) getLatitude
{
    return self.position.latitude;
}

- (double) getLongitude
{
    return self.position.longitude;
}

- (UIColor *) getColor
{
    return nil;
}

- (OAPointDescription *) getPointDescription
{
    return [[OAPointDescription alloc] initWithType:POINT_TYPE_WPT name:self.name];
}

- (BOOL) isVisible
{
    return YES;
}

@end

@implementation OAExtraData
@end

@implementation OAGpxWpt

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        self.satellitesUsedForFixCalculation = -1;
        self.dgpsStationId = -1;
        self.speed = NAN;
        self.magneticVariation = NAN;
        self.geoidHeight = NAN;
        self.elevation = NAN;
        self.fixType = Unknown;
        self.horizontalDilutionOfPrecision = NAN;
        self.verticalDilutionOfPrecision = NAN;
        self.positionDilutionOfPrecision = NAN;
        self.ageOfGpsData = NAN;
        self.distance = 0.0;
    }
    return self;
}

- (void) fillWithWpt:(OAGpxWpt *)gpxWpt
{
    self.wpt = gpxWpt.wpt;
    
    self.position = gpxWpt.position;
    self.color = gpxWpt.color;
    self.name = gpxWpt.name;
    self.desc = gpxWpt.desc;
    self.elevation = gpxWpt.elevation;
    self.time = gpxWpt.time;
    self.comment = gpxWpt.comment;
    self.type = gpxWpt.type;
    
    self.magneticVariation = gpxWpt.magneticVariation;
    self.geoidHeight = gpxWpt.geoidHeight;
    self.source = gpxWpt.source;
    self.symbol = gpxWpt.symbol;
    self.fixType = gpxWpt.fixType;
    self.satellitesUsedForFixCalculation = gpxWpt.satellitesUsedForFixCalculation;
    self.horizontalDilutionOfPrecision = gpxWpt.horizontalDilutionOfPrecision;
    self.verticalDilutionOfPrecision = gpxWpt.verticalDilutionOfPrecision;
    self.positionDilutionOfPrecision = gpxWpt.positionDilutionOfPrecision;
    self.ageOfGpsData = gpxWpt.ageOfGpsData;
    self.dgpsStationId = gpxWpt.dgpsStationId;
    self.distance = gpxWpt.distance;
    
    self.links = gpxWpt.links;
    self.extraData = gpxWpt.extraData;
}

- (void) fillWithTrkPt:(OAGpxTrkPt *)gpxWpt
{
    self.position = gpxWpt.position;
    self.name = gpxWpt.name;
    self.desc = gpxWpt.desc;
    self.elevation = gpxWpt.elevation;
    self.time = gpxWpt.time;
    self.comment = gpxWpt.comment;
    self.type = gpxWpt.type;
    
    self.magneticVariation = gpxWpt.magneticVariation;
    self.geoidHeight = gpxWpt.geoidHeight;
    self.source = gpxWpt.source;
    self.symbol = gpxWpt.symbol;
    self.fixType = gpxWpt.fixType;
    self.satellitesUsedForFixCalculation = gpxWpt.satellitesUsedForFixCalculation;
    self.horizontalDilutionOfPrecision = gpxWpt.horizontalDilutionOfPrecision;
    self.verticalDilutionOfPrecision = gpxWpt.verticalDilutionOfPrecision;
    self.positionDilutionOfPrecision = gpxWpt.positionDilutionOfPrecision;
    self.ageOfGpsData = gpxWpt.ageOfGpsData;
    self.dgpsStationId = gpxWpt.dgpsStationId;
    self.distance = gpxWpt.distance;
    
    self.links = gpxWpt.links;
    self.extraData = gpxWpt.extraData;
}

- (UIColor *) getColor
{
    return [OAUtilities colorFromString:self.color];
}

@end

@implementation OAGpxTrk
@end

@implementation OAGpxTrkPt

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        self.satellitesUsedForFixCalculation = -1;
        self.dgpsStationId = -1;
        self.speed = NAN;
        self.magneticVariation = NAN;
        self.geoidHeight = NAN;
        self.fixType = Unknown;
        self.horizontalDilutionOfPrecision = NAN;
        self.verticalDilutionOfPrecision = NAN;
        self.positionDilutionOfPrecision = NAN;
        self.ageOfGpsData = NAN;
    }
    return self;
}

- (instancetype)initWithPoint:(OAGpxTrkPt *)point
{
    self = [super init];
    if (self)
    {
        self.trkpt = point.trkpt;
        self.satellitesUsedForFixCalculation = point.satellitesUsedForFixCalculation;
        self.dgpsStationId = point.dgpsStationId;
        self.speed = point.speed;
        self.magneticVariation = point.magneticVariation;
        self.geoidHeight = point.geoidHeight;
        self.fixType = point.fixType;
        self.horizontalDilutionOfPrecision = point.horizontalDilutionOfPrecision;
        self.verticalDilutionOfPrecision = point.verticalDilutionOfPrecision;
        self.positionDilutionOfPrecision = point.positionDilutionOfPrecision;
        self.ageOfGpsData = point.ageOfGpsData;
        self.source = point.source;
        self.symbol = point.symbol;
        self.position = point.position;
        self.firstPoint = point.firstPoint;
        self.lastPoint = point.lastPoint;
        self.name = point.name;
        self.desc = point.desc;
        self.elevation = point.elevation;
        self.time = point.time;
        self.comment = point.comment;
        self.type = point.type;
        self.links = point.links;
        self.distance = point.distance;
    }
    return self;
}

- (OAGpxExtension *)getExtensionByKey:(NSString *)key
{
    for (OAGpxExtension *e in ((OAGpxExtensions *)self.extraData).extensions)
    {
        if ([e.name isEqualToString:key])
            return e;
    }
    return nil;
}

- (NSString *) getProfileType
{
    OAGpxExtension *e = [self getExtensionByKey:PROFILE_TYPE_EXTENSION];
    if (e)
        return e.value;
    return nil;
}

- (void) addExtension:(OAGpxExtension *)e
{
    if (!self.extraData)
        self.extraData = [[OAGpxExtensions alloc] init];
    NSArray<OAGpxExtension *> *exts = ((OAGpxExtensions *)self.extraData).extensions;
    if (![exts containsObject:e])
        ((OAGpxExtensions *)self.extraData).extensions = [exts arrayByAddingObject:e];
}

- (void) setProfileType:(NSString *)profileType
{
    OAGpxExtension *e = [self getExtensionByKey:PROFILE_TYPE_EXTENSION];
    if (!e)
    {
        e = [[OAGpxExtension alloc] init];
        e.name = PROFILE_TYPE_EXTENSION;
        e.value = profileType;
        [self addExtension:e];
        return;
    }
    e.value = profileType;
}

- (void) removeProfileType
{
    OAGpxExtension *e = [self getExtensionByKey:PROFILE_TYPE_EXTENSION];
    if (e)
    {
        NSMutableArray *arr = [NSMutableArray arrayWithArray:((OAGpxExtensions *)self.extraData).extensions];
        [arr removeObject:e];
        ((OAGpxExtensions *)self.extraData).extensions = arr;
    }
}

- (BOOL) hasProfile
{
    NSString *profileType = self.getProfileType;
    return profileType != nil && ![GAP_PROFILE_TYPE isEqualToString:profileType];
}

- (NSInteger) getTrkPtIndex
{
    OAGpxExtension *e = [self getExtensionByKey:TRKPT_INDEX_EXTENSION];
    if (e)
        return e ? e.value.integerValue : -1;
    return -1;
}

- (void) setTrkPtIndex:(NSInteger)index
{
    OAGpxExtension *e = [self getExtensionByKey:TRKPT_INDEX_EXTENSION];
    NSString *stringValue = [NSString stringWithFormat:@"%ld", index];
    if (!e)
    {
        e = [[OAGpxExtension alloc] init];
        e.name = TRKPT_INDEX_EXTENSION;
        e.value = stringValue;
        [self addExtension:e];
        return;
    }
    e.value = stringValue;
}

- (BOOL) isGap
{
    NSString *profileType = [self getProfileType];
    return [GAP_PROFILE_TYPE isEqualToString:profileType];
}

- (void)setGap
{
    [self setProfileType:GAP_PROFILE_TYPE];
}

- (void) copyExtensions:(OAGpxTrkPt *)pt
{
    self.extraData = pt.extraData;
}

@end

@implementation OAGpxTrkSeg

- (instancetype)init
{
    self = [super init];
    if (self) {
        _routeTypes = [NSMutableArray new];
        _routeSegments = [NSMutableArray new];
    }
    return self;
}

-(NSArray*) splitByDistance:(double)meters
{
    return [self split:[[OADistanceMetric alloc] init] secondaryMetric:[[OATimeSplit alloc] init] metricLimit:meters];
}

-(NSArray*) splitByTime:(int)seconds
{
    return [self split:[[OATimeSplit alloc] init] secondaryMetric:[[OADistanceMetric alloc] init] metricLimit:seconds];
}

-(NSArray*) split:(OASplitMetric*)metric secondaryMetric:(OASplitMetric *)secondaryMetric metricLimit:(double)metricLimit
{
    NSMutableArray *splitSegments = [NSMutableArray array];
    [OAGPXTrackAnalysis splitSegment:metric secondaryMetric:secondaryMetric metricLimit:metricLimit splitSegments:splitSegments segment:self];
    return [OAGPXTrackAnalysis convert:splitSegments];
}

- (BOOL) hasRoute
{
    return _routeSegments.count > 0 && _routeTypes.count > 0;
}

- (void) fillExtensions
{
    if (_routeSegments.count > 0)
    {
        OAGpxExtension *ext = [[OAGpxExtension alloc] init];
        ext.name = @"route";
        NSMutableArray<OAGpxExtension *> *subexts = [NSMutableArray new];
        for (OARouteSegment *seg in _routeSegments)
        {
            OAGpxExtension *subExt = [[OAGpxExtension alloc] init];
            subExt.name = @"segment";
            subExt.attributes = seg.toDictionary;
            [subexts addObject:subExt];
        }
        ext.subextensions = subexts;
        [self addExtension:ext];
    }
    if (_routeTypes.count > 0)
    {
        OAGpxExtension *ext = [[OAGpxExtension alloc] init];
        ext.name = @"types";
        NSMutableArray<OAGpxExtension *> *subexts = [NSMutableArray new];
        for (OARouteType *type in _routeTypes)
        {
            OAGpxExtension *subExt = [[OAGpxExtension alloc] init];
            subExt.name = @"type";
            subExt.attributes = type.toDictionary;
            [subexts addObject:subExt];
        }
        ext.subextensions = subexts;
        [self addExtension:ext];
    }
}

- (void) addExtension:(OAGpxExtension *)e
{
    if (!self.extraData)
        self.extraData = [[OAGpxExtensions alloc] init];
    NSArray<OAGpxExtension *> *exts = ((OAGpxExtensions *)self.extraData).extensions;
    if (![exts containsObject:e])
        ((OAGpxExtensions *)self.extraData).extensions = [exts arrayByAddingObject:e];
}

@end

@implementation OAGpxRte
@end
@implementation OAGpxRtePt

- (instancetype) initWithTrkPt:(OAGpxTrkPt *)point
{
    self = [super init];
    if (self) {
        self.ageOfGpsData = point.ageOfGpsData;
        self.dgpsStationId = point.dgpsStationId;
        self.fixType = point.fixType;
        self.geoidHeight = point.geoidHeight;
        self.horizontalDilutionOfPrecision = point.horizontalDilutionOfPrecision;
        self.magneticVariation = point.magneticVariation;
        self.positionDilutionOfPrecision = point.positionDilutionOfPrecision;
        self.satellitesUsedForFixCalculation = point.satellitesUsedForFixCalculation;
        self.source = point.source;
        self.speed = point.speed;
        self.symbol = point.symbol;
        self.verticalDilutionOfPrecision = point.verticalDilutionOfPrecision;
        
        self.firstPoint = point.firstPoint;
        self.lastPoint = point.lastPoint;
        self.position = point.position;
        self.name = point.name;
        self.desc = point.desc;
        self.elevation = point.elevation;
        self.time = point.time;
        self.comment = point.comment;
        self.type = point.type;
        self.links = point.links;
        self.extraData = point.extraData;
        self.distance = point.distance;
    }
    return self;
}

@end
@implementation OAGpxLink
@end
@implementation OAGpxMetadata
@end

@implementation OAGpxRouteSegment

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _ID = @"";
        _length = @"";
        _segmentTime = @"";
        _speed = @"";
        _turnType = @"";
        _turnAngle = @"";
        _types = @"";
        _pointTypes = @"";
        _names = @"";
    }
    return self;
}

+ (OAGpxRouteSegment *) fromStringBundle:(NSDictionary<NSString *, NSString *> *)bundle
{
    OAGpxRouteSegment *s = [[OAGpxRouteSegment alloc] init];
    s.ID = bundle[@"id"];
    s.length = bundle[@"length"];
    s.segmentTime = bundle[@"segmentTime"];
    s.speed = bundle[@"speed"];
    s.turnType = bundle[@"turnType"];
    s.turnAngle = bundle[@"turnAngle"];
    s.types = bundle[@"types"];
    s.pointTypes = bundle[@"pointTypes"];
    s.names = bundle[@"names"];
    return s;
}

- (NSDictionary<NSString *, NSString *> *) toStringBundle
{
    NSMutableDictionary *bundle = [NSMutableDictionary new];
    bundle[@"id"] = _ID;
    bundle[@"length"] = _length;
    bundle[@"segmentTime"] = _segmentTime;
    bundle[@"speed"] = _speed;
    bundle[@"turnType"] = _turnType;
    bundle[@"turnAngle"] = _turnAngle;
    bundle[@"types"] = _types;
    bundle[@"pointTypes"] = _pointTypes;
    bundle[@"names"] = _names;
    return bundle;
}

@end

@implementation OAGpxRouteType

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _tag = @"";
        _value = @"";
    }
    return self;
}

+ (OAGpxRouteType *) fromStringBundle:(NSDictionary<NSString *, NSString *> *)bundle
{
    OAGpxRouteType *t = [[OAGpxRouteType alloc] init];
    t.tag = bundle[@"t"];
    t.value = bundle[@"v"];
    return t;
}

- (NSDictionary<NSString *, NSString *> *) toStringBundle
{
    NSMutableDictionary *bundle = [NSMutableDictionary new];
    bundle[@"t"] = _tag;
    bundle[@"v"] = _value;
    return bundle;
}

@end
