//
// ExchangeAdPlacement.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import SwiftUI

/// How a large advertisement is being shown.
///
/// A presented advert covers the host app's content, so it offers a close
/// action; an inline advert sits among that content and doesn't need one.
enum ExchangeAdPlacement: Equatable, Sendable {
    /// The advert is laid out as part of the surrounding content.
    case inline

    /// The advert is shown in a sheet or a full screen cover.
    case presented
}

extension EnvironmentValues {
    @Entry var exchangeAdPlacement = ExchangeAdPlacement.inline
}
