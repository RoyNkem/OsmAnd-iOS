//
//  OAGPXDocument.m
//  OsmAnd
//
//  Created by Alexey Kulish on 12/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXDocument.h"
#import "OAGPXTrackAnalysis.h"
#import "OAUtilities.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/QKeyValueIterator.h>

@implementation OAGPXDocument
{
    double left;
    double top;
    double right;
    double bottom;
}

- (id)initWithGpxDocument:(std::shared_ptr<OsmAnd::GpxDocument>)gpxDocument
{
    if (self = [super init])
    {
        if ([self fetch:gpxDocument])
            return self;
        else
            return nil;
    }
    else
    {
        return nil;
    }
}

- (id)initWithGpxFile:(NSString *)filename
{
    if (self = [super init])
    {
        self.fileName = filename;
        if ([self loadFrom:filename])
            return self;
        else
            return nil;
    }
    else
    {
        return nil;
    }
}

+ (NSArray *)fetchExtensions:(QList<OsmAnd::Ref<OsmAnd::GpxDocument::GpxExtension>>)extensions
{
    if (!extensions.isEmpty()) {
        
        NSMutableArray *_OAExtensions = [NSMutableArray array];
        for (const auto& ext : extensions)
        {
            OAGpxExtension *e = [[OAGpxExtension alloc] init];
            
            e.name = ext->name.toNSString();
            e.value = ext->value.toNSString();
            if (!ext->attributes.isEmpty()) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                for(const auto& entry : OsmAnd::rangeOf(OsmAnd::constOf(ext->attributes))) {
                    [dict setObject:entry.value().toNSString() forKey:entry.key().toNSString()];
                }
                e.attributes = dict;
            }
            
            e.subextensions = [self fetchExtensions:ext->subextensions];
            
            [_OAExtensions addObject:e];
        }
        
        return _OAExtensions;
    }
    
    return nil;
}

+ (OAGpxExtensions *)fetchExtra:(OsmAnd::Ref<OsmAnd::GeoInfoDocument::ExtraData>)extraData
{
    if (extraData != nullptr) {
        
        OsmAnd::Ref<OsmAnd::GpxDocument::GpxExtensions> *_e = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxExtensions>*)&extraData;
        const std::shared_ptr<const OsmAnd::GpxDocument::GpxExtensions> e = _e->shared_ptr();
        
        OAGpxExtensions *exts = [[OAGpxExtensions alloc] init];
        exts.value = e->value.toNSString();
        if (!e->attributes.isEmpty()) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            for(const auto& entry : OsmAnd::rangeOf(OsmAnd::constOf(e->attributes))) {
                [dict setObject:entry.value().toNSString() forKey:entry.key().toNSString()];
            }
            exts.attributes = dict;
        }
        
        exts.extensions = [self fetchExtensions:e->extensions];
        
        return exts;
    }
    return nil;
}

+ (NSArray *)fetchLinks:(QList<OsmAnd::Ref<OsmAnd::GeoInfoDocument::Link>>)links
{
    if (!links.isEmpty()) {
        NSMutableArray *_OALinks = [NSMutableArray array];
        for (const auto& l : links)
        {
            OsmAnd::Ref<OsmAnd::GpxDocument::GpxLink> *_l = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxLink>*)&l;
            const std::shared_ptr<const OsmAnd::GpxDocument::GpxLink> link = _l->shared_ptr();

            OAGpxLink *_OALink = [[OAGpxLink alloc] init];
            _OALink.type = link->type.toNSString();
            _OALink.text = link->text.toNSString();
            _OALink.url = link->url.toNSURL();
            [_OALinks addObject:_OALink];
        }
        return _OALinks;
    }
    return nil;
}

- (void)initBounds
{
    left = DBL_MAX;
    top = DBL_MAX;
    right = DBL_MAX;
    bottom = DBL_MAX;
}

- (void)processBounds:(CLLocationCoordinate2D)coord
{
    if (left == DBL_MAX) {
        left = coord.longitude;
        right = coord.longitude;
        top = coord.latitude;
        bottom = coord.latitude;
        
    } else {
        
        left = MIN(left, coord.longitude);
        right = MAX(right, coord.longitude);
        top = MAX(top, coord.latitude);
        bottom = MIN(bottom, coord.latitude);
    }
}

- (void)applyBounds
{
    double clat = bottom / 2.0 + top / 2.0;
    double clon = left / 2.0 + right / 2.0;
    
    OAGpxBounds bounds;
    bounds.center = CLLocationCoordinate2DMake(clat, clon);
    bounds.topLeft = CLLocationCoordinate2DMake(top, left);
    bounds.bottomRight = CLLocationCoordinate2DMake(bottom, right);
    self.bounds = bounds;
}

