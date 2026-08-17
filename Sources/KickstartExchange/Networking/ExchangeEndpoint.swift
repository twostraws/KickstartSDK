//
// ExchangeEndpoint.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import Foundation

/// Defines the Exchange API endpoints used by the SDK.
enum ExchangeEndpoint {
    static let preview = URL(string: "https://api.kickstart.tools/exchange/v1/preview")!
    static let sessions = URL(string: "https://api.kickstart.tools/exchange/v1/sessions")!
    static let serve = URL(string: "https://api.kickstart.tools/exchange/v1/serve")!
    static let impressions = URL(string: "https://api.kickstart.tools/exchange/v1/impressions")!
    static let reports = URL(string: "https://api.kickstart.tools/exchange/v1/reports")!
}
