//
// WireContractTests.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import Foundation
import Testing
@testable import KickstartExchange

/// Verifies the SDK remains compatible with the shared Exchange API contract.
@Suite("Exchange wire contract")
struct WireContractTests {
    @Test("SDK endpoints and response fields match the shared contract")
    func sharedContract() throws {
        let fixtureURL = try #require(Bundle.module.url(
            forResource: "exchange-v1-contract",
            withExtension: "json"
        ))
        let object = try JSONSerialization.jsonObject(with: Data(contentsOf: fixtureURL))
        let contract = try #require(object as? [String: Any])
        let operations = try #require(contract["operations"] as? [String: Any])

        #expect(try path(for: "preview", in: operations) == ExchangeEndpoint.preview.path)
        let previewClickURL = try #require(URL(string: TestFixtures.previewClickURL))
        #expect(try path(for: "preview_click", in: operations) == previewClickURL.path)
        #expect(try path(for: "session", in: operations) == ExchangeEndpoint.sessions.path)
        #expect(try path(for: "serve", in: operations) == ExchangeEndpoint.serve.path)
        #expect(try path(for: "impression", in: operations) == ExchangeEndpoint.impressions.path)
        #expect(try path(for: "report", in: operations) == ExchangeEndpoint.reports.path)

        let previewFields = try schemaFields(for: "preview", in: operations)
        #expect(previewFields == ["serve_id", "ad"])
        let preview = try operation("preview", in: operations)
        let previewSuccess = try #require(preview["success"] as? [String: Any])
        let previewSchema = try #require(previewSuccess["schema"] as? [String: Any])
        let previewAd = try #require(previewSchema["ad"] as? [String: Any])
        #expect(Set(previewAd.keys) == [
            "name", "subtitle", "developer_name", "icon_url", "click_url", "store_url"
        ])

        let sessionFields = try schemaFields(for: "session", in: operations)
        #expect(sessionFields == ["session_token", "counts_enabled", "counting_reason"])

        let serveFields = try schemaFields(for: "serve", in: operations)
        #expect(serveFields == ["serve_id", "impression_token", "ad"])
        let serve = try operation("serve", in: operations)
        let success = try #require(serve["success"] as? [String: Any])
        let schema = try #require(success["schema"] as? [String: Any])
        let ad = try #require(schema["ad"] as? [String: Any])
        #expect(Set(ad.keys) == [
            "name", "subtitle", "developer_name", "icon_url", "click_url", "store_url"
        ])

        let clickTemplate = try path(for: "click", in: operations)
        let clickURL = try #require(URL(string: TestFixtures.clickURL))
        #expect(
            clickTemplate.replacing("{click_token}", with: clickURL.lastPathComponent)
                == clickURL.path
        )
    }

    private func operation(
        _ name: String,
        in operations: [String: Any]
    ) throws -> [String: Any] {
        try #require(operations[name] as? [String: Any])
    }

    private func path(for name: String, in operations: [String: Any]) throws -> String {
        let operation = try operation(name, in: operations)
        return try #require(operation["path"] as? String)
    }

    private func schemaFields(
        for name: String,
        in operations: [String: Any]
    ) throws -> Set<String> {
        let operation = try operation(name, in: operations)
        let success = try #require(operation["success"] as? [String: Any])
        let schema = try #require(success["schema"] as? [String: Any])
        return Set(schema.keys)
    }
}
