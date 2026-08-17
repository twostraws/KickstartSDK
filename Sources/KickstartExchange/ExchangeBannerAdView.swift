//
// ExchangeBannerAdView.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import SwiftUI

//
// Note to reader: Kickstart Exchange shows a simple banner ad.
// That's easy, right? That's what I thought too! Except you
// need to factor in reporting ads. And making it look and work
// well on all platforms. And making it open links correctly
// on platforms without WebKit. And supporting accessibility
// adjustments. And… and… and… yeah, it's a *lot*.
//
// Anyway, if you're reading this code and thinking this seems
// over-engineered at least or more complex than you expected,
// spare a thought for me going through every platform and
// every device variant, trying Dynamic Type variations,
// VoiceOver, Switch Control, dark/light mode, and more.
//

/// A fixed-format, privacy-preserving Kickstart Exchange banner advertisement.
public struct ExchangeBannerAdView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var model: ExchangeAdViewModel

    /// Creates an Exchange advertisement for the current application bundle.
    ///
    /// Pass `"preview"` in a Debug build or the Simulator to load the
    /// server-provided sample advert without an Exchange account.
    public init(apiKey: String) {
        _model = State(initialValue: ExchangeAdViewModel(apiKey: apiKey))
    }

    /// Creates a deterministic Exchange advertisement for previews.
    ///
    /// The preview uses only the supplied display data. Its buttons are inert,
    /// and it performs no session, StoreKit, network, timer, or reporting work.
    public static func preview(
        appName: String,
        subtitle: String?,
        icon: Image
    ) -> some View {
        ExchangeAdvertisementCard(
            appName: appName,
            subtitle: subtitle,
            icon: icon,
            isStoreEnabled: true,
            openStore: { },
            showInformation: { }
        )
    }
    init(model: ExchangeAdViewModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack {
            if let presentation = model.visiblePresentation {
                ExchangeAdvertisementCard(
                    appName: presentation.ad.name,
                    subtitle: presentation.ad.subtitle,
                    icon: Image(
                        decorative: presentation.icon,
                        scale: 1,
                        orientation: .up
                    ),
                    isStoreEnabled: model.isOpeningStore == false,
                    openStore: {
                        Task { @MainActor in
                            if let storeURL = await model.recordClick() {
                                openURL(storeURL)
                            }
                        }
                    },
                    showInformation: model.showInformation
                )
            }
        }
        .task {
            await model.load()
        }
        .onAppear {
            model.setSceneActive(scenePhase == .active)
        }
        .onDisappear {
            model.deactivate()
        }
        .onChange(of: scenePhase) { _, newPhase in
            model.setSceneActive(newPhase == .active)
        }
        .onScrollVisibilityChange(threshold: 0.5) { isVisible in
            model.setScrollVisible(isVisible)
        }
        .sheet(isPresented: $model.isShowingInformation, onDismiss: model.informationSheetDidDismiss) {
            if let presentation = model.informationPresentation {
                ExchangeAdvertisementInfoView(
                    presentation: presentation,
                    isPreview: model.isPreviewMode,
                    submitReport: model.submitReport
                )
            }
        }
    }
}
