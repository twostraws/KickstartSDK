//
// ExchangeAdViewModel.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import Foundation
import ImageIO

/// Loads, presents, and records interactions for a single Exchange banner.
@MainActor
@Observable
final class ExchangeAdViewModel {
    private(set) var presentation: ExchangeAdPresentation?
    private(set) var informationPresentation: ExchangeAdPresentation?
    private(set) var isOpeningStore = false
    var isShowingInformation = false

    @ObservationIgnored private let client: ExchangeAPIClient?
    @ObservationIgnored private let initialLoadFailure: ExchangeLoadFailure?
    @ObservationIgnored private let storefront: @Sendable () async -> String?
    @ObservationIgnored private let isDevelopment: Bool
    @ObservationIgnored private let isPreview: Bool
    @ObservationIgnored private let impressionRetrySleep:
        @Sendable (TimeInterval) async throws -> Void
    @ObservationIgnored private let diagnosticHandler: @MainActor (String) -> Void
    @ObservationIgnored private let appRunStore: ExchangeAdRunStore
    @ObservationIgnored private let appRunKey: ExchangeAdRunKey?
    @ObservationIgnored private var appRunState: ExchangeAdRunState?
    @ObservationIgnored private var viewabilityTask: Task<Void, Never>?
    @ObservationIgnored private var sceneIsActive = false
    @ObservationIgnored private var isPlacementVisible = false

    init(apiKey: String) {
        storefront = { await ExchangeStorefront.current }
        isDevelopment = ExchangeEnvironment.isDevelopment
        isPreview = apiKey == ExchangeAPIClient.previewAPIKey

        impressionRetrySleep = { delay in
            try await Task.sleep(for: .seconds(delay))
        }

        diagnosticHandler = { print($0) }
        appRunStore = .shared

        guard apiKey.isEmpty == false else {
            client = nil
            initialLoadFailure = .missingAPIKey
            appRunKey = nil
            return
        }

        guard isPreview == false || isDevelopment else {
            client = nil
            initialLoadFailure = .previewUnavailable
            appRunKey = nil
            return
        }

        guard let bundleIdentifier = Bundle.main.bundleIdentifier,
            bundleIdentifier.isEmpty == false
        else {
            client = nil
            initialLoadFailure = .missingBundleIdentifier
            appRunKey = nil
            return
        }

        guard let appVersion = Self.bundleValue(named: "CFBundleShortVersionString"),
            let buildVersion = Self.bundleValue(named: "CFBundleVersion")
        else {
            client = nil
            initialLoadFailure = .missingApplicationVersion
            appRunKey = nil
            return
        }

        let platform = ExchangePlatform.current

        let client = ExchangeAPIClient(
            apiKey: apiKey,
            bundleIdentifier: bundleIdentifier,
            appVersion: appVersion,
            buildVersion: buildVersion,
            platform: platform,
            development: isDevelopment
        )

        self.client = client
        initialLoadFailure = nil

        let appRunKey = ExchangeAdRunKey(
            apiKey: apiKey,
            bundleIdentifier: bundleIdentifier,
            platform: platform,
            development: isDevelopment
        )

        self.appRunKey = appRunKey
        appRunState = appRunStore.state(for: appRunKey)
    }

