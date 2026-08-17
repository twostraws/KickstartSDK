//
// ExchangeSessionRejection.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

/// Carries the server's reason when session creation is rejected.
struct ExchangeSessionRejection: Error, Sendable {
    let reason: String?
}
