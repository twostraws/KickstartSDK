//
// ExchangeAppTransactionEvidence.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import StoreKit

/// Provides verified App Store transaction evidence for shipping builds.
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
