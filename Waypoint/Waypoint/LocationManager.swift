import Combine
import CoreLocation
import UIKit

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    static let shared = LocationManager()
    private static let hasRequestedAlwaysKey = "hasRequestedAlwaysAuthorization"

    private let clManager = CLLocationManager()
    private var lastPostDate: Date?
    private let minPostInterval: TimeInterval = 30
    private var pendingManualSend = false

    @Published var lastLocation: CLLocation?
    @Published var lastStatus: String = "Not yet reported"
    @Published var authStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        clManager.delegate = self
        authStatus = clManager.authorizationStatus
    }

    func startMonitoring() {
        switch clManager.authorizationStatus {
        case .notDetermined:
            // Two-step flow: ask When-In-Use first. Requesting Always from a fresh
            // state never shows an "Always" option — iOS grants provisional access
            // and defers its own upgrade prompt to an arbitrary later time.
            clManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            requestAlwaysUpgradeIfNeeded()
        case .authorizedAlways:
            clManager.startMonitoringSignificantLocationChanges()
        default:
            break
        }
    }

    /// Requests the Always upgrade at most once per install — iOS only shows its
    /// "Change to Always Allow?" dialog the first time, so repeating the request
    /// on every launch/appear would be a no-op. After the one attempt, the app
    /// falls back to directing the user to Settings (see `openSystemSettings`).
    private func requestAlwaysUpgradeIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Self.hasRequestedAlwaysKey) else { return }
        defaults.set(true, forKey: Self.hasRequestedAlwaysKey)
        clManager.requestAlwaysAuthorization()
    }

    /// Requests a fresh one-shot GPS fix and posts it, bypassing the debounce.
    func requestAndPost() {
        pendingManualSend = true
        clManager.requestLocation()
    }

    /// Opens the app's page in Settings so the user can manually switch to "Always" —
    /// needed because iOS only shows the in-app upgrade prompt once per install.
    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        DispatchQueue.main.async { UIApplication.shared.open(url) }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async { self.authStatus = manager.authorizationStatus }
        switch manager.authorizationStatus {
        case .authorizedAlways:
            manager.startMonitoringSignificantLocationChanges()
        case .authorizedWhenInUse:
            // Just upgraded from notDetermined — request Always right away so the
            // "Change to Always Allow?" dialog appears immediately, gated to once.
            requestAlwaysUpgradeIfNeeded()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        DispatchQueue.main.async { self.lastLocation = location }

        if pendingManualSend {
            pendingManualSend = false
            postLocation(location)
            return
        }

        // Debounce: ignore rapid-fire background updates
        let now = Date()
        if let last = lastPostDate, now.timeIntervalSince(last) < minPostInterval { return }
        lastPostDate = now
        postLocation(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async { self.lastStatus = "✗ Location error: \(error.localizedDescription)" }
    }

    // MARK: - Posting

    func postLocation(_ location: CLLocation) {
        let defaults = UserDefaults.standard
        guard
            let urlString = defaults.string(forKey: "webhookURL"), !urlString.isEmpty,
            let url = URL(string: urlString)
        else { return }

        let token = defaults.string(forKey: "bearerToken") ?? ""
        let device = defaults.string(forKey: "deviceName")?.trimmingCharacters(in: .whitespaces) ?? ""

        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            let placemark = placemarks?.first
            let number = placemark?.subThoroughfare ?? ""
            let road   = placemark?.thoroughfare ?? ""
            let street = [number, road].filter { !$0.isEmpty }.joined(separator: " ")
            let city   = placemark?.locality ?? ""
            let state  = placemark?.administrativeArea ?? ""
            self?.send(to: url, token: token, device: device, location: location, street: street, city: city, state: state)
        }
    }

    private func send(to url: URL, token: String, device: String, location: CLLocation, street: String, city: String, state: String) {
        var bgTask: UIBackgroundTaskIdentifier = .invalid
        bgTask = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(bgTask)
        }

        var req = URLRequest(url: url, timeoutInterval: 30)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !token.isEmpty { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }

        var payload: [String: Any] = [
            "lat": location.coordinate.latitude,
            "lon": location.coordinate.longitude,
            "street": street,
            "city": city,
            "state": state,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
        ]
        if !device.isEmpty { payload["device"] = device }
        req.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: req) { [weak self] _, response, error in
            DispatchQueue.main.async {
                if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    let fmt = DateFormatter()
                    fmt.timeStyle = .short
                    self?.lastStatus = "✓ Reported at \(fmt.string(from: Date()))"
                } else {
                    let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                    let msg = error?.localizedDescription ?? "HTTP \(code)"
                    self?.lastStatus = "✗ Failed: \(msg)"
                }
                UIApplication.shared.endBackgroundTask(bgTask)
            }
        }.resume()
    }
}
