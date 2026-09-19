//
// ExchangeEnvironmentTests.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import Foundation
import Testing
@testable import KickstartExchange

/// Verifies build-environment detection and its session request fields.
@MainActor
@Suite("Build environment")
struct ExchangeEnvironmentTests {
    @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
    @Test("The view model defaults to the current build environment")
    func defaultDevelopmentWiring() async throws {
        let handler = MockRequestHandler([
            .success(TestFixtures.response(data: TestFixtures.sessionResponse())),
            .success(TestFixtures.response(data: TestFixtures.creativeResponse())),
            .success(TestFixtures.response(data: TestFixtures.validPNG))
        ])
        let model = ExchangeAdViewModel(
            apiKey: TestFixtures.apiKey,
            bundleIdentifier: "com.example.host",
            request: { request in
                try await handler.response(for: request)
            }
        )

        await model.load()
        let request = try #require(await handler.requests().first)
        let body = try JSONRequestBody.object(from: request)

        #if DEBUG || targetEnvironment(simulator)
        #expect(ExchangeEnvironment.isDevelopment)
        #expect(body["development"] as? Bool == true)
        #expect(body.keys.contains("app_transaction") == false)
        #else
        #expect(ExchangeEnvironment.isDevelopment == false)
        #expect(body.keys.contains("development") == false)
        #endif
    }
}
