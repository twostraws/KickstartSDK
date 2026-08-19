//
// ExchangeLargeAdvertisementCard.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import SwiftUI

//
// Note to reader: unlike the banner, this layout deliberately does not
// make the whole card tappable. The banner can get away with it because
// nothing else on the card competes for the tap, but a large advert
// carries a close button, and a full-bleed tap target sitting behind a
// close button is how people end up in the App Store when they meant to
// leave. Here only the Get button opens the store.
//

/// Displays an advertised app across a large, self-contained card suitable for
/// a sheet, a full screen cover, or a slot in scrolling content.
struct ExchangeLargeAdvertisementCard: View {
    let appName: String
    let subtitle: String?
    let icon: Image
    let palette: ExchangeAdArtworkPalette?
    let isStoreEnabled: Bool
    let showsCloseAction: Bool
    let openStore: () -> Void
    let showInformation: () -> Void
    let close: () -> Void

    @Environment(\.exchangeAdCornerStyle) private var cornerStyle
    @Environment(\.exchangeAdStrokeColor) private var strokeColor
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.exchangeAdPlacement) private var placement

    // Decorations scale gently, but stop before they crowd out enlarged text.
    @ScaledMetric(relativeTo: .body) private var scale = 1.0

    var body: some View {
        shaped
            .frame(maxWidth: maximumWidth)
            .foregroundStyle(.primary)
            .labelStyle(.titleAndIcon)
            .textCase(nil)
            .lineLimit(nil)
            .buttonStyle(.plain)
            .minimumScaleFactor(1)
            .multilineTextAlignment(.center)
            .unredacted()
            .accessibilityElement(children: .contain)
    }

    /// A presented advert takes its shape from the presentation it fills, so
    /// it neither clips itself nor draws a border. Clipping it would also
    /// crop the artwork back inside the safe areas.
    @ViewBuilder
    private var shaped: some View {
        if isPresented {
            stack
        } else {
            stack
                .clipShape(.rect(cornerRadius: cornerStyle.cornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerStyle.cornerRadius)
                        .strokeBorder(borderStyle, lineWidth: 1)
                        .allowsHitTesting(false)
                }
        }
    }

    private var stack: some View {
        ZStack {
            // The artwork is a sibling of the content rather than its
            // background, because a background layer cannot grow past the
            // view it sits behind — which is what reaching the screen edges
            // of a cover requires.
            background
                .ignoresSafeArea(edges: isPresented ? .all : [])
                .allowsHitTesting(false)

            // The card fills whatever space it is given, but falls back to
            // scrolling once enlarged text needs more room than that.
            ViewThatFits(in: .vertical) {
                card

                ScrollView {
                    card
                        .fixedSize(horizontal: false, vertical: true)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
    }

    private var card: some View {
        VStack(spacing: 0) {
            header

            Spacer(minLength: 16)

            details

            Spacer(minLength: 16)

            #if !os(watchOS)
            // On watchOS we skip the Get button because there isn't space.
            AppStoreActionButton(appName: appName, action: openStore)
                .disabled(isStoreEnabled == false)
            #endif
        }
        .padding(decorationScale * ExchangeAdLayoutMetrics.largeCardPadding)
        .frame(
            maxWidth: .infinity,
            minHeight: ExchangeAdLayoutMetrics.largeMinimumHeight,
            maxHeight: .infinity
        )
    }

    private var header: some View {
        HStack(alignment: .top) {
            ExchangeAdDisclosureButton(action: showInformation)

            Spacer(minLength: 8)

            if showsCloseAction {
                ExchangeAdCloseButton(action: close)
            }
        }
    }

    private var details: some View {
        VStack(spacing: 8) {
            icon
                .resizable()
                .scaledToFit()
                .frame(width: iconLength, height: iconLength)
                #if os(visionOS) || os(watchOS)
                .clipShape(.circle)
                #else
                .clipShape(.rect(cornerRadius: iconLength * 0.2))
                #endif
                .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .padding(.bottom, 8)

            Text(verbatim: appName)
                .font(.title2)
                .fontWeight(.bold)
                .allowsHitTesting(false)

            if let subtitle {
                Text(verbatim: subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .allowsHitTesting(false)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            Text(
                "Advertisement: \(appName). \(subtitle ?? "")",
                bundle: .module
            )
        )
    }

    @ViewBuilder
    private var background: some View {
        if let palette {
            MeshGradient(
                width: ExchangeAdArtworkPalette.dimension,
                height: ExchangeAdArtworkPalette.dimension,
                points: ExchangeAdArtworkPalette.meshPoints,
                resolvedColors: palette.meshColors(for: colorScheme)
            )
        } else {
            // Without artwork to sample from we fall back to the same
            // background the banner uses.
            #if os(visionOS)
            Color.clear
            #else
            Rectangle()
                .fill(.windowBackground)
            #endif
        }
    }

    private var isPresented: Bool {
        placement == .presented
    }

    /// Presented adverts fill their presentation; inline ones stay a card.
    private var maximumWidth: Double {
        isPresented ? .infinity : ExchangeAdLayoutMetrics.maximumLargeCardWidth
    }

    private var borderStyle: AnyShapeStyle {
        if let strokeColor {
            AnyShapeStyle(strokeColor)
        } else {
            AnyShapeStyle(.quaternary)
        }
    }

    private var iconLength: Double {
        decorationScale * ExchangeAdLayoutMetrics.largeAppIconLength
    }

    private var decorationScale: Double {
        ExchangeAdLayoutMetrics.decorationScale(for: scale)
    }
}
