//
// ExchangeReportReason.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

/// Identifies why a user is reporting an advertisement.
enum ExchangeReportReason: String, CaseIterable, Encodable, Hashable, Sendable {
    case inappropriate
    case misleading
    case brokenLink = "broken_link"
    case other
}
