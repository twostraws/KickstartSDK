//
// ExchangeServeRequest.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

/// Encodes storefront context for an advertisement request.
struct ExchangeServeRequest: Encodable, Sendable {
    let storefront: String?
}
