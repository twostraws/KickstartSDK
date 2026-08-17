//
// ExchangeAdButtonStyle.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import SwiftUI

/// Applies the lightweight pressed-state treatment used by advertisement controls.
struct ExchangeAdButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension ButtonStyle where Self == ExchangeAdButtonStyle {
    static var exchangeAd: ExchangeAdButtonStyle {
        ExchangeAdButtonStyle()
    }
}
