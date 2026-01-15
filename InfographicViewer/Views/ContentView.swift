import SwiftUI

/// Main view for generating infographics from GitHub repositories
struct ContentView: View {
    @State private var infographic: InteractiveInfographic?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showInfographic = false
    @State private var githubURL = ""
    @State private var showSettings = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                
                VStack(spacing: Spacing.lg) {
                    Spacer()
                        .frame(maxHeight: 60)
                    
                    // Icon
                    Image(systemName: "link.badge.plus")
                        .font(.system(size: 64))
                        .foregroundColor(.textSecondary)
                    
                    // Title
                    Text("Generate Infographic")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text("Enter a GitHub repository URL to generate an interactive infographic")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Open GitHub button
                    Button(action: openGitHub) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up.right.square")
                            Text("Open GitHub")
                        }
                        .font(.subheadline)
                        .foregroundColor(.accentPrimary)
                    }
                    .padding(.top, Spacing.sm)
                    
                    // URL input field
                    TextField("", text: $githubURL, prompt: Text("https://github.com/owner/repo").foregroundColor(.gray.opacity(0.4)))
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($isTextFieldFocused)
                        .padding(.horizontal)
                    
                    // Generate button
                    Button(action: generateFromGitHub) {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "wand.and.stars")
                            }
                            Text(isLoading ? "Generating..." : "Generate Infographic")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 240, height: 50)
                        .background(githubURL.isEmpty || isLoading ? Color.gray : Color.accentPrimary)
                        .cornerRadius(12)
                    }
                    .disabled(githubURL.isEmpty || isLoading)
                    
                    // Backend status
                    Text("Powered by GLM-4.7 via Cerebras")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                    
                    Spacer()
                    
                    // Status/Error display
                    if let error = errorMessage {
                        errorBanner(error)
                    }
                }
            }
            .navigationTitle("Infographic Viewer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.accentPrimary)
                    }
                }
            }
            .onTapGesture {
                isTextFieldFocused = false
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .fullScreenCover(isPresented: $showInfographic) {
            if let infographic = infographic {
                InfographicView(infographic: infographic)
            }
        }
    }
    
    // MARK: - Components
    
    private func loadedInfoCard(_ infographic: InteractiveInfographic) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.success)
                Text("Infographic Loaded")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
            }
            
            Divider()
                .background(Color.bgTertiary)
            
            infoRow("Repository", value: infographic.repoName)
            infoRow("Phases", value: "\(infographic.root.children.count)")
            
            if let overview = infographic.pipelineOverview {
                Text(overview)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .lineLimit(3)
            }
        }
        .padding()
        .background(Color.bgSecondary)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.textPrimary)
        }
    }
    
    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.error)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.textPrimary)
        }
        .padding()
        .background(Color.error.opacity(0.2))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private var viewInfographicButton: some View {
        Button(action: { showInfographic = true }) {
            HStack {
                Image(systemName: "eye.fill")
                Text("View Infographic")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.accentPrimary)
        }
    }
    
    // MARK: - Actions
    
    private func generateFromGitHub() {
        guard !githubURL.isEmpty else { return }
        
        // Hide keyboard
        isTextFieldFocused = false
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let generated = try await InfographicGenerator.generate(from: githubURL)
                await MainActor.run {
                    infographic = generated
                    isLoading = false
                    showInfographic = true  // Automatically show the infographic
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func openGitHub() {
        if let url = URL(string: "https://github.com") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    ContentView()
}
