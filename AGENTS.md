# AGENTS.md

Guidance for AI coding agents (and humans) working on this repo.

## Project Overview

Waypoint is a minimal SwiftUI iOS app that reports significant location changes
to a configurable webhook endpoint. No third-party dependencies, no package
manager — just a plain Xcode project.

- **Xcode project:** `Waypoint/Waypoint.xcodeproj` (target: `Waypoint`)
- **Sources:** `Waypoint/Waypoint/*.swift`
- **Deployment target:** iOS 26.1, Xcode 26+
- **Key files:**
  - `WaypointApp.swift` — app entry point
  - `AppDelegate.swift` — background relaunch handling
  - `LocationManager.swift` — location monitoring, geocoding, webhook POST
  - `ContentView.swift` — main status UI
  - `SettingsView.swift` — configuration UI (device name, webhook URL, token, About)
  - `LaunchScreen.storyboard` — static launch screen (hand-maintained XML)

## Build & Verify

Always verify changes build before committing:

```sh
cd Waypoint
xcodebuild -project Waypoint.xcodeproj -scheme Waypoint \
  -destination 'generic/platform=iOS Simulator' build
```

If you edit `LaunchScreen.storyboard`, validate it separately first:

```sh
ibtool --errors --warnings --notices Waypoint/Waypoint/LaunchScreen.storyboard
```

CI (`.github/workflows/build.yml`) runs the same storyboard validation and a
simulator build (unsigned) on every push and PR to `main` — keep it green.

Storyboard XML gotchas (both have broken the build before):
- `targetRuntime` must be `iOS.CocoaTouch` (not `AppleCocoa Touch`)
- Label fonts use `<fontDescription key="fontDescription" ...>` (not `key="font"`)

## Versioning & Releases

Every user-visible change set must update version info and release notes:

1. **Bump versions** in `Waypoint/Waypoint.xcodeproj/project.pbxproj`:
   - `MARKETING_VERSION` — semantic version (e.g. `1.0.1`); patch for fixes,
     minor for features (both Debug and Release configurations)
   - `CURRENT_PROJECT_VERSION` — increment the build number by 1
2. **Sync the launch screen** — update the hardcoded `v…` label text in
   `LaunchScreen.storyboard` to match `MARKETING_VERSION`
3. **Add a `RELEASE.md` entry** at the top: `## vX.Y.Z (build N) — YYYY-MM-DD`
   with `### Fixed` / `### Changed` / `### Added` subsections as applicable

The Settings About section reads the version from the bundle at runtime — it
needs no manual updates.

## Code Style

- Swift 5+, SwiftUI-first; 4-space indentation
- Follow the existing patterns in the file you're editing; keep diffs surgical
- Persist settings via `UserDefaults` with camelCase keys (`webhookURL`,
  `bearerToken`, `deviceName`)
- No third-party dependencies — use Apple frameworks only
- Comment only where intent isn't obvious; no boilerplate comments
- Keep views small; extract computed properties (e.g. `appVersion`,
  `payloadExample`) rather than inlining complex expressions

## Repo Hygiene

- Never commit `xcuserdata`, `DerivedData`, or other user-specific Xcode state;
  `.gitignore` patterns are anchored with `**/` because the project is nested
  under `Waypoint/` — keep that prefix on any new ignore rules containing `/`
- No secrets in source or docs — the bearer token lives only in UserDefaults
  on device
- Update `README.md` when setup steps, payload format, or endpoint
  requirements change

## Privacy Principles

Preserve these product invariants in any change:

- No analytics, crash reporting, or third-party SDKs
- Location data goes only to the user-configured URL
- Geocoding stays on-device (currently `CLGeocoder`; migrate to MapKit's
  `MKReverseGeocodingRequest` eventually — `CLGeocoder` is deprecated in iOS 26)
