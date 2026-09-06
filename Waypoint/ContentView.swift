import SwiftUI
import CoreLocation

struct ContentView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Status badge
                VStack(spacing: 10) {
                    Image(systemName: authIcon)
                        .font(.system(size: 52))
                        .foregroundColor(authColor)

                    Text(authLabel)
                        .font(.headline)

                    if let loc = locationManager.lastLocation {
                        Text(String(format: "%.5f, %.5f", loc.coordinate.latitude, loc.coordinate.longitude))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)

                // Last report row
                VStack(alignment: .leading, spacing: 4) {
                    Text("LAST REPORT")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                    Text(locationManager.lastStatus)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                // Manual trigger
                Button {
                    if let loc = locationManager.lastLocation {
                        locationManager.postLocation(loc)
                    } else {
                        locationManager.startMonitoring()
                    }
                } label: {
                    Label("Send Location Now", systemImage: "location.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Spacer()

                Text("Waypoint silently reports your location when you move significantly. Location data is sent only to the endpoint you configure.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Waypoint")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .onAppear {
            locationManager.startMonitoring()
        }
    }

    // MARK: - Auth state helpers

    private var authIcon: String {
        switch locationManager.authStatus {
        case .authorizedAlways:      return "location.fill"
        case .authorizedWhenInUse:   return "location"
        case .denied, .restricted:   return "location.slash"
        default:                     return "location.circle"
        }
    }

    private var authColor: Color {
        switch locationManager.authStatus {
        case .authorizedAlways:      return .green
        case .authorizedWhenInUse:   return .yellow
        case .denied, .restricted:   return .red
        default:                     return .gray
        }
    }

    private var authLabel: String {
        switch locationManager.authStatus {
        case .authorizedAlways:      return "Active — Monitoring in Background"
        case .authorizedWhenInUse:   return "Limited — Tap below, then grant Always access"
        case .denied, .restricted:   return "Location Denied — Enable in Settings"
        case .notDetermined:         return "Tap below to enable location access"
        default:                     return "Unknown status"
        }
    }
}
