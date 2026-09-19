//
// ExchangeReportView.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import SwiftUI

/// Presents the available reasons for reporting an advertisement.
@available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
struct ExchangeReportView: View {
    let close: @MainActor @Sendable () -> Void

    var body: some View {
        Form {
            Section {
                Text(
                    "Choose the reason that best describes the problem.",
                    bundle: .module
                )
            }

            Section {
                NavigationLink(
                    value: ExchangeNavigationDestination.reportSubmission(.inappropriate)
                ) {
                    Text("It's inappropriate", bundle: .module)
                }

                NavigationLink(
                    value: ExchangeNavigationDestination.reportSubmission(.misleading)
                ) {
                    Text("It's misleading", bundle: .module)
                }

                NavigationLink(
                    value: ExchangeNavigationDestination.reportSubmission(.brokenLink)
                ) {
                    Text("Broken App Store link", bundle: .module)
                }

                NavigationLink(
                    value: ExchangeNavigationDestination.reportSubmission(.other)
                ) {
                    Text("Other", bundle: .module)
                }
            }
        }
        .formStyle(.grouped)
        .foregroundStyle(.primary)
        #if os(tvOS)
        .padding(.horizontal, 20)
        .scrollClipDisabled()
        #else
        .navigationTitle(Text("Report", bundle: .module))
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: close) {
                    Text("Done", bundle: .module)
                }
            }
        }
    }
}