+ (OAGpxWpt *)fetchWpt:(const std::shared_ptr<const OsmAnd::GpxDocument::GpxWpt>)mark
{
    OAGpxWpt *_mark = [[OAGpxWpt alloc] init];
    _mark.position = CLLocationCoordinate2DMake(mark->position.latitude, mark->position.longitude);
    _mark.name = mark->name.toNSString();
    _mark.desc = mark->description.toNSString();
    _mark.elevation = mark->elevation;
    _mark.time = mark->timestamp.toTime_t();
    _mark.comment = mark->comment.toNSString();
    _mark.type = mark->type.toNSString();
    
    _mark.magneticVariation = mark->magneticVariation;
    _mark.geoidHeight = mark->geoidHeight;
    _mark.source = mark->source.toNSString();
    _mark.symbol = mark->symbol.toNSString();
    _mark.fixType = (OAGpxFixType)mark->fixType;
    _mark.satellitesUsedForFixCalculation = mark->satellitesUsedForFixCalculation;
    _mark.horizontalDilutionOfPrecision = mark->horizontalDilutionOfPrecision;
    _mark.verticalDilutionOfPrecision = mark->verticalDilutionOfPrecision;
    _mark.positionDilutionOfPrecision = mark->positionDilutionOfPrecision;
    _mark.ageOfGpsData = mark->ageOfGpsData;
    _mark.dgpsStationId = mark->dgpsStationId;
    
    _mark.links = [self.class fetchLinks:mark->links];
    
    _mark.extraData = [self.class fetchExtra:mark->extraData];
    
    if (_mark.extraData)
    {
        OAGpxExtensions *exts = (OAGpxExtensions *)_mark.extraData;
        for (OAGpxExtension *e in exts.extensions)
        {
            if ([e.name isEqualToString:@"speed"])
            {
                _mark.speed = [e.value doubleValue];
            }
            else if ([e.name isEqualToString:@"color"])
            {
                _mark.color = e.value;
            }
        }
    }
    
    return _mark;
}

