//
// ExchangeClickSubmissionFailure.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

/// Identifies failures while recording an advertisement click.
enum ExchangeClickSubmissionFailure: Error, Sendable {
    case unexpectedResponse
}
