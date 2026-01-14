import Foundation

/// Service for generating infographics from GitHub repositories
/// This calls a backend API to analyze the repo and generate the hierarchical JSON
enum InfographicGenerator {
    
    // MARK: - Configuration
    
    /// Backend API endpoint for generating infographics
    /// Change this to your actual backend URL
    static var apiEndpoint = "http://localhost:3001/api/infographic/generate"
    
    // MARK: - Errors
    
    enum GeneratorError: LocalizedError {
        case invalidURL
        case networkError(String)
        case invalidResponse
        case serverError(String)
        case parsingError(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid GitHub URL"
            case .networkError(let message):
                return "Network error: \(message)"
            case .invalidResponse:
                return "Invalid response from server"
            case .serverError(let message):
                return "Server error: \(message)"
            case .parsingError(let message):
                return "Failed to parse response: \(message)"
            }
        }
    }
    
    // MARK: - API Request/Response
    
    struct GenerateRequest: Codable {
        let repoUrl: String
        
        enum CodingKeys: String, CodingKey {
            case repoUrl = "repo_url"
        }
    }
    
    struct GenerateResponse: Codable {
        let success: Bool
        let infographic: InteractiveInfographic?
        let error: String?
    }
    
    // MARK: - Generate from GitHub URL
    
    /// Generate an infographic from a GitHub repository URL
    /// - Parameter githubURL: The GitHub repository URL (e.g., https://github.com/owner/repo)
    /// - Returns: The generated InteractiveInfographic
    static func generate(from githubURL: String) async throws -> InteractiveInfographic {
        // Validate URL
        guard let _ = URL(string: githubURL),
              githubURL.contains("github.com") else {
            throw GeneratorError.invalidURL
        }
        
        // Build request
        guard let url = URL(string: apiEndpoint) else {
            throw GeneratorError.networkError("Invalid API endpoint")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120 // 2 minutes - generation can take time
        
        let requestBody = GenerateRequest(repoUrl: githubURL)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeneratorError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to parse error message from response
            if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
               let errorMessage = errorResponse["error"] {
                throw GeneratorError.serverError(errorMessage)
            }
            throw GeneratorError.serverError("HTTP \(httpResponse.statusCode)")
        }
        
        // Parse response
        let decoder = JSONDecoder()
        
        // Try direct infographic response first
        if let infographic = try? decoder.decode(InteractiveInfographic.self, from: data) {
            return infographic
        }
        
        // Try wrapped response
        let generateResponse = try decoder.decode(GenerateResponse.self, from: data)
        
        if let error = generateResponse.error {
            throw GeneratorError.serverError(error)
        }
        
        guard let infographic = generateResponse.infographic else {
            throw GeneratorError.invalidResponse
        }
        
        return infographic
    }
    
    // MARK: - Generate from Local Files (for testing without backend)
    
    /// Generate a simple infographic from local file contents
    /// This is a fallback for testing without a backend
    static func generateLocal(
        projectName: String,
        files: [(path: String, content: String)]
    ) -> InteractiveInfographic {
        // Build a simple hierarchical structure from the files
        var fileNodes: [InfographicNode] = []
        
        for (index, file) in files.enumerated() {
            let language = detectLanguage(from: file.path)
            let lineCount = file.content.components(separatedBy: "\n").count
            
            let fileNode = InfographicNode(
                id: "file-\(index)",
                type: .file,
                label: file.path,
                description: "Source file",
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
        
        // Group files by directory
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
    
    // MARK: - Helpers
    
    private static func detectLanguage(from path: String) -> String {
        let ext = (path as NSString).pathExtension.lowercased()
        switch ext {
        case "swift": return "Swift"
        case "ts", "tsx": return "TypeScript"
        case "js", "jsx": return "JavaScript"
        case "py": return "Python"
        case "rb": return "Ruby"
        case "go": return "Go"
        case "rs": return "Rust"
        case "java": return "Java"
        case "kt": return "Kotlin"
        case "cpp", "cc", "cxx": return "C++"
        case "c": return "C"
        case "h", "hpp": return "Header"
        case "json": return "JSON"
        case "yaml", "yml": return "YAML"
        case "md": return "Markdown"
        case "css": return "CSS"
        case "html": return "HTML"
        default: return ext.isEmpty ? "Unknown" : ext.uppercased()
        }
    }
}
