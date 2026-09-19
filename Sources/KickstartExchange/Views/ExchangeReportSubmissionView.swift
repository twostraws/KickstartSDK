//
// ExchangeReportSubmissionView.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import SwiftUI

/// Submits a selected report reason and displays the submission result.
@available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
struct ExchangeReportSubmissionView: View {
    let reason: ExchangeReportReason
    let isPreview: Bool
    let submit: @MainActor @Sendable (ExchangeReportReason) async -> Bool
    let close: @MainActor @Sendable () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var state = SubmissionState.submitting

    var body: some View {
        Group {
            switch state {
            case .submitting:
                Form {
                    Section {
                        ProgressView()
                        Text("Sending report…", bundle: .module)
                    }
                }
                .formStyle(.grouped)

            case .failed:
                Form {
                    Section {
                        Text("Report not sent", bundle: .module)
                            .bold()
                            .accessibilityAddTraits(.isHeader)
                        Text(
                            "Check your connection and try again.",
                            bundle: .module
                        )
                    }

                    Section {
                        Button {
                            state = .submitting
                        } label: {
                            Label {
                                Text("Try Again", bundle: .module)
                            } icon: {
                                Image(systemName: "arrow.clockwise")
                            }
                        }

                        Button {
                            dismiss()
                        } label: {
                            Text("Choose Another Reason", bundle: .module)
                        }
                    }
                }
                .formStyle(.grouped)

            case .sent:
                Form {
                    Section {
                        Label {
                            if isPreview {
                                Text("Test report complete", bundle: .module)
                                    .bold()
                            } else {
                                Text("Report sent", bundle: .module)
                                    .bold()
                            }
                        } icon: {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        .accessibilityAddTraits(.isHeader)

                        if isPreview {
                            Text("No report was stored.", bundle: .module)
                        } else {
                            Text("Thank you. We'll review it.", bundle: .module)
                        }
                    }
                }
                .formStyle(.grouped)
            }
        }
        .navigationBarBackButtonHidden(state == .sent)
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
                .disabled(isSubmitting)
            }
        }
        .interactiveDismissDisabled(isSubmitting)
        .task(id: state) {
            guard state == .submitting else {
                return
            }

            let wasSent = await submit(reason)
            guard Task.isCancelled == false else {
                return
            }
            state = wasSent ? .sent : .failed
        }
    }

    private var isSubmitting: Bool {
        state == .submitting
    }

    /// Tracks the report submission screen's current outcome.
    private enum SubmissionState: Equatable {
        case submitting
        case failed
        case sent
    }
}
