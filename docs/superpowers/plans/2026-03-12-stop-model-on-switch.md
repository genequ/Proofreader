# Stop Previous Model on Settings Save Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stop the previous Ollama model when user switches to a different model in Settings and clicks OK.

**Architecture:** Add a `stop(model:)` method to `OllamaService` that runs the `ollama stop` command via Process. Track the previous model in `SettingsView` and call the stop method when OK is clicked if the model changed.

**Tech Stack:** Swift, SwiftUI, Foundation (Process), actor isolation, async/await

---

## File Structure

**Files to modify:**
- `Sources/OllamaService.swift` - Add `stop(model:)` method
- `Sources/AppState.swift` - Add `stopModel(_:)` bridge method
- `Sources/SettingsView.swift` - Track previous model, stop on OK

**Files to reference:**
- `Sources/AppDelegate.swift` - Reference existing `ollama stop` implementation

---

## Chunk 1: Add `stop(model:)` method to `OllamaService`

### Task 1: Add the `stop(model:)` method to OllamaService

**Files:**
- Modify: `Sources/OllamaService.swift` (after line 318, before `// MARK: - Error Mapping`)

- [ ] **Step 1: Add the stop method to OllamaService**

Add this method after the `preload(model:)` method (after line 318, before the existing `// MARK: - Error Mapping`):

```swift
// MARK: - Model Management

func stop(model: String) async {
    guard let ollamaPath = OllamaService.findOllamaPath() else {
        print("[OllamaService] Cannot stop model: Ollama not found")
        return
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: ollamaPath)
    process.arguments = ["stop", model]

    do {
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus == 0 {
            print("[OllamaService] Stopped model: \(model)")
        } else {
            print("[OllamaService] Failed to stop model \(model), exit code: \(process.terminationStatus)")
        }
    } catch {
        // Silently ignore errors - stopping a model is non-critical
        print("[OllamaService] Failed to stop model \(model): \(error)")
    }
}
```

- [ ] **Step 2: Build to verify compilation**

Run: `swift build`

Expected: Build succeeds with no errors

- [ ] **Step 3: Commit**

```bash
git add Sources/OllamaService.swift
git commit -m "feat: add stop(model:) method to OllamaService"
```

---

## Chunk 2: Add `stopModel(_:)` bridge method to AppState

### Task 2: Add the bridge method in AppState

**Files:**
- Modify: `Sources/AppState.swift` (after line 142, after the `updateKeyboardShortcut` method)

**Prerequisites:**
- Chunk 1 must be completed first (adds `stop(model:)` to `OllamaService`)

- [ ] **Step 1: Add stopModel method to AppState**

Add this method after `updateKeyboardShortcut`:

```swift
/// Stops the specified model in Ollama to free memory
/// - Parameter model: The model name to stop (e.g., "llama2")
func stopModel(_ model: String) {
    Task {
        await ollamaService.stop(model: model)
    }
}
```

- [ ] **Step 2: Build to verify compilation**

Run: `swift build`

Expected: Build succeeds with no errors

- [ ] **Step 3: Commit**

```bash
git add Sources/AppState.swift
git commit -m "feat: add stopModel(_:) bridge method to AppState"
```

---

## Chunk 3: Track previous model in SettingsView

### Task 3: Add previousModel state tracking

**Files:**
- Modify: `Sources/SettingsView.swift` (add new @State after line 9)

**Prerequisites:**
- Chunk 1 and 2 must be completed first

- [ ] **Step 1: Add previousModel state variable**

Add after line 9 (after `originalShortcut`):

```swift
@State private var previousModel: String = ""
```

- [ ] **Step 2: Store previous model on appear**

Modify the `onAppear` block (currently lines 127-135) to store the previous model:

Find:
```swift
.onAppear {
    // Store original values for Cancel
    originalURL = appState.ollamaURL
    originalShortcut = appState.keyboardShortcut
```

