//
// ExchangeImpressionRequest.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

/// Encodes the token used to record a viewed advertisement impression.
struct ExchangeImpressionRequest: Encodable, Sendable {
    let impressionToken: String

    /// Maps the request properties to their Exchange API wire keys.
    enum CodingKeys: String, CodingKey {
        case impressionToken = "impression_token"
    }
}