- (BOOL) fetch:(std::shared_ptr<OsmAnd::GpxDocument>)gpxDocument
{
    [self initBounds];

    self.version = gpxDocument->version.toNSString();
    self.creator = gpxDocument->creator.toNSString();
    
    if (gpxDocument->metadata != nullptr) {
        OAGpxMetadata *metadata = [[OAGpxMetadata alloc] init];
        metadata.name = gpxDocument->metadata->name.toNSString();
        metadata.desc = gpxDocument->metadata->description.toNSString();
        metadata.time = gpxDocument->metadata->timestamp.toTime_t();
        metadata.links = [self.class fetchLinks:gpxDocument->metadata->links];
        metadata.extraData = [self.class fetchExtra:gpxDocument->extraData];
        
        self.metadata = metadata;
    }
    
    // Location Marks
    if (!gpxDocument->locationMarks.isEmpty()) {
        const QList<OsmAnd::Ref<OsmAnd::GeoInfoDocument::LocationMark>> marks = gpxDocument->locationMarks;
        
        NSMutableArray<OAGpxWpt *> *_marks = [NSMutableArray array];
        for (const auto& m : marks)
        {
            OsmAnd::Ref<OsmAnd::GpxDocument::GpxWpt> *_m = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxWpt>*)&m;
            const std::shared_ptr<const OsmAnd::GpxDocument::GpxWpt> mark = _m->shared_ptr();
            
            OAGpxWpt *_mark = [self.class fetchWpt:mark];
            [self processBounds:_mark.position];

            [_marks addObject:_mark];
        }
        self.locationMarks = _marks;
    }
   
    // Tracks
    if (!gpxDocument->tracks.isEmpty()) {
        QList<OsmAnd::Ref<OsmAnd::GeoInfoDocument::Track>> trcks = gpxDocument->tracks;
        NSMutableArray<OAGpxTrk *> *_trcks = [NSMutableArray array];
        for (const auto& t : trcks)
        {
            OsmAnd::Ref<OsmAnd::GpxDocument::GpxTrk> *_t = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxTrk>*)&t;
            const std::shared_ptr<const OsmAnd::GpxDocument::GpxTrk> track = _t->shared_ptr();

            OAGpxTrk *_track = [[OAGpxTrk alloc] init];
            
            _track.name = track->name.toNSString();
            _track.desc = track->description.toNSString();
            _track.comment = track->comment.toNSString();
            _track.type = track->type.toNSString();
            _track.links = [self.class fetchLinks:track->links];
            
            _track.source = track->source.toNSString();
            _track.slotNumber = track->slotNumber;

            if (!track->segments.isEmpty()) {
                NSMutableArray<OAGpxTrkSeg *> *seg = [NSMutableArray array];
                
                for (const auto& s : track->segments)
                {
                    OAGpxTrkSeg *_s = [[OAGpxTrkSeg alloc] init];

                    if (!s->points.isEmpty()) {
                        NSMutableArray<OAGpxTrkPt *> *pts = [NSMutableArray array];
                        
                        for (const auto& pt : s->points)
                        {
                            OsmAnd::Ref<OsmAnd::GpxDocument::GpxTrkPt> *_pt = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxTrkPt>*)&pt;
                            const std::shared_ptr<const OsmAnd::GpxDocument::GpxTrkPt> p = _pt->shared_ptr();

                            OAGpxTrkPt *_p = [[OAGpxTrkPt alloc] init];
                            
                            _p.position = CLLocationCoordinate2DMake(p->position.latitude, p->position.longitude);
                            _p.name = p->name.toNSString();
                            _p.desc = p->description.toNSString();
                            _p.elevation = p->elevation;
                            _p.time = p->timestamp.toTime_t();
                            _p.comment = p->comment.toNSString();
                            _p.type = p->type.toNSString();
                            _p.links = [self.class fetchLinks:p->links];
                            
                            _p.magneticVariation = p->magneticVariation;
                            _p.geoidHeight = p->geoidHeight;
                            _p.source = p->source.toNSString();
                            _p.symbol = p->symbol.toNSString();
                            _p.fixType = (OAGpxFixType)p->fixType;
                            _p.satellitesUsedForFixCalculation = p->satellitesUsedForFixCalculation;
                            _p.horizontalDilutionOfPrecision = p->horizontalDilutionOfPrecision;
                            _p.verticalDilutionOfPrecision = p->verticalDilutionOfPrecision;
                            _p.positionDilutionOfPrecision = p->positionDilutionOfPrecision;
                            _p.ageOfGpsData = p->ageOfGpsData;
                            _p.dgpsStationId = p->dgpsStationId;

                            _p.extraData = [self.class fetchExtra:p->extraData];
                            if (_p.extraData) {
                                OAGpxExtensions *exts = (OAGpxExtensions *)_p.extraData;
                                for (OAGpxExtension *e in exts.extensions) {
                                    if ([e.name isEqualToString:@"speed"]) {
                                        _p.speed = [e.value doubleValue];
                                        break;
                                    }
                                }
                            }

                            [self processBounds:_p.position];
                            [pts addObject:_p];
                        }
                        _s.points = pts;
                    }
                    
                    _s.extraData = [self.class fetchExtra:s->extraData];
                    
                    [seg addObject:_s];
                }
                
                _track.segments = seg;
            }
            
            _track.extraData = [self.class fetchExtra:t->extraData];
            
            [_trcks addObject:_track];
        }
        self.tracks = _trcks;
    }
    
    // Routes
    if (!gpxDocument->routes.isEmpty()) {
        QList<OsmAnd::Ref<OsmAnd::GeoInfoDocument::Route>> rts = gpxDocument->routes;
        NSMutableArray<OAGpxRte *> *_rts = [NSMutableArray array];
        for (const auto& r : rts)
        {
            OsmAnd::Ref<OsmAnd::GpxDocument::GpxRte> *_r = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxRte>*)&r;
            const std::shared_ptr<const OsmAnd::GpxDocument::GpxRte> route = _r->shared_ptr();

            OAGpxRte *_route = [[OAGpxRte alloc] init];
            
            _route.name = route->name.toNSString();
            _route.desc = route->description.toNSString();
            _route.comment = route->comment.toNSString();
            _route.type = route->type.toNSString();
            _route.links = [self.class fetchLinks:route->links];
            
            _route.source = route->source.toNSString();
            _route.slotNumber = route->slotNumber;

            if (!route->points.isEmpty()) {
                NSMutableArray<OAGpxRtePt *> *_points = [NSMutableArray array];
                
                for (const auto& pt : route->points)
                {
                    OsmAnd::Ref<OsmAnd::GpxDocument::GpxRtePt> *_pt = (OsmAnd::Ref<OsmAnd::GpxDocument::GpxRtePt>*)&pt;
                    const std::shared_ptr<const OsmAnd::GpxDocument::GpxRtePt> p = _pt->shared_ptr();

                    OAGpxRtePt *_p = [[OAGpxRtePt alloc] init];
                    
                    _p.position = CLLocationCoordinate2DMake(p->position.latitude, p->position.longitude);
                    _p.name = p->name.toNSString();
                    _p.desc = p->description.toNSString();
                    _p.elevation = p->elevation;
                    _p.time = p->timestamp.toTime_t();
                    _p.comment = p->comment.toNSString();
                    _p.type = p->type.toNSString();
                    _p.links = [self.class fetchLinks:p->links];
                    
                    _p.magneticVariation = p->magneticVariation;
                    _p.geoidHeight = p->geoidHeight;
                    _p.source = p->source.toNSString();
                    _p.symbol = p->symbol.toNSString();
                    _p.fixType = (OAGpxFixType)p->fixType;
                    _p.satellitesUsedForFixCalculation = p->satellitesUsedForFixCalculation;
                    _p.horizontalDilutionOfPrecision = p->horizontalDilutionOfPrecision;
                    _p.verticalDilutionOfPrecision = p->verticalDilutionOfPrecision;
                    _p.positionDilutionOfPrecision = p->positionDilutionOfPrecision;
                    _p.ageOfGpsData = p->ageOfGpsData;
                    _p.dgpsStationId = p->dgpsStationId;
                    
                    _p.extraData = [self.class fetchExtra:p->extraData];
                    if (_p.extraData) {
                        OAGpxExtensions *exts = (OAGpxExtensions *)_p.extraData;
                        for (OAGpxExtension *e in exts.extensions) {
                            if ([e.name isEqualToString:@"speed"]) {
                                _p.speed = [e.value doubleValue];
                                break;
                            }
                        }
                    }
                    
                    [self processBounds:_p.position];
                    [_points addObject:_p];
                    
                }
                
                _route.points = _points;
            }
            
            _route.extraData = [self.class fetchExtra:r->extraData];
            
            [_rts addObject:_route];
        }
        self.routes = _rts;
    }

    [self applyBounds];
    
    return YES;
}

