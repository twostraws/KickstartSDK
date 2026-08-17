//
// PublicAPIFixture.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import KickstartExchange
import SwiftUI

/// Compiles representative uses of the SDK's public SwiftUI API.
@MainActor
private struct PublicAPIFixture: View {
    var body: some View {
        ExchangeBannerAdView(apiKey: "example-api-key")

        ExchangeBannerAdView(apiKey: "example-api-key")
            .exchangeAdCornerStyle(.rounded)
            .exchangeAdStroke(.orange)
            .exchangeAdActionTextColor(.orange)
            .exchangeAdDisclosureBackgroundColor(.purple)

        ExchangeBannerAdView(apiKey: "example-api-key")
            .exchangeAdCornerStyle(.square)

        ExchangeBannerAdView.preview(
            appName: "Example App",
            subtitle: "Example subtitle",
            icon: Image(systemName: "app.fill")
        )
        .exchangeAdCornerStyle(.rounded)
        .exchangeAdStroke(.clear)
        .exchangeAdActionTextColor(.green)
        .exchangeAdDisclosureBackgroundColor(.indigo)

        ExchangeBannerAdView.preview(
            appName: "Example App",
            subtitle: nil,
            icon: Image(systemName: "app.fill")
        )
    }
}
