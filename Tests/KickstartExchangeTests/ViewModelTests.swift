//
// ViewModelTests.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import Foundation
import Testing
@testable import KickstartExchange

/// Verifies advertisement loading, presentation, and interaction lifecycles.
@MainActor
@Suite("Advertisement lifecycle")
struct ViewModelTests {
    @Test("Preview loads without sessions or accounting")
    func previewAdvert() async throws {
        let handler = MockRequestHandler([
            .success(TestFixtures.response(data: TestFixtures.previewResponse())),
            .success(TestFixtures.response(data: TestFixtures.validPNG)),
            .success(TestFixtures.response(
                data: Data(),
                statusCode: 302,
                headers: ["location": TestFixtures.previewStoreURL]
            ))
        ])
        let model = makeModel(
            apiKey: ExchangeAPIClient.previewAPIKey,
            handler: handler
        )

        await model.load()
        model.setSceneActive(true)
        model.setPlacementVisible(true)

        let storeURL = try #require(await model.recordClick())
        #expect(storeURL.absoluteString == TestFixtures.previewStoreURL)
        #expect(model.presentation?.serveID == "preview")
        #expect(model.presentation?.impressionToken == nil)
        let requests = await handler.requests()
        #expect(requests.count == 3)
        #expect(requests[2].url?.absoluteString == TestFixtures.previewClickURL)
    }

    @Test("A failed preview click still returns the direct store URL")
    func failedPreviewClickUsesFallback() async throws {
        let handler = MockRequestHandler([
            .success(TestFixtures.response(data: TestFixtures.previewResponse())),
            .success(TestFixtures.response(data: TestFixtures.validPNG)),
            .failure(URLError(.timedOut))
        ])
        let model = makeModel(
            apiKey: ExchangeAPIClient.previewAPIKey,
            handler: handler
        )

        await model.load()

        let storeURL = try #require(await model.recordClick())
        #expect(storeURL.absoluteString == TestFixtures.previewStoreURL)
        #expect(model.isOpeningStore == false)
    }

    @Test("Preview reports exercise the API without a live serve")
    func previewReport() async throws {
        let handler = MockRequestHandler([
            .success(TestFixtures.response(data: TestFixtures.previewResponse())),
            .success(TestFixtures.response(data: TestFixtures.validPNG)),
            .success(TestFixtures.response(data: Data(), statusCode: 204))
        ])
        let model = makeModel(
            apiKey: ExchangeAPIClient.previewAPIKey,
            handler: handler
        )

        await model.load()
        model.showInformation()

        #expect(await model.submitReport(reason: .other))
        #expect(model.visiblePresentation == nil)
        let requests = await handler.requests()
        #expect(requests.count == 3)
        #expect(requests[2].url == ExchangeEndpoint.reports)
        let body = try JSONRequestBody.object(from: requests[2])
        #expect(body["serve_id"] as? String == "preview")
        #expect(body["reason"] as? String == "other")
    }

    @Test("Preview is unavailable in shipping builds")
    func shippingPreviewIsUnavailable() async {
        let handler = MockRequestHandler([])
        var diagnostic = ""
        let model = makeModel(
            apiKey: ExchangeAPIClient.previewAPIKey,
            handler: handler,
            isDevelopment: false,
            diagnosticHandler: { diagnostic = $0 }
        )

        await model.load()

        #expect(model.presentation == nil)
        #expect(await handler.requests().isEmpty)
        #expect(diagnostic.contains("preview key is available only"))
    }

    @Test("A valid session, ad, and artwork become ready after one load")
    func readyState() async {
        let handler = readyHandler()
        let model = makeModel(handler: handler)

        await model.load()

        #expect(model.presentation?.ad.name == "Example App")
        #expect(model.presentation?.impressionToken == TestFixtures.impressionToken)
        #expect(await handler.requests().count == 3)
    }

    @Test("Every banner in one app run reuses the same advert")
    func bannersReuseAdvert() async {
        let handler = readyHandler()
        let appRunStore = ExchangeAdRunStore()
        let firstModel = makeModel(
            handler: handler,
            appRunStore: appRunStore
        )
        let secondModel = makeModel(
            handler: handler,
            appRunStore: appRunStore
        )

        await firstModel.load()
        await secondModel.load()

        #expect(firstModel.presentation?.serveID == secondModel.presentation?.serveID)
        #expect(firstModel.presentation?.ad.name == secondModel.presentation?.ad.name)
        #expect(await handler.requests().count == 3)
    }

