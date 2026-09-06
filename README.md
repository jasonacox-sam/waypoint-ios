# Waypoint

A minimal iOS app that silently reports significant location changes to a configurable webhook endpoint.

No ads. No tracking. No accounts. Your location goes exactly where you point it.

## How It Works

Waypoint registers with iOS's [Significant Location Change service](https://developer.apple.com/documentation/corelocation/cllocationmanager/startmonitoringsignificantlocationchanges()) — a low-power API that wakes the app when you've moved meaningfully (city-scale distance). On each trigger, it reverse-geocodes your position for city/state and POSTs a small JSON payload to your endpoint.

The app keeps running in the background and is relaunched automatically by iOS after a device restart.

## Payload

```json
{
  "lat": 34.3839,
  "lon": -118.5553,
  "city": "Valencia",
  "state": "CA",
  "timestamp": "2026-09-05T20:00:00Z"
}
```

## Setup — Xcode

> Requires Xcode 15+ and iOS 16+ deployment target.

### 1. Create the Xcode project

1. Open Xcode → **File → New → Project**
2. Choose **iOS → App**
3. Fill in:
   - **Product Name:** `Waypoint`
   - **Bundle Identifier:** `com.yourname.waypoint` (must be unique for your Apple ID)
   - **Interface:** SwiftUI
   - **Language:** Swift
4. Save the project somewhere convenient

### 2. Add the source files

Delete the auto-generated `ContentView.swift`, then drag all five `.swift` files from this repo's `Waypoint/` directory into your Xcode project:

- `WaypointApp.swift`
- `AppDelegate.swift`
- `LocationManager.swift`
- `ContentView.swift`
- `SettingsView.swift`

Make sure **"Copy items if needed"** and your target are checked.

### 3. Add location permissions (Info tab)

In Xcode, select your target → **Info** tab → hover over any row → click **+** to add:

| Key | Value |
|-----|-------|
| `NSLocationAlwaysAndWhenInUseUsageDescription` | Waypoint uses your location in the background to report significant location changes. |
| `NSLocationAlwaysUsageDescription` | Waypoint needs Always location access to report changes when the app is closed. |
| `NSLocationWhenInUseUsageDescription` | Waypoint needs location access to report where you are. |

### 4. Add Background Modes capability

Select your target → **Signing & Capabilities** → **+ Capability** → **Background Modes** → check **Location updates**.

### 5. Build and run on device

Connect your iPhone, select it as the destination, hit **Run (⌘R)**. Sign with your Apple Developer account when prompted.

First launch: tap the location icon to grant "Always" permission. The status badge turns green when monitoring is active.

### 6. Configure the endpoint

Tap the gear icon → enter your webhook URL and Bearer token → **Save**.

## Endpoint Requirements

Your server must accept:

```
POST /location
Authorization: Bearer <token>
Content-Type: application/json
```

A `200 OK` response body of `{"ok": true}` is expected. Non-200 responses are logged in the app UI.

## Privacy

- No analytics, no crash reporting, no third-party SDKs.
- Location data is sent only to the URL you configure.
- Reverse geocoding uses Apple's on-device CLGeocoder (no external API call for city/state).
- Bearer token is stored in UserDefaults on your device.

## License

MIT
