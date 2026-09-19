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

    /// The icon's colors, sampled once so every placement shares the work.
    let palette: ExchangeAdArtworkPalette?

    init(
        serveID: String?,
        impressionToken: String?,
        ad: ExchangeServedAdResponse,
        icon: CGImage
    ) {
        self.serveID = serveID
        self.impressionToken = impressionToken
        self.ad = ad
        self.icon = icon
        palette = ExchangeAdArtworkPalette(icon: icon)
    }
}
