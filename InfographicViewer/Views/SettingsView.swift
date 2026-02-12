import SwiftUI

/// Settings view - simplified since backend handles API keys
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var testStatus: TestStatus = .idle
    
    enum TestStatus: Equatable {
        case idle
        case testing
        case success
        case failed(String)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Backend Status Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "server.rack")
                                .foregroundColor(.accentPrimary)
                            Text("Railway Backend")
                                .font(.headline)
                            .foregroundColor(.textPrimary)
                        }
                        
                        Text("Infographics are generated server-side using GLM-4.7 via Cerebras")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        
                        Text(InfographicGenerator.currentBackendURL)
                            .font(.caption2)
                            .foregroundColor(.textTertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                } header: {
                    Text("Backend")
                }
                
                // Test Connection Section
                Section {
                    Button(action: testConnection) {
                        HStack {
                            switch testStatus {
                            case .idle:
                                Image(systemName: "network")
                                Text("Test Backend Connection")
                            case .testing:
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Testing...")
                            case .success:
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.success)
                                Text("Backend Online!")
                            case .failed(let error):
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.error)
                                Text(error)
                            }
                            Spacer()
                        }
                    }
                    .disabled(testStatus == .testing)
                }
                
                // About Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How it works")
                            .font(.headline)
                        
                        Text("1. Enter a GitHub repository URL")
                        Text("2. The app sends the URL to our Railway backend")
                        Text("3. Backend calls GLM-4.7 via Cerebras to analyze the repo")
                        Text("4. Returns a validated hierarchical JSON")
                        Text("5. Navigate the infographic by tapping to drill down")
                    }
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                } header: {
                    Text("About")
                }
                
                // Pricing Info
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pricing")
                            .font(.subheadline)
                            .foregroundColor(.textPrimary)
                        Text("Free tier available (GLM-4.7 via Cerebras)")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                } header: {
                    Text("Cost")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.accentPrimary)
                }
            }
        }
    }
    
    private func testConnection() {
        testStatus = .testing
        
        Task {
            do {
                // Test the backend health endpoint
                let healthURL = InfographicGenerator.currentBackendURL
                    .replacingOccurrences(of: "/generate", with: "/health")
                
                guard let url = URL(string: healthURL) else {
                    await MainActor.run {
                        testStatus = .failed("Invalid URL")
                    }
                    return
                }
                
                let (data, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse {
                    await MainActor.run {
                        if httpResponse.statusCode == 200 {
                            // Check if API key is configured on backend
                            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let apiKeyConfigured = json["api_key_configured"] as? Bool {
                                if apiKeyConfigured {
                                    testStatus = .success
                                } else {
                                    testStatus = .failed("Backend API key not configured")
                                }
                            } else {
                            testStatus = .success
                            }
                        } else {
                            testStatus = .failed("HTTP \(httpResponse.statusCode)")
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    testStatus = .failed(error.localizedDescription)
                }
            }
            
            // Reset after 3 seconds
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                if case .success = testStatus {
                    testStatus = .idle
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
