//
// RequestMilestone.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

/// Marks when a numbered mock request starts or finishes.
enum RequestMilestone: Equatable, Sendable {
    case started(Int)
    case finished(Int)
}
