//
// ExchangeStorefront.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import Foundation
import StoreKit

/// The App Store storefront country of the device's store account.
///
/// Kickstart Exchange uses this to keep adverts inside the countries their
/// developers chose, and to report country-level analytics. It is the country
/// of the store account, a fact shared by millions of accounts, never a
/// location or an identifier of the device or person.
enum ExchangeStorefront {
    /// The current storefront's ISO alpha-3 country code, such as "GBR", or
    /// nil when the device has no signed-in store account.
    static var current: String? {
        get async {
            await Storefront.current?.countryCode
        }
    }
}
