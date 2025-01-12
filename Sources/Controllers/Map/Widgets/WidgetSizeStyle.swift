//
//  WidgetSizeStyle.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 10.01.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAWidgetSizeStyleObjWrapper)
@objcMembers
final class WidgetSizeStyleObjWrapper: NSObject {

    static func getLabelFontSizeFor(type: EOAWidgetSizeStyle) -> CGFloat {
        switch type {
        case .small, .medium, .large: 11
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }

    static func getValueFontSizeFor(type: EOAWidgetSizeStyle) -> CGFloat {
        switch type {
        case .small: 22
        case .medium: 33
        case .large: 50
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }

    static func getUnitsFontSizeFor(type: EOAWidgetSizeStyle) -> CGFloat {
        switch type {
        case .small, .medium, .large: 11
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }

    static func getTopBottomPadding(type: EOAWidgetSizeStyle) -> CGFloat {
        switch type {
        case .small: 7
        case .medium: 10
        case .large: 12
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }

    static func getPaddingBetweenIconAdndValue(type: EOAWidgetSizeStyle) -> CGFloat {
        switch type {
        case .small: 6
        case .medium, .large: 12
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
}
