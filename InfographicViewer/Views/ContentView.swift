import SwiftUI
import UniformTypeIdentifiers

/// Main view for testing the infographic visualization
struct ContentView: View {
    @State private var infographic: InteractiveInfographic?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showFilePicker = false
    @State private var showInfographic = false
    @State private var githubURL = ""
    @State private var selectedTab = 0
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab selector
                    Picker("Mode", selection: $selectedTab) {
                        Text("Samples").tag(0)
                        Text("From GitHub").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    // Content based on selected tab
                    switch selectedTab {
                    case 0:
                        samplesView
                    case 1:
                        githubInputView
                    default:
                        samplesView
                    }
                    
                    Spacer()
                    
                    // Status/Error display
                    if let error = errorMessage {
                        errorBanner(error)
                    }
                    
                    // View button when infographic is loaded
                    if infographic != nil {
                        viewInfographicButton
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
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [UTType.json],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .fullScreenCover(isPresented: $showInfographic) {
            if let infographic = infographic {
                InfographicView(infographic: infographic)
            }
        }
    }
    
    // MARK: - Samples View
    
    private var samplesView: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                Text("Load a sample infographic to test the visualization")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Sample buttons
                VStack(spacing: Spacing.sm) {
                    sampleButton(
                        title: "California Law Chatbot",
                        subtitle: "Python CLI application",
                        filename: "California-Law-Chatbot_interactive",
                        icon: "scale.3d"
                    )
                    
                    sampleButton(
                        title: "HTTPie CLI",
                        subtitle: "Command-line HTTP client",
                        filename: "cli_interactive",
                        icon: "terminal"
                    )
                }
                .padding()
                
                if let infographic = infographic {
                    loadedInfoCard(infographic)
                }
            }
            .padding(.top)
        }
    }
    
    private func sampleButton(title: String, subtitle: String, filename: String, icon: String) -> some View {
        Button(action: { loadSample(filename) }) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.accentPrimary)
                    .frame(width: 44)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.textTertiary)
            }
            .padding()
            .background(Color.bgSecondary)
            .cornerRadius(12)
        }
    }
    
    // MARK: - File Picker View
    
    private var filePickerView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.textSecondary)
            
            Text("Load JSON from File")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            
            Text("Select a JSON file generated by repo2interactive.py")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { showFilePicker = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "folder.badge.plus")
                    Text("Choose File")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .background(Color.accentPrimary)
                .cornerRadius(12)
            }
            
            if let infographic = infographic {
                loadedInfoCard(infographic)
            }
        }
        .padding()
    }
    
    // MARK: - GitHub Input View
    
    private var githubInputView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "link.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.textSecondary)
            
            Text("Generate from GitHub")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            
            Text("Enter a GitHub repository URL to generate an infographic")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack {
                TextField("https://github.com/owner/repo", text: $githubURL)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                Button(action: openGitHub) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.title2)
                        .foregroundColor(.accentPrimary)
                }
            }
            .padding(.horizontal)
            
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
            
            if let infographic = infographic {
                loadedInfoCard(infographic)
            }
        }
        .padding()
    }
    
    // MARK: - Shared Components
    
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
        .padding()
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
    
    private func loadSample(_ filename: String) {
        isLoading = true
        errorMessage = nil
        
        if let loaded = InteractiveInfographic.load(from: filename) {
            infographic = loaded
        } else {
            errorMessage = "Failed to load sample: \(filename)"
        }
        
        isLoading = false
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            loadFromURL(url)
            
        case .failure(let error):
            errorMessage = "Failed to select file: \(error.localizedDescription)"
        }
    }
    
    private func loadFromURL(_ url: URL) {
        isLoading = true
        errorMessage = nil
        
        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "Cannot access file"
            isLoading = false
            return
        }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let data = try Data(contentsOf: url)
            if let loaded = InteractiveInfographic.load(from: data) {
                infographic = loaded
            } else {
                errorMessage = "Invalid JSON format"
            }
        } catch {
            errorMessage = "Failed to load file: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func generateFromGitHub() {
        guard !githubURL.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let generated = try await InfographicGenerator.generate(from: githubURL)
                await MainActor.run {
                    infographic = generated
                    isLoading = false
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
