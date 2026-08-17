//
// ExchangeAdvertisementCard.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import SwiftUI

/// Displays an advertised app's icon, copy, disclosure, and App Store action.
struct ExchangeAdvertisementCard: View {
    let appName: String
    let subtitle: String?
    let icon: Image
    let isStoreEnabled: Bool
    let openStore: () -> Void
    let showInformation: () -> Void

    @Environment(\.exchangeAdCornerStyle) private var cornerStyle
    @Environment(\.exchangeAdStrokeColor) private var strokeColor
    @Environment(\.exchangeAdDisclosureBackgroundColor) private var disclosureBackgroundColor
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isDisclosureFocused: Bool

    // Decorations scale gently, but stop before they crowd out enlarged text.
    @ScaledMetric(relativeTo: .body) private var scale = 1.0

    var body: some View {
        HStack(
            alignment: ExchangeAdLayoutMetrics.verticalContentAlignment,
            spacing: ExchangeAdLayoutMetrics.horizontalContentSpacing
        ) {
            icon
                .resizable()
                .scaledToFit()
                .frame(width: iconLength, height: iconLength)
                #if os(visionOS) || os(watchOS)
                .clipShape(.circle)
                #else
                .clipShape(.rect(cornerRadius: iconLength * 0.2))
                #endif
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: appName)
                        .font(.headline)
                        .allowsHitTesting(false)

                    if let subtitle {
                        Text(verbatim: subtitle)
                            .font(.subheadline)
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

                Button(action: showInformation) {
                    Text("Ad", bundle: .module)
                        .bold()
                        .foregroundStyle(
                            isDisclosureFocused
                                ? focusedForegroundColor
                                : .white
                        )
                        .font(.caption2)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(
                            isDisclosureFocused
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
                .padding(.top, 3)
                #if !os(macOS) && !targetEnvironment(macCatalyst)
                // On platforms without a mouse pointer we make the Ad
                // button easier to tap.
                .contentShape(.rect.inset(by: -20))
                #endif
                #if os(tvOS)
                .buttonStyle(.exchangeAd)
                .focused($isDisclosureFocused)
                .focusEffectDisabled()
                #endif
                .accessibilityInputLabels([
                    Text("Ad", bundle: .module),
                    Text("About this ad", bundle: .module)
                ])
                .accessibilityLabel(Text("About this ad", bundle: .module))
                .accessibilityHint(
                    Text(
                        "Shows information about this advertisement",
                        bundle: .module
                    )
                )
            }
            .frame(
                minWidth: ExchangeAdLayoutMetrics.minimumHorizontalTextWidth,
                maxWidth: .infinity,
                alignment: .leading
            )

            #if !os(watchOS)
            // On watchOS we skip the Get button because there isn't space.
            Spacer(minLength: 5)

            AppStoreActionButton(appName: appName, action: openStore)
                .disabled(isStoreEnabled == false)
            #endif
        }
        .padding(decorationScale * ExchangeAdLayoutMetrics.cardPadding)
        .background {
            #if !os(visionOS) && !os(tvOS)
            // Follow Apple's lead and make the whole ad tappable on most
            // platforms, but not visionOS because it would trigger
            // accidental taps, and not tvOS because it's pointless there.
            Button(action: openStore) {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .disabled(isStoreEnabled == false)

            #if os(watchOS)
            // On watchOS we don't have a Get button because space is too limited,
            // so mark this background button as the Get button.
            .accessibilityLabel(Text("Get \(appName)", bundle: .module))
            .accessibilityHint(
                Text("Opens the App Store", bundle: .module)
            )
            #else
            // On other platforms we don't want this to become an extra
            // accessibility control, to avoid confusion.
            .accessibilityHidden(true)
            #endif
            #endif
        }
        #if os(visionOS)
        .glassBackgroundEffect(in: .rect(cornerRadius: cornerStyle.cornerRadius))
        #else
        .background(.windowBackground, in: .rect(cornerRadius: cornerStyle.cornerRadius))
        #endif
        .overlay {
            if let strokeColor {
                RoundedRectangle(cornerRadius: cornerStyle.cornerRadius)
                    .strokeBorder(strokeColor, lineWidth: 1)
                    .allowsHitTesting(false)
            } else {
                RoundedRectangle(cornerRadius: cornerStyle.cornerRadius)
                    .strokeBorder(.quaternary, lineWidth: 1)
                    .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: ExchangeAdLayoutMetrics.maximumCardWidth)
        .foregroundStyle(.primary)
        .labelStyle(.titleAndIcon)
        .textCase(nil)
        .lineLimit(nil)
        .buttonStyle(.plain)
        .minimumScaleFactor(1)
        .multilineTextAlignment(.leading)
        .unredacted()
        .accessibilityElement(children: .contain)
    }

    private var iconLength: Double {
        decorationScale * ExchangeAdLayoutMetrics.appIconLength
    }

    private var decorationScale: Double {
        ExchangeAdLayoutMetrics.decorationScale(for: scale)
    }

    private var focusedBackgroundColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var focusedForegroundColor: Color {
        colorScheme == .dark ? .black : .white
    }
}
