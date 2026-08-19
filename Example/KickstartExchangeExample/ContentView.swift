//
// ContentView.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import SwiftUI

/// Lists the advertisement placements this example demonstrates.
struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink("Pinned to the bottom") {
                        PinnedBannerExample()
                    }

                    NavigationLink("Inside a scrolling list") {
                        ScrollingBannerExample()
                    }

                    NavigationLink("With custom styling") {
                        StyledBannerExample()
                    }
                } header: {
                    Text("Placements")
                } footer: {
                    Text(
                        """
                        Every screen uses the "preview" API key, so Debug builds \
                        and the Simulator show a sample advert that charges nobody.
                        """
                    )
                }
            }
            .navigationTitle("Kickstart Exchange")
        }
    }
}

#Preview {
    ContentView()
}
