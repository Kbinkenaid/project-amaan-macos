import SwiftUI
import SecurityTools

struct SettingsView: View {
    @StateObject private var apiKeyManager = APIKeyManager()
    @State private var hibpKey: String = ""
    @State private var virustotalKey: String = ""
    @State private var shodanKey: String = ""
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var editingService: APIService?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "key.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                        Text("API Key Management")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    Text("Configure API keys to enable security services")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)

                Divider()

                // HaveIBeenPwned
                APIKeyCard(
                    service: .haveIBeenPwned,
                    apiKey: $hibpKey,
                    isConfigured: apiKeyManager.hasAPIKey(for: .haveIBeenPwned),
                    onSave: { saveKey(for: .haveIBeenPwned, key: hibpKey) },
                    onRemove: { removeKey(for: .haveIBeenPwned) }
                )

                // VirusTotal
                APIKeyCard(
                    service: .virustotal,
                    apiKey: $virustotalKey,
                    isConfigured: apiKeyManager.hasAPIKey(for: .virustotal),
                    onSave: { saveKey(for: .virustotal, key: virustotalKey) },
                    onRemove: { removeKey(for: .virustotal) }
                )

                // Shodan
                APIKeyCard(
                    service: .shodan,
                    apiKey: $shodanKey,
                    isConfigured: apiKeyManager.hasAPIKey(for: .shodan),
                    onSave: { saveKey(for: .shodan, key: shodanKey) },
                    onRemove: { removeKey(for: .shodan) }
                )

                Spacer()

                // Info Section
                VStack(alignment: .leading, spacing: 12) {
                    Divider()

                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                        Text("API keys are stored securely in macOS Keychain")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Click the link on each card to get your API key")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            loadExistingKeys()
        }
    }

    private func loadExistingKeys() {
        // Load masked versions or clear if not exists
        if apiKeyManager.hasAPIKey(for: .haveIBeenPwned) {
            hibpKey = "••••••••••••••••••••••••••••••••"
        }
        if apiKeyManager.hasAPIKey(for: .virustotal) {
            virustotalKey = "••••••••••••••••••••••••••••••••"
        }
        if apiKeyManager.hasAPIKey(for: .shodan) {
            shodanKey = "••••••••••••••••••••••••••••••••"
        }
    }

    private func saveKey(for service: APIService, key: String) {
        // Don't save masked placeholder
        if key.contains("•") {
            alertTitle = "No Changes"
            alertMessage = "Enter a new API key to save"
            showingAlert = true
            return
        }

        let result = apiKeyManager.storeAPIKey(key, for: service)
        if result.isSuccess {
            alertTitle = "Success"
            alertMessage = "\(service.name) API key saved successfully"

            // Update the field with masked value
            switch service.identifier {
            case "hibp": hibpKey = "••••••••••••••••••••••••••••••••"
            case "virustotal": virustotalKey = "••••••••••••••••••••••••••••••••"
            case "shodan": shodanKey = "••••••••••••••••••••••••••••••••"
            default: break
            }
        } else {
            alertTitle = "Error"
            alertMessage = result.error?.localizedDescription ?? "Failed to save API key"
        }
        showingAlert = true
    }

    private func removeKey(for service: APIService) {
        let result = apiKeyManager.removeAPIKey(for: service)
        if result.isSuccess {
            alertTitle = "Removed"
            alertMessage = "\(service.name) API key removed"

            // Clear the field
            switch service.identifier {
            case "hibp": hibpKey = ""
            case "virustotal": virustotalKey = ""
            case "shodan": shodanKey = ""
            default: break
            }
        } else {
            alertTitle = "Error"
            alertMessage = result.error?.localizedDescription ?? "Failed to remove API key"
        }
        showingAlert = true
    }
}

struct APIKeyCard: View {
    let service: APIService
    @Binding var apiKey: String
    let isConfigured: Bool
    let onSave: () -> Void
    let onRemove: () -> Void

    @State private var isEditing = false
    @State private var showKey = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(service.name)
                            .font(.headline)
                            .fontWeight(.semibold)

                        if isConfigured {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }

                    Text(service.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // Status Badge
                Text(isConfigured ? "Configured" : "Not Configured")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(isConfigured ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                    .foregroundColor(isConfigured ? .green : .orange)
                    .cornerRadius(8)
            }

            // API Key Input
            HStack(spacing: 12) {
                if showKey {
                    TextField("Enter API Key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                } else {
                    SecureField("Enter API Key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }

                Button(action: { showKey.toggle() }) {
                    Image(systemName: showKey ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help(showKey ? "Hide API Key" : "Show API Key")
            }

            // Actions
            HStack {
                // Get API Key Link
                if let url = URL(string: service.websiteURL) {
                    Link(destination: url) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right.square")
                            Text("Get API Key")
                        }
                        .font(.caption)
                    }
                }

                Spacer()

                // Remove Button
                if isConfigured {
                    Button(action: onRemove) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("Remove")
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }

                // Save Button
                Button(action: onSave) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                        Text("Save Key")
                    }
                    .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .disabled(apiKey.isEmpty)
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
