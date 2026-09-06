# Release Notes

## v1.0.1 (build 2) — 2026-09-05

### Fixed
- Build failure caused by a malformed `LaunchScreen.storyboard`:
  - `targetRuntime` corrected from `AppleCocoa Touch` to `iOS.CocoaTouch`
  - Label font attributes corrected from `key="font"` to `key="fontDescription"`

### Added
- GitHub Actions CI: unsigned iOS Simulator build + launch screen storyboard
  validation on every push and PR to `main`

### Changed
- Launch screen icon now has rounded corners (matching the iOS app icon
  corner ratio), baked into the `WaypointIcon` asset with an antialiased mask
- Restructured the repo: the full Xcode project now lives under `Waypoint/`
  in the containing `waypoint-ios` repository
- `.gitignore` patterns anchored with `**/` so they match the nested project
  layout; user-specific Xcode files (`xcuserdata`) removed from tracking
- README setup rewritten to use the included Xcode project (open, set your
  signing team/bundle ID, run) instead of manual project creation
- Settings now shows the app version (read dynamically from the bundle) in a
  new About section

## v1.0.0 (build 1) — 2026-09-05

Initial release.

- Background significant-location-change monitoring with automatic relaunch
  after device restart
- Reverse geocoding (city/state) via on-device CLGeocoder
- POSTs JSON payload (lat, lon, city, state, device, timestamp) to a
  configurable webhook endpoint with optional Bearer token auth
- SwiftUI status UI with settings for device name, webhook URL, and token
- Custom app icon and launch screen
