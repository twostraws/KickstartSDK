//
// ExchangeAdArtworkPalette.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import CoreGraphics
import SwiftUI

//
// Note to reader: Apple Music and Spotify build their now-playing
// backgrounds out of the artwork itself, and it looks great. MusicKit
// exposes Artwork.backgroundColor to do that, but there is no such API
// for an arbitrary image, so we make our own: shrink the app icon down
// to a handful of pixels and treat those as gradient stops.
//
// The catch is contrast. Plenty of app icons are almost entirely white,
// and plenty more are almost entirely black, so sampled colors used
// as-is produce backgrounds that swallow the text on top of them. That
// is why every sample gets pinned into a brightness band chosen for the
// current color scheme: dark backgrounds in dark mode, light ones in
// light mode, and legible primary-colored text either way.
//
// Light mode needs more than a brightness clamp. Dark text wants real
// luminance behind it, and a saturated color simply does not carry
// much, so light backgrounds are also pulled towards pastel. Dark mode
// keeps far more of the icon's color, because white text only needs the
// background to stay dark.
//

/// A small grid of colors sampled from an advertised app's icon, conditioned so
/// large advertisement backgrounds stay readable behind primary-colored text.
struct ExchangeAdArtworkPalette: Equatable, Sendable {

    /// The number of samples taken along each axis of the icon.
    static let dimension = 3

    /// How much darker the bottom row is than the top, which gives even a
    /// completely flat icon some sense of depth.
    static let verticalFalloff = 0.1

    /// How far samples are pushed to keep one color scheme readable.
    struct Conditioning: Equatable, Sendable {
        /// The strongest saturation a sample may reach, which stops vivid
        /// icons from turning the card into a neon slab.
        var maximumSaturation: Double

        /// The brightness range conditioned samples occupy.
        var brightnessBand: ClosedRange<Double>
    }

    /// Dark mode carries white text, so backgrounds stay dark and may keep
    /// most of the icon's color.
    static let darkConditioning = Conditioning(
        maximumSaturation: 0.7,
        brightnessBand: 0.16...0.4
    )

    /// Light mode carries dark text, which needs far more luminance behind
    /// it than a saturated color provides — so light backgrounds go pastel.
    static let lightConditioning = Conditioning(
        maximumSaturation: 0.18,
        brightnessBand: 0.88...0.97
    )

    /// Returns the conditioning that keeps a color scheme readable.
    static func conditioning(for colorScheme: ColorScheme) -> Conditioning {
        colorScheme == .dark ? darkConditioning : lightConditioning
    }

    /// The evenly spaced mesh vertices matching the sampling grid.
    static let meshPoints: [SIMD2<Float>] = {
        let steps = Float(dimension - 1)

        return (0..<dimension).flatMap { row in
            (0..<dimension).map { column in
                SIMD2(Float(column) / steps, Float(row) / steps)
            }
        }
    }()

    /// One icon sample, stored as hue, saturation, and brightness so the
    /// palette can be conditioned for either color scheme without resampling
    /// the artwork.
    struct Sample: Equatable, Sendable {
        var hue: Double
        var saturation: Double
        var brightness: Double
    }

    /// The sampled icon colors, ordered row by row from the top of the icon.
    let samples: [Sample]

    /// Creates a palette from already-sampled colors.
    ///
    /// - Parameter samples: Exactly `dimension * dimension` samples, ordered
    ///   row by row from the top of the icon.
    init?(samples: [Sample]) {
        guard samples.count == Self.dimension * Self.dimension else {
            return nil
        }

        self.samples = samples
    }

    /// Creates a palette by shrinking an app icon down to a sampling grid.
    ///
    /// - Parameter icon: The advertised app's icon.
    init?(icon: CGImage) {
        let dimension = Self.dimension

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil,
                  width: dimension,
                  height: dimension,
                  bitsPerComponent: 8,
                  bytesPerRow: 0,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return nil
        }

        // Averaging every pixel down into each cell matters more than speed
        // here, because we only ever do this once per advertisement.
        context.interpolationQuality = .high
        context.draw(
            icon,
            in: CGRect(x: 0, y: 0, width: dimension, height: dimension)
        )

        guard let data = context.data else {
            return nil
        }

        let bytes = data.assumingMemoryBound(to: UInt8.self)
        let bytesPerRow = context.bytesPerRow
        var samples: [Sample] = []
        samples.reserveCapacity(dimension * dimension)

