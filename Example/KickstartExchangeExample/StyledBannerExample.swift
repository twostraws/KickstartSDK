//
// StyledBannerExample.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import KickstartExchange
import SwiftUI

//
// Note to reader: the styling modifiers flow down through the
// environment, so they reach both advertisement layouts. What they
// deliberately cannot do is hide the ad disclosure or the advertised
// app's own name, icon, and subtitle.
//

/// Applies each Kickstart Exchange styling modifier to both advertisement
/// layouts, so you can see how far they bend to match an app's design.
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

                ExchangeLargeAdView(apiKey: "preview")
                    .exchangeAdStroke(.orange)
                    .exchangeAdActionTextColor(.orange)
                    .exchangeAdDisclosureBackgroundColor(.purple)

                ExchangeLargeAdView.preview(
                    appName: "Example App",
                    subtitle: "A deterministic preview card",
                    icon: Image(systemName: "app.fill")
                )
                .exchangeAdCornerStyle(.square)
                .exchangeAdDisclosureBackgroundColor(.indigo)

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
