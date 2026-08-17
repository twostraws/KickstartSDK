//
// ExchangeAdPresentation.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import CoreGraphics
import Foundation

/// Contains the display-ready content and URLs for an advertisement.
struct ExchangeAdPresentation: Sendable {
    let serveID: String?
    let impressionToken: String?
    let ad: ExchangeServedAdResponse
    let icon: CGImage
}