- (BOOL) loadFrom:(NSString *)filename
{
    if (filename && filename.length > 0)
        return [self fetch:OsmAnd::GpxDocument::loadFrom(QString::fromNSString(filename))];
    else
        return false;
}

+ (void) fillLinks:(QList<OsmAnd::Ref<OsmAnd::GpxDocument::Link>>&)links linkArray:(NSArray *)linkArray
{
    std::shared_ptr<OsmAnd::GpxDocument::GpxLink> link;
    for (OAGpxLink *l in linkArray)
    {
        link.reset(new OsmAnd::GpxDocument::GpxLink());
        link->url = QUrl::fromNSURL(l.url);
        link->type = QString::fromNSString(l.type);
        link->text = QString::fromNSString(l.text);
        links.append(link);
        link = nullptr;
    }
}

+ (void) fillExtensions:(const std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions>&)extensions ext:(OAGpxExtensions *)ext
{
    for (OAGpxExtension *e in ext.extensions)
    {
        std::shared_ptr<OsmAnd::GpxDocument::GpxExtension> extension(new OsmAnd::GpxDocument::GpxExtension());
        [self fillExtension:extension ext:e];
        extensions->extensions.push_back(extension);
        extension = nullptr;
    }
}

+ (void) fillExtension:(const std::shared_ptr<OsmAnd::GpxDocument::GpxExtension>&)extension ext:(OAGpxExtension *)e
{
    extension->name = QString::fromNSString(e.name);
    extension->value = QString::fromNSString(e.value);
    for (NSString *key in e.attributes.allKeys)
    {
        extension->attributes[QString::fromNSString(key)] = QString::fromNSString(e.attributes[key]);
    }
    for (OAGpxExtension *es in e.subextensions)
    {
        std::shared_ptr<OsmAnd::GpxDocument::GpxExtension> subextension(new OsmAnd::GpxDocument::GpxExtension());
        [self fillExtension:subextension ext:es];
        extension->subextensions.push_back(subextension);
        subextension = nullptr;
    }
}

+ (void)fillMetadata:(std::shared_ptr<OsmAnd::GpxDocument::GpxMetadata>)meta usingMetadata:(OAGpxMetadata *)m
{
    meta->name = QString::fromNSString(m.name);
    meta->description = QString::fromNSString(m.desc);
    meta->timestamp = QDateTime::fromTime_t(m.time);
    
    [self fillLinks:meta->links linkArray:m.links];
    
    std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions> extensions;
    extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
    if (m.extraData)
        [self fillExtensions:extensions ext:(OAGpxExtensions *)m.extraData];
    meta->extraData = extensions;
    extensions = nullptr;
}

