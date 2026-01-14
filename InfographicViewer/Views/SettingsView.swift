import SwiftUI

/// Settings view for configuring the OpenRouter API key
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var apiKey: String = ""
    @State private var showAPIKey = false
    @State private var testStatus: TestStatus = .idle
    
    enum TestStatus {
        case idle
        case testing
        case success
        case failed(String)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // API Key Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("OpenRouter API Key")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        Text("Required to generate infographics from GitHub URLs")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        
                        HStack {
                            if showAPIKey {
                                TextField("sk-or-...", text: $apiKey)
                                    .textFieldStyle(.roundedBorder)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            } else {
                                SecureField("sk-or-...", text: $apiKey)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            Button(action: { showAPIKey.toggle() }) {
                                Image(systemName: showAPIKey ? "eye.slash" : "eye")
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        
                        // Save button
                        Button(action: saveAPIKey) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                Text("Save Key")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.accentPrimary)
                        .disabled(apiKey.isEmpty)
                    }
                } header: {
                    Text("API Configuration")
                }
                
                // Get API Key Section
                Section {
                    Link(destination: URL(string: "https://openrouter.ai/keys")!) {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundColor(.accentPrimary)
                            Text("Get OpenRouter API Key")
                                .foregroundColor(.accentPrimary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pricing")
                            .font(.subheadline)
                            .foregroundColor(.textPrimary)
                        Text("Uses Gemini 2.0 Flash (~$0.10 per repo analysis)")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                } header: {
                    Text("OpenRouter")
                }
                
                // Test Connection Section
                Section {
                    Button(action: testConnection) {
                        HStack {
                            switch testStatus {
                            case .idle:
                                Image(systemName: "network")
                                Text("Test Connection")
                            case .testing:
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Testing...")
                            case .success:
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.success)
                                Text("Connection OK!")
                            case .failed(let error):
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.error)
                                Text(error)
                            }
                            Spacer()
                        }
                    }
                    .disabled(apiKey.isEmpty || testStatus == .testing)
                }
                
                // About Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How it works")
                            .font(.headline)
                        
                        Text("1. Enter a GitHub repository URL")
                        Text("2. The app calls OpenRouter's Gemini model")
                        Text("3. Gemini analyzes the repository structure")
                        Text("4. Returns a hierarchical JSON for visualization")
                    }
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                } header: {
                    Text("About")
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
            .onAppear {
                apiKey = InfographicGenerator.apiKey ?? ""
            }
        }
    }
    
    private func saveAPIKey() {
        InfographicGenerator.apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func testConnection() {
        guard !apiKey.isEmpty else { return }
        
        testStatus = .testing
        saveAPIKey()
        
        Task {
            do {
                // Simple test - just check if the API responds
                let url = URL(string: "https://openrouter.ai/api/v1/models")!
                var request = URLRequest(url: url)
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    await MainActor.run {
                        if httpResponse.statusCode == 200 {
                            testStatus = .success
                        } else if httpResponse.statusCode == 401 {
                            testStatus = .failed("Invalid API key")
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
