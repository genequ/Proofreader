# Proofreader - AI-Powered Text Proofreading for macOS

A sleek menu bar utility that uses AI models to proofread and correct text anywhere on your Mac with a global keyboard shortcut.

**Supports multiple AI providers:**
- 🦙 **Ollama** - Run models locally on your Mac
- 💻 **LM Studio** - Local models with a friendly interface
- ☁️ **DeepSeek** - Cloud API, no installation needed

![Proofreader Menu Bar](https://img.shields.io/badge/macOS-14.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## Features

- ✨ **Global Keyboard Shortcut** - Proofread text anywhere (default: `⌘+.`). Uses native macOS Carbon HotKeys for zero-latency, beep-free operation.
- 🔄 **Multiple AI Providers** - Choose between Ollama (local), LM Studio (local), or DeepSeek (cloud)
- 🎯 **Menu Bar Utility** - Lightweight, always accessible from your menu bar
- ⚡ **Real-time Processing** - Instant proofreading with streaming output and visual feedback
- 🎨 **macOS Native** - Built with SwiftUI following Apple's HIG
- 🔧 **Customizable** - Change providers, models, prompts, and keyboard shortcuts
- 📊 **Usage Statistics** - Track corrections, time saved, and session history
- 🔌 **Connection Health Monitoring** - Auto-reconnect and real-time status indicators
- 🎓 **Guided Onboarding** - Interactive setup wizard for first-time users
- 📋 **Multiple Input Methods** - Proofread selected text or clipboard content

## Requirements

- macOS 14.0 or later (Sonoma and newer)
- One of the following AI providers:
  - **Ollama**: Install with `brew install ollama` and pull a model
  - **LM Studio**: Download from [lmstudio.ai](https://lmstudio.ai/)
  - **DeepSeek**: Get API key from [platform.deepseek.com](https://platform.deepseek.com/)


## Usage

1. **Select text** anywhere on your Mac
2. **Press `⌘+.`** (or your custom shortcut)
3. **Wait for processing** - the menu bar icon shows progress
4. **Review results** - corrected text appears in a dialog
5. **Copy and close** - clicking "Copy Corrected" automatically copies to clipboard and closes the dialog

### Dialog Actions
- **Copy Corrected**: Copies the proofread text to clipboard and closes the dialog
- **Show Differences**: Toggle to view side-by-side comparison of original vs corrected text
- **Done**: Close the dialog without copying


## Configuration

### Settings Dialog
- **Provider Selection**: Choose between Ollama, LM Studio, or DeepSeek
- **Provider URL/API Key**: Configure connection settings for your chosen provider
  - Ollama: `http://127.0.0.1:11434` (default)
  - LM Studio: `http://127.0.0.1:1234/v1` (default)
  - DeepSeek: Enter your API key
- **Model Selection**: Choose from available models for your selected provider
- **Keyboard Shortcut**: Customize the global hotkey
- **Test Connection**: Verify provider connectivity

### Default Prompt
```
You are a text proofreader. Your task is to correct typos and grammar errors in the provided text while strictly preserving the original meaning, formatting, and style.
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

# Build release version
./build-app.sh

# The app will be created as Proofreader.app
```

### Project Structure
```
Proofreader/
├── Sources/
│   ├── AppState.swift               # Main state management
│   ├── ProofreaderApp.swift         # App entry point
│   ├── LLMProvider.swift            # Provider protocol
│   ├── OllamaService.swift          # Ollama API integration
│   ├── LMStudioService.swift        # LM Studio API integration
│   ├── DeepSeekService.swift        # DeepSeek API integration
│   ├── SettingsView.swift           # Configuration UI
│   ├── ProofreadingDialog.swift     # Results display
│   ├── OnboardingView.swift         # First-run setup wizard
│   ├── ProviderStatusView.swift     # Connection status indicator
│   ├── StatisticsView.swift         # Usage analytics display
│   ├── ShortcutManager.swift        # Keyboard shortcut handling
│   ├── ClipboardManager.swift       # Clipboard operations
│   └── ... other views
├── Resources/
│   └── AppIcon.icns                # Application icon
├── Package.swift                   # Swift package configuration
└── build-app.sh                    # Build script
```

## Troubleshooting

### Common Issues

**"No models available"**
- **Ollama**: Ensure Ollama is running (`ollama serve`) and pull a model (`ollama pull gemma3:1b`)
- **LM Studio**: Open LM Studio, load a model, and ensure the API server is enabled
- **DeepSeek**: Verify your API key is valid and check your internet connection

**Connection errors**
- Check that your selected provider is running/configured correctly
- Verify the URL or API key in Settings
- For Ollama: `curl http://127.0.0.1:11434/api/tags`
- For LM Studio: Ensure "Enable Server" is on in settings
- For DeepSeek: Check that your API key is valid at [platform.deepseek.com](https://platform.deepseek.com/)

**Keyboard shortcut not working**
- The app uses native Carbon HotKeys, which are very robust.
- If it still fails, check `System Settings → Privacy & Security → Accessibility` and ensure Proofreader is enabled.

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

**Ollama:**
1. Pull the model: `ollama pull <model-name>`
2. Click "Refresh" in model selection
3. Select the new model from Settings

**LM Studio:**
1. Open LM Studio and go to the AI Models tab
2. Search and download your desired model
3. Load the model for chatting
4. The model will appear in Proofreader's model dropdown

**DeepSeek:**
1. Models are fetched automatically from the API
2. Available models: `deepseek-chat`, `deepseek-coder`
3. Select from the dropdown in Settings

### Custom Keyboard Shortcuts
Supported formats:
- `command+.` (default)
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
- Uses native URLSession for HTTP requests (no external dependencies)
- Inspired by the need for quick, AI-powered proofreading
- Icons from [SF Symbols](https://developer.apple.com/sf-symbols/)

## Support

If you encounter any issues or have questions:

1. Check the [Troubleshooting](#troubleshooting) section
2. Search [existing issues](https://github.com/genequ/Proofreader/issues)
3. Create a [new issue](https://github.com/genequ/Proofreader/issues/new) with details

---

⭐ **Star this repo** if you find Proofreader useful!
