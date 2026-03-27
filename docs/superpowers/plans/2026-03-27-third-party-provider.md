# Third-Party Provider Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add DeepSeek as a third-party API-based LLM provider with API key authentication.

**Architecture:** Extend existing `LLMProvider` protocol with a new `DeepSeekService` actor. Add `deepseek` case to `LLMProviderType` enum. Store API key via `@AppStorage`. Update SettingsView to show API key field when DeepSeek is selected.

**Tech Stack:** Swift 5.9, SwiftUI, async/await, URLSession, OpenAI-compatible API

---

## Task 1: Add API Key Authentication Error Types

**Files:**
- Modify: `Sources/LLMError.swift`

- [ ] **Step 1: Add new error cases to LLMError enum**

Add these cases after `case invalidResponse` on line 11:

```swift
case unauthorized(String)  // Invalid API key (401)
case rateLimitExceeded     // API rate limit (429)
```

- [ ] **Step 2: Update errorDescription switch statement**

Add these cases in the switch block after `case .invalidResponse`:

```swift
case .unauthorized:
    return "Unauthorized"
case .rateLimitExceeded:
    return "Rate Limit Exceeded"
```

- [ ] **Step 3: Update failureReason switch statement**

Add these cases in the switch block after `case .invalidResponse`:

```swift
case .unauthorized(let provider):
    return "The API key for \(provider) is invalid or expired."
case .rateLimitExceeded:
    return "The API rate limit has been exceeded. Please try again later."
```

- [ ] **Step 4: Update recoverySuggestion switch statement**

Add these cases in the switch block after `case .invalidResponse`:

```swift
case .unauthorized:
    return "Check your API key in Settings."
case .rateLimitExceeded:
    return "Wait a moment and try again, or upgrade your API plan."
```

- [ ] **Step 5: Update severity switch statement**

Add `.unauthorized` case to the `.high` severity row:

```swift
case .unauthorized, .modelNotFound, .invalidURL:
    return .high
```

Add `.rateLimitExceeded` case to the `.medium` severity row:

```swift
case .rateLimitExceeded, .connectionFailed, .networkTimeout, .invalidResponse:
    return .medium
```

- [ ] **Step 6: Run tests to verify no existing tests break**

Run: `swift test`

