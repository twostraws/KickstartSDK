//
// ExchangeNavigationDestination.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

/// Defines destinations available from the advertisement information flow.
enum ExchangeNavigationDestination: Hashable {
    case report
    case reportSubmission(ExchangeReportReason)
}
