//
// DiagnosticRecorder.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

/// Collects development diagnostics for test assertions.
@MainActor
final class DiagnosticRecorder {
    private(set) var messages: [String] = []

    func record(_ message: String) {
        messages.append(message)
    }
}
