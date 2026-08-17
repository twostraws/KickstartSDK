//
// ExchangeSessionRequest.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

/// Encodes the application and environment details used to start a session.
struct ExchangeSessionRequest: Encodable, Sendable {
    let apiKey: String
    let bundleIdentifier: String
    let platform: String
    let appVersion: String
    let buildVersion: String
    let sdkVersion: String
    let development: Bool?
    let appTransaction: String?

    /// Maps the request properties to their Exchange API wire keys.
    enum CodingKeys: String, CodingKey {
        case apiKey = "api_key"
        case bundleIdentifier = "bundle_id"
        case platform
        case appVersion = "app_version"
        case buildVersion = "build_version"
        case sdkVersion = "sdk_version"
        case development
        case appTransaction = "app_transaction"
    }
}
