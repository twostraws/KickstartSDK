//
// EventDeliveryDiagnosticsTests.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import Foundation
import Testing
@testable import KickstartExchange

/// Verifies diagnostics produced by failed development event delivery.
@MainActor
@Suite("Development impression diagnostics")
struct EventDeliveryDiagnosticsTests {
    @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
    @Test("A development impression failure reports once")
    func developmentFailureReports() async throws {
        let handler = readyHandler(impression: .failure(URLError(.timedOut)))
        let recorder = DiagnosticRecorder()
        let model = makeModel(handler: handler, recorder: recorder)
        await model.load()

        _ = try #require(await model.recordClick())
        #expect(await AsyncTestWaiter.until {
            recorder.messages.isEmpty == false
        })
        #expect(recorder.messages == [Self.impressionDiagnostic])
    }

    @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
    @Test("Shipping impression failures remain quiet")
    func shippingFailureStaysQuiet() async throws {
        let handler = readyHandler(
            impression: .success(TestFixtures.response(data: Data(), statusCode: 503))
        )
        let recorder = DiagnosticRecorder()
        let model = makeModel(
            handler: handler,
            recorder: recorder,
            isDevelopment: false
        )
        await model.load()

        _ = try #require(await model.recordClick())
        #expect(await AsyncTestWaiter.until {
            await handler.requests().count == 5
        })
        await Task.yield()
        #expect(recorder.messages.isEmpty)
    }

    @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
    @Test("Canceled impression delivery remains quiet")
    func cancellationStaysQuiet() async throws {
        let handler = readyHandler(impression: .failure(URLError(.cancelled)))
        let recorder = DiagnosticRecorder()
        let model = makeModel(handler: handler, recorder: recorder)
        await model.load()

        _ = try #require(await model.recordClick())
        #expect(await AsyncTestWaiter.until {
            await handler.requests().count == 5
        })
        await Task.yield()
        #expect(recorder.messages.isEmpty)
    }

    private static let impressionDiagnostic =
        """
        Kickstart Exchange: The test ad impression could not be recorded. \
        Check the network connection and reload the test ad.
        """

    private func readyHandler(
        impression: Result<MockRequestHandler.Response, URLError>
    ) -> MockRequestHandler {
        MockRequestHandler([
            .success(TestFixtures.response(data: TestFixtures.sessionResponse())),
            .success(TestFixtures.response(data: TestFixtures.creativeResponse())),
            .success(TestFixtures.response(data: TestFixtures.validPNG)),
            .success(TestFixtures.completedClickResponse),
            impression
        ])
    }

    @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
    private func makeModel(
        handler: MockRequestHandler,
        recorder: DiagnosticRecorder,
        isDevelopment: Bool = true
    ) -> ExchangeAdViewModel {
        ExchangeAdViewModel(
            apiKey: TestFixtures.apiKey,
            bundleIdentifier: TestFixtures.bundleIdentifier,
            appVersion: TestFixtures.appVersion,
            buildVersion: TestFixtures.buildVersion,
            request: { request in
                try await handler.response(for: request)
            },
            isDevelopment: isDevelopment,
            diagnosticHandler: recorder.record
        )
    }
}
