//
// LoadDiagnosticsTests.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import Foundation
import Testing
@testable import KickstartExchange

/// Verifies actionable diagnostics for advertisement loading failures.
@MainActor
@Suite("Development load diagnostics")
struct LoadDiagnosticsTests {
    @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
    @Test("A missing bundle identifier produces one actionable diagnostic")
    func missingBundleIdentifier() async {
        let handler = MockRequestHandler()
        let recorder = DiagnosticRecorder()
        let model = ExchangeAdViewModel(
            apiKey: TestFixtures.apiKey,
            bundleIdentifier: nil,
            request: { request in
                try await handler.response(for: request)
            },
            isDevelopment: true,
            diagnosticHandler: recorder.record
        )

        await model.load()

        #expect(model.presentation == nil)
        #expect(recorder.messages == [
            """
            Kickstart Exchange: A test ad could not be loaded because the host app has no bundle identifier. \
            Set the app target's product bundle identifier.
            """
        ])
        #expect(await handler.requests().isEmpty)
    }

    @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
    @Test("A session rejection keeps its actionable reason")
    func sessionRejection() async {
        let rejected = TestFixtures.response(
            data: Data(),
            statusCode: 204,
            headers: ["x-exchange-reason": "unknown_api_key"]
        )
        let handler = MockRequestHandler([.success(rejected), .success(rejected)])
        let recorder = DiagnosticRecorder()
        let model = makeModel(handler: handler, recorder: recorder)

        await model.load()

        #expect(model.presentation == nil)
        #expect(recorder.messages == [
            """
            Kickstart Exchange: No test advert shown – this API key was not recognized. \
            Copy it again from the app's Overview page.
            """
        ])
    }

    @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
    @Test("An unexpected serve response produces one service diagnostic")
    func unexpectedServeResponse() async {
        let handler = MockRequestHandler([
            .success(TestFixtures.response(data: TestFixtures.sessionResponse())),
            .success(TestFixtures.response(data: Data(), statusCode: 503))
        ])
        let recorder = DiagnosticRecorder()
        let model = makeModel(handler: handler, recorder: recorder)

        await model.load()

        #expect(model.presentation == nil)
        #expect(recorder.messages == [
            """
            Kickstart Exchange: The advertisement service returned an unexpected response. \
            Try again or update KickstartSDK.
            """
        ])
        #expect(await handler.requests().count == 2)
    }

    @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
    private func makeModel(
        handler: MockRequestHandler,
        recorder: DiagnosticRecorder
    ) -> ExchangeAdViewModel {
        ExchangeAdViewModel(
            apiKey: TestFixtures.apiKey,
            bundleIdentifier: TestFixtures.bundleIdentifier,
            appVersion: TestFixtures.appVersion,
            buildVersion: TestFixtures.buildVersion,
            request: { request in
                try await handler.response(for: request)
            },
            isDevelopment: true,
            diagnosticHandler: recorder.record
        )
    }
}
