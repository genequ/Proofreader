# LM Studio Provider Support

**Date:** 2026-03-25
**Status:** Draft
**Author:** Claude

## Overview

Add LM Studio as a second LLM provider alongside Ollama. Users can switch between providers in Settings, with each provider maintaining its own URL and model selection.

## Requirements

- Users can select between Ollama and LM Studio as their LLM provider
- Each provider has its own URL and model settings that persist when switching
- LM Studio's OpenAI-compatible API is properly supported
- Model listing works with LM Studio's `/v1/models` endpoint
- Fallback to manual model entry if API listing fails
- Existing Ollama functionality remains unchanged

## Architecture

### Protocol-based Abstraction

Create a `LLMProvider` protocol that both services conform to:

```swift
protocol LLMProvider {
    func checkInstallation() async -> ProviderStatus
    func listModels() async throws -> [String]
    func generateStream(model: String, prompt: String) -> AsyncThrowingStream<String, Error>
    func stop(model: String) async
    func preload(model: String) async
    func updateBaseURL(_ url: String)
}
```

### Provider Enum

```swift
enum LLMProviderType: String, CaseIterable, Codable {
    case ollama = "Ollama"
    case lmstudio = "LM Studio"
}
```

### Service Architecture

- `OllamaService` - Existing service, conforms to `LLMProvider`
- `LMStudioService` - New service for LM Studio's OpenAI-compatible API
- Services remain independent - no shared base class

## Data Flow

1. **App Launch** - Load saved provider type, URL, and model from `@AppStorage`
2. **Provider Switch** - Instantiate appropriate service, check connection, load models
3. **Model Listing** - Try provider's API endpoint; if fails, show manual text field
4. **Proofreading** - Route to current provider's `generateStream` method

## Settings UI

```
┌─────────────────────────────────────┐
│ Status View (shows current provider)│
├─────────────────────────────────────┤
│ Provider: [Ollama ▾]                │
│                                     │
│ URL:    [http://127.0.0.1:11434]    │
│ Model:  [gemma3:4b         ▾]      │
│ Shortcut: [command+.]               │
│ Highlights: [━━━━━●━━━] 25%         │
└─────────────────────────────────────┘
```

### Provider-Specific Storage

Each provider's settings are saved separately:

```swift
@AppStorage("selectedProvider") var selectedProvider: LLMProviderType = .ollama

// Ollama settings
@AppStorage("ollamaURL") var ollamaURL: String = "http://127.0.0.1:11434"
@AppStorage("ollamaModel") var ollamaModel: String = "gemma3:4b"

// LM Studio settings
@AppStorage("lmstudioURL") var lmstudioURL: String = "http://127.0.0.1:1234/v1"
@AppStorage("lmstudioModel") var lmstudioModel: String = ""
```

## LM Studio API Details

### Configuration

- **Base URL**: `http://127.0.0.1:1234/v1` (default)
- **List Models**: `GET /v1/models`
- **Generate Stream**: `POST /v1/chat/completions` with `stream: true`
- **Stop Model**: Not supported - no-op implementation

### API Responses

**List Models Response:**
```json
{
  "data": [
    {"id": "deepseek-r1", "object": "model", ...},
    {"id": "llama-3-8b", "object": "model", ...}
  ]
}
```

**Stream Response:** Server-Sent Events (SSE) format compatible with OpenAI

## Component Changes

### New Files

1. **`Sources/LLMProvider.swift`** - Protocol and provider enum
2. **`Sources/LMStudioService.swift`** - LM Studio API client
3. **`Sources/LLMError.swift`** - Provider-agnostic error types

### Modified Files

1. **`Sources/AppState.swift`**
   - Add provider selection and provider-specific storage
   - Replace direct `ollamaService` calls with `currentProvider` computed property
   - Update `checkOllamaStatus()` → `checkProviderStatus()`

2. **`Sources/SettingsView.swift`**
   - Add provider dropdown at top
   - Switch URL/model bindings based on selected provider
   - Update OK/Cancel to handle provider-specific reverts

3. **`Sources/OllamaService.swift`**
   - Conform to `LLMProvider` protocol
   - No behavior changes

4. **`Sources/OllamaStatus.swift`** → **`Sources/ProviderStatus.swift`**
   - Rename to be provider-agnostic
   - Enum cases remain the same

5. **`Sources/OllamaError.swift`** → **`Sources/LLMError.swift`**
   - Rename and make provider-agnostic
   - Add LM Studio-specific error cases if needed

6. **Tests**
   - Add `Tests/LMStudioServiceTests.swift`
   - Update `Tests/AppStateTests.swift` for provider switching

## Error Handling

Provider-agnostic errors mapped to `LLMError`:

| Error | Ollama | LM Studio |
|-------|--------|-----------|
| `notInstalled` | Binary not found | Always "installed" (app-based) |
| `notRunning` | Connection refused | Connection refused on port 1234 |
| `noModelsAvailable` | Empty models list | Empty `/v1/models` response |
| `networkTimeout` | Request timeout | Request timeout |
| `invalidURL` | Malformed URL | Malformed URL |

## Testing Strategy

### Unit Tests

1. **LMStudioService**
   - API endpoint construction
   - Model listing with response parsing
   - Streaming with SSE parsing
   - Error mapping

2. **AppState provider switching**
   - Switching provider updates service reference
   - Provider-specific settings load/save correctly
   - Status check routes to correct service

3. **SettingsView**
   - Provider dropdown updates URL/model bindings
   - Cancel reverts to provider-specific original values
   - OK saves current provider's settings

### Integration Tests

1. Provider independence - settings don't leak between providers
2. Model listing fallback - LM Studio falls back to manual entry
3. Service isolation - `stop()` on LM Studio is safe no-op

### Manual Testing

- [ ] Install LM Studio, load a model, verify connection
- [ ] Switch between providers, verify settings persist
- [ ] Test proofreading with each provider
- [ ] Test with LM Studio not running (error handling)
- [ ] Test with Ollama not running (error handling)

## Implementation Notes

1. **LM Studio model unloading** - Unlike Ollama, LM Studio doesn't have a CLI command to stop models. Models are automatically unloaded after a timeout. The `stop()` method will be a no-op for LM Studio.

2. **Streaming format** - LM Studio uses OpenAI's SSE format with `data:` prefixes. Need to parse this differently from Ollama's JSON-line format.

3. **Prompt format** - LM Studio expects OpenAI's chat completions format:
   ```json
   {
     "model": "model-name",
     "messages": [{"role": "user", "content": "prompt"}],
     "stream": true
   }
   ```

4. **Backward compatibility** - Existing users with `ollamaURL` and `currentModel` settings will continue to work. The new `selectedProvider` defaults to `.ollama`.
