//
// PresentationLayoutTests.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import KickstartExchange

/// Verifies advertisement cards adapt to constrained presentation widths.
@Suite("Advertisement presentation layout")
@MainActor
struct PresentationLayoutTests {
    @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
    @Test("The card adapts its height at narrow widths")
    func narrowCardAdaptsItsHeight() {
        let regularSize = cardSize(width: 320)
        let narrowSize = cardSize(width: 200)

        #expect(regularSize.width == 320)
        #expect(narrowSize.width == 200)
        #expect(narrowSize.height > regularSize.height)
    }

    @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
    @Test("The large card reserves its minimum height")
    func largeCardReservesMinimumHeight() {
        let size = largeCardSize(width: 390)

        #expect(size.width == 390)
        #expect(size.height >= ExchangeAdLayoutMetrics.largeMinimumHeight)
    }

    @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
    @Test("The large card grows rather than clipping enlarged text")
    func largeCardGrowsForLongCopy() {
        let regularSize = largeCardSize(width: 390)
        let narrowSize = largeCardSize(width: 200)

        #expect(narrowSize.height >= regularSize.height)
    }

    @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
    private func largeCardSize(width: Double) -> CGSize {
        let card = ExchangeLargeAdvertisementCard(
            appName: "A Thirty Character App Name!",
            subtitle: "A useful thirty-character line",
            icon: Image(systemName: "app.fill"),
            palette: .preview,
            isStoreEnabled: true,
            showsCloseAction: true,
            openStore: { },
            showInformation: { },
            close: { }
        )
        .frame(width: width)

        return NSHostingView(rootView: card).fittingSize
    }

    @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
    private func cardSize(width: Double) -> CGSize {
        let card = ExchangeAdvertisementCard(
            appName: "A Thirty Character App Name!",
            subtitle: "A useful thirty-character line",
            icon: Image(systemName: "app.fill"),
            isStoreEnabled: true,
            openStore: { },
            showInformation: { }
        )
        .frame(width: width)

        return NSHostingView(rootView: card).fittingSize
    }
}
#endif
