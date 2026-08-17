//
// APIClientTests.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import Foundation
import Testing
@testable import KickstartExchange

/// Verifies Exchange API request construction and response handling.
@Suite("API client")
struct APIClientTests {
    @Test("Preview fetches only the public sample advert")
    func previewAdvert() async throws {
        let handler = MockRequestHandler([
            .success(TestFixtures.response(data: TestFixtures.previewResponse()))
        ])
        let client = TestFixtures.client(handler: handler, development: true)

        let response = try await client.preview()
        let request = try #require(await handler.requests().first)

        #expect(request.url == ExchangeEndpoint.preview)
        #expect(request.httpMethod == "GET")
        #expect(request.httpBody == nil)
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(response.serveID == "preview")
        #expect(response.impressionToken == nil)
        #expect(response.ad.name == "Kickstart Exchange")
        #expect(response.ad.clickURL.absoluteString == TestFixtures.previewClickURL)
        #expect(response.ad.storeURL?.absoluteString == TestFixtures.previewStoreURL)
    }

    @Test("Development session sends exact fields without App Transaction")
    func exactDevelopmentSessionFields() async throws {
        let handler = MockRequestHandler([
            .success(TestFixtures.response(data: TestFixtures.sessionResponse(
                countsEnabled: false,
                countingReason: "development_build"
            )))
        ])
        let client = TestFixtures.client(
            handler: handler,
            development: true,
            platform: .macOS,
            appTransaction: {
                Issue.record("Development requested App Transaction evidence.")
                return "header.payload.signature"
            }
        )

        _ = try await client.session()
        let request = try #require(await handler.requests().first)
        let body = try JSONRequestBody.object(from: request)

        #expect(request.url == ExchangeEndpoint.sessions)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(Set(body.keys) == [
            "api_key", "bundle_id", "platform", "app_version",
            "build_version", "sdk_version", "development"
        ])
        #expect(body["api_key"] as? String == TestFixtures.apiKey)
        #expect(body["bundle_id"] as? String == TestFixtures.bundleIdentifier)
        #expect(body["platform"] as? String == "macos")
        #expect(body["app_version"] as? String == TestFixtures.appVersion)
        #expect(body["build_version"] as? String == TestFixtures.buildVersion)
        #expect(body["development"] as? Bool == true)
    }

    @Test("Session decodes accounting eligibility and reason")
    func sessionAccountingEligibility() async throws {
        let handler = MockRequestHandler([
            .success(TestFixtures.response(data: TestFixtures.sessionResponse(
                countsEnabled: false,
                countingReason: "app_transaction_unavailable"
            )))
        ])
        let client = TestFixtures.client(handler: handler)

        let session = try await client.session()

        #expect(session.countsEnabled == false)
        #expect(session.countingReason == "app_transaction_unavailable")
    }

    @Test("Shipping session sends verified evidence only to session creation")
    func exactShippingSessionFields() async throws {
        let evidence = "synthetic.header.signature"
        let handler = MockRequestHandler([
            .success(TestFixtures.response(data: TestFixtures.sessionResponse()))
        ])
        let client = TestFixtures.client(
            handler: handler,
            appTransaction: { evidence }
        )

        _ = try await client.session()
        let request = try #require(await handler.requests().first)
        let body = try JSONRequestBody.object(from: request)

        #expect(Set(body.keys) == [
            "api_key", "bundle_id", "platform", "app_version",
            "build_version", "sdk_version", "app_transaction"
        ])
        #expect(body["app_transaction"] as? String == evidence)
        #expect(body.keys.contains("development") == false)
        #expect(body.keys.contains("storefront") == false)
        #expect(body.keys.contains("locale") == false)
        #expect(body.keys.contains("device_id") == false)
        #expect(body.keys.contains("installation_id") == false)
        #expect(body.keys.contains("transaction_id") == false)
        #expect(request.value(forHTTPHeaderField: "User-Agent") == nil)
    }

    @Test("Serve uses bearer authorization and only optional storefront")
    func exactServeFields() async throws {
        let handler = MockRequestHandler([
            .success(TestFixtures.response(data: TestFixtures.sessionResponse())),
            .success(TestFixtures.response(data: TestFixtures.creativeResponse()))
        ])
        let client = TestFixtures.client(handler: handler)
        let session = try await client.session()

        let result = try await client.serve(session: session, storefront: "GBR")
        guard case .advertisement(let response) = result else {
            Issue.record("Serve did not return an advertisement.")
            return
        }

        let requests = await handler.requests()
        let request = requests[1]
        let body = try JSONRequestBody.object(from: request)
        #expect(request.url == ExchangeEndpoint.serve)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(TestFixtures.sessionToken)")
        #expect(Set(body.keys) == ["storefront"])
        #expect(body["storefront"] as? String == "GBR")
        #expect(response.impressionToken == TestFixtures.impressionToken)
        #expect(response.ad.clickURL.absoluteString == TestFixtures.clickURL)
        #expect(response.ad.storeURL?.absoluteString == TestFixtures.storeURL)
    }

    @Test("Click recording quietly resolves the App Store destination")
    func clickRecording() async throws {
        let handler = MockRequestHandler([
            .success(TestFixtures.completedClickResponse)
        ])
        let client = TestFixtures.client(handler: handler)
        let clickURL = try #require(URL(string: TestFixtures.clickURL))

        let destination = try await client.submitClick(to: clickURL)
        let request = try #require(await handler.requests().first)

        #expect(destination.absoluteString == TestFixtures.storeURL)
        #expect(request.url == clickURL)
        #expect(request.httpMethod == "GET")
        #expect(request.httpBody == nil)
        #expect(request.timeoutInterval == 2)
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test("Serve without storefront sends an empty JSON object")
    func serveWithoutStorefront() async throws {
        let handler = MockRequestHandler([
            .success(TestFixtures.response(data: TestFixtures.sessionResponse())),
            .success(TestFixtures.response(data: TestFixtures.creativeResponse()))
        ])
        let client = TestFixtures.client(handler: handler)
        let session = try await client.session()

        _ = try await client.serve(session: session)
        let requests = await handler.requests()
        let body = try JSONRequestBody.object(from: requests[1])
        #expect(body.isEmpty)
    }

    @Test("Shipping skips serve when accounting is disabled")
    func shippingSkipsNoncountingServe() async throws {
        let handler = MockRequestHandler([
            .success(TestFixtures.response(data: TestFixtures.sessionResponse(
                countsEnabled: false,
                countingReason: "app_transaction_unavailable"
            )))
        ])
        let client = TestFixtures.client(handler: handler)
        let session = try await client.session()

        let result = try await client.serve(session: session)

        guard case .rejected(let reason) = result else {
            Issue.record("Shipping attempted to serve a noncounting advert.")
            return
        }
        #expect(reason == "app_transaction_unavailable")
        let requests = await handler.requests()
        #expect(requests.count == 1)
        #expect(requests.allSatisfy { $0.url != ExchangeEndpoint.serve })
    }

    @Test("Development can serve when accounting is disabled")
    func developmentAllowsNoncountingServe() async throws {
        let handler = MockRequestHandler([
            .success(TestFixtures.response(data: TestFixtures.sessionResponse(
                countsEnabled: false,
                countingReason: "development_build"
            ))),
            .success(TestFixtures.response(data: TestFixtures.creativeResponse()))
        ])
        let client = TestFixtures.client(handler: handler, development: true)
        let session = try await client.session()

        let result = try await client.serve(session: session)

        guard case .advertisement = result else {
            Issue.record("Development did not serve its noncounting test advert.")
            return
        }
        let requests = await handler.requests()
        #expect(requests.count == 2)
        #expect(requests[1].url == ExchangeEndpoint.serve)
    }

    @Test("Impression sends only its distinct capability")
    func exactImpressionFields() async throws {
        let handler = MockRequestHandler([
            .success(TestFixtures.completedImpressionResponse)
        ])
        let client = TestFixtures.client(handler: handler)

        try await client.submitImpression(token: TestFixtures.impressionToken)
        let request = try #require(await handler.requests().first)
        let body = try JSONRequestBody.object(from: request)

        #expect(request.url == ExchangeEndpoint.impressions)
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(Set(body.keys) == ["impression_token"])
        #expect(body["impression_token"] as? String == TestFixtures.impressionToken)
        #expect(body.keys.contains("serve_id") == false)
        #expect(body.keys.contains("type") == false)
    }

    @Test("Report sends only the serve ID and fixed reason")
    func exactReportFields() async throws {
        let handler = MockRequestHandler([
            .success(TestFixtures.response(data: Data(), statusCode: 204))
        ])
        let client = TestFixtures.client(handler: handler)

        try await client.submitReport(
            serveID: TestFixtures.serveID,
            reason: .brokenLink
        )
        let request = try #require(await handler.requests().first)
        let body = try JSONRequestBody.object(from: request)

        #expect(request.url == ExchangeEndpoint.reports)
        #expect(request.httpMethod == "POST")
        #expect(request.timeoutInterval == 5)
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(Set(body.keys) == ["serve_id", "reason"])
        #expect(body["serve_id"] as? String == TestFixtures.serveID)
        #expect(body["reason"] as? String == "broken_link")
    }

    @Test("Client failures and missing status do not retry impressions")
    func permanentImpressionResponseStatus() async {
        for statusCode in [nil, 200, 400, 499] as [Int?] {
            let handler = MockRequestHandler([
                .success((data: Data(), statusCode: statusCode, headers: [:]))
            ])
            let client = TestFixtures.client(handler: handler)

            do {
                try await client.submitImpression(token: TestFixtures.impressionToken)
                Issue.record("A non-204 impression response succeeded.")
            } catch let failure as ExchangeImpressionDeliveryFailure {
                #expect(failure == .unexpectedResponse)
            } catch {
                Issue.record("Unexpected error: \(error)")
            }
        }
    }

    @Test("Server failures are retryable impression failures", arguments: [500, 503, 599])
    func retryableImpressionResponseStatus(_ statusCode: Int) async {
        let handler = MockRequestHandler([
            .success(TestFixtures.response(data: Data(), statusCode: statusCode))
        ])
        let client = TestFixtures.client(handler: handler)

        do {
            try await client.submitImpression(token: TestFixtures.impressionToken)
            Issue.record("A server-failed impression response succeeded.")
        } catch let failure as ExchangeImpressionDeliveryFailure {
            #expect(failure == .server)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Transport bounds requests without retaining web state")
    func ephemeralTransportConfiguration() {
        let configuration = ExchangeAPIClient.makeURLSessionConfiguration()

        #expect(configuration.timeoutIntervalForRequest == 15)
        #expect(configuration.timeoutIntervalForResource == 30)
        #expect(configuration.requestCachePolicy == .reloadIgnoringLocalCacheData)
        #expect(configuration.urlCache == nil)
        #expect(configuration.httpCookieStorage == nil)
        #expect(configuration.httpShouldSetCookies == false)
    }

    @Test("Transport rejects redirects before following them")
    func redirectPolicy() async throws {
        let sourceURL = try #require(URL(string: "https://api.kickstart.tools/exchange/v1/sessions"))
        let targetURL = try #require(URL(string: "https://example.com/capture"))
        let response = try #require(HTTPURLResponse(
            url: sourceURL,
            statusCode: 307,
            httpVersion: "HTTP/1.1",
            headerFields: ["Location": targetURL.absoluteString]
        ))
        let task = URLSession.shared.dataTask(with: sourceURL)
        let redirectedRequest: URLRequest? = await withCheckedContinuation { continuation in
            ExchangeRedirectDelegate().urlSession(
                URLSession.shared,
                task: task,
                willPerformHTTPRedirection: response,
                newRequest: URLRequest(url: targetURL)
            ) { request in
                continuation.resume(returning: request)
            }
        }

        #expect(redirectedRequest == nil)
    }
}
