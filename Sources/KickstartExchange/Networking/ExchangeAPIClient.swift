//
// ExchangeAPIClient.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import Foundation

/// Performs session, advertisement, event, and report requests to the Exchange API.
struct ExchangeAPIClient: Sendable {
    /// The injectable transport operation used to execute an HTTP request.
    typealias Request = @Sendable (URLRequest) async throws -> (
        data: Data,
        statusCode: Int?,
        headers: [String: String]
    )

    static let previewAPIKey = "preview"
    static let sdkVersion = "0.5.0"

    private static let sharedURLSession = URLSession(
        configuration: makeURLSessionConfiguration(),
        delegate: ExchangeRedirectDelegate(),
        delegateQueue: nil
    )

    let apiKey: String
    let bundleIdentifier: String
    let appVersion: String
    let buildVersion: String
    let platform: ExchangePlatform
    let development: Bool
    let request: Request

    private let appTransaction: @Sendable () async -> String?

    @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
    init(
        apiKey: String,
        bundleIdentifier: String,
        appVersion: String,
        buildVersion: String,
        platform: ExchangePlatform,
        development: Bool
    ) {
        self.init(
            apiKey: apiKey,
            bundleIdentifier: bundleIdentifier,
            appVersion: appVersion,
            buildVersion: buildVersion,
            platform: platform,
            development: development,
            appTransaction: ExchangeAppTransactionEvidence.current,
            request: Self.performRequest
        )
    }

    init(
        apiKey: String,
        bundleIdentifier: String,
        appVersion: String,
        buildVersion: String,
        platform: ExchangePlatform,
        development: Bool,
        appTransaction: @escaping @Sendable () async -> String? = { nil },
        request: @escaping Request
    ) {
        self.apiKey = apiKey
        self.bundleIdentifier = bundleIdentifier
        self.appVersion = appVersion
        self.buildVersion = buildVersion
        self.platform = platform
        self.development = development
        self.appTransaction = appTransaction
        self.request = request
    }

