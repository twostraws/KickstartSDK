<p align="center">
    <img src="Assets/logo.svg" alt="Kickstart SDK logo" width="600" />
</p>

<p align="center">
    <img src="https://img.shields.io/badge/iOS-18.0+-27ae60.svg" alt="iOS 18.0 or later" />
    <img src="https://img.shields.io/badge/macOS-15.0+-2980b9.svg" alt="macOS 15.0 or later" />
    <img src="https://img.shields.io/badge/tvOS-18.0+-8e44ad.svg" alt="tvOS 18.0 or later" />
    <img src="https://img.shields.io/badge/watchOS-11.0+-c0392b.svg" alt="watchOS 11.0 or later" />
    <img src="https://img.shields.io/badge/visionOS-2.0+-e67e22.svg" alt="visionOS 2.0 or later" />
</p>

KickstartSDK is the Swift package for [Kickstart Exchange](https://exchange.kickstart.tools), which is a free cross-promotion service for independent Apple platform apps.

Kickstart Exchange was designed for maximum user privacy. It matches apps, not people, and does not track users or devices – see the [privacy notice](https://exchange.kickstart.tools/privacy) for full details.

The package requires Xcode 26, and supports iOS 18, iPadOS 18, macOS 15, tvOS 18, watchOS 11, and visionOS 2 or later. It has no dependencies and is licensed under the MIT License.

## Installation

Add `https://github.com/twostraws/KickstartSDK` in Xcode, then link the `KickstartExchange` product to your app target.

**Tip:** Link KickstartExchange only to a main app binary – Apple's review guidelines prohibit using it on extensions such as widgets or App Clips.

You can try the live, server-provided sample advert without creating an account, to see how it might look in your app:

```swift
ExchangeBannerAdView(apiKey: "preview")
```

The reserved `preview` key works only in Debug builds and the Simulator. It creates no application session, records no impressions, clicks, or reports, and shows nothing in shipping builds.

When you’re ready to integrate Exchange, visit <https://exchange.kickstart.tools>, create a free account, then register your app to get an API key. You can place it in your binary directly, like this:

```swift
import KickstartExchange
import SwiftUI

/// Displays a Kickstart Exchange banner beneath the app's settings.
struct SettingsFooter: View {
    var body: some View {
        ExchangeBannerAdView(apiKey: "ks_live_REPLACE_WITH_API_KEY")
    }
}
```

You're welcome to disable Kickstart Exchange at any time, including if users buy a "Remove Ads" in-app purchase. For example, you might add custom logic like this:

```swift
if hasPremiumAccess == false {
    ExchangeBannerAdView(apiKey: "ks_live_REPLACE_WITH_API_KEY")
}
```

Real adverts are shown automatically when your app goes live. **Note:** Simulator doesn’t support previewing App Store links.

## Previewing and styling

You can preview banner ads in Xcode like this:

```swift
#Preview {
    ExchangeBannerAdView.preview(
        appName: "Example App",
        subtitle: "Example subtitle",
        icon: Image("ExampleIcon")
    )
}
```

Four modifiers adjust the card's presentation:

```swift
ExchangeBannerAdView(apiKey: "ks_live_REPLACE_WITH_API_KEY")
    .exchangeAdCornerStyle(.rounded)
    .exchangeAdStroke(.orange)
    .exchangeAdActionTextColor(.orange)
    .exchangeAdDisclosureBackgroundColor(.purple)
```

- `exchangeAdCornerStyle(_:)`: `.square` or `.rounded`. Both preserve the advertised app
  icon's standard rounding.
- `exchangeAdStroke(_:)`: sets the card's stroke color. The stroke is always one point wide.
- `exchangeAdActionTextColor(_:)`: sets the App Store action button's text color.
- `exchangeAdDisclosureBackgroundColor(_:)`: sets the ad disclosure button's background color.

Like other SwiftUI modifiers these flow down through the environment, so applying them to a container styles every card inside it.

## Large adverts

`ExchangeLargeAdView` shows the same advert as a large card: the ad disclosure in one corner, the app icon, name, and subtitle stacked in the middle, and the App Store action at the bottom. Its background is built from the advertised app's icon, sampled down to a small grid and used as a mesh gradient, so the card is themed to the artwork without ever showing a recognisable copy of it. Every sampled color is conditioned for the current color scheme before it is used, so the text on top stays legible whatever the icon looks like.

Place it inside scrolling content to run an advert between sections, exactly like the banner:

```swift
List {
    Section("Latest") {
        // your content
    }

    Section {
        ExchangeLargeAdView(apiKey: "ks_live_REPLACE_WITH_API_KEY")
    }
}
```

Or present it, which adds a close action so people can always leave:

```swift
.exchangeAdSheet(isPresented: $isShowingAd, apiKey: "ks_live_REPLACE_WITH_API_KEY")
.exchangeAdFullScreenCover(isPresented: $isShowingAd, apiKey: "ks_live_REPLACE_WITH_API_KEY")
```

`exchangeAdFullScreenCover(isPresented:apiKey:)` falls back to a sheet on macOS, which has no full screen cover of its own. A presented advert fills its sheet or cover edge to edge, with the artwork running under the safe areas and the content inset clear of them, so it takes its shape from the presentation rather than drawing a card of its own – `exchangeAdCornerStyle(_:)` and `exchangeAdStroke(_:)` therefore apply only to inline adverts. The remaining styling modifiers apply to both.

Unlike the banner, a large advert is not tappable as a whole – only its Get button opens the App Store, so a mistimed tap near the close button cannot send someone to the store by accident.


**Important:** This SDK is released under the MIT License, so you are free to inspect, modify, and redistribute it, including as part of your own service. However, only unmodified versions of this SDK may connect to the official Kickstart Exchange service. Modified versions may be blocked, and apps using them may be removed from Kickstart Exchange.

## Testing your integration

Debug builds and the Simulator automatically ask Kickstart Exchange for a *test advert*: a real response from the live service, so seeing the card is proof your API key, bundle identifier, and network path all work. Test adverts charge nobody, earn nothing, and are never counted in analytics, and they work even before Kickstart Exchange begins serving.

If no card appears while testing, or if the SDK cannot record a test ad impression, check Xcode's debug console for errors explaining what failed and what to try next. For shipping builds, check the Integration card in the Exchange dashboard.

## Example app

`KickstartSDK.xcworkspace` contains the package alongside a small iOS example app in `Example/`. Open the workspace, choose the **KickstartExchangeExample** scheme, and run it in the Simulator to see each placement without an Exchange account – every screen uses the `preview` API key, so the adverts you see are test adverts that charge nobody.

The example covers pinning a banner beneath your content, placing one between rows of a scrolling list so you can watch viewability tracking decide when the card has really been seen, and applying each styling modifier.

## Privacy and data flow

In shipping builds, the SDK asks `AppTransaction.shared` for a locally verified Apple-signed App Transaction and sends its JWS only to the application-session endpoint, to verify it’s a real app install. It never prompts for App Store sync.

Kickstart Exchange doesn’t retain, hash, log, correlate, target with, or analyze these values, and the SDK does not persist the JWS. After that transient verification, the application session contains no user or device identity – it's as private as we can make it.

For details about information processed by Kickstart Exchange and how long it is retained, see the [Kickstart Exchange privacy notice](https://exchange.kickstart.tools/privacy). Exchange keeps app-level advert delivery and interaction records for approximately 30 days. These records do not identify individual users or devices.

The SDK sends app-level details including the API key, bundle identifier, platform, app and build versions, SDK version, App Store country, development mode when applicable, and the optional signed evidence described above. Platform and storefront are app-level compatibility and accounting data, not identifiers for a specific person or device – we just need to be sure we can recommend apps the user can actually install.

During one app process run, every `ExchangeBannerAdView` and `ExchangeLargeAdView` for the same app integration reuses the first advert result and one shared impression-delivery sequence. **Moving between screens does not request replacement adverts or create additional impressions.**

When someone taps an advert, the SDK records the click then opens the direct `apps.apple.com` destination supplied with the advert.

If the advertiser has added an App Store Connect provider token, that App Store destination also contains Apple's provider token and the `KickstartExchange` campaign token. Apple may show the advertiser privacy-protected campaign results such as product-page views, downloads, usage, sales, and subscriptions, but that's all handled by Apple through App Store Connect – Kickstart Exchange does not receive those App Store conversion details.

## App Store privacy disclosure

The included privacy manifest declares **Usage Data: Product Interaction** and **Usage Data: Advertising Data** for Third-Party Advertising, Developer's Advertising or Marketing, Analytics, and App Functionality – please make sure these are both declared on App Store Connect, in addition to any other privacy settings for your app. Both data types are unlinked from identity and are not used for tracking.

App developers remain responsible for disclosing everything collected by their app and every other integrated SDK. Please follow the [exact App Store Connect steps](https://exchange.kickstart.tools/guide#app-privacy), keep any additional disclosures your app requires, and provide your own complete privacy policy that mentions and links to Kickstart Exchange.

## Contributing

We welcome all contributions, whether that's fixing up existing code, adding comments, or improving this README – everyone is welcome!

- You must comment your code thoroughly, using documentation comments or regular comments as applicable.
- All code must be licensed under the MIT license so it can benefit the most people.
- Please ensure SwiftLint runs cleanly with no violations.

## License

MIT License.

Copyright (c) 2026 Paul Hudson.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
