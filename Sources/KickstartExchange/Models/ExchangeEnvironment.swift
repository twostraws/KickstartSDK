//
// ExchangeEnvironment.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import Foundation

/// Whether this build is a development build rather than a shipping one.
///
/// Development builds request a test advert, which proves the integration works
/// without charging any developer for an impression nobody saw. The simulator is
/// included because profiling tools build in release mode.
enum ExchangeEnvironment {
    static let diagnosticPrefix = "Kickstart Exchange:"

    static var isDevelopment: Bool {
        #if DEBUG
        true
        #elseif targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }

    static func formattedDiagnostic(_ message: String) -> String {
        "\(diagnosticPrefix) \(message)"
    }
}