    @Test("A tap records quietly before returning the store URL and ignores repeats")
    func tapRecordsBeforeOpeningStore() async throws {
        let handler = readyHandler(
            additional: [
                .success(TestFixtures.completedClickResponse),
                .success(TestFixtures.completedImpressionResponse)
            ],
            suspendedRequestNumber: 4
        )
        let model = makeModel(handler: handler)
        await model.load()

        let clickTask = Task { @MainActor in
            await model.recordClick()
        }
        await handler.waitUntilRequestStarts(4)
        #expect(model.isOpeningStore)
        #expect(await model.recordClick() == nil)

        let requests = await handler.requests()
        #expect(requests[3].url?.absoluteString == TestFixtures.clickURL)
        #expect(requests[3].httpMethod == "GET")
        await handler.resumeSuspendedRequest()

        let storeURL = try #require(await clickTask.value)
        #expect(storeURL.absoluteString == TestFixtures.storeURL)
        #expect(model.isOpeningStore == false)
        #expect(await AsyncTestWaiter.until {
            await handler.requests().count == 5
        })
    }

    @Test("Visibility must remain continuous for a full second")
    func interruptedVisibility() async throws {
        let handler = readyHandler(
            additional: [.success(TestFixtures.completedImpressionResponse)]
        )
        let model = makeModel(handler: handler)
        await model.load()

        model.setSceneActive(true)
        model.setPlacementVisible(true)
        try? await Task.sleep(for: .milliseconds(600))
        model.setPlacementVisible(false)
        try? await Task.sleep(for: .milliseconds(600))
        #expect(await handler.requests().count == 3)

        model.setPlacementVisible(true)
        #expect(await AsyncTestWaiter.until(timeout: .seconds(2)) {
            await handler.requests().count == 4
        })
        let request = try #require(await handler.requests().last)
        let body = try JSONRequestBody.object(from: request)
        #expect(body["impression_token"] as? String == TestFixtures.impressionToken)
    }

    @Test("All banners in one app run share one impression delivery")
    func bannersShareImpression() async {
        let handler = readyHandler(
            additional: [.success(TestFixtures.completedImpressionResponse)]
        )
        let appRunStore = ExchangeAdRunStore()
        let firstModel = makeModel(
            handler: handler,
            appRunStore: appRunStore
        )
        let secondModel = makeModel(
            handler: handler,
            appRunStore: appRunStore
        )
        await firstModel.load()
        await secondModel.load()

        firstModel.setSceneActive(true)
        firstModel.setPlacementVisible(true)
        secondModel.setSceneActive(true)
        secondModel.setPlacementVisible(true)

        #expect(await AsyncTestWaiter.until(timeout: .seconds(2)) {
            await handler.requests().count == 4
        })
        try? await Task.sleep(for: .milliseconds(100))
        #expect(await handler.requests().count == 4)
    }

    @Test("An accepted report suppresses every banner for the app run")
    func reportSuppressesAllBanners() async {
        let handler = readyHandler(
            additional: [.success(TestFixtures.response(data: Data(), statusCode: 204))]
        )
        let appRunStore = ExchangeAdRunStore()
        let firstModel = makeModel(
            handler: handler,
            isDevelopment: false,
            appRunStore: appRunStore
        )
        let secondModel = makeModel(
            handler: handler,
            isDevelopment: false,
            appRunStore: appRunStore
        )

        await firstModel.load()
        await secondModel.load()
        firstModel.showInformation()

        #expect(await firstModel.submitReport(reason: .misleading))
        #expect(firstModel.visiblePresentation == nil)
        #expect(secondModel.visiblePresentation == nil)
        #expect(await firstModel.recordClick() == nil)
        #expect(await handler.requests().count == 4)
    }

    @Test("A failed report leaves the shared advert visible")
    func failedReportRemainsVisible() async {
        let handler = readyHandler(
            additional: [.success(TestFixtures.response(data: Data(), statusCode: 500))]
        )
        let model = makeModel(handler: handler, isDevelopment: false)

        await model.load()
        model.showInformation()

        let wasSent = await model.submitReport(reason: .other)
        #expect(wasSent == false)
        #expect(model.visiblePresentation != nil)
    }

    private func readyHandler(
        additional: [Result<MockRequestHandler.Response, URLError>] = [],
        suspendedRequestNumber: Int? = nil
    ) -> MockRequestHandler {
        MockRequestHandler([
            .success(TestFixtures.response(data: TestFixtures.sessionResponse())),
            .success(TestFixtures.response(data: TestFixtures.creativeResponse())),
            .success(TestFixtures.response(data: TestFixtures.validPNG))
        ] + additional, suspendedRequestNumber: suspendedRequestNumber)
    }

    private func makeModel(
        apiKey: String = TestFixtures.apiKey,
        handler: MockRequestHandler,
        isDevelopment: Bool = true,
        appRunStore: ExchangeAdRunStore = ExchangeAdRunStore(),
        diagnosticHandler: @escaping @MainActor (String) -> Void = { _ in }
    ) -> ExchangeAdViewModel {
        ExchangeAdViewModel(
            apiKey: apiKey,
            bundleIdentifier: TestFixtures.bundleIdentifier,
            appVersion: TestFixtures.appVersion,
            buildVersion: TestFixtures.buildVersion,
            request: { request in
                try await handler.response(for: request)
            },
            isDevelopment: isDevelopment,
            appRunStore: appRunStore,
            diagnosticHandler: diagnosticHandler
        )
    }
}
