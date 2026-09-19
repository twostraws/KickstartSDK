//
// ExchangeAdPresentationModifiers.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import SwiftUI

/// Wraps a large advertisement for presentation, marking its placement so the
/// card offers a close action.
@available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
struct ExchangeLargeAdPresentation: View {
    let apiKey: String

    var body: some View {
        ExchangeLargeAdView(apiKey: apiKey)
            .environment(\.exchangeAdPlacement, .presented)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Presents a large advertisement in a sheet or a full screen cover.
@available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
private struct ExchangeAdPresentationModifier: ViewModifier {
    @Binding var isPresented: Bool
    let apiKey: String
    let usesFullScreenCover: Bool

    func body(content: Content) -> some View {
        #if os(macOS)
        // macOS has no full screen cover, so both modifiers use a sheet.
        content.sheet(isPresented: $isPresented) {
            advertisement
        }
        #else
        if usesFullScreenCover {
            content.fullScreenCover(isPresented: $isPresented) {
                advertisement
            }
        } else {
            content.sheet(isPresented: $isPresented) {
                advertisement
            }
        }
        #endif
    }

    private var advertisement: some View {
        ExchangeLargeAdPresentation(apiKey: apiKey)
    }
}

@available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
public extension View {
    /// Presents a large Kickstart Exchange advertisement in a sheet.
    ///
    /// The advert carries its own close action, so people can always leave.
    ///
    /// - Parameters:
    ///   - isPresented: Whether the advertisement is currently shown.
    ///   - apiKey: Your Exchange API key, or `"preview"` in a Debug build or
    ///     the Simulator to show the server-provided sample advert.
    func exchangeAdSheet(
        isPresented: Binding<Bool>,
        apiKey: String
    ) -> some View {
        modifier(
            ExchangeAdPresentationModifier(
                isPresented: isPresented,
                apiKey: apiKey,
                usesFullScreenCover: false
            )
        )
    }

    /// Presents a large Kickstart Exchange advertisement in a full screen
    /// cover, falling back to a sheet on macOS, which has no full screen
    /// cover of its own.
    ///
    /// The advert carries its own close action, so people can always leave.
    ///
    /// - Parameters:
    ///   - isPresented: Whether the advertisement is currently shown.
    ///   - apiKey: Your Exchange API key, or `"preview"` in a Debug build or
    ///     the Simulator to show the server-provided sample advert.
    func exchangeAdFullScreenCover(
        isPresented: Binding<Bool>,
        apiKey: String
    ) -> some View {
        modifier(
            ExchangeAdPresentationModifier(
                isPresented: isPresented,
                apiKey: apiKey,
                usesFullScreenCover: true
            )
        )
    }
}
