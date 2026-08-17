//
// AsyncTestWaiter.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import Foundation

/// Polls an asynchronous condition until it succeeds or reaches a timeout.
@MainActor
enum AsyncTestWaiter {
    static func until(
        timeout: Duration = .seconds(2),
        condition: () async -> Bool
    ) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)

        while clock.now < deadline {
            if await condition() {
                return true
            }

            try? await Task.sleep(for: .milliseconds(10))
        }

        return await condition()
    }
}
