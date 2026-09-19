//
// PinnedBannerExample.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import KickstartExchange
import SwiftUI

/// Pins an advertisement below the content, which is the placement most apps
/// reach for when asking people to pay to remove ads.
struct PinnedBannerExample: View {
    var body: some View {
        List(1...50, id: \.self) { row in
            Text("Row \(row)")
        }
        .safeAreaInset(edge: .bottom) {
            ExchangeBannerAdView(apiKey: "preview")
                .padding()
        }
        .navigationTitle("Pinned")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PinnedBannerExample()
    }
}
