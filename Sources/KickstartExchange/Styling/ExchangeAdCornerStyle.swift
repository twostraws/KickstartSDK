//
// ExchangeAdCornerStyle.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

/// A corner treatment for Kickstart Exchange advertisement cards.
public enum ExchangeAdCornerStyle: Equatable, Sendable {
    /// A card with square corners.
    case square

    /// A card using the SDK's standard corner radius.
    case rounded

    var cornerRadius: Double {
        switch self {
        case .square:
            0
        case .rounded:
            ExchangeAdLayoutMetrics.cardCornerRadius
        }
    }
}
