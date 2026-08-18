//
// PrivacyManifestTests.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import Foundation
import Testing

/// Verifies the SDK privacy manifest declares its exact data practices.
@Suite("Privacy manifest")
struct PrivacyManifestTests {
    @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
    @Test("The manifest declares the exact Exchange data types and purposes")
    func exactDataTypesAndPurposes() throws {
        let packageRoot = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let manifestURL = packageRoot
            .appending(path: "Sources/KickstartExchange/Resources/PrivacyInfo.xcprivacy")
        let data = try Data(contentsOf: manifestURL)
        let propertyList = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        )
        let manifest = try #require(propertyList as? [String: Any])

        let expectedRootKeys: Set<String> = [
            "NSPrivacyTracking",
            "NSPrivacyCollectedDataTypes"
        ]
        #expect(Set(manifest.keys) == expectedRootKeys)
        #expect(manifest["NSPrivacyTracking"] as? Bool == false)
        #expect(manifest["NSPrivacyTrackingDomains"] == nil)
        #expect(manifest["NSPrivacyAccessedAPITypes"] == nil)

        let expectedTypes: Set<String> = [
            "NSPrivacyCollectedDataTypeProductInteraction",
            "NSPrivacyCollectedDataTypeAdvertisingData"
        ]
        let expectedPurposes: Set<String> = [
            "NSPrivacyCollectedDataTypePurposeThirdPartyAdvertising",
            "NSPrivacyCollectedDataTypePurposeDeveloperAdvertising",
            "NSPrivacyCollectedDataTypePurposeAnalytics",
            "NSPrivacyCollectedDataTypePurposeAppFunctionality"
        ]
        let expectedDeclarationKeys: Set<String> = [
            "NSPrivacyCollectedDataType",
            "NSPrivacyCollectedDataTypeLinked",
            "NSPrivacyCollectedDataTypeTracking",
            "NSPrivacyCollectedDataTypePurposes"
        ]
        let declarations = try #require(
            manifest["NSPrivacyCollectedDataTypes"] as? [[String: Any]]
        )
        var declaredTypes = Set<String>()

        for declaration in declarations {
            #expect(Set(declaration.keys) == expectedDeclarationKeys)
            let dataType = try #require(
                declaration["NSPrivacyCollectedDataType"] as? String
            )
            declaredTypes.insert(dataType)
            #expect(declaration["NSPrivacyCollectedDataTypeLinked"] as? Bool == false)
            #expect(declaration["NSPrivacyCollectedDataTypeTracking"] as? Bool == false)

            let purposes = try #require(
                declaration["NSPrivacyCollectedDataTypePurposes"] as? [String]
            )
            #expect(Set(purposes) == expectedPurposes)
            #expect(purposes.count == expectedPurposes.count)
        }

        #expect(declarations.count == expectedTypes.count)
        #expect(declaredTypes == expectedTypes)
    }
}
