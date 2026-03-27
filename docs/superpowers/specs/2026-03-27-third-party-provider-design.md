# Third-Party Provider Support Design

**Date:** 2026-03-27
**Status:** Draft
**Author:** Claude Code

## Overview

Add support for third-party API-based LLM providers, starting with DeepSeek. This enables users to use cloud-based AI services alongside local providers (Ollama, LM Studio).

## Requirements

- Add DeepSeek as a new provider option
- When DeepSeek is selected, display "API Key" field instead of "URL" field
- Securely store API key in UserDefaults
- Fetch available models from DeepSeek's API
- Use OpenAI-compatible API format for requests

## Architecture

### Provider Type Extension

```swift
enum LLMProviderType: String, CaseIterable, Codable {
    case ollama = "Ollama"
    case lmstudio = "LM Studio"
    case deepseek = "DeepSeek"
}
```

### DeepSeekService Actor

New file: `Sources/DeepSeekService.swift`

```swift
@preconcurrency actor DeepSeekService: @preconcurrency LLMProvider {
    private var apiKey: String
    private let baseURL = "https://api.deepseek.com/v1"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func updateAPIKey(_ key: String) {
        self.apiKey = key
    }

    // Implement LLMProvider protocol with OpenAI-compatible API
    // - checkInstallation() validates API key via /models endpoint
    // - listModels() returns available DeepSeek models
    // - generateStream() uses /chat/completions with streaming
}
```

### State Management (AppState.swift)

Add properties:
```swift
@AppStorage("deepseekApiKey") private(set) var deepseekApiKey: String = ""
@AppStorage("deepseekModel") var deepseekModel: String = "deepseek-chat"

// Computed property to get current API key based on provider
var currentAPIKey: String {
    switch selectedProvider {
    case .deepseek: return deepseekApiKey
    default: return ""
    }
}
```

### UI Changes (SettingsView.swift)

Conditional field rendering:
```swift
// Replace URL field with API Key field for DeepSeek
if appState.selectedProvider == .deepseek {
    HStack {
        Text("API Key:")
            .frame(width: 80, alignment: .trailing)
        SecureField("Enter API Key", text: $appState.deepseekApiKey)
            .textFieldStyle(RoundedBorderTextFieldStyle())
    }
} else {
    // Existing URL field
    HStack {
        Text("URL:")
            .frame(width: 80, alignment: .trailing)
        TextField("Provider URL", text: $appState.currentProviderURL)
            .textFieldStyle(RoundedBorderTextFieldStyle())
    }
}
```

### API Models (DeepSeekService.swift)

OpenAI-compatible request/response models (can reuse LM Studio's structs):
- `DeepSeekChatRequest` (same as LMStudioChatRequest)
- `DeepSeekChatResponse` (same as LMStudioChatResponse)
- `DeepSeekStreamChunk` (same as LMStudioStreamChunk)

## Data Flow

### Initialization
1. User selects "DeepSeek" from provider picker
2. UI switches to show API Key field
3. User enters API key and clicks OK
4. `deepseekApiKey` saved to UserDefaults
5. `DeepSeekService` instantiated with API key
6. Health check validates API key via `/models` endpoint

### Proofreading
1. User triggers proofreading
2. `AppState.proofreadText()` uses current provider
3. For DeepSeek: API key added to request header `Authorization: Bearer <key>`
4. Streaming response processed same as LM Studio

## Error Handling

- Invalid API key → `LLMError.unauthorized` (401 response)
- Rate limit → `LLMError.rateLimitExceeded` (429 response)
- Network errors → existing `LLMError` types

## Testing

Unit tests in `Tests/DeepSeekServiceTests.swift`:
- `testCheckInstallationWithValidKey` - returns connected status
- `testCheckInstallationWithInvalidKey` - returns error status
- `testListModels` - returns model list
- `testGenerateStream` - yields streamed content

## Security Considerations

- API keys stored in UserDefaults (per user requirement)
- API key never logged or displayed in plain text after entry
- Requests use HTTPS only

## Future Extensions

- Add more providers: OpenAI, Anthropic, Google Gemini
- Provider-specific settings (temperature, max tokens)
- API key rotation support
- Usage/cost tracking per provider
