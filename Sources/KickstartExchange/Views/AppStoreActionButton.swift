//
// AppStoreActionButton.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import SwiftUI

/// Displays the action that opens an advertised app in the App Store.
@available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
struct AppStoreActionButton: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.exchangeAdActionTextColor) private var textColor
    @FocusState private var isFocused: Bool

    let appName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Get", bundle: .module)
                .font(.body)
                .fontWeight(.bold)
                .padding(.vertical, 8)
                .padding(.horizontal, 24)
                .background(
                    isFocused
                        ? AnyShapeStyle(focusedBackgroundColor)
                        : AnyShapeStyle(.background.secondary)
                )
                .clipShape(.capsule)
                .foregroundStyle(
                    isFocused
                        ? focusedForegroundColor
                        : textColor
                )
        }
        #if os(tvOS)
        .buttonStyle(.exchangeAd)
        .focused($isFocused)
        .focusEffectDisabled()
        #endif
        .accessibilityLabel(Text("Get \(appName)", bundle: .module))
        .accessibilityHint(Text("Opens the App Store", bundle: .module))
    }

    private var focusedBackgroundColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var focusedForegroundColor: Color {
        colorScheme == .dark ? .black : .white
    }
}
