//
// ContentView.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import SwiftUI

/// Presents each advertisement placement the SDK supports.
struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Inline", systemImage: "list.bullet") {
                NavigationStack {
                    InlineAdsExample()
                }
            }

            Tab("Pinned", systemImage: "rectangle.bottomthird.inset.filled") {
                NavigationStack {
                    PinnedBannerExample()
                }
            }

            Tab("Sheet", systemImage: "rectangle.portrait.bottomhalf.filled") {
                NavigationStack {
                    SheetAdExample()
                }
            }

            Tab("Full screen", systemImage: "rectangle.portrait.fill") {
                NavigationStack {
                    FullScreenCoverAdExample()
                }
            }

            Tab("Styling", systemImage: "paintbrush") {
                NavigationStack {
                    StyledBannerExample()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
