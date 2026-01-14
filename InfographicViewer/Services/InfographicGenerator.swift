import Foundation
import os

/// Service for generating infographics from GitHub repositories
/// Calls the Railway backend which handles OpenRouter + validation
enum InfographicGenerator {
    
    // MARK: - Configuration
    
    private static let logger = Logger(subsystem: "com.arjundivecha.InfographicViewer", category: "InfographicGenerator")
    
    /// Railway backend URL for infographic generation
    /// Uses the same Railway deployment as Spoken Reality
    private static let backendURL = "https://spoken-reality-production-9cd5.up.railway.app/api/infographic/generate"
    
    /// Model to use (passed to backend)
    private static let model = "zai-glm-4.7"
    
    /// UserDefaults key for custom backend URL (optional override)
    private static let backendURLKey = "infographic_backend_url"
    
    /// Get the backend URL (can be overridden in settings)
    static var currentBackendURL: String {
        UserDefaults.standard.string(forKey: backendURLKey) ?? backendURL
    }
    
    /// Legacy API key property (kept for backward compatibility with Settings UI)
    /// No longer needed since backend handles the API key
    static var apiKey: String? {
        get { "backend-managed" }  // Always return non-nil so UI doesn't show "API key required"
        set { }  // No-op
    }
    
    // MARK: - Errors
    