+ (void)fillWpt:(std::shared_ptr<OsmAnd::GpxDocument::GpxWpt>)wpt usingWpt:(OAGpxWpt *)w
{
    wpt->position.latitude = w.position.latitude;
    wpt->position.longitude = w.position.longitude;
    wpt->name = QString::fromNSString(w.name);
    wpt->description = QString::fromNSString(w.desc);
    wpt->elevation = w.elevation;
    wpt->timestamp = QDateTime::fromTime_t(w.time);
    wpt->magneticVariation = w.magneticVariation;
    wpt->geoidHeight = w.geoidHeight;
    wpt->comment = QString::fromNSString(w.comment);
    wpt->source = QString::fromNSString(w.source);
    wpt->symbol = QString::fromNSString(w.symbol);
    wpt->type = QString::fromNSString(w.type);
    wpt->fixType = (OsmAnd::GpxDocument::GpxFixType)w.fixType;
    wpt->satellitesUsedForFixCalculation = w.satellitesUsedForFixCalculation;
    wpt->horizontalDilutionOfPrecision = w.horizontalDilutionOfPrecision;
    wpt->verticalDilutionOfPrecision = w.verticalDilutionOfPrecision;
    wpt->positionDilutionOfPrecision = w.positionDilutionOfPrecision;
    wpt->ageOfGpsData = w.ageOfGpsData;
    wpt->dgpsStationId = w.dgpsStationId;
    
    [self fillLinks:wpt->links linkArray:w.links];
    
    NSMutableArray *extArray = [NSMutableArray array];
    if (w.extraData)
    {
        OAGpxExtensions *exts = (OAGpxExtensions *)w.extraData;
        if (exts.extensions)
            for (OAGpxExtension *e in exts.extensions)
                if (![e.name isEqualToString:@"speed"] && ![e.name isEqualToString:@"color"])
                    [extArray addObject:e];
    }
    
    if (w.speed >= 0)
    {
        OAGpxExtension *e = [[OAGpxExtension alloc] init];
        e.name = @"speed";
        e.value = [NSString stringWithFormat:@"%.3f", w.speed];
        [extArray addObject:e];
    }
    if (w.color.length > 0)
    {
        OAGpxExtension *e = [[OAGpxExtension alloc] init];
        e.name = @"color";
        e.value = w.color;
        [extArray addObject:e];
    }
    
    if (extArray.count > 0)
    {
        OAGpxExtensions *ext = [[OAGpxExtensions alloc] init];
        ext.extensions = [NSArray arrayWithArray:extArray];
        w.extraData = ext;
    }
    
    std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions> extensions;
    extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
    if (w.extraData)
        [self fillExtensions:extensions ext:(OAGpxExtensions *)w.extraData];
    wpt->extraData = extensions;
    extensions = nullptr;
}

