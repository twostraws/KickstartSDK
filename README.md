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

KickstartSDK contains two independent library products for Apple platform apps: [Kickstart Exchange](https://exchange.kickstart.tools) for free cross-promotion, and Kickstart Signal for feature requests and developer-reviewed feedback.

Kickstart Exchange and Signal were designed for maximum user privacy. Exchange matches apps, not people, and does not track users or devices. Signal supports anonymous feedback without requiring a Signal account or tracking people across apps. See the [Exchange privacy notice](https://exchange.kickstart.tools/privacy) and [Signal privacy notice](https://signal.kickstart.tools/privacy) for full details.

The package requires Swift 6.2 (Xcode 26) or later, has no dependencies, and is licensed under the MIT License.

## Kickstart Exchange

Promote your app for free by showing native banner ads for other participating apps. Exchange matches apps based on relevance, without tracking people.

### Installing Kickstart Exchange

Add `https://github.com/twostraws/KickstartSDK` in Xcode, then link the `KickstartExchange` product to your app target.

**Tip:** Link KickstartExchange only to a main app binary – Apple's review guidelines prohibit using it on extensions such as widgets or App Clips.

To integrate Exchange, visit <https://exchange.kickstart.tools>, create a free account, then register your app to get an API key. You can place it in your binary directly, like this:

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

If the app’s minimum OS version is below the supported versions, gate the same call:

```swift
if #available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *) {
    ExchangeBannerAdView(apiKey: "ks_live_REPLACE_WITH_API_KEY")
}
```

Real adverts are shown automatically when your app goes live. **Note:** Simulator doesn’t support previewing App Store links.

### Previewing and styling Exchange

You can try the live, server-provided sample advert without creating an account, to see how it might look in your app:

```swift
ExchangeBannerAdView(apiKey: "preview")
```

The reserved `preview` key works only in Debug builds and the Simulator. It creates no application session, records no impressions, clicks, or reports, and shows nothing in shipping builds.

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

Five modifiers adjust the card's presentation:

```swift
ExchangeBannerAdView(apiKey: "ks_live_REPLACE_WITH_API_KEY")
    .exchangeAdCornerStyle(.rounded)
    .exchangeAdStroke(.orange)
    .exchangeAdBackground(.white)
    .exchangeAdActionTextColor(.orange)
    .exchangeAdDisclosureBackgroundColor(.purple)
```

- `exchangeAdCornerStyle(_:)`: `.square` or `.rounded`. Both preserve the advertised app
  icon's standard rounding.
- `exchangeAdStroke(_:)`: sets the card's stroke color. The stroke is always one point wide.
- `exchangeAdBackground(_:)`: sets the card's background color. Defaults to the system
  window background, and has no effect on visionOS, where cards use a glass background.
- `exchangeAdActionTextColor(_:)`: sets the App Store action button's text color.
- `exchangeAdDisclosureBackgroundColor(_:)`: sets the ad disclosure button's background color.

Like other SwiftUI modifiers these flow down through the environment, so applying them to a container styles every card inside it.

### Testing your Exchange integration

Debug builds and the Simulator automatically ask Kickstart Exchange for a *test advert*: a real response from the live service, so seeing the card is proof your API key, bundle identifier, and network path all work. Test adverts charge nobody, earn nothing, and are never counted in analytics, and they work even before Kickstart Exchange begins serving.

If no card appears while testing, or if the SDK cannot record a test ad impression, check Xcode's debug console for errors explaining what failed and what to try next. For shipping builds, check the Integration card in the Exchange dashboard.

### Exchange privacy and data flow

In shipping builds, the SDK asks `AppTransaction.shared` for a locally verified Apple-signed App Transaction and sends its JWS only to the application-session endpoint, to verify it’s a real app install. It never prompts for App Store sync.

Kickstart Exchange doesn’t retain, hash, log, correlate, target with, or analyze these values, and the SDK does not persist the JWS. After that transient verification, the application session contains no user or device identity – it's as private as we can make it.

For details about information processed by Kickstart Exchange and how long it is retained, see the [Kickstart Exchange privacy notice](https://exchange.kickstart.tools/privacy). Exchange keeps app-level advert delivery and interaction records for approximately 30 days. These records do not identify individual users or devices.

The SDK sends app-level details including the API key, bundle identifier, platform, app and build versions, SDK version, App Store country, development mode when applicable, and the optional signed evidence described above. Platform and storefront are app-level compatibility and accounting data, not identifiers for a specific person or device – we just need to be sure we can recommend apps the user can actually install.

During one app process run, every `ExchangeBannerAdView` for the same app integration reuses the first advert result and one shared impression-delivery sequence. **Moving between screens does not request replacement adverts or create additional impressions.**

When someone taps an advert, the SDK records the click then opens the direct `apps.apple.com` destination supplied with the advert.

If the advertiser has added an App Store Connect provider token, that App Store destination also contains Apple's provider token and the `KickstartExchange` campaign token. Apple may show the advertiser privacy-protected campaign results such as product-page views, downloads, usage, sales, and subscriptions, but that's all handled by Apple through App Store Connect – Kickstart Exchange does not receive those App Store conversion details.

### Exchange App Store privacy disclosure

The included privacy manifest declares **Usage Data: Product Interaction** and **Usage Data: Advertising Data** for Third-Party Advertising, Developer's Advertising or Marketing, Analytics, and App Functionality – please make sure these are both declared on App Store Connect, in addition to any other privacy settings for your app. Both data types are unlinked from identity and are not used for tracking.

App developers remain responsible for disclosing everything collected by their app and every other integrated SDK. Please follow the [exact App Store Connect steps](https://exchange.kickstart.tools/guide#app-privacy), keep any additional disclosures your app requires, and provide your own complete privacy policy that mentions and links to Kickstart Exchange.

### Using the official Exchange service

**Important:** This SDK is released under the MIT License, so you are free to inspect, modify, and redistribute it, including as part of your own service. However, only unmodified versions of this SDK may connect to the official Kickstart Exchange service. Modified versions may be blocked, and apps using them may be removed from Kickstart Exchange.

## Kickstart Signal

Collect feature requests, votes, and comments through a native feedback board. Review submissions in the dashboard before publishing them.

### Installing Kickstart Signal

Add `https://github.com/twostraws/KickstartSDK` in Xcode, then link the `KickstartSignal` product to your app target.

Visit [Kickstart Signal](https://signal.kickstart.tools), create a free account, and register your app to get an API key. If your app already uses Exchange, use the same app API key.

Place the board inside a navigation stack:

```swift
import KickstartSignal
import SwiftUI

NavigationStack {
    SignalBoardView(apiKey: "ks_live_REPLACE_WITH_API_KEY")
}
```

If the board is already inside a navigation stack, use `SignalBoardView` directly. When presenting it in a sheet, put the `NavigationStack` inside the sheet. The board pushes its own detail and submission screens onto that stack, so if you bind the stack to a path, use `NavigationPath` rather than an array of your own route type.

### Previewing Signal

To try an interactive sample board without an API key:

```swift
#Preview {
    NavigationStack {
        SignalBoardView.demo()
    }
}
```

The demo uses sample requests and comments, keeps changes in memory for that board instance, and makes no network requests. A new demo board starts with fresh sample state.

### Submissions and voting

Submissions stay private until you publish them. Each new user request starts with one vote from the submitting installation. The SDK remembers that vote, so the author can undo it after publication without being counted twice. Retries do not add votes. The initial vote also honors `.kickstartPremiumUser(_:)`.

### Customizing Signal text

Customizable keys in the app's `Localizable.xcstrings`:

| Key | Used for | Default |
| --- | --- | --- |
| `Signal.Title` | Board navigation title | Feature Requests |
| `Signal.DetailTitle` | Request detail navigation title | Request |
| `Signal.SuggestionTitle` | Suggestion button and submission screen title | Suggest a Feature |
| `Signal.DeveloperName` | Developer replies heading | Developer |
| `Signal.ConfirmationMessage` | Successful suggestion confirmation | Thanks for sharing your suggestion! |
| `Signal.EmptyStatusMessage` | Empty board, including status filters | Nothing to see here yet. |

### Testing Signal

`SignalBoardView.demo()` needs no dashboard settings. To test your app's real board, open its **Signal** tab in the Kickstart dashboard, adjust these settings, and click **Save settings**:

- **Allow Xcode testing:** Enable this for local builds or the Simulator, using the bundle ID registered in the dashboard. It skips Apple verification and uses your live board, so submissions and votes are real. Turn it off when you finish testing; TestFlight and App Review work with it off.
- **Allow comments and voting:** Leave this enabled to test voting and reading or submitting comments. Turning it off still lets users browse requests and submit new suggestions.

### Signal privacy and data flow

The SDK sends the API key, bundle identifier, SDK version for server diagnostics, and whatever users explicitly submit: request titles, descriptions, and comments. Votes, requests, and comments also carry an anonymous installation ID. This is a random UUID the SDK creates the first time the installation votes or submits something, stored in `UserDefaults`, and it is never created just for browsing. It lets the same installation undo its vote without being counted twice, and is not derived from the user or their device. When `.kickstartPremiumUser(true)` is set, a premium flag is sent with added votes, requests, and comments; otherwise the flag is omitted.

When the server asks the SDK to verify the install, the SDK asks `AppTransaction.shared` for a locally verified Apple-signed App Transaction and sends its JWS only to the session endpoint, as Exchange does. It never prompts for App Store sync.

### Signal App Store privacy disclosure

If you send premium status, disclose **Purchase History** for **App Functionality**, **not linked to identity**, and **not used for tracking**.

The included privacy manifest declares **User ID**, **Product Interaction**, **Other User Content**, and **Purchase History** for App Functionality, all marked **not linked to identity** and **not used for tracking**. These declarations describe supported SDK data uses and can appear in Xcode's combined privacy report even when premium status is not supplied. Your App Store Connect answers must reflect your app's actual collection and any applicable optional disclosure exceptions.

Signal does not use feedback data for tracking, advertising, or marketing. It is designed for infrequent, optional feedback outside your app's primary purpose, with users entering and explicitly submitting their feedback each time. We consider this anonymous feedback eligible under [Apple's Optional Disclosure guidelines](https://developer.apple.com/app-store/app-privacy-details/#optional-disclosure), but we encourage you to read it for yourself and make your own decision. Keep your app's other required disclosures and include Signal in your privacy policy.

## Example apps

Open `Sandbox/Sandbox.xcodeproj`, choose the **Sandbox** scheme, and run it on your chosen platform, or choose the **SandboxWatch** scheme for watchOS. The project links the SDK through its local package reference. For device builds, select your own development team under **Signing & Capabilities** for the target you are running.

The Exchange section demonstrates pinned, scrolling, and styled banners using the `preview` API key. These sample adverts charge nobody; they demonstrate placement and styling without testing real impression tracking.

The Signal section has an **Example board** where you can browse requests, vote, read comments, and try the submission forms. Changes are temporary: returning to the sandbox menu and opening the example again creates a fresh board. Opening a request and returning to the same board preserves its state.

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
