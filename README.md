# Waypoint

A minimal iOS app that silently reports significant location changes to a configurable webhook endpoint.

No ads. No tracking. No accounts. Your location goes exactly where you point it.

## How It Works

Waypoint registers with iOS's [Significant Location Change service](https://developer.apple.com/documentation/corelocation/cllocationmanager/startmonitoringsignificantlocationchanges()) — a low-power API that wakes the app when you've moved meaningfully (city-scale distance). On each trigger, it reverse-geocodes your position for city/state and POSTs a small JSON payload to your endpoint.

The app keeps running in the background and is relaunched automatically by iOS after a device restart.

## Payload

```json
{
  "lat": 34.1184,
  "lon": -118.3004,
  "city": "Los Angeles",
  "state": "CA",
  "timestamp": "2026-09-05T20:00:00Z"
}
```

## Setup — Xcode

> Requires Xcode 26+ (iOS 26.1 deployment target).

### 1. Open the project

Clone this repo and open `Waypoint/Waypoint.xcodeproj` in Xcode. Location permissions and the Background Modes (Location updates) capability are already configured.

### 2. Set your signing identity

Select the **Waypoint** target → **Signing & Capabilities** → choose your own **Team**, and change the **Bundle Identifier** to something unique for your Apple ID (e.g., `com.yourname.waypoint`).

### 3. Build and run on device

Connect your iPhone, select it as the destination, hit **Run (⌘R)**. Sign with your Apple Developer account when prompted.

First launch: tap the location icon to grant "Always" permission. The status badge turns green when monitoring is active.

### 4. Configure the endpoint

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