    // Use an ephemeral session configuration and force disable
    // all caching and cookies for maximum privacy.
    static func makeURLSessionConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 30
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        return configuration
    }

    // MARK: - API operations

    func preview() async throws -> ExchangeServeResponse {
        try Task.checkCancellation()

        let response: (data: Data, statusCode: Int?, headers: [String: String])
        do {
            var request = URLRequest(
                url: ExchangeEndpoint.preview,
                cachePolicy: .reloadIgnoringLocalCacheData
            )
            request.httpMethod = "GET"
            response = try await self.request(request)
        } catch {
            try rethrowCancellation(error)
            throw ExchangeLoadFailure.advertRequest
        }

        try Task.checkCancellation()

        guard response.statusCode == 200 else {
            throw ExchangeLoadFailure.advertServiceResponse
        }

        do {
            let wire = try JSONDecoder().decode(WirePreviewResponse.self, from: response.data)
            return ExchangeServeResponse(
                serveID: wire.serveID,
                impressionToken: nil,
                ad: wire.ad
            )
        } catch {
            try rethrowCancellation(error)
            throw ExchangeLoadFailure.advertDecoding
        }
    }

    func serve(
        session: ExchangeSessionResponse,
        storefront: String? = nil
    ) async throws -> ExchangeServeResult {
        try Task.checkCancellation()
        if development == false, session.countsEnabled == false {
            return .rejected(reason: session.countingReason)
        }

        let response = try await requestServe(
            sessionToken: session.sessionToken,
            storefront: storefront
        )
        return try decodeServeResponse(response)
    }

    func submitImpression(token: String) async throws {
        let body = ExchangeImpressionRequest(impressionToken: token)

        let response: (data: Data, statusCode: Int?, headers: [String: String])
        do {
            response = try await post(body, to: ExchangeEndpoint.impressions)
        } catch {
            try rethrowCancellation(error)
            throw ExchangeImpressionDeliveryFailure.transport
        }

        try Task.checkCancellation()

        switch response.statusCode {
        case 204:
            return
        case let statusCode? where (500...599).contains(statusCode):
            throw ExchangeImpressionDeliveryFailure.server
        default:
            throw ExchangeImpressionDeliveryFailure.unexpectedResponse
        }
    }

    func submitClick(to url: URL) async throws -> URL {
        var clickRequest = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 2
        )
        clickRequest.httpMethod = "GET"

        let response = try await request(clickRequest)
        try Task.checkCancellation()

        guard response.statusCode == 302,
              let location = response.headers["location"],
              let destination = URL(string: location) else {
            throw ExchangeClickSubmissionFailure.unexpectedResponse
        }

        return destination
    }

    func submitReport(serveID: String, reason: ExchangeReportReason) async throws {
        let response = try await post(
            ExchangeReportRequest(serveID: serveID, reason: reason),
            to: ExchangeEndpoint.reports,
            timeoutInterval: 5
        )

        try Task.checkCancellation()

        guard response.statusCode == 204 else {
            throw ExchangeReportSubmissionFailure.unexpectedResponse
        }
    }

    func iconData(from url: URL) async throws -> Data {
        let response: (data: Data, statusCode: Int?, headers: [String: String])

        do {
            let request = URLRequest(
                url: url,
                cachePolicy: .reloadIgnoringLocalCacheData
            )
            response = try await self.request(request)
        } catch {
            try rethrowCancellation(error)
            throw ExchangeLoadFailure.artworkDownload
        }

        try Task.checkCancellation()

        guard response.statusCode == 200 else {
            throw ExchangeLoadFailure.artworkDownload
        }

        return response.data
    }

    /// Turns a rejection reason from Kickstart Exchange into something a
    /// developer can act on. Only ever printed in development builds.
    func explanation(for reason: String?) -> String {
        let advice = switch reason {
        case "unknown_api_key":
            "this API key was not recognized. Copy it again from the app's Overview page."
        case "bundle_id_mismatch":
            """
            this API key belongs to a different bundle identifier. This app is \
            \(bundleIdentifier); check you are using the right API key.
            """
        case "app_not_verified":
            "this app has not been verified yet. Finish verifying it on the app's Overview page."
        case "app_not_approved":
            "this app is waiting for approval. Adverts begin once it is approved."
        case "serving_paused":
            """
            you have paused showing adverts in this app. Resume them on the \
            app's Overview page to show adverts again.
            """
        case "app_suspended":
            "this app has been suspended by Kickstart Exchange. See the app's Overview page."
        case "app_removed":
            "this app has been removed from Kickstart Exchange."
        case "account_not_active":
            "this account is not active, so no adverts are served."
        case "app_transaction_unavailable":
            "App Transaction evidence was unavailable. Use a signed App Store build."
        case "verification_service_unavailable":
            "the App Transaction verification service is temporarily unavailable."
        case "app_transaction_invalid":
            "App Transaction evidence could not be verified."
        case "not_app_store_build":
            "this is not an App Store build, so advert accounting is disabled."
        case "app_identity_mismatch":
            "the verified App Transaction belongs to a different app."
        default:
            "no advert was returned. Check the app's Overview page on Kickstart Exchange."
        }

        return "No test advert shown – \(advice)"
    }

    // MARK: - Request construction

    func session() async throws -> ExchangeSessionResponse {
        let evidence: String?

        if development {
            evidence = nil
        } else if let value = await appTransaction(), value.isEmpty == false {
            evidence = value
        } else {
            evidence = nil
        }

        let body = ExchangeSessionRequest(
            apiKey: apiKey,
            bundleIdentifier: bundleIdentifier,
            platform: platform.rawValue,
            appVersion: appVersion,
            buildVersion: buildVersion,
            sdkVersion: Self.sdkVersion,
            development: development ? true : nil,
            appTransaction: evidence
        )

        let response: (data: Data, statusCode: Int?, headers: [String: String])

        do {
            response = try await post(body, to: ExchangeEndpoint.sessions)
        } catch {
            try rethrowCancellation(error)
            throw ExchangeLoadFailure.advertRequest
        }

        switch response.statusCode {
        case 204:
            throw ExchangeSessionRejection(
                reason: response.headers["x-exchange-reason"]
            )
        case 200:
            break
        default:
            throw ExchangeLoadFailure.advertServiceResponse
        }

        do {
            let wire = try JSONDecoder().decode(
                WireSessionResponse.self,
                from: response.data
            )

            guard wire.sessionToken.isEmpty == false else {
                throw ExchangeLoadFailure.advertDecoding
            }

            return ExchangeSessionResponse(
                sessionToken: wire.sessionToken,
                countsEnabled: wire.countsEnabled,
                countingReason: wire.countingReason
            )
        } catch let failure as ExchangeLoadFailure {
            throw failure
        } catch {
            throw ExchangeLoadFailure.advertDecoding
        }
    }

    private func post(
        _ body: some Encodable,
        to url: URL,
        bearerToken: String? = nil,
        timeoutInterval: TimeInterval? = nil
    ) async throws -> (data: Data, statusCode: Int?, headers: [String: String]) {
        var request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalCacheData
        )

        if let timeoutInterval {
            request.timeoutInterval = timeoutInterval
        }

        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let bearerToken {
            request.setValue(
                "Bearer \(bearerToken)",
                forHTTPHeaderField: "Authorization"
            )
        }

        return try await self.request(request)
    }

    private func requestServe(
        sessionToken: String,
        storefront: String?
    ) async throws -> (data: Data, statusCode: Int?, headers: [String: String]) {
        do {
            let response = try await post(
                ExchangeServeRequest(storefront: storefront),
                to: ExchangeEndpoint.serve,
                bearerToken: sessionToken
            )

            try Task.checkCancellation()
            return response
        } catch {
            try rethrowCancellation(error)
            throw ExchangeLoadFailure.advertRequest
        }
    }

    private func decodeServeResponse(
        _ response: (data: Data, statusCode: Int?, headers: [String: String])
    ) throws -> ExchangeServeResult {
        switch response.statusCode {
        case 204:
            return .rejected(reason: response.headers["x-exchange-reason"])
        case 200:
            break
        default:
            throw ExchangeLoadFailure.advertServiceResponse
        }

        do {
            let wire = try JSONDecoder().decode(
                WireServeResponse.self,
                from: response.data
            )

            guard wire.serveID.isEmpty == false,
                  wire.impressionToken.isEmpty == false else {
                throw ExchangeLoadFailure.advertDecoding
            }

            try Task.checkCancellation()

            return .advertisement(ExchangeServeResponse(
                serveID: wire.serveID,
                impressionToken: wire.impressionToken,
                ad: wire.ad
            ))
        } catch let failure as ExchangeLoadFailure {
            throw failure
        } catch {
            try rethrowCancellation(error)
            throw ExchangeLoadFailure.advertDecoding
        }
    }

    private func rethrowCancellation(_ error: any Error) throws {
        try Task.checkCancellation()

        if error is CancellationError
            || (error as? URLError)?.code == .cancelled {
            throw CancellationError()
        }
    }

    private static func performRequest(
        _ request: URLRequest
    ) async throws -> (data: Data, statusCode: Int?, headers: [String: String]) {
        let (data, response) = try await sharedURLSession.data(for: request)
        let http = response as? HTTPURLResponse
        var headers: [String: String] = [:]

        for (name, value) in http?.allHeaderFields ?? [:] {
            if let name = name as? String, let value = value as? String {
                headers[name.lowercased()] = value
            }
        }

        return (data, http?.statusCode, headers)
    }

}

