# Infographic Viewer

A minimal iOS app for testing GitHub repository visualization as interactive, nested infographics.

This is a standalone test app for validating the mobile visualization approach described in the PRD before integrating it into [Spoken Reality](../Spoken%20Reality/).

## Features

- **Load Sample Infographics** - Test with pre-generated JSON files
- **Load from File** - Import your own JSON files
- **Generate from GitHub** - Enter a GitHub URL to generate an infographic (requires backend)
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

### Option 1: Quick Start (Samples Only)

1. Open Xcode
2. Create a new iOS App project named "InfographicViewer"
3. Delete the default ContentView.swift
4. Drag all files from `InfographicViewer/` folder into your project
5. Add the JSON files from `Resources/` to your project (check "Copy items if needed")
6. Build and run

### Option 2: With Backend (Generate from GitHub)

1. Set up the backend API (see below)
2. Update `InfographicGenerator.apiEndpoint` to your backend URL
3. Build and run

## Backend API

To generate infographics from GitHub URLs, you need a backend that:

1. Accepts POST requests with `{ "repo_url": "https://github.com/owner/repo" }`
2. Analyzes the repository using AI (Claude/Gemini)
3. Returns the hierarchical JSON in the `InteractiveInfographic` schema

See the [repo2interactive.py](../Spoken%20Reality/SpokenRealityApp/Tools/repo2interactive/) script for the generation logic.

### Expected API Response

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
