# Infographic Viewer

A minimal iOS app for testing GitHub repository visualization as interactive, nested infographics.

This is a standalone test app for validating the mobile visualization approach described in the PRD before integrating it into [Spoken Reality](../Spoken%20Reality/).

## Features

- **Load Sample Infographics** - Test with pre-generated JSON files
- **Load from File** - Import your own JSON files
- **Generate from GitHub** - Enter a GitHub URL to generate an infographic
  - Uses OpenRouter API with Gemini 2.0 Flash
  - No separate backend needed!
- **Pinch-to-Zoom** - (Coming soon) Smooth zoom like Working Copy
- **Search** - (Coming soon) Find files and functions in the visualization

## Screenshots

The app displays repository structure as nested, expandable boxes:

```
REPO
├── PHASE (Ingestion, Processing, Output)
│   ├── STEP (individual processes)
│   │   ├── FILE (source files)
│   │   │   ├── FUNCTION (methods)
│   │   │   │   └── CODE (actual code blocks)
```

## Setup

### Step 1: Create Xcode Project

1. Open Xcode → File → New → Project
2. Choose iOS → App
3. Settings:
   - Product Name: `InfographicViewer`
   - Interface: **SwiftUI**
   - Language: **Swift**
4. Save in: `/Users/arjundivecha/Dropbox/AAA Backup/A Working/InfographicViewer/`
5. Delete the auto-generated `ContentView.swift` and `InfographicViewerApp.swift`
6. Drag the `InfographicViewer/` subfolder into Xcode (with all Swift files)
7. Add JSON files from `Resources/` to the project
8. Build and run!

### Step 2: Configure API Key (for GitHub generation)

1. Get an API key from [OpenRouter](https://openrouter.ai/keys)
2. In the app, tap the ⚙️ Settings button
3. Enter your OpenRouter API key
4. Tap "Test Connection" to verify

**Cost**: ~$0.10 per repository analysis (using Gemini 2.0 Flash)

## How GitHub Generation Works

The app calls OpenRouter's API directly (no backend needed):

1. You enter a GitHub URL
2. App sends the URL to OpenRouter with Gemini 2.0 Flash
3. Gemini fetches and analyzes the repository
4. Returns hierarchical JSON for visualization

This is the same approach used by [repo2interactive.py](../Spoken%20Reality/SpokenRealityApp/Tools/repo2interactive/).

### JSON Schema

```json
{
  "version": "2.0",
  "schema": "interactive-infographic",
  "repo_url": "https://github.com/owner/repo",
  "repo_name": "repo",
  "repo_summary": "Brief description",
  "pipeline_overview": "What this repo does",
  "generated_at": "2026-01-14T12:00:00Z",
  "root": {
    "id": "root",
    "type": "repo",
    "label": "Repository Name",
    "children": [...]
  }
}
```

## Project Structure

```
InfographicViewer/
├── App/
│   └── InfographicViewerApp.swift    # App entry point
├── Views/
│   ├── ContentView.swift              # Main UI with tabs
│   └── InfographicView.swift          # Nested box visualization
├── Models/
│   └── InfographicModels.swift        # Data models (from Spoken Reality)
├── Services/
│   └── InfographicGenerator.swift     # API client for generation
├── Theme/
│   └── Colors.swift                   # Color palette
└── Resources/
    ├── California-Law-Chatbot_interactive.json
    └── cli_interactive.json
```

## Related Projects

- **[Spoken Reality](../Spoken%20Reality/)** - The full voice-first app builder
- **[repo2interactive.py](../Spoken%20Reality/SpokenRealityApp/Tools/repo2interactive/)** - Python script for generating infographic JSON

## PRD Reference

This app validates the hypothesis from the [Mobile GitHub Repo Visualization PRD](../Spoken%20Reality/PRD.md):

> "There's an opportunity for a purpose-built solution (like a mobile-optimized 'code map' viewer) that accounts for iPhone interaction and performance limitations."

Key PRD recommendations implemented:
- ✅ Progressive disclosure (tap to expand/collapse)
- ✅ Touch-optimized controls (no hover dependencies)
- 🔜 Pinch-to-zoom (like Working Copy)
- 🔜 Search functionality

## License

Part of the Spoken Reality project.
