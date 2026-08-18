//
// ExchangeAdRunState.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import Observation

/// Tracks whether advertising has been suppressed for the current app run.
@available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
@MainActor
@Observable
final class ExchangeAdRunState {
    private(set) var isSuppressed = false

    func suppress() {
        isSuppressed = true
    }
}
