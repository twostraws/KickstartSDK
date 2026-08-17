//
// ExchangeServedAdResponse.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import Foundation

/// Decodes the advertised app details returned by the Exchange API.
struct ExchangeServedAdResponse: Decodable, Sendable {
    let name: String
    let subtitle: String?
    let developerName: String
    let iconURL: URL
    let clickURL: URL
    let storeURL: URL?

    /// Maps the response properties to their Exchange API wire keys.
    enum CodingKeys: String, CodingKey {
        case name
        case subtitle
        case developerName = "developer_name"
        case iconURL = "icon_url"
        case clickURL = "click_url"
        case storeURL = "store_url"
    }
}
