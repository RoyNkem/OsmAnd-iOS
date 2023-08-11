//
//  TravelGpx.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 11.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

class TravelGpx : TravelArticle {
    
    let DISTANCE = "distance"
    let DIFF_ELEVATION_UP = "diff_ele_up"
    let DIFF_ELEVATION_DOWN = "diff_ele_down"
    let MAX_ELEVATION = "max_ele"
    let MIN_ELEVATION = "min_ele"
    let AVERAGE_ELEVATION = "avg_ele"
    let ROUTE_RADIUS = "route_radius"
    let USER = "user"
    let ACTIVITY_TYPE = "route_activity_type"
    
    var user: String?
    var activityType: String?
    var totalDistance: Float = 0
    var diffElevationUp: Double = 0
    var diffElevationDown: Double = 0
    var maxElevation: Double = Double.nan
    var minElevation: Double = Double.nan
    var avgElevation: Double = 0
    
    override func getAnalysis() -> OAGPXTrackAnalysis? {
        var analysis = OAGPXTrackAnalysis()
        if (gpxFile != nil && gpxFile!.hasAltitude()) {
            analysis = gpxFile!.getAnalysis(0)
        } else {
            analysis.diffElevationDown = diffElevationDown
            analysis.diffElevationUp = diffElevationUp
            analysis.maxElevation = maxElevation
            analysis.minElevation = minElevation
            analysis.totalDistance = totalDistance
            analysis.totalDistanceWithoutGaps = totalDistance
            analysis.avgElevation = avgElevation
            //if maxElevation != Double.nan && minElevation != Double.nan {
            //    analysis.getElevationData().setHasData(true);
            //}
        }
        return analysis
    }
    
    func createWptPt(amenity: OAPOIAdapter, lang: String) -> OAWptPtAdapter {
        var wptPt = OAWptPtAdapter()
        wptPt.setPosition(CLLocationCoordinate2D(latitude: amenity.latitude(), longitude: amenity.longitude()))
        wptPt.setName(amenity.name())
        return wptPt
    }
    
    override func getPointFilterString() -> String {
        return "route_track_point";
    }
}