+ (void)fillTrack:(std::shared_ptr<OsmAnd::GpxDocument::GpxTrk>)trk usingTrack:(OAGpxTrk *)t
{
    std::shared_ptr<OsmAnd::GpxDocument::GpxTrkPt> trkpt;
    std::shared_ptr<OsmAnd::GpxDocument::GpxTrkSeg> trkseg;

    trk->name = QString::fromNSString(t.name);
    trk->description = QString::fromNSString(t.desc);
    trk->comment = QString::fromNSString(t.comment);
    trk->source = QString::fromNSString(t.source);
    trk->type = QString::fromNSString(t.type);
    trk->slotNumber = t.slotNumber;
    
    for (OAGpxTrkSeg *s in t.segments)
    {
        trkseg.reset(new OsmAnd::GpxDocument::GpxTrkSeg());
        
        for (OAGpxTrkPt *p in s.points)
        {
            trkpt.reset(new OsmAnd::GpxDocument::GpxTrkPt());
            trkpt->position.latitude = p.position.latitude;
            trkpt->position.longitude = p.position.longitude;
            trkpt->name = QString::fromNSString(p.name);
            trkpt->description = QString::fromNSString(p.desc);
            trkpt->elevation = p.elevation;
            trkpt->timestamp = QDateTime::fromTime_t(p.time);
            trkpt->magneticVariation = p.magneticVariation;
            trkpt->geoidHeight = p.geoidHeight;
            trkpt->comment = QString::fromNSString(p.comment);
            trkpt->source = QString::fromNSString(p.source);
            trkpt->symbol = QString::fromNSString(p.symbol);
            trkpt->type = QString::fromNSString(p.type);
            trkpt->fixType = (OsmAnd::GpxDocument::GpxFixType)p.fixType;
            trkpt->satellitesUsedForFixCalculation = p.satellitesUsedForFixCalculation;
            trkpt->horizontalDilutionOfPrecision = p.horizontalDilutionOfPrecision;
            trkpt->verticalDilutionOfPrecision = p.verticalDilutionOfPrecision;
            trkpt->positionDilutionOfPrecision = p.positionDilutionOfPrecision;
            trkpt->ageOfGpsData = p.ageOfGpsData;
            trkpt->dgpsStationId = p.dgpsStationId;
            
            [self.class fillLinks:trkpt->links linkArray:p.links];
            
            NSMutableArray *extArray = [NSMutableArray array];
            if (p.extraData)
            {
                OAGpxExtensions *exts = (OAGpxExtensions *)p.extraData;
                if (exts.extensions)
                    for (OAGpxExtension *e in exts.extensions)
                        if (![e.name isEqualToString:@"speed"])
                            [extArray addObject:e];
            }
            
            if (p.speed >= 0.0)
            {
                OAGpxExtension *e = [[OAGpxExtension alloc] init];
                e.name = @"speed";
                e.value = [NSString stringWithFormat:@"%.3f", p.speed];
                [extArray addObject:e];
            }
            
            if (extArray.count > 0)
            {
                OAGpxExtensions *ext = [[OAGpxExtensions alloc] init];
                ext.extensions = [NSArray arrayWithArray:extArray];
                p.extraData = ext;
            }
            
            std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions> extensions;
            extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
            if (p.extraData)
                [self.class fillExtensions:extensions ext:(OAGpxExtensions *)p.extraData];
            trkpt->extraData = extensions;
            extensions = nullptr;
            
            trkseg->points.append(trkpt);
            trkpt = nullptr;
        }
        
        std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions> extensions;
        extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
        if (s.extraData)
            [self.class fillExtensions:extensions ext:(OAGpxExtensions *)s.extraData];
        trkseg->extraData = extensions;
        extensions = nullptr;
        
        trk->segments.append(trkseg);
        trkseg = nullptr;
    }
    
    [self.class fillLinks:trk->links linkArray:t.links];
    
    std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions> extensions;
    extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
    if (t.extraData)
        [self.class fillExtensions:extensions ext:(OAGpxExtensions *)t.extraData];
    trk->extraData = extensions;
    extensions = nullptr;
}

+ (void)fillRoute:(std::shared_ptr<OsmAnd::GpxDocument::GpxRte>)rte usingRoute:(OAGpxRte *)r
{
    std::shared_ptr<OsmAnd::GpxDocument::GpxRtePt> rtept;

    rte->name = QString::fromNSString(r.name);
    rte->description = QString::fromNSString(r.desc);
    rte->comment = QString::fromNSString(r.comment);
    rte->source = QString::fromNSString(r.source);
    rte->type = QString::fromNSString(r.type);
    rte->slotNumber = r.slotNumber;
    
    for (OAGpxRtePt *p in r.points)
    {
        rtept.reset(new OsmAnd::GpxDocument::GpxRtePt());
        rtept->position.latitude = p.position.latitude;
        rtept->position.longitude = p.position.longitude;
        rtept->category = QString::fromNSString(p.name);
        rtept->name = QString::fromNSString(p.name);
        rtept->description = QString::fromNSString(p.desc);
        rtept->elevation = p.elevation;
        rtept->timestamp = QDateTime::fromTime_t(p.time);
        rtept->magneticVariation = p.magneticVariation;
        rtept->geoidHeight = p.geoidHeight;
        rtept->comment = QString::fromNSString(p.comment);
        rtept->source = QString::fromNSString(p.source);
        rtept->symbol = QString::fromNSString(p.symbol);
        rtept->type = QString::fromNSString(p.type);
        rtept->fixType = (OsmAnd::GpxDocument::GpxFixType)p.fixType;
        rtept->satellitesUsedForFixCalculation = p.satellitesUsedForFixCalculation;
        rtept->horizontalDilutionOfPrecision = p.horizontalDilutionOfPrecision;
        rtept->verticalDilutionOfPrecision = p.verticalDilutionOfPrecision;
        rtept->positionDilutionOfPrecision = p.positionDilutionOfPrecision;
        rtept->ageOfGpsData = p.ageOfGpsData;
        rtept->dgpsStationId = p.dgpsStationId;
        
        [self.class fillLinks:rtept->links linkArray:p.links];
        
        NSMutableArray *extArray = [NSMutableArray array];
        if (p.extraData)
        {
            OAGpxExtensions *exts = (OAGpxExtensions *)p.extraData;
            if (exts.extensions)
                for (OAGpxExtension *e in exts.extensions)
                    if (![e.name isEqualToString:@"speed"])
                        [extArray addObject:e];
        }
        
        if (p.speed >= 0.0)
        {
            OAGpxExtension *e = [[OAGpxExtension alloc] init];
            e.name = @"speed";
            e.value = [NSString stringWithFormat:@"%.3f", p.speed];
            [extArray addObject:e];
        }
        
        if (extArray.count > 0)
        {
            OAGpxExtensions *ext = [[OAGpxExtensions alloc] init];
            ext.extensions = [NSArray arrayWithArray:extArray];
            p.extraData = ext;
        }
        
        std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions> extensions;
        extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
        if (p.extraData)
            [self.class fillExtensions:extensions ext:(OAGpxExtensions *)p.extraData];
        rtept->extraData = extensions;
        extensions = nullptr;
        
        rte->points.append(rtept);
    }
    
    [self.class fillLinks:rte->links linkArray:r.links];
    
    std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions> extensions;
    extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
    if (r.extraData)
        [self.class fillExtensions:extensions ext:(OAGpxExtensions *)r.extraData];
    rte->extraData = extensions;
    extensions = nullptr;
}