    enum GeneratorError: LocalizedError {
        case invalidURL
        case networkError(String)
        case invalidResponse
        case serverError(String)
        case parsingError(String)
        case rateLimited
        case backendUnavailable
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid GitHub URL. Use format: https://github.com/owner/repo"
            case .networkError(let message):
                return "Network error: \(message)"
            case .invalidResponse:
                return "Invalid response from backend"
            case .serverError(let message):
                return "Backend error: \(message)"
            case .parsingError(let message):
                return "Failed to parse response: \(message)"
            case .rateLimited:
                return "Rate limited. Please wait a moment and try again."
            case .backendUnavailable:
                return "Backend service unavailable. Please try again later."
            }
        }
    }
    
    // MARK: - Generate from GitHub URL
    
    /// Generate an infographic from a GitHub repository URL
    /// Calls the Railway backend which handles OpenRouter + validation
    static func generate(from githubURL: String) async throws -> InteractiveInfographic {
        logger.info("Generate start (repo=\(githubURL, privacy: .public), backend=\(currentBackendURL, privacy: .public))")
        
        // Validate URL
        guard githubURL.contains("github.com") else {
            logger.error("Generate failed: invalid GitHub URL")
            throw GeneratorError.invalidURL
        }
        
        // Call backend
        let infographic = try await callBackend(repoURL: githubURL)
        
        logger.info("Generate success (repo=\(infographic.repoName, privacy: .public))")
        return infographic
    }
    
    // MARK: - Backend API Call
    
    private static func callBackend(repoURL: String) async throws -> InteractiveInfographic {
        guard let url = URL(string: currentBackendURL) else {
            throw GeneratorError.networkError("Invalid backend URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 300 // 5 minutes for large repos
        
        let payload: [String: Any] = [
            "repo_url": repoURL,
            "model": model
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        logger.info("Backend request prepared (bytes=\(request.httpBody?.count ?? 0, privacy: .public))")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Backend call failed: response not HTTPURLResponse")
            throw GeneratorError.invalidResponse
        }
        
        logger.info("Backend HTTP status \(httpResponse.statusCode, privacy: .public) (bytes=\(data.count, privacy: .public))")
        
        // Handle rate limiting
        if httpResponse.statusCode == 429 {
            logger.error("Backend rate limited (429)")
            throw GeneratorError.rateLimited
        }
        
        // Handle service unavailable
        if httpResponse.statusCode == 503 || httpResponse.statusCode == 502 {
            logger.error("Backend unavailable (\(httpResponse.statusCode))")
            throw GeneratorError.backendUnavailable
        }
        
        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            logger.error("Backend response parsing failed: not valid JSON")
            throw GeneratorError.invalidResponse
        }
        
        // Check for error in response
        if let success = json["success"] as? Bool, !success {
            let errorMessage = json["error"] as? String ?? "Unknown error"
            logger.error("Backend returned error: \(errorMessage, privacy: .public)")
            throw GeneratorError.serverError(errorMessage)
        }
        
        // Extract the infographic data
        guard let infographicData = json["data"] as? [String: Any] else {
            logger.error("Backend response missing 'data' field")
            throw GeneratorError.invalidResponse
        }
        
        // Convert back to Data for decoding
        let infographicJSON = try JSONSerialization.data(withJSONObject: infographicData)
        
        // Decode
        do {
            let decoder = JSONDecoder()
            let infographic = try decoder.decode(InteractiveInfographic.self, from: infographicJSON)
            logger.info("Infographic decoded successfully")
            return infographic
        } catch {
            logger.error("Infographic decode failed: \(error.localizedDescription, privacy: .public)")
            throw GeneratorError.parsingError(error.localizedDescription)
        }
    }
    
    // MARK: - Local Generation (fallback)
    
    /// Generate a simple infographic from local file contents
    /// This is a fallback for testing without backend
    static func generateLocal(
        projectName: String,
        files: [(path: String, content: String)]
    ) -> InteractiveInfographic {
        var fileNodes: [InfographicNode] = []
        
        for (index, file) in files.enumerated() {
            let language = detectLanguage(from: file.path)
            let lineCount = file.content.components(separatedBy: "\n").count
            
            let fileNode = InfographicNode(
                id: "file-\(index)",
                type: .file,
                label: (file.path as NSString).lastPathComponent,
                description: file.path,
                children: [],
                visualHint: VisualHint(icon: "doc.text", color: "#D29922", badge: nil),
                phaseMetadata: nil,
                stepMetadata: nil,
                fileMetadata: FileMetadata(
                    filePath: file.path,
                    language: language,
                    githubUrl: nil,
                    lineCount: lineCount
                ),
                functionMetadata: nil,
                codeMetadata: nil,
                connections: nil
            )
            fileNodes.append(fileNode)
        }
        
        let rootNode = InfographicNode(
            id: "root",
            type: .repo,
            label: projectName,
            description: "Project structure",
            children: [
                InfographicNode(
                    id: "phase-1",
                    type: .phase,
                    label: "Source Files",
                    description: "All project files",
                    children: fileNodes,
                    visualHint: VisualHint(icon: "folder", color: "#A371F7", badge: nil),
                    phaseMetadata: PhaseMetadata(phaseId: "1", phasePurpose: "Contains all source files"),
                    stepMetadata: nil,
                    fileMetadata: nil,
                    functionMetadata: nil,
                    codeMetadata: nil,
                    connections: nil
                )
            ],
            visualHint: VisualHint(icon: "folder.fill", color: "#58A6FF", badge: nil),
            phaseMetadata: nil,
            stepMetadata: nil,
            fileMetadata: nil,
            functionMetadata: nil,
            codeMetadata: nil,
            connections: nil
        )
        
        return InteractiveInfographic(
            version: "2.0",
            schema: "interactive-infographic",
            repoUrl: "local://\(projectName)",
            repoName: projectName,
            repoSummary: "Locally generated infographic",
            pipelineOverview: "Simple file listing",
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            root: rootNode
        )
    }
    
    private static func detectLanguage(from path: String) -> String {
        let ext = (path as NSString).pathExtension.lowercased()
        switch ext {
        case "swift": return "Swift"
        case "ts", "tsx": return "TypeScript"
        case "js", "jsx": return "JavaScript"
        case "py": return "Python"
        case "go": return "Go"
        case "rs": return "Rust"
        case "java": return "Java"
        case "kt": return "Kotlin"
        case "json": return "JSON"
        case "md": return "Markdown"
        default: return ext.isEmpty ? "Unknown" : ext.uppercased()
        }
    }
}
