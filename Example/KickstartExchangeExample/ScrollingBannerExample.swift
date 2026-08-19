//
// ScrollingBannerExample.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import KickstartExchange
import SwiftUI

//
// Note to reader: scroll the advertisement off screen and back on
// again. The SDK only records an impression once the card has been
// at least half visible for a full second, and only once per app
// run - so scrolling past it repeatedly does not inflate anything.
//

/// Places an advertisement between rows of scrolling content, where the SDK's
/// viewability tracking decides when the card has genuinely been seen.
struct ScrollingBannerExample: View {
    var body: some View {
        List {
            Section {
                ForEach(1...5, id: \.self) { row in
                    Text("Row \(row)")
                }
            }

            Section {
                ExchangeBannerAdView(apiKey: "preview")
                    .listRowInsets(.init(top: 2, leading: 2, bottom: 2, trailing: 2))
                    .listRowBackground(Color.clear)
            }

            Section {
                ForEach(6...20, id: \.self) { row in
                    Text("Row \(row)")
                }
            }
        }
        .navigationTitle("In a list")
        .navigationBarTitleDisplayMode(.inline)
        .listSectionSpacing(8)
    }
}

#Preview {
    NavigationStack {
        ScrollingBannerExample()
    }
}