Replace with:
```swift
.onAppear {
    // Store original values for Cancel
    originalURL = appState.ollamaURL
    originalShortcut = appState.keyboardShortcut
    previousModel = appState.currentModel
```

- [ ] **Step 3: Update Cancel button to revert model**

The Cancel button should also revert the model selection:

Find:
```swift
Button("Cancel") {
    // Revert changes
    appState.ollamaURL = originalURL
    appState.keyboardShortcut = originalShortcut
    dismiss()
}
```

Replace with:
```swift
Button("Cancel") {
    // Revert changes
    appState.ollamaURL = originalURL
    appState.keyboardShortcut = originalShortcut
    appState.currentModel = previousModel
    dismiss()
}
```

- [ ] **Step 4: Build to verify compilation**

Run: `swift build`

Expected: Build succeeds with no errors

- [ ] **Step 5: Commit**

```bash
git add Sources/SettingsView.swift
git commit -m "feat: track previous model in SettingsView and revert on Cancel"
```

---

## Chunk 4: Stop previous model on OK click

### Task 4: Implement the stop logic in OK button

**Files:**
- Modify: `Sources/SettingsView.swift` (lines 115-119, OK button action)

**Prerequisites:**
- Chunks 1-3 must be completed first

- [ ] **Step 1: Update OK button to stop previous model**

Find the OK button:
```swift
Button("OK") {
    appState.updateOllamaURL(appState.ollamaURL)
    appState.updateKeyboardShortcut(appState.keyboardShortcut)
    dismiss()
}
```

Replace with:
```swift
Button("OK") {
    // Stop previous model if it changed
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

- [ ] **Step 2: Build and sign the app**

Run: `./build-app.sh`

Expected: Build succeeds, Proofreader.app created

- [ ] **Step 3: Manual testing - Verify model stops on OK**

1. Launch the app: `open build/Proofreader.app`
2. Open Settings (from menu bar)
3. Note the current model
4. Change to a different model from the picker
5. Before clicking OK, open Terminal and run: `ollama list`
6. Note which models are loaded (check "loaded" status in output)
7. Click OK in Settings
8. Run `ollama list` again in Terminal
9. Verify: The previous model should no longer show as loaded

- [ ] **Step 4: Manual testing - Verify Cancel doesn't stop model**

1. Open Settings again
2. Change to a different model
3. Click Cancel
4. Run `ollama list` in Terminal
5. Verify: Both models should still show as loaded (no change)
6. Verify: The model picker reverts to the original selection

- [ ] **Step 5: Commit**

```bash
git add Sources/SettingsView.swift
git commit -m "feat: stop previous model when switching via Settings OK"
```

---

## Chunk 5: Run full test suite

### Task 5: Verify no regressions

**Files:**
- Test: Run all tests

- [ ] **Step 1: Run full test suite**

Run: `swift test`

Expected: All tests pass

- [ ] **Step 2: Final verification**

The feature is complete when:
1. Switching models via Settings OK stops the previous model
2. Canceling Settings does NOT stop any model
3. The app builds and runs without errors
4. All existing tests pass

- [ ] **Step 3: Final commit (if any cleanup needed)**

If any issues found during testing, fix and commit with:
```bash
git commit -m "fix: address issues found during testing"
```

---

## Testing Summary

**Manual Testing Checklist:**
- [ ] Model stops when changing via Settings + OK
- [ ] Model does NOT stop when using Cancel
- [ ] App launches and Settings opens correctly
- [ ] Can still proofread with the new model
- [ ] `ollama list` confirms model unload behavior

**Automated Testing:**
- [ ] `swift test` passes all tests

---

## Completion Criteria

The implementation is complete when:
1. `OllamaService.stop(model:)` method exists and works
2. `AppState.stopModel(_:)` bridge method exists
3. `SettingsView` tracks `previousModel`
4. OK button stops previous model if changed
5. Cancel button does NOT stop any model
6. All tests pass
7. Manual testing confirms the behavior
