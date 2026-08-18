//
// ExchangeAppTransactionEvidence.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import StoreKit

/// Provides verified App Store transaction evidence for shipping builds.
@available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
enum ExchangeAppTransactionEvidence {
    static func current() async -> String? {
        #if DEBUG || targetEnvironment(simulator)
        nil
        #else
        do {
            let result = try await AppTransaction.shared
            guard case .verified = result else {
                return nil
            }

            let representation = result.jwsRepresentation
            return representation.isEmpty ? nil : representation
        } catch {
            return nil
        }
        #endif
    }
}
