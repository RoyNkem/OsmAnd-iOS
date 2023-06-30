//
//  BatteryWidget.swift
//  OsmAnd Maps
//
//  Created by Paul on 15.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OABatteryWidget)
@objcMembers
class BatteryWidget: OATextInfoWidget {
    
    var cachedLeftTime: TimeInterval = 0
    
    init() {
        super.init(type: .battery)
        setIcons(charging: false)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateInfo() -> Bool {
        let time = Date().timeIntervalSince1970
        if isUpdateNeeded() || time - cachedLeftTime > 1 {
            cachedLeftTime = time

            let level = UIDevice.current.batteryLevel
            let status = UIDevice.current.batteryState
            var charging = false
            if level == -1 || status == .unknown {
                setText("?", subtext: nil)
            } else {
                charging = (status == .charging || status == .full)
                setText("\(Int(level * 100))%", subtext: nil)
            }
            setIcons(charging: charging)
        }
        return false
    }
    
    private func setIcons(charging: Bool) {
        if charging {
            setIcons("widget_battery_charging_day", widgetNightIcon: "widget_battery_charging_night")
        } else {
            setIcons(.battery)
        }
    }
    
}
