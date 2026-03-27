# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

```bash
# Build the app (creates Proofreader.app with code signing)
./build-app.sh

# Debug build (faster, no signing)
swift build

# Run tests
swift test

# Run specific test
swift test --filter testName
```

## Architecture

This is a macOS menu bar app using SwiftUI. The app uses Ollama's local LLM API for text proofreading.

### Key Architectural Patterns

**State Management**: Centralized in `AppState.swift` using `@MainActor` and `@AppStorage` for persistence. All views observe `AppState` as an `@EnvironmentObject`.

**Window Management**: `WindowManager` singleton manages non-Modal windows (settings, dialogs, onboarding) via string IDs. Windows are reused if already open.

**Global Shortcuts**: `ShortcutManager` uses Carbon HotKeys API (`RegisterEventHotKey`) for zero-latency global keyboard shortcuts. This requires Accessibility permissions.

**Async/Await Pattern**: `OllamaService` is an `actor` with async methods for streaming responses (`AsyncThrowingStream<String, Error>`).

### Service Layer

- `OllamaService`: Actor-based HTTP client with `listModels()`, `generate()`, `generateStream()`, and health checks. Uses `OllamaService.findOllamaPath()` for cross-platform binary detection.
- `LMStudioService`: Actor-based HTTP client for LM Studio's OpenAI-compatible API. Methods: `checkInstallation()`, `listModels()`, `generateStream()`, `updateBaseURL()`. Connects to `http://127.0.0.1:1234/v1` by default.
- `DeepSeekService`: Actor-based HTTP client for DeepSeek API. Uses API key authentication. Compatible with OpenAI API format. Methods: `checkInstallation()`, `listModels()`, `generateStream()`, `updateAPIKey()`.
- `ClipboardManager`: Simulates `Cmd+C` via `CGEvent` to capture selected text, then polls clipboard for changes.
- `StatisticsManager`: Tracks usage with debounced saves (2s delay) and `forceSave()` on quit.

### Status Types

`OllamaStatus` enum represents connection state: `.checking`, `.notInstalled`, `.installed(running:)`, `.connected(models:)`, `.error(OllamaError)`. Prefer this over the legacy `connectionStatus` computed property.

### Diff Algorithm

`DiffHighlightView` uses Longest Common Subsequence (LCS) for character-level diffing. The backtracking looks ahead for matches when LCS paths are equal to avoid false positives. Trailing whitespace differences are filtered out post-processing.

## Code Signing

The app uses a self-signed "ProofreaderDev" certificate. Run `./setup-cert.sh` if missing. Entitlements are in `Entitlements.plist` (sandbox disabled for global hotkeys/clipboard).

## Important Notes

- **Platform**: macOS 14.0+ only. Availability checks must match `Package.swift`.
- **Actor Isolation**: `OllamaService` is an actor - calls must be awaited from `@MainActor` contexts.
- **Timer Management**: Always invalidate timers before creating new ones to prevent memory leaks.
- **Memory**: App stops Ollama models on quit via `AppDelegate.applicationWillTerminate`.
- **Logging**: Use `Log.debug()`/`Log.error()` (defined in `ClipboardManager.swift`) - debug statements are `#if DEBUG` only.
- **Third-Party Providers**: DeepSeek uses API key authentication stored in UserDefaults. API key is sent via Bearer token in Authorization header.

## Common Pitfalls

- Don't use `@available` version lower than 14.0
- Don't block main thread with `usleep` - use async `Task.sleep` or polling
- Don't define duplicate enums across files (e.g., `DiffOperation`, `TextDifference`) - keep single source of truth
- Don't use `connectionStatus` - it's deprecated; use `ollamaStatus` instead
- Don't create new `OllamaService` instances - share the one in `AppState`
