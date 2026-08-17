//
// ExchangeAdRunStore.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

/// Shares advertisement acquisition and impression work across matching views.
@MainActor
final class ExchangeAdRunStore {
    static let shared = ExchangeAdRunStore()

    /// Stores shared state and in-flight work for one advertisement run.
    private struct Entry {
        let state: ExchangeAdRunState
        var acquisitionTask: Task<ExchangeAdRunResult, Never>?
        var result: ExchangeAdRunResult?
        var impressionTask: Task<Void, Never>?
    }

    private var entries: [ExchangeAdRunKey: Entry] = [:]

    func state(for key: ExchangeAdRunKey) -> ExchangeAdRunState {
        if let state = entries[key]?.state {
            return state
        }

        let entry = Entry(state: ExchangeAdRunState())
        entries[key] = entry
        return entry.state
    }

    func result(
        for key: ExchangeAdRunKey,
        acquire: @escaping @MainActor @Sendable () async -> ExchangeAdRunResult
    ) async -> ExchangeAdRunResult {
        if let result = entries[key]?.result {
            return result
        }

        if let acquisitionTask = entries[key]?.acquisitionTask {
            return await acquisitionTask.value
        }

        let acquisitionTask = Task { @MainActor in
            await acquire()
        }

        var entry = entries[key] ?? Entry(state: ExchangeAdRunState())
        entry.acquisitionTask = acquisitionTask
        entries[key] = entry

        let result = await acquisitionTask.value
        entry = entries[key] ?? Entry(state: ExchangeAdRunState())
        entry.acquisitionTask = nil
        entry.result = result
        entries[key] = entry
        return result
    }

    func hasStartedImpression(for key: ExchangeAdRunKey) -> Bool {
        entries[key]?.impressionTask != nil
    }

    @discardableResult
    func beginImpression(
        for key: ExchangeAdRunKey,
        deliver: @escaping @MainActor @Sendable () async -> Void
    ) -> Task<Void, Never>? {
        guard var entry = entries[key],
              entry.result != nil,
              entry.state.isSuppressed == false else {
            return nil
        }

        if let impressionTask = entry.impressionTask {
            return impressionTask
        }

        let impressionTask = Task { @MainActor in
            await deliver()
        }

        entry.impressionTask = impressionTask
        entries[key] = entry
        return impressionTask
    }
}
