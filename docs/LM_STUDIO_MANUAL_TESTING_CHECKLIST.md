# LM Studio Provider - Manual Testing Checklist

This document outlines the manual testing steps for validating the LM Studio provider integration.

## Prerequisites

1. Install Ollama from https://ollama.ai
2. Install LM Studio from https://lmstudio.ai
3. Pull at least one model in Ollama (e.g., `ollama pull gemma3:4b`)
4. Load at least one model in LM Studio

## Automated Testing (Completed)

- [x] Build the app: `./build-app.sh` - **SUCCESS**
- [x] Run all tests: `swift test` - **ALL 13 TESTS PASS**

## Manual Testing Steps

### Test 1: Initial State Verification

**Steps:**
1. Launch Proofreader.app
2. Open Settings (click menu bar icon → Settings)

**Expected Results:**
- Provider dropdown shows "Ollama" as default
- Model dropdown shows Ollama models
- URL field shows `http://127.0.0.1:11434`

### Test 2: Switch to LM Studio

**Steps:**
1. In Settings, change Provider dropdown to "LM Studio"
2. Verify URL updates to `http://127.0.0.1:1234/v1`
3. Click "Refresh Models" button
4. Select a model from the dropdown
5. Click "OK" to save settings

**Expected Results:**
- URL field automatically updates to LM Studio's default URL
- Models list populates from LM Studio API
- Settings are saved when OK is clicked
- Status icon shows green checkmark if LM Studio is running

### Test 3: Proofreading with LM Studio

**Steps:**
1. Select some text in any application
2. Press the global shortcut (default: Cmd+.)
3. Wait for proofreading to complete
4. Review the corrected text

**Expected Results:**
- Proofreading dialog appears
- Text is processed by LM Studio model
- Corrections are displayed with diff highlighting
- No errors occur during processing

### Test 4: Switch Back to Ollama

**Steps:**
1. Open Settings again
2. Change Provider dropdown back to "Ollama"
3. Verify URL shows `http://127.0.0.1:11434`
4. Verify previous Ollama model is still selected
5. Click "OK"

**Expected Results:**
- URL reverts to Ollama's default
- Previous Ollama model selection is preserved
- Settings save successfully

### Test 5: LM Studio Not Running

**Steps:**
1. Ensure LM Studio is NOT running
2. Switch to LM Studio provider in Settings
3. Select a model and click OK
4. Try to proofread some text

**Expected Results:**
- Status icon shows red X or error triangle
- Error message indicates connection failure
- App remains responsive (no crash or hang)
- Error message is provider-agnostic (mentions "provider" not "LM Studio")

### Test 6: Ollama Not Running

**Steps:**
1. Ensure Ollama is NOT running (`ollama stop` or kill process)
2. Switch to Ollama provider in Settings
3. Try to proofread some text

**Expected Results:**
- Status icon shows red X or error triangle
- Error message indicates connection failure
- App remains responsive (no crash or hang)
- Error message is provider-agnostic

### Test 7: Provider URL Independence

**Steps:**
1. Switch to Ollama provider
2. Change URL to `http://localhost:11434`
3. Switch to LM Studio provider
4. Verify URL shows `http://127.0.0.1:1234/v1` (NOT localhost)
5. Switch back to Ollama
6. Verify URL shows `http://localhost:11434` (preserved)

**Expected Results:**
- Each provider maintains its own URL setting
- Switching providers doesn't affect other provider's URL
- URLs are preserved when switching back

### Test 8: Model Independence

**Steps:**
1. Select Ollama provider
2. Choose model "gemma3:4b"
3. Switch to LM Studio provider
4. Choose a different model
5. Switch back to Ollama

**Expected Results:**
- Each provider maintains its own model selection
- Switching providers doesn't affect other provider's model
- Model selections are preserved when switching back

## Test Results

| Test # | Test Name | Status | Notes |
|--------|-----------|--------|-------|
| 1 | Initial State Verification | | |
| 2 | Switch to LM Studio | | |
| 3 | Proofreading with LM Studio | | |
| 4 | Switch Back to Ollama | | |
| 5 | LM Studio Not Running | | |
| 6 | Ollama Not Running | | |
| 7 | Provider URL Independence | | |
| 8 | Model Independence | | |

## Known Issues

None identified during automated testing.

## Test Environment

- macOS Version: [Fill in]
- Proofreader Version: 1.2.0 (Build 202603252013)
- Ollama Version: [Fill in]
- LM Studio Version: [Fill in]
- Test Date: [Fill in]
