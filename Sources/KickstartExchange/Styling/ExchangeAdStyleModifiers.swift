//
// ExchangeAdStyleModifiers.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import SwiftUI

@available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
extension EnvironmentValues {
    @Entry var exchangeAdCornerStyle = ExchangeAdCornerStyle.rounded
    @Entry var exchangeAdStrokeColor: Color?
    @Entry var exchangeAdDisclosureBackgroundColor = Color.blue

    // Blue is a safe default text color everywhere except visionOS.
    #if os(visionOS)
    @Entry var exchangeAdActionTextColor = Color.primary
    #else
    @Entry var exchangeAdActionTextColor = Color.blue
    #endif
}

@available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
public extension View {
    /// Sets the corner treatment for Kickstart Exchange advertisement cards
    /// within this view.
    func exchangeAdCornerStyle(_ style: ExchangeAdCornerStyle) -> some View {
        environment(\.exchangeAdCornerStyle, style)
    }

    /// Sets the stroke color for Kickstart Exchange advertisement cards
    /// within this view.
    func exchangeAdStroke(_ color: Color) -> some View {
        environment(\.exchangeAdStrokeColor, color)
    }

    /// Sets the text color of the App Store action button for Kickstart
    /// Exchange advertisements within this view.
    func exchangeAdActionTextColor(_ color: Color) -> some View {
        environment(\.exchangeAdActionTextColor, color)
    }

    /// Sets the background color of the ad disclosure button for Kickstart
    /// Exchange advertisements within this view.
    func exchangeAdDisclosureBackgroundColor(_ color: Color) -> some View {
        environment(\.exchangeAdDisclosureBackgroundColor, color)
    }
}
