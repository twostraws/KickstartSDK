//
// ExchangeAdRunKey.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

/// Identifies shared advertisement work for one app, platform, key, and environment.
struct ExchangeAdRunKey: Hashable, Sendable {
    let apiKey: String
    let bundleIdentifier: String
    let platform: ExchangePlatform
    let development: Bool
}