/// Prevents URLSession from following redirects automatically.
final class ExchangeRedirectDelegate: NSObject,
    URLSessionTaskDelegate,
    @unchecked Sendable {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping @Sendable (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}

/// Decodes the raw session response returned by the Exchange API.
private struct WireSessionResponse: Decodable {
    let sessionToken: String
    let countsEnabled: Bool
    let countingReason: String?

    /// Maps the response properties to their Exchange API wire keys.
    enum CodingKeys: String, CodingKey {
        case sessionToken = "session_token"
        case countsEnabled = "counts_enabled"
        case countingReason = "counting_reason"
    }
}

/// Decodes a counted advertisement response from the Exchange API.
private struct WireServeResponse: Decodable {
    let serveID: String
    let impressionToken: String
    let ad: ExchangeServedAdResponse

    /// Maps the response properties to their Exchange API wire keys.
    enum CodingKeys: String, CodingKey {
        case serveID = "serve_id"
        case impressionToken = "impression_token"
        case ad
    }
}

/// Decodes a sample advertisement response from the preview endpoint.
private struct WirePreviewResponse: Decodable {
    let serveID: String?
    let ad: ExchangeServedAdResponse

    /// Maps the response properties to their Exchange API wire keys.
    enum CodingKeys: String, CodingKey {
        case serveID = "serve_id"
        case ad
    }
}
