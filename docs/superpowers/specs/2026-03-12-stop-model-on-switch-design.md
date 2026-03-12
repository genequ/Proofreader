# Design: Stop Previous Model on Settings Save

**Date:** 2026-03-12
**Status:** Approved

## Overview

When the user changes the model in Settings and clicks OK, the previously selected model should be stopped (unloaded from memory) before switching to the new one. This prevents multiple models from remaining loaded in Ollama, which consumes unnecessary RAM.

## Problem Statement

Currently, when a user switches models in the Settings dialog, the previous model remains loaded in Ollama's memory. For users with limited RAM or running large models (e.g., Llama 3 70B), this can cause significant memory pressure.

## Requirements

1. Stop the previous model only when the user clicks "OK" in Settings (not on selection)
2. Allow users to browse model options without side effects
3. Fail gracefully if stopping the model fails (non-critical operation)

## Implementation

### 1. Add `stop(model:)` method to `OllamaService`

Location: `Sources/OllamaService.swift`

```swift
func stop(model: String) async {
    // Use Process to run 'ollama stop <model>' command
    // Silently ignore errors
}
```

- Actor-isolated async method
- Uses existing `OllamaService.findOllamaPath()` for cross-platform binary detection
- Logs errors but doesn't throw

### 2. Track previous model in `SettingsView`

Location: `Sources/SettingsView.swift`

```swift
@State private var previousModel: String = ""

// In onAppear:
previousModel = appState.currentModel
```

Store the original model when Settings opens, similar to how `originalURL` and `originalShortcut` are tracked.

### 3. Stop previous model in OK button handler

Location: `Sources/SettingsView.swift` OK button action

```swift
Button("OK") {
    // Stop previous model if changed
    if previousModel != appState.currentModel {
        Task {
            await appState.stopModel(previousModel)
        }
    }
    appState.updateOllamaURL(appState.ollamaURL)
    appState.updateKeyboardShortcut(appState.keyboardShortcut)
    dismiss()
}
```

### 4. Add `stopModel()` bridge method to `AppState`

Location: `Sources/AppState.swift`

```swift
func stopModel(_ model: String) {
    Task {
        await ollamaService.stop(model: model)
    }
}
```

## Data Flow

```
User changes model in picker → currentModel binding updates
User clicks OK → Compare previousModel with appState.currentModel
If different → Task { await appState.stopModel(previousModel) }
              → Dismiss dialog
```

## Error Handling

- Stopping a model is a best-effort operation
- If the `ollama stop` command fails, log but don't show user-facing errors
- The new model should still be used regardless of stop success/failure
- This mirrors the existing pattern in `AppDelegate.applicationWillTerminate`

## Testing

1. Open Settings, note current model
2. Change to a different model
3. Click Cancel → previous model should remain loaded
4. Open Settings again, change model, click OK → previous model should be unloaded
5. Verify via `ollama list` that only the new model is loaded
