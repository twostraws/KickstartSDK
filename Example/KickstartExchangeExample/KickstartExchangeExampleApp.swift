//
// KickstartExchangeExampleApp.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import SwiftUI

//
// Note to reader: this example app exists so you can see the SDK
// running without an Exchange account. Every screen passes the
// "preview" API key, which Debug builds and the Simulator answer
// with a real server response for a sample advert. Nobody is
// charged, nothing is counted, and the integration path - session,
// serve, artwork, impression, click - is exercised for real.
//

/// Demonstrates Kickstart Exchange advertisement placements.
@main
struct KickstartExchangeExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
