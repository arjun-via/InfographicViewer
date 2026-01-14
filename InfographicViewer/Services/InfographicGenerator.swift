import Foundation

/// Service for generating infographics from GitHub repositories
/// Calls OpenRouter API directly (like repo2interactive.py) - no separate backend needed
enum InfographicGenerator {
    
    // MARK: - Configuration
    
    /// OpenRouter API endpoint
    private static let openRouterURL = "https://openrouter.ai/api/v1/chat/completions"
    
    /// Model to use for analysis
    private static let model = "google/gemini-2.0-flash-001"
    
    /// UserDefaults key for API key
    private static let apiKeyKey = "openrouter_api_key"
    
    /// Get or set the OpenRouter API key
    static var apiKey: String? {
        get { UserDefaults.standard.string(forKey: apiKeyKey) }
        set { UserDefaults.standard.set(newValue, forKey: apiKeyKey) }
    }
    
    // MARK: - Errors
    
    enum GeneratorError: LocalizedError {
        case noAPIKey
        case invalidURL
        case networkError(String)
        case invalidResponse
        case serverError(String)
        case parsingError(String)
        case rateLimited
        
        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "OpenRouter API key not set. Go to Settings to add your key."
            case .invalidURL:
                return "Invalid GitHub URL. Use format: https://github.com/owner/repo"
            case .networkError(let message):
                return "Network error: \(message)"
            case .invalidResponse:
                return "Invalid response from API"
            case .serverError(let message):
                return "API error: \(message)"
            case .parsingError(let message):
                return "Failed to parse response: \(message)"
            case .rateLimited:
                return "Rate limited. Please wait a moment and try again."
            }
        }
    }
    
    // MARK: - Generate from GitHub URL
    
    /// Generate an infographic from a GitHub repository URL
    /// Calls OpenRouter API with Gemini to analyze the repository
    static func generate(from githubURL: String) async throws -> InteractiveInfographic {
        // Check for API key
        guard let key = apiKey, !key.isEmpty else {
            throw GeneratorError.noAPIKey
        }
        
        // Validate URL
        guard githubURL.contains("github.com") else {
            throw GeneratorError.invalidURL
        }
        
        // Build the prompt
        let prompt = buildAnalysisPrompt(repoURL: githubURL)
        
        // Call OpenRouter
        let jsonString = try await callOpenRouter(apiKey: key, prompt: prompt)
        
        // Parse the response
        return try parseInfographicJSON(jsonString)
    }
    
    // MARK: - OpenRouter API Call
    
    private static func callOpenRouter(apiKey: String, prompt: String) async throws -> String {
        guard let url = URL(string: openRouterURL) else {
            throw GeneratorError.networkError("Invalid API URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://github.com/infographic-viewer", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("InfographicViewer", forHTTPHeaderField: "X-Title")
        request.timeoutInterval = 300 // 5 minutes for large repos
        
        let payload: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.2,
            "max_tokens": 32000
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeneratorError.invalidResponse
        }
        
        // Handle rate limiting
        if httpResponse.statusCode == 429 {
            throw GeneratorError.rateLimited
        }
        
        // Handle other errors
        guard httpResponse.statusCode == 200 else {
            if let errorJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJSON["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw GeneratorError.serverError(message)
            }
            throw GeneratorError.serverError("HTTP \(httpResponse.statusCode)")
        }
        
        // Parse OpenRouter response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw GeneratorError.invalidResponse
        }
        
        return content
    }
    
    // MARK: - JSON Parsing
    
    private static func parseInfographicJSON(_ raw: String) throws -> InteractiveInfographic {
        // Extract JSON from potential markdown code blocks
        let jsonString = extractJSON(from: raw)
        
        guard let data = jsonString.data(using: .utf8) else {
            throw GeneratorError.parsingError("Invalid UTF-8 string")
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(InteractiveInfographic.self, from: data)
        } catch {
            throw GeneratorError.parsingError(error.localizedDescription)
        }
    }
    
    private static func extractJSON(from raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code blocks
        if text.contains("```") {
            // Find JSON within code blocks
            if let jsonStart = text.range(of: "{"),
               let jsonEnd = text.range(of: "}", options: .backwards) {
                text = String(text[jsonStart.lowerBound...jsonEnd.upperBound])
            }
        }
        
        // Find raw JSON
        if let jsonStart = text.firstIndex(of: "{"),
           let jsonEnd = text.lastIndex(of: "}") {
            return String(text[jsonStart...jsonEnd])
        }
        
        return text
    }
    
    // MARK: - Prompt Builder
    
    private static func buildAnalysisPrompt(repoURL: String) -> String {
        """
        You are a Principal Systems Architect with expertise in code analysis. Your task is to analyze the GitHub repository at:
        \(repoURL)

        You must produce a HIERARCHICAL JSON structure that an iOS app can use for interactive drill-down navigation.
        The user will tap on elements to zoom in and see more detail, recursively, until they reach the actual code.

        ================================================================================
        ANALYSIS INSTRUCTIONS
        ================================================================================

        1. **FETCH THE ENTIRE REPOSITORY**
           - Read all source files from the repository
           - Understand the project structure and dependencies
           - Identify the programming language(s) used

        2. **IDENTIFY ENTRY POINTS**
           - Find main entry points (main.py, app.py, index.js, __main__.py, etc.)
           - Identify CLI entry points, web routes, or event handlers
           - Note which files are the "starting points" of execution

        3. **TRACE EXECUTION FLOW**
           - Follow the code execution path from entry points
           - Map out which functions call which other functions
           - Identify data transformations and I/O operations

        4. **EXTRACT RELEVANT CODE**
           - For each function/class you identify, extract the actual source code
           - Include ONLY the relevant functions, not entire files
           - Preserve proper indentation and formatting

        5. **BUILD THE HIERARCHY**
           Create a tree with these levels (use as many as appropriate):
           
           Level 0: REPO (root)
              └── Level 1: PHASE (pipeline phases like Ingestion, Processing, Output)
                     └── Level 2: STEP (specific processing steps)
                            └── Level 3: FILE (source files involved)
                                   └── Level 4: FUNCTION (functions/classes)
                                          └── Level 5: CODE_BLOCK (actual code)

        ================================================================================
        JSON SCHEMA
        ================================================================================

        Your output MUST be a single JSON object with this EXACT structure:

        {
          "version": "2.0",
          "schema": "interactive-infographic",
          "repo_url": "\(repoURL)",
          "repo_name": "short-name",
          "repo_summary": "1-3 sentence description",
          "pipeline_overview": "1-2 sentence pipeline summary",
          "generated_at": "2026-01-14T00:00:00Z",
          "root": {
            "id": "root",
            "type": "repo",
            "label": "Repository Name",
            "description": "Short description",
            "visual_hint": {
              "icon": "folder.fill",
              "color": "#58A6FF"
            },
            "children": [
              // Array of phase nodes
            ]
          }
        }

        ================================================================================
        NODE TYPES
        ================================================================================

        Each node MUST have: id, type, label, description, visual_hint, children

        Node types: repo, phase, step, file, function, code_block

        For "phase" nodes, add phase_metadata with phase_id and phase_purpose
        For "step" nodes, add step_metadata with source_nodes and target_nodes
        For "file" nodes, add file_metadata with file_path, language, github_url
        For "function" nodes, add function_metadata with signature, line_start, line_end
        For "code_block" nodes, add code_metadata with actual code string and annotations

        ================================================================================
        CRITICAL RULES
        ================================================================================

        1. Extract REAL code from the repository - do NOT make up code
        2. Include only functions in the main execution flow
        3. Generate correct GitHub URLs with line numbers: .../blob/main/path.py#L10-L50
        4. Use valid SF Symbol names: terminal, doc.text, function, folder.fill, play.fill
        5. Leaf nodes (code_block) MUST have empty children array
        6. Respond with VALID JSON ONLY - no markdown, no explanation

        ================================================================================
        """
    }
    
    // MARK: - Local Generation (fallback)
    
    /// Generate a simple infographic from local file contents
    /// This is a fallback for testing without API
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