- (BOOL) saveTo:(NSString *)filename
{
    std::shared_ptr<OsmAnd::GpxDocument> document;
    std::shared_ptr<OsmAnd::GpxDocument::GpxMetadata> metadata;
    std::shared_ptr<OsmAnd::GpxDocument::GpxWpt> wpt;
    std::shared_ptr<OsmAnd::GpxDocument::GpxTrk> trk;
    std::shared_ptr<OsmAnd::GpxDocument::GpxRte> rte;
    std::shared_ptr<OsmAnd::GpxDocument::GpxExtensions> extensions;
    
    
    document.reset(new OsmAnd::GpxDocument());
    document->version = QString::fromNSString(self.version);
    document->creator = QString::fromNSString(self.creator);
    
    extensions.reset(new OsmAnd::GpxDocument::GpxExtensions());
    if (self.extraData)
        [self.class fillExtensions:extensions ext:(OAGpxExtensions *)self.extraData];
    document->extraData = extensions;
    extensions = nullptr;

    metadata.reset(new OsmAnd::GpxDocument::GpxMetadata());
    if (self.metadata)
        [self.class fillMetadata:metadata usingMetadata:(OAGpxMetadata *)self.metadata];

    document->metadata = metadata;
    metadata = nullptr;

    for (OAGpxWpt *w in self.locationMarks)
    {
        wpt.reset(new OsmAnd::GpxDocument::GpxWpt());
        [self.class fillWpt:wpt usingWpt:w];

        document->locationMarks.append(wpt);
        wpt = nullptr;
    }

    for (OAGpxTrk *t in self.tracks)
    {
        trk.reset(new OsmAnd::GpxDocument::GpxTrk());
        [self.class fillTrack:trk usingTrack:t];
        
        document->tracks.append(trk);
        trk = nullptr;
    }

    for (OAGpxRte *r in self.routes)
    {
        rte.reset(new OsmAnd::GpxDocument::GpxRte());
        [self.class fillRoute:rte usingRoute:r];
        
        document->routes.append(rte);
        rte = nullptr;
    }
    
    return document->saveTo(QString::fromNSString(filename));
}

- (BOOL) isCloudmadeRouteFile
{
    return self.creator && [@"cloudmade" isEqualToString:[self.creator lowerCase]];
}

- (OALocationMark *) findPointToShow
{
    for (OAGpxTrk *t in self.tracks) {
        for (OAGpxTrkSeg *s in t.segments) {
            if (s.points.count > 0) {
                return [s.points firstObject];
            }
        }
    }
    for (OAGpxRte *r in self.routes) {
        if (r.points.count > 0) {
            return [r.points firstObject];
        }
    }
    if (_locationMarks.count > 0) {
        return [_locationMarks firstObject];
    }
    return nil;
}

- (BOOL) isEmpty
{
    for (OAGpxTrk *t in self.tracks)
        if (t.segments != nil)
        {
            for (OAGpxTrkSeg *s in t.segments)
            {
                BOOL tracksEmpty = (s.points.count == 0);
                if (!tracksEmpty)
                    return NO;
            }
        }
    
    return self.locationMarks.count == 0 && self.routes.count == 0;
}

- (void) addGeneralTrack
{
    OAGpxTrk *generalTrack = [self getGeneralTrack];
    if (generalTrack && ![_tracks containsObject:generalTrack])
        _tracks = [@[generalTrack] arrayByAddingObjectsFromArray:_tracks];
}

-(OAGpxTrk *) getGeneralTrack
{
    OAGpxTrkSeg *generalSegment = [self getGeneralSegment];
    if (!_generalTrack && _generalSegment)
    {
        OAGpxTrk *track = [[OAGpxTrk alloc] init];
        track.segments = @[generalSegment];
        _generalTrack = track;
        track.generalTrack = YES;
    }
    return _generalTrack;
}

