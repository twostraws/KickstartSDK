//
// ExchangeAdLayoutMetrics.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import SwiftUI

/// Provides platform-specific sizing and spacing for advertisement layouts.
enum ExchangeAdLayoutMetrics {
    static let maximumDecorationScale = 1.25
    static let cardCornerRadius = 20.0

    #if os(watchOS)
    static let minimumHorizontalTextWidth = 0.0
    static let verticalContentAlignment = VerticalAlignment.top
    #else
    static let minimumHorizontalTextWidth = 140.0
    static let verticalContentAlignment = VerticalAlignment.center
    #endif

    #if os(tvOS)
    static let maximumCardWidth = 760.0
    static let horizontalContentSpacing: CGFloat? = 24
    static let cardPadding = 20.0
    #else
    static let maximumCardWidth = 450.0
    static let horizontalContentSpacing: CGFloat? = nil
    static let cardPadding = 10.0
    #endif

    #if os(tvOS)
    static let appIconLength = 96.0
    #elseif os(watchOS)
    static let appIconLength = 48.0
    #else
    static let appIconLength = 64.0
    #endif

    #if os(tvOS)
    static let minimumDisclosureWidth = 66.0
    #elseif os(visionOS)
    static let minimumDisclosureWidth = 60.0
    #elseif os(macOS)
    static let minimumDisclosureWidth = 28.0
    #else
    static let minimumDisclosureWidth = 44.0
    #endif

    static func decorationScale(for scaledMetric: Double) -> Double {
        min(scaledMetric, maximumDecorationScale)
    }
}
