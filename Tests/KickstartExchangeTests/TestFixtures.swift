//
// TestFixtures.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import Foundation
@testable import KickstartExchange

/// Provides reusable Exchange requests, responses, and sample values for tests.
enum TestFixtures {
    static let apiKey = "example-api-key"
    static let bundleIdentifier = "com.example.host"
    static let appVersion = "1.2.3"
    static let buildVersion = "45"
    static let sessionToken = "session-token"
    static let serveID = "serve-id"
    static let impressionToken = "impression-token"
    static let iconURL = "https://api.kickstart.tools/exchange/v1/artwork/icon.png"
    static let clickURL = "https://api.kickstart.tools/exchange/v1/clicks/click-token"
    static let storeURL = "https://apps.apple.com/app/id123456789?pt=123456&ct=KickstartExchange&mt=8"
    static let previewClickURL = "https://api.kickstart.tools/exchange/v1/preview/click"
    static let previewStoreURL = "https://apps.apple.com/app/id6758355178"

    static func client(
        handler: MockRequestHandler,
        development: Bool = false,
        platform: ExchangePlatform = .iOS,
        appTransaction: @escaping @Sendable () async -> String? = { nil }
    ) -> ExchangeAPIClient {
        ExchangeAPIClient(
            apiKey: apiKey,
            bundleIdentifier: bundleIdentifier,
            appVersion: appVersion,
            buildVersion: buildVersion,
            platform: platform,
            development: development,
            appTransaction: appTransaction,
            request: { request in
                try await handler.response(for: request)
            }
        )
    }

    static func response(
        data: Data,
        statusCode: Int = 200,
        headers: [String: String] = [:]
    ) -> MockRequestHandler.Response {
        (data, statusCode, headers)
    }

    static func sessionResponse(
        token: String = sessionToken,
        countsEnabled: Bool = true,
        countingReason: String? = nil
    ) -> Data {
        let reason = countingReason.map { "\"\($0)\"" } ?? "null"
        return Data(
            """
            {
              "session_token": "\(token)",
              "counts_enabled": \(countsEnabled),
              "counting_reason": \(reason)
            }
            """.utf8
        )
    }

    static func creativeResponse() -> Data {
        Data(
            """
            {
              "serve_id": "\(serveID)",
              "impression_token": "\(impressionToken)",
              "ad": {
                "name": "Example App",
                "subtitle": "A useful subtitle",
                "developer_name": "Example Developer",
                "icon_url": "\(iconURL)",
                "click_url": "\(clickURL)",
                "store_url": "\(storeURL)"
              }
            }
            """.utf8
        )
    }

    static func previewResponse() -> Data {
        Data(
            """
            {
              "serve_id": "preview",
              "ad": {
                "name": "Kickstart Exchange",
                "subtitle": "Test advert – it works!",
                "developer_name": "Kickstart Exchange",
                "icon_url": "\(iconURL)",
                "click_url": "\(previewClickURL)",
                "store_url": "\(previewStoreURL)"
              }
            }
            """.utf8
        )
    }

    static var completedImpressionResponse: MockRequestHandler.Response {
        response(data: Data(), statusCode: 204)
    }

    static var completedClickResponse: MockRequestHandler.Response {
        response(
            data: Data(),
            statusCode: 302,
            headers: ["location": storeURL]
        )
    }

    static var validPNG: Data {
        Data(
            base64Encoded: """
            iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=
            """
        ) ?? Data()
    }
}
