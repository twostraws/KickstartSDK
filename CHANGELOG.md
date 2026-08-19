# Changelog

## Unreleased

- Added `ExchangeLargeAdView`, a large advertisement layout that can be placed
  inside scrolling content or presented as a sheet or full screen cover.
- Added `exchangeAdSheet(isPresented:apiKey:)` and
  `exchangeAdFullScreenCover(isPresented:apiKey:)`, which present a large
  advertisement with a close action.
- Fixed advertisements never recording an impression outside a scroll view.
- Fixed a presented advertisement ignoring a Dynamic Type size set by the
  host app, which a sheet or full screen cover drops at the presentation
  boundary.

## 0.5.0

Initial release.
