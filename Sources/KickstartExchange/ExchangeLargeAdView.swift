//
// ExchangeLargeAdView.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import SwiftUI

/// A large, privacy-preserving Kickstart Exchange advertisement.
///
/// Place it inside scrolling content to run an advert between sections, or
/// present it with ``SwiftUICore/View/exchangeAdSheet(isPresented:apiKey:)`` or
/// ``SwiftUICore/View/exchangeAdFullScreenCover(isPresented:apiKey:)``, which
/// add a close action for you.
///
/// Every advert in one app process run shows the same advertised app and shares
/// a single impression, exactly like ``ExchangeBannerAdView``.
public struct ExchangeLargeAdView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.exchangeAdPlacement) private var placement
    @Environment(\.dismiss) private var dismiss
    @State private var model: ExchangeAdViewModel

    /// Creates a large Exchange advertisement for the current application
    /// bundle.
    ///
    /// Pass `"preview"` in a Debug build or the Simulator to load the
    /// server-provided sample advert without an Exchange account.
    public init(apiKey: String) {
        _model = State(initialValue: ExchangeAdViewModel(apiKey: apiKey))
    }

    /// Creates a deterministic large Exchange advertisement for previews.
    ///
    /// The preview uses only the supplied display data and a representative
    /// artwork palette. Its buttons are inert, and it performs no session,
    /// StoreKit, network, timer, or reporting work.
    public static func preview(
        appName: String,
        subtitle: String?,
        icon: Image
    ) -> some View {
        ExchangeLargeAdvertisementCard(
            appName: appName,
            subtitle: subtitle,
            icon: icon,
            palette: .preview,
            isStoreEnabled: true,
            showsCloseAction: false,
            openStore: {},
            showInformation: {},
            close: {}
        )
    }

    init(model: ExchangeAdViewModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack {
            if let presentation = model.visiblePresentation {
                ExchangeLargeAdvertisementCard(
                    appName: presentation.ad.name,
                    subtitle: presentation.ad.subtitle,
                    icon: Image(
                        decorative: presentation.icon,
                        scale: 1,
                        orientation: .up
                    ),
                    palette: presentation.palette,
                    isStoreEnabled: model.isOpeningStore == false,
                    showsCloseAction: placement == .presented,
                    openStore: {
                        Task { @MainActor in
                            if let storeURL = await model.recordClick() {
                                openURL(storeURL)
                            }
                        }
                    },
                    showInformation: model.showInformation,
                    close: { dismiss() }
                )
            }
        }
        .task {
            await model.load()
        }
        .onAppear {
            model.setSceneActive(scenePhase == .active)

            // A presented advert has no scroll view to report for it, so
            // appearing is the only visibility signal it will ever get.
            if placement == .presented {
                model.setPlacementVisible(true)
            }
        }
        .onDisappear {
            model.deactivate()
        }
        .onChange(of: scenePhase) { _, newPhase in
            model.setSceneActive(newPhase == .active)
        }
        .onScrollVisibilityChange(threshold: 0.5) { isVisible in
            guard placement == .inline else {
                return
            }

            model.setPlacementVisible(isVisible)
        }
        .sheet(
            isPresented: $model.isShowingInformation,
            onDismiss: model.informationSheetDidDismiss
        ) {
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

#Preview("Inline") {
    ScrollView {
        VStack {
            ForEach(0..<3, id: \.self) { index in
                Text("\(index) item")
            }

            ExchangeLargeAdView(apiKey: "preview")

            ForEach(3..<20, id: \.self) { index in
                Text("\(index) item")
            }
        }
        .padding()
    }
}

#Preview("Presented") {
    ExchangeLargeAdPresentation(apiKey: "preview")
}