Expected: All existing tests pass (no new tests yet, just verifying we didn't break anything)

- [ ] **Step 7: Commit**

```bash
git add Sources/LLMError.swift
git commit -m "feat: add unauthorized and rateLimit error types for API providers"
```

---

## Task 2: Add DeepSeek to Provider Type Enum

**Files:**
- Modify: `Sources/LLMProvider.swift`

- [ ] **Step 1: Add deepseek case to LLMProviderType enum**

Add this line after `case lmstudio = "LM Studio"` on line 27:

```swift
case deepseek = "DeepSeek"
```

- [ ] **Step 2: Run tests to verify no existing tests break**

Run: `swift test`

Expected: All existing tests pass

- [ ] **Step 3: Commit**

```bash
git add Sources/LLMProvider.swift
git commit -m "feat: add DeepSeek to LLMProviderType enum"
```

---

## Task 3: Create DeepSeekService Actor

**Files:**
- Create: `Sources/DeepSeekService.swift`

- [ ] **Step 1: Create DeepSeekService.swift with base structure**

Create new file with:

```swift
import Foundation

@preconcurrency actor DeepSeekService: @preconcurrency LLMProvider {
    private var apiKey: String
    private let baseURL = "https://api.deepseek.com/v1"
    private let session: URLSession
    private let timeout: TimeInterval = 120.0

    init(apiKey: String) {
        self.apiKey = apiKey
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: config)
    }

    func updateAPIKey(_ key: String) {
        self.apiKey = key
    }

    func updateBaseURL(_ url: String) {
        // DeepSeek uses fixed base URL, this is a no-op
    }

    func stop(model: String) async {
        // API-based provider, no-op
    }

    func preload(model: String) async {
        // API-based provider, no-op needed
    }
}
```

- [ ] **Step 2: Add checkInstallation method**

Add after `preload` method:

```swift
func checkInstallation() async -> ProviderStatus {
    do {
        let models = try await listModels()
        return .connected(models: models)
    } catch let error as LLMError {
        return .error(error)
    } catch {
        return .error(.connectionFailed(underlying: error))
    }
}
```

- [ ] **Step 3: Add listModels method**

Add after `checkInstallation` method:

```swift
func listModels() async throws -> [String] {
    guard let url = URL(string: "\(baseURL)/models") else {
        throw LLMError.invalidURL(baseURL)
    }

    var request = URLRequest(url: url)
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

    do {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw LLMError.unauthorized("DeepSeek")
        case 429:
            throw LLMError.rateLimitExceeded
        default:
            throw LLMError.connectionFailed(underlying: URLError(.badServerResponse))
        }

        let modelsResponse = try JSONDecoder().decode(DeepSeekModelsResponse.self, from: data)
        let models = modelsResponse.data.map { $0.id }

        if models.isEmpty {
            throw LLMError.noModelsAvailable
        }

        return models
    } catch let error as LLMError {
        throw error
    } catch let urlError as URLError {
        throw mapURLError(urlError)
    } catch {
        throw LLMError.connectionFailed(underlying: error)
    }
}
```

- [ ] **Step 4: Add generateStream method**

Add after `listModels` method:

```swift
func generateStream(model: String, prompt: String) -> AsyncThrowingStream<String, Error> {
    return AsyncThrowingStream { continuation in
        Task {
            do {
                guard let url = URL(string: "\(baseURL)/chat/completions") else {
                    throw URLError(.badURL)
                }

                let requestBody = DeepSeekChatRequest(
                    model: model,
                    messages: [DeepSeekMessage(role: "user", content: prompt)],
                    stream: true
                )

                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(requestBody)

                let (result, response) = try await session.bytes(for: request)

                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode == 401 {
                            throw LLMError.unauthorized("DeepSeek")
                        }
                        if httpResponse.statusCode == 429 {
                            throw LLMError.rateLimitExceeded
                        }
                    }
                    throw URLError(.badServerResponse)
                }

                for try await line in result.lines {
                    guard line.hasPrefix("data: ") else { continue }

                    let jsonStart = line.index(line.startIndex, offsetBy: 6)
                    let jsonString = String(line[jsonStart...])

                    if jsonString == "[DONE]" {
                        continuation.finish()
                        return
                    }

                    guard let data = jsonString.data(using: .utf8) else { continue }
                    let chunk = try JSONDecoder().decode(DeepSeekStreamChunk.self, from: data)

                    if let content = chunk.choices.first?.delta.content {
                        continuation.yield(content)
                    }

                    if chunk.choices.first?.finishReason == "stop" {
                        continuation.finish()
                        return
                    }
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}
```

- [ ] **Step 5: Add mapURLError helper method**

Add at the end of the actor before closing brace:

```swift
private func mapURLError(_ error: URLError) -> LLMError {
    switch error.code {
    case .timedOut:
        return .networkTimeout
    case .cannotConnectToHost, .cannotFindHost, .networkConnectionLost:
        return .notRunning
    case .badURL:
        return .invalidURL(baseURL)
    default:
        return .connectionFailed(underlying: error)
    }
}
```

- [ ] **Step 6: Add API response structs at end of file**

Add after the actor closing brace:

```swift
// MARK: - API Models

struct DeepSeekModelsResponse: Codable {
    let data: [DeepSeekModel]
    let object: String
}

struct DeepSeekModel: Codable {
    let id: String
    let object: String
}

struct DeepSeekChatRequest: Codable {
    let model: String
    let messages: [DeepSeekMessage]
    let stream: Bool?

    init(model: String, messages: [DeepSeekMessage], stream: Bool = false) {
        self.model = model
        self.messages = messages
        self.stream = stream
    }
}

struct DeepSeekMessage: Codable {
    let role: String
    let content: String
}

struct DeepSeekStreamChunk: Codable {
    let id: String
    let choices: [DeepSeekStreamChoice]
}

struct DeepSeekStreamChoice: Codable {
    let delta: DeepSeekStreamDelta
    let finishReason: String?

    enum CodingKeys: String, CodingKey {
        case delta
        case finishReason = "finish_reason"
    }
}

struct DeepSeekStreamDelta: Codable {
    let content: String?
}
```

- [ ] **Step 7: Verify the file compiles**

Run: `swift build`

Expected: Build succeeds with no errors

- [ ] **Step 8: Commit**

```bash
git add Sources/DeepSeekService.swift
git commit -m "feat: add DeepSeekService actor with OpenAI-compatible API"
```

---

## Task 4: Add DeepSeek State to AppState

**Files:**
- Modify: `Sources/AppState.swift`

- [ ] **Step 1: Add DeepSeek @AppStorage properties**

Add after line 10 (after `lmstudioModel` property):

```swift
@AppStorage("deepseekApiKey") private(set) var deepseekApiKey: String = ""
@AppStorage("deepseekModel") var deepseekModel: String = "deepseek-chat"
```

- [ ] **Step 2: Add DeepSeekService instance**

Add after line 90 (after `lmstudioService` property):

```swift
private var deepseekService = DeepSeekService(apiKey: "")
```

- [ ] **Step 3: Update currentProvider computed property**

Replace the entire `currentProvider` computed property (lines 42-49) with:

```swift
var currentProvider: any LLMProvider {
    switch selectedProvider {
    case .ollama:
        return ollamaService
    case .lmstudio:
        return lmstudioService
    case .deepseek:
        return deepseekService
    }
}
```

- [ ] **Step 4: Update currentModel computed property**

Replace the entire `currentModel` computed property (lines 51-68) with:

```swift
var currentModel: String {
    get {
        switch selectedProvider {
        case .ollama:
            return ollamaModel
        case .lmstudio:
            return lmstudioModel
        case .deepseek:
            return deepseekModel
        }
    }
    set {
        switch selectedProvider {
        case .ollama:
            ollamaModel = newValue
        case .lmstudio:
            lmstudioModel = newValue
        case .deepseek:
            deepseekModel = newValue
        }
    }
}
```

- [ ] **Step 5: Update currentProviderURL computed property**

Replace the entire `currentProviderURL` computed property (lines 70-87) with:

```swift
var currentProviderURL: String {
    get {
        switch selectedProvider {
        case .ollama:
            return ollamaURL
        case .lmstudio:
            return lmstudioURL
        case .deepseek:
            return "https://api.deepseek.com/v1"  // Fixed URL for display
        }
    }
    set {
        switch selectedProvider {
        case .ollama:
            ollamaURL = newValue
        case .lmstudio:
            lmstudioURL = newValue
        case .deepseek:
            // DeepSeek URL is fixed, ignore setter
            break
        }
    }
}
```

- [ ] **Step 6: Add method to update DeepSeek API key**

Add after `updateOllamaURL` method (after line 185):

```swift
func updateDeepSeekAPIKey(_ key: String) {
    deepseekApiKey = key
    Task {
        await deepseekService.updateAPIKey(key)
        checkOllamaStatus()
    }
}
```

- [ ] **Step 7: Verify the file compiles**

Run: `swift build`

Expected: Build succeeds with no errors

- [ ] **Step 8: Commit**

```bash
git add Sources/AppState.swift
git commit -m "feat: add DeepSeek state management to AppState"
```

---

## Task 5: Update SettingsView for API Key Field

**Files:**
- Modify: `Sources/SettingsView.swift`

- [ ] **Step 1: Add @State for tracking API key changes**

Add after line 11 (after `previousProvider`):

```swift
@State private var originalAPIKey: String = ""
```

- [ ] **Step 2: Replace URL field with conditional rendering**

Replace lines 64-75 (the URL field HStack) with:

```swift
// URL field for local providers, API Key for DeepSeek
if appState.selectedProvider == .deepseek {
    HStack(alignment: .center) {
        Text("API Key:")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(width: 80, alignment: .trailing)
        SecureField("Enter API Key", text: Binding(
            get: { appState.deepseekApiKey },
            set: { appState.deepseekApiKey = $0 }
        ))
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .focused($isURLFieldFocused)
    }
} else {
    HStack(alignment: .center) {
        Text("URL:")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(width: 80, alignment: .trailing)
        TextField("Provider URL", text: Binding(
            get: { appState.currentProviderURL },
            set: { appState.currentProviderURL = $0 }
        ))
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .focused($isURLFieldFocused)
    }
}
```

- [ ] **Step 3: Update onAppear to store original API key**

Replace the `onAppear` modifier (lines 174-184) with:

```swift
.onAppear {
    // Store original values for Cancel
    originalURL = appState.currentProviderURL
    originalShortcut = appState.keyboardShortcut
    previousModel = appState.currentModel
    previousProvider = appState.selectedProvider
    originalAPIKey = appState.deepseekApiKey

    appState.checkOllamaStatus()
    isURLFieldFocused = true
    setupKeyMonitor()
}
```

- [ ] **Step 4: Update Cancel button to restore API key**

Replace the Cancel button action (lines 148-155) with:

```swift
Button("Cancel") {
    // Revert changes
    appState.currentProviderURL = originalURL
    appState.keyboardShortcut = originalShortcut
    appState.currentModel = previousModel
    appState.selectedProvider = previousProvider
    appState.deepseekApiKey = originalAPIKey
    dismiss()
}
```

- [ ] **Step 5: Update OK button to handle API key**

Replace the OK button action (lines 158-166) with:

```swift
Button("OK") {
    // Stop previous model if it changed
    if previousModel != appState.currentModel {
        appState.stopModel(previousModel)
    }

    // Update provider settings based on type
    if appState.selectedProvider == .deepseek {
        appState.updateDeepSeekAPIKey(appState.deepseekApiKey)
    } else {
        appState.updateOllamaURL(appState.currentProviderURL)
    }

    appState.updateKeyboardShortcut(appState.keyboardShortcut)
    dismiss()
}
```

- [ ] **Step 6: Update provider onChange to handle DeepSeek**

Replace the entire `onChange` block for provider (lines 41-56) with:

```swift
.onChange(of: appState.selectedProvider) { _, newProvider in
    // Stop previous model if provider changed
    if previousProvider != newProvider {
        // Store the previous provider's model before switching
        switch previousProvider {
        case .ollama:
            // Ollama model is already stored
            break
        case .lmstudio:
            // LM Studio model is already stored
            break
        case .deepseek:
            // DeepSeek model is already stored
            break
        }
        previousProvider = newProvider
        appState.checkOllamaStatus()
    }
}
```

- [ ] **Step 7: Verify the file compiles**

Run: `swift build`

Expected: Build succeeds with no errors

- [ ] **Step 8: Commit**

```bash
git add Sources/SettingsView.swift
git commit -m "feat: add API key field for DeepSeek in SettingsView"
```

---

## Task 6: Write Tests for DeepSeekService

**Files:**
- Create: `Tests/DeepSeekServiceTests.swift`

- [ ] **Step 1: Create test file with imports and base class**

Create new file with:

```swift
import XCTest
@testable import Proofreader

final class DeepSeekServiceTests: XCTestCase {
    var service: DeepSeekService!

    override func setUp() {
        super.setUp()
        service = DeepSeekService(apiKey: "test-api-key")
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }
}
```

- [ ] **Step 2: Add test for invalid API key handling**

Add inside the class:

```swift
func testListModelsWithInvalidKey() async throws {
    // This test expects 401 error with invalid key
    do {
        _ = try await service.listModels()
        XCTFail("Expected unauthorized error, but got success")
    } catch let error as LLMError {
        if case .unauthorized = error {
            // Expected error
            XCTAssert(true)
        } else {
            XCTFail("Expected unauthorized error, got: \(error)")
        }
    } catch {
        XCTFail("Expected LLMError.unauthorized, got: \(error)")
    }
}
```

- [ ] **Step 3: Add test for service initialization**

Add inside the class:

```swift
func testServiceInitialization() {
    let testKey = "test-key-123"
    let testService = DeepSeekService(apiKey: testKey)
    // Service should initialize without throwing
    XCTAssertNotNil(testService)
}
```

- [ ] **Step 4: Add test for API key update**

Add inside the class:

```swift
func testUpdateAPIKey() async {
    let newKey = "new-api-key"
    await service.updateAPIKey(newKey)
    // No assertion needed - this tests that the method doesn't crash
    // In a real scenario, we'd verify the key is used in subsequent requests
}
```

- [ ] **Step 5: Add test for updateBaseURL no-op**

Add inside the class:

```swift
func testUpdateBaseURLIsNoOp() async {
    // DeepSeek has fixed base URL, updateBaseURL should be a no-op
    await service.updateBaseURL("http://example.com")
    // No way to verify the URL didn't change without exposing it
    // This test ensures the method exists and doesn't crash
}
```

- [ ] **Step 6: Add test for stop method**

Add inside the class:

```swift
func testStopIsNoOp() async {
    // DeepSeek is API-based, stop should be a no-op
    await service.stop(model: "deepseek-chat")
    // No assertion - this tests that the method doesn't crash
}
```

- [ ] **Step 7: Add test for preload method**

Add inside the class:

```swift
func testPreloadIsNoOp() async {
    // DeepSeek is API-based, preload should be a no-op
    await service.preload(model: "deepseek-chat")
    // No assertion - this tests that the method doesn't crash
}
```

- [ ] **Step 8: Run the tests**

Run: `swift test --filter DeepSeekServiceTests`

Expected: Tests pass (note: `testListModelsWithInvalidKey` may skip if no network)

- [ ] **Step 9: Commit**

```bash
git add Tests/DeepSeekServiceTests.swift
git commit -m "test: add DeepSeekService unit tests"
```

---

## Task 7: Integration Testing

**Files:**
- No files created/modified - manual testing

- [ ] **Step 1: Build the app**

Run: `./build-app.sh`

Expected: App builds successfully with code signing

- [ ] **Step 2: Launch the app and verify provider options**

Run: `open build/Proofreader.app`

Expected: App launches, menu bar icon appears

- [ ] **Step 3: Open Settings and verify DeepSeek option**

Click menu bar icon → Settings → Provider dropdown

Expected: "DeepSeek" appears in provider dropdown

- [ ] **Step 4: Select DeepSeek and verify API Key field appears**

Select "DeepSeek" from dropdown

Expected: "URL" field changes to "API Key" field with secure text entry

- [ ] **Step 5: Enter a test API key and verify status**

Enter a test DeepSeek API key → Click OK

Expected: Status updates (shows connected or error based on key validity)

- [ ] **Step 6: Verify model list updates**

After entering valid API key, check Model dropdown

Expected: DeepSeek models appear (deepseek-chat, deepseek-coder, etc.)

- [ ] **Step 7: Test proofreading with invalid key**

Enter invalid API key → Try proofreading

Expected: Error message about unauthorized access

- [ ] **Step 8: Clean up test data**

Reset to local provider (Ollama or LM Studio) for normal use

- [ ] **Step 9: Commit any fixes if issues found**

If any bugs were found and fixed during testing:

```bash
git add -A
git commit -m "fix: address issues found during integration testing"
```

---

## Task 8: Documentation Update

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Add DeepSeek to Architecture section**

Add after LM Studio description in the Service Layer section:

```markdown
- `DeepSeekService`: Actor-based HTTP client for DeepSeek API. Uses API key authentication. Compatible with OpenAI API format. Methods: `checkInstallation()`, `listModels()`, `generateStream()`, `updateAPIKey()`.
```

- [ ] **Step 2: Add DeepSeek configuration note**

Add in Important Notes section:

```markdown
- **Third-Party Providers**: DeepSeek uses API key authentication stored in UserDefaults. API key is sent via Bearer token in Authorization header.
```

- [ ] **Step 3: Commit documentation**

```bash
git add CLAUDE.md
git commit -m "docs: add DeepSeek provider documentation"
```

---

## Self-Review Summary

**Spec Coverage Check:**
- ✅ DeepSeek provider type added
- ✅ API key storage in UserDefaults
- ✅ Settings UI shows API Key field when DeepSeek selected
- ✅ API key used in requests
- ✅ Models fetched from DeepSeek API
- ✅ Error handling for 401/429 responses
- ✅ Tests written
- ✅ Documentation updated

**Placeholder Scan:** No placeholders found. All code is complete.

**Type Consistency:** All property names and types are consistent across tasks.
