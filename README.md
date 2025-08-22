# Proofreader - AI-Powered Text Proofreading for macOS

A sleek menu bar utility that uses Ollama's AI models to proofread and correct text anywhere on your Mac with a global keyboard shortcut.

![Proofreader Menu Bar](https://img.shields.io/badge/macOS-12.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## Features

- ✨ **Global Keyboard Shortcut** - Proofread selected text anywhere (default: `⌘+/`)
- 🚀 **Ollama Integration** - Works with any Ollama model (Gemma, Llama, Mistral, etc.)
- 🎯 **Menu Bar Utility** - Lightweight, always accessible from your menu bar
- ⚡ **Real-time Processing** - Instant proofreading with visual feedback
- 🎨 **macOS Native** - Built with SwiftUI following Apple's HIG
- 🔧 **Customizable** - Change models, prompts, and keyboard shortcuts

## Requirements

- macOS 12.0 or later
- [Ollama](https://ollama.ai) installed and running
- At least one Ollama model pulled (e.g., `ollama pull gemma:4b`)

## Installation

### Option 1: Download Pre-built App
1. Download the latest `Proofreader.app` from [Releases](https://github.com/genequ/Proofreader/releases)
2. Drag to your Applications folder
3. Launch the app (right-click → Open if Gatekeeper blocks it)

### Option 2: Build from Source
```bash
# Clone the repository
git clone https://github.com/genequ/Proofreader.git
cd Proofreader

# Build the application
./build-app.sh

# The app will be created as Proofreader.app
open Proofreader.app
```

## Usage

1. **Select text** anywhere on your Mac
2. **Press `⌘+/`** (or your custom shortcut)
3. **Wait for processing** - the menu bar icon shows progress
4. **Review results** - corrected text appears in a dialog
5. **Copy to clipboard** or close the dialog

### Menu Bar Actions
- Click the menu bar icon to access:
  - **Proofread Selection** - Manual trigger
  - **Change Prompt** - Customize the proofreading instructions
  - **Select Model** - Switch between Ollama models
  - **Settings** - Configure Ollama URL and keyboard shortcut
  - **Quit** - Exit the application

## Configuration

### Settings Dialog
- **Ollama URL**: `http://127.0.0.1:11434` (default)
- **Model Selection**: Choose from available Ollama models
- **Keyboard Shortcut**: Customize the global hotkey
- **Test Connection**: Verify Ollama connectivity

### Default Prompt
```
Proofread the following text to correct typos and grammar errors while strictly preserving the original meaning, formatting, and style. Maintain the input format exactly (e.g., Markdown remains Markdown, plain text remains plain text). Do not add explanations, notes, or extra output—only return the corrected text.
```

## Building from Source

### Prerequisites
- Xcode 14.0 or later
- Swift 5.9 or later
- Ollama running locally

### Build Steps
```bash
# Clone and build
git clone https://github.com/genequ/Proofreader.git
cd Proofreader

# Install dependencies (Alamofire)
swift package update

# Build release version
./build-app.sh

# The app will be created as Proofreader.app
```

### Project Structure
```
Proofreader/
├── Sources/
│   ├── AppState.swift          # Main state management
│   ├── ProofreaderApp.swift    # App entry point
│   ├── OllamaService.swift     # Ollama API integration
│   ├── SettingsView.swift      # Configuration UI
│   ├── ProofreadingDialog.swift # Results display
│   └── ... other views
├── Resources/
│   └── AppIcon.icns           # Application icon
├── Package.swift              # Swift package configuration
└── build-app.sh               # Build script
```

## Troubleshooting

### Common Issues

**"No models available"**
- Ensure Ollama is running: `ollama serve`
- Pull at least one model: `ollama pull gemma:2b`

**Connection errors**
- Check Ollama URL in Settings (default: `http://127.0.0.1:11434`)
- Verify Ollama is accessible: `curl http://127.0.0.1:11434/api/tags`

**Keyboard shortcut not working**
- Check Accessibility permissions in System Settings
- Ensure Proofreader has input monitoring access

### Permissions
On first run, macOS may require:
- **Accessibility Access**: For global keyboard shortcuts
- **Input Monitoring**: To detect key presses
- **Automation**: For clipboard access

Grant these in: `System Settings → Privacy & Security → Accessibility`

## Customization

### Modifying the Proofreading Prompt
1. Click menu bar icon → "Change Prompt"
2. Edit the instructions as needed
3. Click "OK" to save

### Adding New Models
1. Pull the model: `ollama pull <model-name>`
2. Restart Proofreader or click "Refresh" in model selection
3. Select the new model from Settings

### Custom Keyboard Shortcuts
Supported formats:
- `command+/` (default)
- `control+shift+p`
- `option+space`
- `f1` through `f12`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- Uses [Alamofire](https://github.com/Alamofire/Alamofire) for HTTP requests
- Inspired by the need for quick, AI-powered proofreading
- Icons from [SF Symbols](https://developer.apple.com/sf-symbols/)

## Support

If you encounter any issues or have questions:

1. Check the [Troubleshooting](#troubleshooting) section
2. Search [existing issues](https://github.com/genequ/Proofreader/issues)
3. Create a [new issue](https://github.com/genequ/Proofreader/issues/new) with details

---

⭐ **Star this repo** if you find Proofreader useful!