import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var webhookURL: String = UserDefaults.standard.string(forKey: "webhookURL") ?? ""
    @State private var bearerToken: String = UserDefaults.standard.string(forKey: "bearerToken") ?? ""
    @State private var deviceName: String = UserDefaults.standard.string(forKey: "deviceName") ?? ""
    @State private var showToken = false

    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text("Device Name"),
                    footer: Text("Identifies this device to the receiver. Use a unique name per person (e.g. \"Jason\", \"Jane\").")
                ) {
                    TextField("Jason", text: $deviceName)
                        .autocorrectionDisabled()
                }

                Section(
                    header: Text("Webhook URL"),
                    footer: Text("HTTPS endpoint that accepts POST requests with your location.")
                ) {
                    TextField("https://example.com/location", text: $webhookURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                }

                Section(
                    header: Text("Bearer Token"),
                    footer: Text("Sent as the Authorization header. Leave empty for unauthenticated endpoints.")
                ) {
                    HStack {
                        if showToken {
                            TextField("Token", text: $bearerToken)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("Bearer token", text: $bearerToken)
                        }
                        Button { showToken.toggle() } label: {
                            Image(systemName: showToken ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: Text("Payload Reference")) {
                    Text(payloadExample)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Section {
                    Link("View source on GitHub",
                         destination: URL(string: "https://github.com/jasonacox-sam/waypoint-ios")!)
                        .foregroundColor(.accentColor)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        UserDefaults.standard.set(webhookURL, forKey: "webhookURL")
                        UserDefaults.standard.set(bearerToken, forKey: "bearerToken")
                        UserDefaults.standard.set(deviceName, forKey: "deviceName")
                        dismiss()
                    }
                    .bold()
                    .disabled(webhookURL.isEmpty)
                }
            }
        }
    }

    private let payloadExample = """
    {
      "lat": 34.1184,
      "lon": -118.3004,
      "city": "Los Angeles",
      "state": "CA",
      "device": "Jason",
      "timestamp": "2026-09-05T20:00:00Z"
    }
    """
}
