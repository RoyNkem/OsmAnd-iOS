//
//  OASQLiteTileSourceMapLayerProvider.h
//  OsmAnd
//
//  Created by Alexey Kulish on 03/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//
#include <CoreFoundation/CoreFoundation.h>
#include <objc/objc.h>
#include <OsmAndCore/Map/ImageMapLayerProvider.h>
#include <OsmAndCore/IWebClient.h>
#include <QWaitCondition>
#include <QReadWriteLock>
#include <QList>
#include <QHash>
#include <OsmAndCore/QtExtensions.h>
#include <array>
#include <OsmAndCore/stdlib_common.h>
#include <functional>
#include <QSet>

#import "OASQLiteTileSource.h"

class OASQLiteTileSourceMapLayerProvider : public OsmAnd::ImageMapLayerProvider
{
private:
    const std::shared_ptr<const OsmAnd::IWebClient> _webClient;

    mutable QMutex _tilesInProcessMutex;
    std::array< QSet< OsmAnd::TileId >, OsmAnd::ZoomLevelsCount > _tilesInProcess;
    QWaitCondition _waitUntilAnyTileIsProcessed;
    
    void lockTile(const OsmAnd::TileId tileId, const OsmAnd::ZoomLevel zoom);
    void unlockTile(const OsmAnd::TileId tileId, const OsmAnd::ZoomLevel zoom);
    QByteArray downloadTile(const OsmAnd::TileId tileId, const OsmAnd::ZoomLevel zoom);
    const std::shared_ptr<const SkBitmap> downloadShiftedTile(const OsmAnd::TileId tileIdNext, const OsmAnd::ZoomLevel zoom, const NSData *data, double offsetY);
    const std::shared_ptr<const SkBitmap> createShiftedTileBitmap(const NSData *data, const NSData* dataNext, double offsetY);
    const std::shared_ptr<const SkBitmap> decodeBitmap(const NSData *data);

protected:
public:
    OASQLiteTileSourceMapLayerProvider(const QString& fileName);
    virtual ~OASQLiteTileSourceMapLayerProvider();
    
    OASQLiteTileSource *ts;
    
    virtual QByteArray obtainImage(const OsmAnd::IMapTiledDataProvider::Request& request);
    virtual const std::shared_ptr<const SkBitmap> obtainImageBitmap(
        const OsmAnd::IMapTiledDataProvider::Request& request);
    virtual bool supportsObtainImageBitmap() const;

    virtual void obtainImageAsync(
        const OsmAnd::IMapTiledDataProvider::Request& request,
        const OsmAnd::ImageMapLayerProvider::AsyncImage* asyncImage);
    
    virtual OsmAnd::AlphaChannelPresence getAlphaChannelPresence() const;
    virtual OsmAnd::MapStubStyle getDesiredStubsStyle() const;
    
    virtual float getTileDensityFactor() const;
    virtual uint32_t getTileSize() const;
    
    virtual bool supportsNaturalObtainData() const;
    virtual bool supportsNaturalObtainDataAsync() const;
    
    virtual OsmAnd::ZoomLevel getMinZoom() const;
    virtual OsmAnd::ZoomLevel getMaxZoom() const;
};