    init(
        apiKey: String,
        bundleIdentifier: String?,
        appVersion: String? = "1.2.3",
        buildVersion: String? = "45",
        platform: ExchangePlatform = .iOS,
        request: @escaping ExchangeAPIClient.Request,
        storefront: @escaping @Sendable () async -> String? = { nil },
        isDevelopment: Bool = ExchangeEnvironment.isDevelopment,
        appTransaction: @escaping @Sendable () async -> String? = { nil },
        impressionRetrySleep: @escaping @Sendable (TimeInterval) async throws -> Void = { delay in
            try await Task.sleep(for: .seconds(delay))
        },
        appRunStore: ExchangeAdRunStore = ExchangeAdRunStore(),
        diagnosticHandler: @escaping @MainActor (String) -> Void = { print($0) }
    ) {
        self.storefront = storefront
        self.isDevelopment = isDevelopment
        isPreview = apiKey == ExchangeAPIClient.previewAPIKey
        self.impressionRetrySleep = impressionRetrySleep
        self.appRunStore = appRunStore
        self.diagnosticHandler = diagnosticHandler

        guard apiKey.isEmpty == false else {
            client = nil
            initialLoadFailure = .missingAPIKey
            appRunKey = nil
            return
        }

        guard isPreview == false || isDevelopment else {
            client = nil
            initialLoadFailure = .previewUnavailable
            appRunKey = nil
            return
        }

        guard let bundleIdentifier, bundleIdentifier.isEmpty == false else {
            client = nil
            initialLoadFailure = .missingBundleIdentifier
            appRunKey = nil
            return
        }

        guard let appVersion, appVersion.isEmpty == false,
            let buildVersion, buildVersion.isEmpty == false
        else {
            client = nil
            initialLoadFailure = .missingApplicationVersion
            appRunKey = nil
            return
        }

        let client = ExchangeAPIClient(
            apiKey: apiKey,
            bundleIdentifier: bundleIdentifier,
            appVersion: appVersion,
            buildVersion: buildVersion,
            platform: platform,
            development: isDevelopment,
            appTransaction: appTransaction,
            request: request
        )

        self.client = client
        initialLoadFailure = nil

        let appRunKey = ExchangeAdRunKey(
            apiKey: apiKey,
            bundleIdentifier: bundleIdentifier,
            platform: platform,
            development: isDevelopment
        )

        self.appRunKey = appRunKey
        appRunState = appRunStore.state(for: appRunKey)
    }

    func deactivate() {
        stopViewabilityTimer()
        sceneIsActive = false
        isPlacementVisible = false
        isShowingInformation = false
        informationPresentation = nil
    }

    func setSceneActive(_ isActive: Bool) {
        sceneIsActive = isActive
        reevaluateViewability()
    }

    func setPlacementVisible(_ isVisible: Bool) {
        isPlacementVisible = isVisible
        reevaluateViewability()
    }

    var isPreviewMode: Bool {
        isPreview
    }

    var visiblePresentation: ExchangeAdPresentation? {
        guard appRunState?.isSuppressed != true else {
            return nil
        }

        return presentation
    }

    func showInformation() {
        guard let visiblePresentation else {
            return
        }

        informationPresentation = visiblePresentation
        isShowingInformation = true
        reevaluateViewability()
    }

    func informationSheetDidDismiss() {
        isShowingInformation = false
        informationPresentation = nil
        reevaluateViewability()
    }

    func recordClick() async -> URL? {
        guard isOpeningStore == false,
            let presentation = visiblePresentation
        else {
            return nil
        }

        isOpeningStore = true
        defer { isOpeningStore = false }

        stopViewabilityTimer()
        _ = beginImpression()

        let redirectDestination: URL?

        if let client {
            redirectDestination = try? await client.submitClick(to: presentation.ad.clickURL)
        } else {
            redirectDestination = nil
        }

        return presentation.ad.storeURL ?? redirectDestination
    }

    func submitReport(reason: ExchangeReportReason) async -> Bool {
        guard isDevelopment == false || isPreview,
            let client,
            let informationPresentation,
            let serveID = informationPresentation.serveID,
            let appRunState,
            appRunState.isSuppressed == false
        else {
            return false
        }

        do {
            try await client.submitReport(
                serveID: serveID,
                reason: reason
            )

            appRunState.suppress()
            stopViewabilityTimer()
            return true
        } catch {
            return false
        }
    }

    func load() async {
        if presentation != nil {
            reevaluateViewability()
            return
        }

        guard let appRunKey else {
            await reportInitialLoadFailure()
            return
        }

        let result = await appRunStore.result(for: appRunKey) {
            await self.acquireAdvertisement()
        }

        guard Task.isCancelled == false else {
            return
        }

        switch result {
            case .unavailable:
                return
            case .advertisement(let presentation):
                self.presentation = presentation
                reevaluateViewability()
        }
    }

    private func reportInitialLoadFailure() async {
        do {
            try Task.checkCancellation()

            guard client != nil else {
                throw initialLoadFailure ?? .missingBundleIdentifier
            }
        } catch is CancellationError {
            // Cancellation is an expected lifecycle event and stays quiet.
        } catch let failure as ExchangeLoadFailure {
            report(failure.diagnosticMessage)
        } catch {
            // Invalid host configuration deliberately collapses without retrying.
        }
    }

