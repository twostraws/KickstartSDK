//
// ExchangeAdDisclosureButton.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import SwiftUI

/// Displays the "Ad" disclosure that opens an advertisement's information
/// screen, shared by every advertisement layout so the disclosure looks and
/// behaves identically wherever an advert appears.
struct ExchangeAdDisclosureButton: View {
    let action: () -> Void

    @Environment(\.exchangeAdDisclosureBackgroundColor) private var disclosureBackgroundColor
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: action) {
            Text("Ad", bundle: .module)
                .bold()
                .foregroundStyle(
                    isFocused
                        ? focusedForegroundColor
                        : .white
                )
                .font(.caption2)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    isFocused
                        ? AnyShapeStyle(focusedBackgroundColor)
                        : AnyShapeStyle(disclosureBackgroundColor.gradient),
                    in: .rect(cornerRadius: 5)
                )
        }
        .buttonBorderShape(.roundedRectangle(radius: 5))
        .frame(
            minWidth: ExchangeAdLayoutMetrics.minimumDisclosureWidth,
            alignment: .topLeading
        )
        #if !os(macOS) && !targetEnvironment(macCatalyst)
        // On platforms without a mouse pointer we make the Ad
        // button easier to tap.
        .contentShape(.rect.inset(by: -20))
        #endif
        #if os(tvOS)
        .buttonStyle(.exchangeAd)
        .focused($isFocused)
        .focusEffectDisabled()
        #endif
        .accessibilityInputLabels([
            Text("Ad", bundle: .module),
            Text("About this ad", bundle: .module),
        ])
        .accessibilityLabel(Text("About this ad", bundle: .module))
        .accessibilityHint(
            Text(
                "Shows information about this advertisement",
                bundle: .module
            )
        )
    }

    private var focusedBackgroundColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var focusedForegroundColor: Color {
        colorScheme == .dark ? .black : .white
    }
}
