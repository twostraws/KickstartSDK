//
// ExchangeAdvertisementInfoView.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import SwiftUI

//
// Note to reader: tvOS makes this whole flow terrible without
// some platform workarounds. Specifically, we need to make
// each piece of text focusable so it can be scrolled through,
// remove navigation titles because they look horrific out of
// the box, and also force a primary foreground style otherwise
// we get matching foreground/background style.
//

/// Explains an advertisement and provides navigation for reporting it.
@available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
struct ExchangeAdvertisementInfoView: View {
    let presentation: ExchangeAdPresentation
    let isPreview: Bool
    let submitReport: @MainActor @Sendable (ExchangeReportReason) async -> Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                if ExchangeEnvironment.isDevelopment {
                    Section {
                        Text(
                            """
                            This is a test advert, shown because the app is running from Xcode or the Simulator. \
                            It proves the Kickstart Exchange integration works, and no advertiser is charged for it. \
                            Real adverts appear once the app ships from the App Store.
                            """,
                            bundle: .module
                        )
                        #if os(tvOS)
                        .focusable(true)
                        #endif
                    } header: {
                        Text("Test advert", bundle: .module)
                    }
                }

                Section {
                    Text(verbatim: presentation.ad.developerName)
                        #if os(tvOS)
                        .focusable(true)
                        #endif
                } header: {
                    Text("Advertiser", bundle: .module)
                }

                Section {
                    Text("The app you’re using", bundle: .module)
                    Text("Your device platform", bundle: .module)
                    Text("App Store availability", bundle: .module)
                        #if os(tvOS)
                        .focusable(true)
                        #endif
                } header: {
                    Text("This ad is based on", bundle: .module)
                }

                Section {
                    Text(
                        "Kickstart Exchange does not track you or your device.",
                        bundle: .module
                    )
                    #if os(tvOS)
                    .focusable(true)
                    #endif
                } header: {
                    Text("Privacy", bundle: .module)
                }

                if isPreview || ExchangeEnvironment.isDevelopment == false {
                    Section {
                        NavigationLink(value: ExchangeNavigationDestination.report) {
                            Label {
                                Text("Report this advertisement", bundle: .module)
                            } icon: {
                                Image(systemName: "exclamationmark.bubble")
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationDestination(for: ExchangeNavigationDestination.self) { destination in
                switch destination {
                case .report:
                    ExchangeReportView(close: { dismiss() })
                case .reportSubmission(let reason):
                    ExchangeReportSubmissionView(
                        reason: reason,
                        isPreview: isPreview,
                        submit: submitReport,
                        close: { dismiss() }
                    )
                }
            }
            #if os(tvOS)
            .padding(.horizontal, 20)
            .scrollClipDisabled()
            #else
            .navigationTitle(Text("About this ad", bundle: .module))
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done", bundle: .module)
                    }
                }
            }
        }
    }
}
