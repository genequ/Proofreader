# Proofreader - AI-Powered Text Proofreading for macOS

A sleek menu bar utility that uses AI models to proofread and correct text anywhere on your Mac with a global keyboard shortcut.

**Supports multiple AI providers:**
- 🦙 **Ollama** - Run models locally on your Mac
- 🌐 **OpenRouter** - Cloud API with xAI Grok models
- ☁️ **DeepSeek** - Cloud API, no installation needed

![Proofreader Menu Bar](https://img.shields.io/badge/macOS-14.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## Features

- ✨ **Global Keyboard Shortcut** - Proofread text anywhere (default: `⌘+.`). Uses native macOS Carbon HotKeys for zero-latency, beep-free operation.
- 🔄 **Multiple AI Providers** - Choose between Ollama (local), or DeepSeek / OpenRouter (cloud)
- 🎯 **Menu Bar Utility** - Lightweight, always accessible from your menu bar
- ⚡ **Real-time Processing** - Instant proofreading with streaming output and visual feedback
- 🎨 **macOS Native** - Built with SwiftUI following Apple's HIG
- 🔧 **Customizable** - Change providers, models, prompts, and keyboard shortcuts
- 📝 **Prompt Templates** - Built-in templates (Academic, Business, Technical, etc.) and custom templates. Switch templates in the result dialog to regenerate instantly.
- 🔄 **Replace Button** - One-click replacement of original text with corrected version in the source application
- 📊 **Usage Statistics** - Track corrections, time saved, and session history
- 🔌 **Connection Health Monitoring** - Auto-reconnect and real-time status indicators
- 🎓 **Guided Onboarding** - Interactive setup wizard for first-time users
- 📋 **Multiple Input Methods** - Proofread selected text or clipboard content

## Requirements

- macOS 14.0 or later (Sonoma and newer)
- One of the following AI providers:
  - **Ollama**: Install with `brew install ollama` and pull a model
  - **OpenRouter**: Get API key from [openrouter.ai](https://openrouter.ai/)
  - **DeepSeek**: Get API key from [platform.deepseek.com](https://platform.deepseek.com/)


## Usage

1. **Select text** anywhere on your Mac
2. **Press `⌘+.`** (or your custom shortcut)
3. **Wait for processing** - the menu bar icon shows progress
4. **Review results** - corrected text appears in a dialog with diff highlighting
5. **Replace or Copy** - use "Replace" to update the original text in place, or "Copy Result" to copy to clipboard

### Dialog Actions
- **Replace**: Replaces the original text in the source application with the corrected version (copies to clipboard, switches to source app, and pastes)
- **Copy Result**: Copies the proofread text to clipboard and closes the dialog
- **Show Differences**: Toggle to view side-by-side comparison of original vs corrected text with diff highlights
- **Template Picker**: Switch to a different prompt template and regenerate instantly (one-time, does not change saved setting)
- **Close**: Close the dialog without copying


## Configuration

### Settings Dialog
- **Provider Selection**: Choose between Ollama, DeepSeek, or OpenRouter
- **Provider URL/API Key**: Configure connection settings for your chosen provider
  - Ollama: `http://127.0.0.1:11434` (default)
  - DeepSeek: Enter your API key
  - OpenRouter: Enter your API key
- **Model Selection**: Choose from available models for your selected provider
- **Keyboard Shortcut**: Customize the global hotkey
- **Test Connection**: Verify provider connectivity

### Default Prompt
```
You are a text proofreader. Your task is to correct typos and grammar errors in the provided text while strictly preserving the original meaning, formatting, and style.
```

### Prompt Templates
Proofreader includes built-in prompt templates for different writing styles:
- **Default** - General proofreading for non-native English speakers
- **Academic Writing** - Formal academic and research writing
- **Business Communication** - Professional emails and business documents
- **Casual Writing** - Informal messages and social media
- **Technical Documentation** - Technical writing and documentation
- **Creative Writing** - Stories, articles, and creative content

You can also create custom templates. Only the "Default" template cannot be deleted. Switch templates in the result dialog to regenerate with a different template — the selection is one-time and does not persist.

## Building from Source

### Prerequisites
- Xcode 14.0 or later
- Swift 5.9 or later
- An AI provider (Ollama, DeepSeek, or OpenRouter API key)

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
│   ├── OpenRouterService.swift       # OpenRouter API integration
│   ├── DeepSeekService.swift        # DeepSeek API integration
│   ├── SettingsView.swift           # Configuration UI
│   ├── PromptEditorView.swift       # Template management UI
│   ├── PromptTemplate.swift         # Template model & manager
│   ├── ProofreadingDialog.swift     # Results display with template picker
│   ├── DiffHighlightView.swift      # Async diff highlighting (background LCS)
│   ├── PromptTemplate.swift         # Template management (built-in + custom)
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
- **OpenRouter**: Verify your API key is valid and check your internet connection
- **DeepSeek**: Verify your API key is valid and check your internet connection

**Connection errors**
- Check that your selected provider is running/configured correctly
- Verify the URL or API key in Settings
- For Ollama: `curl http://127.0.0.1:11434/api/tags`
- For OpenRouter: Verify your API key is valid at [openrouter.ai](https://openrouter.ai/)
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
1. Click menu bar icon → "Change Template"
2. Edit the instructions as needed
3. Click "OK" to save

### Adding New Models

**Ollama:**
1. Pull the model: `ollama pull <model-name>`
2. Click "Refresh" in model selection
3. Select the new model from Settings

**OpenRouter:**
1. Models are fetched automatically from the API (xAI Grok models)
2. Select from the dropdown in Settings

**DeepSeek:**
1. Models are fetched automatically from the API
2. Select from the dropdown in Settings

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
