//
// ExchangeAdPlacement.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import SwiftUI

/// How a large advertisement is being shown.
///
/// The placement decides two things the advert cannot work out for itself:
/// whether it should offer a close action, and where its visibility signal
/// comes from. Scrolling placements sit inside a scroll view and can use its
/// visibility tracking; presented placements have no scroll view above them,
/// so they report visibility as the presentation appears and disappears.
enum ExchangeAdPlacement: Equatable, Sendable {
    /// The advert is laid out as part of the surrounding content.
    case inline

    /// The advert is shown in a sheet or a full screen cover.
    case presented
}

extension EnvironmentValues {
    @Entry var exchangeAdPlacement = ExchangeAdPlacement.inline
}
