//
// ExchangeLoadFailure.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

/// Describes why an advertisement could not be loaded.
enum ExchangeLoadFailure: Error, Sendable {
    case missingAPIKey
    case previewUnavailable
    case missingBundleIdentifier
    case missingApplicationVersion
    case advertRequest
    case advertServiceResponse
    case advertDecoding
    case artworkDownload

    var diagnosticMessage: String {
        switch self {
        case .missingAPIKey:
            "A test ad could not be loaded because the API key is empty. Copy it again from the app's Overview page."
        case .previewUnavailable:
            """
            The preview key is available only in Debug builds and the Simulator. \
            Use a live API key in shipping builds.
            """
        case .missingBundleIdentifier:
            """
            A test ad could not be loaded because the host app has no bundle identifier. \
            Set the app target's product bundle identifier.
            """
        case .missingApplicationVersion:
            """
            A test ad could not be loaded because the host app has no version or build number. \
            Set both values in the app target.
            """
        case .advertRequest:
            "The test ad request failed. Check the network connection and try again."
        case .advertServiceResponse:
            "The advertisement service returned an unexpected response. Try again or update KickstartSDK."
        case .advertDecoding:
            "The test ad response could not be decoded. Update KickstartSDK and try again."
        case .artworkDownload:
            "The test ad artwork could not be downloaded. Try again."
        }
    }
}
