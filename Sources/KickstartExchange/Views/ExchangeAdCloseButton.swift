//
// ExchangeAdCloseButton.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import SwiftUI

/// Dismisses a presented advertisement.
struct ExchangeAdCloseButton: View {
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(
                    isFocused
                        ? focusedForegroundColor
                        : .primary
                )
                .padding(8)
                .background(
                    isFocused
                        ? AnyShapeStyle(focusedBackgroundColor)
                        : AnyShapeStyle(.thinMaterial),
                    in: .circle
                )
        }
        .buttonBorderShape(.circle)
        #if !os(macOS) && !targetEnvironment(macCatalyst)
        // Keep the close target comfortably tappable on touch platforms.
        .contentShape(.rect.inset(by: -12))
        #endif
        #if os(tvOS)
        .buttonStyle(.exchangeAd)
        .focused($isFocused)
        .focusEffectDisabled()
        #endif
        .accessibilityLabel(Text("Close", bundle: .module))
        .accessibilityHint(
            Text("Dismisses this advertisement", bundle: .module)
        )
    }

    private var focusedBackgroundColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var focusedForegroundColor: Color {
        colorScheme == .dark ? .black : .white
    }
}
