//
// ExchangeReportRequest.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

/// Encodes the serve identifier and reason for an advertisement report.
struct ExchangeReportRequest: Encodable, Sendable {
    let serveID: String
    let reason: ExchangeReportReason

    /// Maps the request properties to their Exchange API wire keys.
    enum CodingKeys: String, CodingKey {
        case serveID = "serve_id"
        case reason
    }
}