    private func acquireAdvertisement() async -> ExchangeAdRunResult {
        do {
            try Task.checkCancellation()

            guard let client else {
                throw initialLoadFailure ?? .missingBundleIdentifier
            }

            let response: ExchangeServeResponse

            if isPreview {
                response = try await client.preview()
            } else {
                async let session = client.session()
                async let currentStorefront = storefront()
                let activeSession = try await session
                let resolvedStorefront = await currentStorefront
                try Task.checkCancellation()

                let serveResult = try await client.serve(
                    session: activeSession,
                    storefront: resolvedStorefront
                )

                try Task.checkCancellation()

                switch serveResult {
                    case .advertisement(let advertisement):
                        response = advertisement
                    case .rejected(let reason):
                        report(client.explanation(for: reason))
                        return .unavailable
                }
            }

            let data = try await client.iconData(from: response.ad.iconURL)
            try Task.checkCancellation()

            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                let icon = CGImageSourceCreateImageAtIndex(source, 0, nil)
            else {
                throw ExchangeLoadFailure.artworkDownload
            }

            try Task.checkCancellation()

            let presentation = ExchangeAdPresentation(
                serveID: response.serveID,
                impressionToken: response.impressionToken,
                ad: response.ad,
                icon: icon
            )

            return .advertisement(presentation)
        } catch is CancellationError {
            // Cancellation is an expected lifecycle event and stays quiet.
        } catch let rejection as ExchangeSessionRejection {
            if let client {
                report(client.explanation(for: rejection.reason))
            }
        } catch let failure as ExchangeLoadFailure {
            report(failure.diagnosticMessage)
        } catch {
            // A failed request deliberately collapses without retrying.
        }

        return .unavailable
    }

    private func report(_ message: String) {
        guard isDevelopment || isPreview, Task.isCancelled == false else {
            return
        }

        diagnosticHandler(ExchangeEnvironment.formattedDiagnostic(message))
    }

    private func reevaluateViewability() {
        guard presentation != nil else {
            stopViewabilityTimer()
            return
        }

        guard qualifiesForImpression,
            let appRunKey,
            appRunStore.hasStartedImpression(for: appRunKey) == false
        else {
            stopViewabilityTimer()
            return
        }

        guard viewabilityTask == nil else {
            return
        }

        viewabilityTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                return
            }

            guard Task.isCancelled == false,
                let self,
                qualifiesForImpression
            else {
                return
            }

            viewabilityTask = nil
            _ = beginImpression()
        }
    }

    private var qualifiesForImpression: Bool {
        sceneIsActive
            && isPlacementVisible
            && isShowingInformation == false
            && presentation?.impressionToken != nil
            && visiblePresentation != nil
    }

    @discardableResult
    private func beginImpression() -> Task<Void, Never>? {
        guard let appRunKey,
            let client,
            let impressionToken = presentation?.impressionToken
        else {
            return nil
        }

        let impressionRetrySleep = impressionRetrySleep
        let isDevelopment = isDevelopment
        let diagnosticHandler = diagnosticHandler

        return appRunStore.beginImpression(for: appRunKey) {
            let retryDelays: [TimeInterval] = [0.25, 1]

            for attempt in 0...retryDelays.count {
                guard Task.isCancelled == false else {
                    return
                }

                do {
                    try await client.submitImpression(token: impressionToken)
                    return
                } catch is CancellationError {
                    return
                } catch let failure as ExchangeImpressionDeliveryFailure
                    where failure == .transport || failure == .server
                {
                    guard attempt < retryDelays.count else {
                        break
                    }

                    let delay = retryDelays[attempt]

                    do {
                        try await impressionRetrySleep(delay)
                    } catch {
                        return
                    }
                } catch {
                    break
                }
            }

            if isDevelopment, Task.isCancelled == false {
                diagnosticHandler(
                    ExchangeEnvironment.formattedDiagnostic(
                        "The test ad impression could not be recorded. Check the network connection and reload the test ad."
                    ))
            }
        }
    }

    private func stopViewabilityTimer() {
        viewabilityTask?.cancel()
        viewabilityTask = nil
    }

    private static func bundleValue(named name: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: name) as? String,
            value.isEmpty == false
        else {
            return nil
        }

        return value
    }

}
