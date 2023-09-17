//
//  CoordinatesMapCenterWidget.swift
//  OsmAnd Maps
//
//  Created by Skalii on 24.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OACoordinatesMapCenterWidget)
@objcMembers
class CoordinatesMapCenterWidget: CoordinatesBaseWidget {

    init() {
        super.init(type: .coordinatesMapCenter)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func updateInfo() -> Bool {
        let visible = OAWidgetsVisibilityHelper.sharedInstance().shouldShowTopMapCenterCoordinatesWidget()
        let loc: CLLocation = OARootViewController.instance().mapPanel.mapViewController.getMapLocation()

        updateVisibility(visible: visible)
        if visible {
            showFormattedCoordinates(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude)
        }
        return true
    }

    override func getCoordinateIcon() -> UIImage {
        let iconId = OAAppSettings.sharedManager().nightMode
            ? "widget_coordinates_map_center_night"
            : "widget_coordinates_map_center_day"
        return UIImage.init(named: iconId)!
    }
}
