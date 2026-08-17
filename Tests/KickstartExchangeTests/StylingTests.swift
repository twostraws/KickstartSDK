//
// StylingTests.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import Testing
@testable import KickstartExchange

/// Verifies advertisement corner styles.
@Suite("Advertisement styling")
struct StylingTests {
    @Test("Corner styles resolve safe radii")
    func cornerStyles() {
        #expect(ExchangeAdCornerStyle.square.cornerRadius == 0)
        #expect(ExchangeAdCornerStyle.rounded.cornerRadius == ExchangeAdLayoutMetrics.cardCornerRadius)
    }
}
