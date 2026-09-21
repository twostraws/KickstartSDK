//
// FullScreenCoverAdExample.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import KickstartExchange
import SwiftUI

/// Presents a large advertisement in a full screen cover once someone has
/// finished a handful of actions, the way a game might run an advert between
/// levels.
struct FullScreenCoverAdExample: View {
    /// How many actions are needed before the advertisement appears.
    private static let threshold = 5

    @State private var completedActions = 0
    @State private var isShowingAd = false

    var body: some View {
        List {
            Section {
                LabeledContent("Levels completed") {
                    Text("\(completedActions) of \(Self.threshold)")
                        .monospacedDigit()
                }

                ProgressView(
                    value: Double(completedActions),
                    total: Double(Self.threshold)
                )

                Button("Complete a level") {
                    completedActions += 1

                    if completedActions >= Self.threshold {
                        completedActions = 0
                        isShowingAd = true
                    }
                }
            } footer: {
                Text(
                    """
                    On macOS this falls back to a sheet, because macOS has no \
                    full screen cover of its own.
                    """
                )
            }
        }
        .navigationTitle("Full screen")
        .navigationBarTitleDisplayMode(.inline)
        .exchangeAdFullScreenCover(isPresented: $isShowingAd, apiKey: "preview")
    }
}

#Preview {
    NavigationStack {
        FullScreenCoverAdExample()
    }
}
