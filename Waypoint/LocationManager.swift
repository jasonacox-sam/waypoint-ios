import CoreLocation
import UIKit

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    static let shared = LocationManager()

    private let clManager = CLLocationManager()
    private var lastPostDate: Date?
    private let minPostInterval: TimeInterval = 30

    @Published var lastLocation: CLLocation?
    @Published var lastStatus: String = "Not yet reported"
    @Published var authStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        clManager.delegate = self
        authStatus = clManager.authorizationStatus
    }

    func startMonitoring() {
        clManager.requestAlwaysAuthorization()
        if clManager.authorizationStatus == .authorizedAlways {
            clManager.startMonitoringSignificantLocationChanges()
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async { self.authStatus = manager.authorizationStatus }
        if manager.authorizationStatus == .authorizedAlways {
            manager.startMonitoringSignificantLocationChanges()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // Debounce: ignore rapid-fire updates
        let now = Date()
        if let last = lastPostDate, now.timeIntervalSince(last) < minPostInterval { return }
        lastPostDate = now

        DispatchQueue.main.async { self.lastLocation = location }
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

        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            let city = placemarks?.first?.locality ?? ""
            let state = placemarks?.first?.administrativeArea ?? ""
            self?.send(to: url, token: token, location: location, city: city, state: state)
        }
    }

    private func send(to url: URL, token: String, location: CLLocation, city: String, state: String) {
        var bgTask: UIBackgroundTaskIdentifier = .invalid
        bgTask = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(bgTask)
        }

        var req = URLRequest(url: url, timeoutInterval: 30)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !token.isEmpty { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }

        let payload: [String: Any] = [
            "lat": location.coordinate.latitude,
            "lon": location.coordinate.longitude,
            "city": city,
            "state": state,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
        ]
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
