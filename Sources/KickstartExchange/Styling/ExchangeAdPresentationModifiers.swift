//
// ExchangeAdPresentationModifiers.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import SwiftUI

//
// Note to reader: a Dynamic Type size the host app injects with
// dynamicTypeSize() doesn't reach content shown in a sheet or a full
// screen cover – that content gets the system setting instead. An
// inline advert inherits the injected size and a presented one would
// not, which is a strange way for the same advert to behave. So we read
// the size on the presenting side and hand it across ourselves.
//

/// Wraps a large advertisement for presentation, marking its placement so the
/// card offers a close action.
@available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
struct ExchangeLargeAdPresentation: View {
    let apiKey: String

    /// The Dynamic Type size to carry across the presentation boundary, or
    /// `nil` to inherit whatever the surrounding context already provides.
    ///
    /// Forcing a size unconditionally would pin the advert wherever nothing
    /// needs carrying — an Xcode preview's Dynamic Type variants, most
    /// obviously — so the size is only applied when there is one to apply.
    var dynamicTypeSize: DynamicTypeSize?

    var body: some View {
        advertisement
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var advertisement: some View {
        let advert = ExchangeLargeAdView(apiKey: apiKey)
            .environment(\.exchangeAdPlacement, .presented)

        if let dynamicTypeSize {
            advert.dynamicTypeSize(dynamicTypeSize)
        } else {
            advert
        }
    }
}

/// Presents a large advertisement, carrying the presenting view's Dynamic Type
/// size across the presentation boundary.
@available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
private struct ExchangeAdPresentationModifier: ViewModifier {
    @Binding var isPresented: Bool
    let apiKey: String
    let usesFullScreenCover: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
        ExchangeLargeAdPresentation(
            apiKey: apiKey,
            dynamicTypeSize: dynamicTypeSize
        )
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
