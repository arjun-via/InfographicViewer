import SwiftUI

@main
struct InfographicViewerApp: App {
    init() {
        // Load OPENROUTER_API_KEY from a bundled `.env` (Debug builds only).
        // The `.env` file is copied into the app bundle by an Xcode Run Script build phase.
        loadEnvFromBundleIfPresent()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
    
    private func loadEnvFromBundleIfPresent() {
#if DEBUG
        guard let envURL = Bundle.main.url(forResource: ".env", withExtension: nil) else {
            return
        }
        guard let envContents = try? String(contentsOf: envURL, encoding: .utf8) else {
            return
        }

        // Parse `.env` file (KEY=VALUE, ignores blank lines and comments).
        let lines = envContents.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

            let parts = trimmed.components(separatedBy: "=")
            guard parts.count >= 2 else { continue }

            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1...].joined(separator: "=").trimmingCharacters(in: .whitespaces)

            // Persist the one thing we need for GitHub generation.
            if key == "OPENROUTER_API_KEY", !value.isEmpty {
                InfographicGenerator.apiKey = value
            }
        }
#endif
    }
}
