//
// InlineAdsExample.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import KickstartExchange
import SwiftUI

//
// Note to reader: scroll the adverts off screen and back on again.
// The SDK only records an impression once a card has been at least
// half visible for a full second, and only once per app run - so
// scrolling past them repeatedly does not inflate anything.
//
// Both cards show the same advertised app on purpose. One advert is
// fetched per app process run and shared by every placement, so this
// screen is showing you one advert twice, not two adverts.
//

/// Places both advertisement layouts between rows of scrolling content, where
/// the SDK's viewability tracking decides when a card has genuinely been seen.
struct InlineAdsExample: View {
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
            } header: {
                Text("Banner")
            }

            Section {
                ForEach(6...12, id: \.self) { row in
                    Text("Row \(row)")
                }
            }

            Section {
                ExchangeLargeAdView(apiKey: "preview")
                    .listRowInsets(.init(top: 2, leading: 2, bottom: 2, trailing: 2))
                    .listRowBackground(Color.clear)
            } header: {
                Text("Large")
            }

            Section {
                ForEach(13...25, id: \.self) { row in
                    Text("Row \(row)")
                }
            }
        }
        .navigationTitle("Inline")
        .navigationBarTitleDisplayMode(.inline)
        .listSectionSpacing(8)
    }
}

#Preview {
    NavigationStack {
        InlineAdsExample()
    }
}
