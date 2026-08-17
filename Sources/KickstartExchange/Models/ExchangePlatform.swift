//
// ExchangePlatform.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// The Apple platform an advert is being requested for.
///
/// Kickstart Exchange matches adverts against the platform making the request,
/// so an advert is only ever shown where its app can actually be installed.
/// This describes the kind of device, never a specific one.
enum ExchangePlatform: String, Hashable, Sendable {
    case iOS = "ios"
    case iPadOS = "ipados"
    case macOS = "macos"
    case tvOS = "tvos"
    case watchOS = "watchos"
    case visionOS = "visionos"

    /// The platform this code is currently running on.
    @MainActor
    static var current: ExchangePlatform {
        #if os(watchOS)
        .watchOS
        #elseif os(visionOS)
        .visionOS
        #elseif os(tvOS)
        .tvOS
        #elseif os(macOS)
        .macOS
        #elseif targetEnvironment(macCatalyst)
        // Catalyst apps are installed from the Mac App Store.
        .macOS
        #elseif os(iOS)
        // Compatible iPhone and iPad binaries still compile as iOS on Mac
        // and Apple Vision Pro, so identify the platform they run on.
        if ProcessInfo.processInfo.isiOSAppOnMac {
            return .macOS
        }
        if UIDevice.current.userInterfaceIdiom == .vision {
            return .visionOS
        }
        return UIDevice.current.userInterfaceIdiom == .pad ? .iPadOS : .iOS
        #else
        .iOS
        #endif
    }
}
