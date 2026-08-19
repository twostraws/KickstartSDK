//
// SheetAdExample.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import KickstartExchange
import SwiftUI

//
// Note to reader: the countdown lives in a task attached to this
// screen rather than to the tab bar, so it starts when you arrive
// and is cancelled when you leave. Starting timers at app launch
// for screens nobody has visited yet is a good way to show adverts
// to people who are not looking at them.
//

/// Presents a large advertisement in a sheet once a short delay elapses, the
/// way an app might run an advert after someone finishes a task.
struct SheetAdExample: View {
    /// How long the screen waits before presenting the advertisement.
    private static let delay = 5

    @State private var isShowingAd = false
    @State private var secondsRemaining = SheetAdExample.delay

    var body: some View {
        List {
            Section {
                if secondsRemaining > 0 {
                    LabeledContent("Presenting in") {
                        Text("\(secondsRemaining)s")
                            .monospacedDigit()
                    }
                } else {
                    Text("Presented")
                        .foregroundStyle(.secondary)
                }

                Button("Show it now") {
                    secondsRemaining = 0
                    isShowingAd = true
                }
            } footer: {
                Text(
                    """
                    The advert arrives in a sheet with its own close button, so \
                    there is always a way out.
                    """
                )
            }

            Section {
                Button("Start the countdown again") {
                    secondsRemaining = Self.delay
                }
            }
        }
        .navigationTitle("Sheet")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: secondsRemaining) {
            guard secondsRemaining > 0 else {
                return
            }

            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                return
            }

            secondsRemaining -= 1

            if secondsRemaining == 0 {
                isShowingAd = true
            }
        }
        .exchangeAdSheet(isPresented: $isShowingAd, apiKey: "preview")
    }
}

#Preview {
    NavigationStack {
        SheetAdExample()
    }
}
