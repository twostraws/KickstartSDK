//
// StyledBannerExample.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import KickstartExchange
import SwiftUI

/// Applies each Kickstart Exchange styling modifier so you can see how far the
/// card bends to match an app's design without hiding the advert disclosure.
struct StyledBannerExample: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                ExchangeBannerAdView(apiKey: "preview")
                    .exchangeAdCornerStyle(.square)

                ExchangeBannerAdView(apiKey: "preview")
                    .exchangeAdCornerStyle(.rounded)
                    .exchangeAdStroke(.orange)
                    .exchangeAdActionTextColor(.orange)
                    .exchangeAdDisclosureBackgroundColor(.purple)

                ExchangeBannerAdView.preview(
                    appName: "Example App",
                    subtitle: "A deterministic preview card",
                    icon: Image(systemName: "app.fill")
                )
                .exchangeAdActionTextColor(.green)
                .exchangeAdDisclosureBackgroundColor(.indigo)
            }
            .padding()
        }
        .navigationTitle("Styling")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        StyledBannerExample()
    }
}