- (OAGpxTrkSeg *) getGeneralSegment
{
    if (!_generalSegment && [self getNonEmptySegmentsCount] > 1)
        [self buildGeneralSegment];

    return _generalSegment;
}

- (void) buildGeneralSegment
{
    OAGpxTrkSeg *segment = [[OAGpxTrkSeg alloc] init];
    for (OAGpxTrk *track in _tracks)
    {
        for (OAGpxTrkSeg *s in track.segments)
        {
            if (s.points.count > 0)
            {
                NSMutableArray <OAGpxTrkPt *> *waypoints = [[NSMutableArray alloc] initWithCapacity:s.points.count];
                for (OAGpxTrkPt *wptPt in s.points)
                {
                    [waypoints addObject:[[OAGpxTrkPt alloc] initWithPoint:wptPt]];
                }
                waypoints[0].firstPoint = YES;
                waypoints[waypoints.count - 1].lastPoint = YES;
                segment.points = segment.points ? [segment.points arrayByAddingObjectsFromArray:waypoints] : @[waypoints];
            }
        }
    }
    if (segment.points.count > 0)
    {
        segment.generalSegment = YES;
        _generalSegment = segment;
    }
}

- (NSInteger) getNonEmptySegmentsCount
{
    int count = 0;
    for (OAGpxTrk *t in _tracks)
    {
        for (OAGpxTrkSeg *s in t.segments)
        {
            if (s.points.count > 0)
                count++;
        }
    }
    return count;
}

// Analysis
- (OAGPXTrackAnalysis*) getAnalysis:(long)fileTimestamp
{
    OAGPXTrackAnalysis *g = [[OAGPXTrackAnalysis alloc] init];
    g.wptPoints = (int)self.locationMarks.count;
    NSMutableArray *splitSegments = [NSMutableArray array];
    for(OAGpxTrk *subtrack in self.tracks){
        for(OAGpxTrkSeg *segment in subtrack.segments){
            g.totalTracks ++;
            if(segment.points.count > 1) {
                [splitSegments addObject:[[OASplitSegment alloc] initWithTrackSegment:segment]];
            }
        }
    }
    [g prepareInformation:fileTimestamp splitSegments:splitSegments];
    
    return g;
}


-(NSArray*) splitByDistance:(int)meters
{
    return [self split:[[OADistanceMetric alloc] init] secondaryMetric:[[OATimeSplit alloc] init] metricLimit:meters];
}

-(NSArray*) splitByTime:(int)seconds
{
    return [self split:[[OATimeSplit alloc] init] secondaryMetric:[[OADistanceMetric alloc] init] metricLimit:seconds];
}

-(NSArray*) split:(OASplitMetric*)metric secondaryMetric:(OASplitMetric *)secondaryMetric metricLimit:(int)metricLimit
{
    NSMutableArray *splitSegments = [NSMutableArray array];
    for (OAGpxTrk *subtrack in self.tracks) {
        for (OAGpxTrkSeg *segment in subtrack.segments) {
            [OAGPXTrackAnalysis splitSegment:metric secondaryMetric:secondaryMetric metricLimit:metricLimit splitSegments:splitSegments segment:segment];
        }
    }
    return [OAGPXTrackAnalysis convert:splitSegments];
}

- (BOOL) hasRtePt
{
    for (OAGpxRte *r in _routes)
        if (r.points.count > 0)
            return YES;

    return NO;
}

- (BOOL) hasWptPt
{
    return _locationMarks.count > 0;
}

- (BOOL) hasTrkPt
{
    for (OAGpxTrk *t in _tracks)
        for (OAGpxTrkSeg *ts in t.segments)
            if (ts.points.count > 0)
                return YES;

    return NO;
}

- (UIColor *) getColor:(NSArray<OAGpxExtension *> *)extensions
{
    for (OAGpxExtension *e in extensions)
    {
        if ([e.name isEqualToString:@"color"])
        {
            bool ok;
            const auto color = OsmAnd::Utilities::parseColor(QString::fromNSString(e.value), OsmAnd::ColorARGB(), &ok);
            if (!ok)
                return nil;
            
            return UIColorFromARGB(color.argb);
        }
    }
}

- (double) getSpeed:(NSArray<OAGpxExtension *> *)extensions
{
    for (OAGpxExtension *e in extensions)
    {
        if ([e.name isEqualToString:@"speed"])
        {
            return [e.value doubleValue];
        }
    }
}

@end