        for row in 0..<dimension {
            for column in 0..<dimension {
                let offset = row * bytesPerRow + column * 4
                let alpha = Double(bytes[offset + 3]) / 255

                // Icons are opaque in practice, but undoing the premultiply
                // keeps a transparent corner from reading as black.
                let divisor = alpha > 0 ? alpha * 255 : 255
                samples.append(
                    Self.sample(
                        red: Double(bytes[offset]) / divisor,
                        green: Double(bytes[offset + 1]) / divisor,
                        blue: Double(bytes[offset + 2]) / divisor
                    )
                )
            }
        }

        self.samples = samples
    }

    /// A representative palette used by the SDK's preview APIs, so previews
    /// show the same background treatment a real advert receives.
    static let preview = ExchangeAdArtworkPalette(
        samples: [
            Sample(hue: 0.62, saturation: 0.55, brightness: 0.85),
            Sample(hue: 0.66, saturation: 0.60, brightness: 0.90),
            Sample(hue: 0.70, saturation: 0.50, brightness: 0.80),
            Sample(hue: 0.60, saturation: 0.50, brightness: 0.75),
            Sample(hue: 0.65, saturation: 0.65, brightness: 0.95),
            Sample(hue: 0.72, saturation: 0.55, brightness: 0.78),
            Sample(hue: 0.58, saturation: 0.45, brightness: 0.70),
            Sample(hue: 0.63, saturation: 0.50, brightness: 0.80),
            Sample(hue: 0.74, saturation: 0.60, brightness: 0.72)
        ]
    )

    /// Returns the mesh gradient colors for a color scheme.
    ///
    /// - Parameter colorScheme: The color scheme the advertisement is shown in.
    func meshColors(for colorScheme: ColorScheme) -> [Color.Resolved] {
        let conditioning = Self.conditioning(for: colorScheme)
        let band = conditioning.brightnessBand
        let span = band.upperBound - band.lowerBound
        let lastRow = Double(Self.dimension - 1)

        return samples.enumerated().map { index, sample in
            let depth = Double(index / Self.dimension) / lastRow
            let banded = band.lowerBound + sample.brightness * span
            let shaded = banded - depth * Self.verticalFalloff

            return Self.resolved(
                hue: sample.hue,
                saturation: min(sample.saturation, conditioning.maximumSaturation),
                brightness: min(max(shaded, 0), 1)
            )
        }
    }

    /// Converts sRGB components into a stored sample.
    static func sample(red: Double, green: Double, blue: Double) -> Sample {
        let red = min(max(red, 0), 1)
        let green = min(max(green, 0), 1)
        let blue = min(max(blue, 0), 1)

        let maximum = max(red, green, blue)
        let minimum = min(red, green, blue)
        let delta = maximum - minimum

        let hue: Double

        if delta == 0 {
            hue = 0
        } else if maximum == red {
            hue = ((green - blue) / delta).truncatingRemainder(dividingBy: 6)
        } else if maximum == green {
            hue = (blue - red) / delta + 2
        } else {
            hue = (red - green) / delta + 4
        }

        let degrees = hue * 60
        return Sample(
            hue: (degrees < 0 ? degrees + 360 : degrees) / 360,
            saturation: maximum == 0 ? 0 : delta / maximum,
            brightness: maximum
        )
    }

    /// Converts hue, saturation, and brightness back into a concrete color.
    static func resolved(
        hue: Double,
        saturation: Double,
        brightness: Double
    ) -> Color.Resolved {
        let sector = (hue.truncatingRemainder(dividingBy: 1) * 6 + 6)
            .truncatingRemainder(dividingBy: 6)
        let offset = sector - sector.rounded(.down)
        let primary = brightness * (1 - saturation)
        let falling = brightness * (1 - saturation * offset)
        let rising = brightness * (1 - saturation * (1 - offset))

        let components: (red: Double, green: Double, blue: Double) =
            switch Int(sector) {
            case 0: (brightness, rising, primary)
            case 1: (falling, brightness, primary)
            case 2: (primary, brightness, rising)
            case 3: (primary, falling, brightness)
            case 4: (rising, primary, brightness)
            default: (brightness, primary, falling)
            }

        return Color.Resolved(
            colorSpace: .sRGB,
            red: Float(components.red),
            green: Float(components.green),
            blue: Float(components.blue)
        )
    }
}
