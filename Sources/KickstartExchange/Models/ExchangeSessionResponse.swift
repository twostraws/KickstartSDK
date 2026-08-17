//
// ExchangeSessionResponse.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

/// Contains the token and accounting status granted for an Exchange session.
struct ExchangeSessionResponse: Sendable {
    let sessionToken: String
    let countsEnabled: Bool
    let countingReason: String?
}
