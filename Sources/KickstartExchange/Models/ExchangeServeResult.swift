//
// ExchangeServeResult.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

/// Represents either a received advertisement or the server's rejection reason.
enum ExchangeServeResult: Sendable {
    case advertisement(ExchangeServeResponse)
    case rejected(reason: String?)
}
