//
// ArtworkPaletteTests.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import CoreGraphics
import SwiftUI
import Testing

@testable import KickstartExchange

/// Verifies icon sampling and the contrast conditioning that keeps large
/// advertisement backgrounds readable.
@Suite("Advertisement artwork palette")
struct ArtworkPaletteTests {

    /// The contrast ratio WCAG AA asks of normal-sized text.
    static let minimumContrastRatio = 4.5

    /// Icon colors chosen to cover the cases that break naive sampling: pure
    /// white and pure black icons, flat greys, and fully saturated artwork.
    static let iconColors: [(red: Double, green: Double, blue: Double)] = [
        (0, 0, 0),
        (1, 1, 1),
        (0.5, 0.5, 0.5),
        (1, 0, 0),
        (0, 1, 0),
        (0, 0, 1),
        (1, 1, 0),
        (0.1, 0.05, 0.2),
    ]

    @Test("Sampling an icon fills the whole mesh grid")
    func samplingFillsTheGrid() throws {
        let palette = try #require(
            ExchangeAdArtworkPalette(icon: icon(red: 0.8, green: 0.2, blue: 0.2)))
        let expected = ExchangeAdArtworkPalette.dimension * ExchangeAdArtworkPalette.dimension

        #expect(palette.samples.count == expected)
        #expect(ExchangeAdArtworkPalette.meshPoints.count == expected)
        #expect(palette.meshColors(for: .dark).count == expected)
    }

    @Test("A palette rejects a grid it cannot fill")
    func incompleteGridIsRejected() {
        #expect(ExchangeAdArtworkPalette(samples: []) == nil)
        #expect(
            ExchangeAdArtworkPalette(
                samples: [.init(hue: 0, saturation: 0, brightness: 0)]
            ) == nil
        )
    }

    @Test("A solid icon samples to its own hue and saturation")
    func solidIconKeepsItsHue() throws {
        let palette = try #require(ExchangeAdArtworkPalette(icon: icon(red: 1, green: 0, blue: 0)))

        for sample in palette.samples {
            #expect(abs(sample.hue) < 0.01)
            #expect(abs(sample.saturation - 1) < 0.01)
            #expect(abs(sample.brightness - 1) < 0.01)
        }
    }

    @Test(
        "Every icon stays legible behind primary text",
        arguments: [ColorScheme.dark, ColorScheme.light]
    )
    func everyIconStaysLegible(colorScheme: ColorScheme) throws {
        for color in Self.iconColors {
            let palette = try #require(
                ExchangeAdArtworkPalette(
                    icon: icon(red: color.red, green: color.green, blue: color.blue)
                )
            )

            for background in palette.meshColors(for: colorScheme) {
                let ratio = contrastRatio(
                    of: background,
                    against: colorScheme == .dark ? 1 : 0
                )

                #expect(
                    ratio >= Self.minimumContrastRatio,
                    """
                    \(color) produced a \(ratio) contrast ratio in \
                    \(colorScheme) mode.
                    """
                )
            }
        }
    }

    @Test("Vivid artwork is calmed to the saturation ceiling")
    func vividArtworkIsCalmed() throws {
        let palette = try #require(ExchangeAdArtworkPalette(icon: icon(red: 0, green: 1, blue: 0)))

        for background in palette.meshColors(for: .dark) {
            let components = [background.red, background.green, background.blue]
            let maximum = Double(components.max() ?? 0)
            let minimum = Double(components.min() ?? 0)
            let saturation = maximum == 0 ? 0 : (maximum - minimum) / maximum

            #expect(
                saturation <= ExchangeAdArtworkPalette.darkConditioning.maximumSaturation + 0.01)
        }
    }

    @Test("A flat icon still gains depth from top to bottom")
    func flatIconGainsDepth() throws {
        let palette = try #require(
            ExchangeAdArtworkPalette(icon: icon(red: 0.5, green: 0.5, blue: 0.5)))
        let colors = palette.meshColors(for: .dark)
        let dimension = ExchangeAdArtworkPalette.dimension

        let topBrightness = Double(colors[0].red)
        let bottomBrightness = Double(colors[dimension * (dimension - 1)].red)

        #expect(topBrightness > bottomBrightness)
    }

    /// Builds a solid-colored icon to sample from.
    private func icon(red: Double, green: Double, blue: Double) throws -> CGImage {
        let colorSpace = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        let context = try #require(
            CGContext(
                data: nil,
                width: 32,
                height: 32,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )

        context.setFillColor(red: red, green: green, blue: blue, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: 32, height: 32))
        return try #require(context.makeImage())
    }

    /// Returns the WCAG contrast ratio between a background and a text
    /// luminance, where white text is `1` and black text is `0`.
    private func contrastRatio(
        of background: Color.Resolved,
        against textLuminance: Double
    ) -> Double {
        let backgroundLuminance =
            0.2126 * Double(background.linearRed)
            + 0.7152 * Double(background.linearGreen)
            + 0.0722 * Double(background.linearBlue)

        let lighter = max(backgroundLuminance, textLuminance)
        let darker = min(backgroundLuminance, textLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }
}
