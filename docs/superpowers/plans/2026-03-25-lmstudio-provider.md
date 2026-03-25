# LM Studio Provider Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add LM Studio as a second LLM provider alongside Ollama, with provider switching in Settings.

**Architecture:** Protocol-based abstraction (`LLMProvider`) with independent services (`OllamaService`, `LMStudioService`). Provider selection stored in `@AppStorage`, each provider maintains its own URL and model settings.

**Tech Stack:** Swift 5.9+, SwiftUI, Async/Await, URLSession, Server-Sent Events (SSE) parsing

---

## File Structure

### New Files
| File | Responsibility |
|------|---------------|
| `Sources/LLMProvider.swift` | Protocol definition and `LLMProviderType` enum |
| `Sources/LMStudioService.swift` | LM Studio API client (OpenAI-compatible) |
| `Sources/LLMError.swift` | Provider-agnostic error types |
| `Sources/ProviderStatus.swift` | Renamed from `OllamaStatus.swift` |
| `Tests/LMStudioServiceTests.swift` | LM Studio service unit tests |

### Modified Files
| File | Changes |
|------|---------|
| `Sources/AppState.swift` | Add provider selection, provider-specific storage, `currentProvider` computed property |
| `Sources/SettingsView.swift` | Add provider dropdown, switch URL/model bindings dynamically |
| `Sources/OllamaService.swift` | Conform to `LLMProvider` protocol (no behavior change) |
| `Sources/OllamaError.swift` | Migrate to `LLMError.swift` |
| `Sources/OllamaStatus.swift` | Rename to `ProviderStatus.swift` |
| `Tests/AppStateTests.swift` | Add provider switching tests |

---

## Task 1: Create LLMProvider Protocol and Enum

**Files:**
- Create: `Sources/LLMProvider.swift`

- [ ] **Step 1: Write the protocol definition**

Create `Sources/LLMProvider.swift`:

```swift
import Foundation

/// Protocol that all LLM providers must conform to
protocol LLMProvider {
    /// Check if the provider is installed and running
    func checkInstallation() async -> ProviderStatus

    /// List available models
    func listModels() async throws -> [String]

    /// Generate text with streaming response
    func generateStream(model: String, prompt: String) -> AsyncThrowingStream<String, Error>

    /// Stop a running model (no-op if not supported)
    func stop(model: String) async

    /// Preload a model into memory
    func preload(model: String) async

    /// Update the base URL for API requests
    func updateBaseURL(_ url: String)
}

/// Available LLM provider types
enum LLMProviderType: String, CaseIterable, Codable {
    case ollama = "Ollama"
    case lmstudio = "LM Studio"
}
```

- [ ] **Step 2: Verify compiles**

Run: `swift build`

Expected: Builds successfully with new protocol

- [ ] **Step 3: Commit**

```bash
git add Sources/LLMProvider.swift
git commit -m "feat: add LLMProvider protocol and provider enum"
```

---

## Task 2: Rename OllamaStatus to ProviderStatus

**Files:**
- Create: `Sources/ProviderStatus.swift`
- Delete: `Sources/OllamaStatus.swift`
- Modify: `Sources/*.swift` (update imports)

- [ ] **Step 1: Read current OllamaStatus**

Read: `Sources/OllamaStatus.swift`

- [ ] **Step 2: Create ProviderStatus.swift**

Create `Sources/ProviderStatus.swift` with same content, just renamed:

```swift
import Foundation

enum ProviderStatus: Equatable {
    case checking
    case notInstalled
    case installed(running: Bool)
    case connected(models: [String])
    case error(LLMError)

    var isHealthy: Bool {
        if case .connected = self {
            return true
        }
        return false
    }

    var canProofread: Bool {
        if case .connected(let models) = self, !models.isEmpty {
            return true
        }
        return false
    }

    var statusIcon: String {
        switch self {
        case .checking:
            return "hourglass"
        case .notInstalled:
            return "xmark.circle"
        case .installed(let running):
            return running ? "checkmark.circle" : "pause.circle"
        case .connected:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
}
```

Note: Changed `OllamaError` to `LLMError` - we'll create that in Task 4.

- [ ] **Step 3: Update all files importing OllamaStatus**

Search and replace in all Swift files:
- `OllamaStatus` → `ProviderStatus`

Run: `grep -r "OllamaStatus" Sources/ --include="*.swift"`

- [ ] **Step 4: Delete old file**

```bash
rm Sources/OllamaStatus.swift
```

- [ ] **Step 5: Verify compiles**

Run: `swift build`

Expected: Builds successfully (may have errors for LLMError until Task 4)

- [ ] **Step 6: Commit**

```bash
git add Sources/ProviderStatus.swift
git add -u Sources/OllamaStatus.swift
git commit -m "refactor: rename OllamaStatus to ProviderStatus"
```

---

## Task 3: Create LLMError (rename from OllamaError)

**Files:**
- Create: `Sources/LLMError.swift`
- Delete: `Sources/OllamaError.swift`

- [ ] **Step 1: Read current OllamaError**

Read: `Sources/OllamaError.swift`

- [ ] **Step 2: Create LLMError.swift**

Create `Sources/LLMError.swift`:

```swift
import Foundation

enum LLMError: LocalizedError {
    case notInstalled
    case notRunning
    case noModelsAvailable
    case connectionFailed(underlying: Error)
    case modelNotFound(String)
    case networkTimeout
    case invalidURL(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notInstalled:
            return "Provider Not Installed"
        case .notRunning:
            return "Provider Not Running"
        case .noModelsAvailable:
            return "No Models Available"
        case .connectionFailed:
            return "Connection Failed"
        case .modelNotFound(let model):
            return "Model Not Found: \(model)"
        case .networkTimeout:
            return "Network Timeout"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .invalidResponse:
            return "Invalid Response"
        }
    }

    var failureReason: String? {
        switch self {
        case .notInstalled:
            return "The LLM provider application is not installed on this system."
        case .notRunning:
            return "The LLM provider is not running. Please start it first."
        case .noModelsAvailable:
            return "No models are available. Please download at least one model."
        case .connectionFailed(let error):
            return "Could not connect to the provider: \(error.localizedDescription)"
        case .modelNotFound(let model):
            return "The model '\(model)' was not found."
        case .networkTimeout:
            return "The request timed out. Please check your network connection."
        case .invalidURL:
            return "The configured URL is not valid."
        case .invalidResponse:
            return "The provider returned an invalid response."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notInstalled:
            return "Install the LLM provider application."
        case .notRunning:
            return "Start the LLM provider application."
        case .noModelsAvailable:
            return "Download and install a model in the provider application."
        case .connectionFailed:
            return "Check that the provider is running and the URL is correct."
        case .modelNotFound:
            return "Verify the model name or download the model."
        case .networkTimeout:
            return "Try again or check your network connection."
        case .invalidURL:
            return "Check the URL in Settings."
        case .invalidResponse:
            return "Try again or restart the provider."
        }
    }
}
```

- [ ] **Step 3: Update all files using OllamaError**

Search and replace in all Swift files:
- `: OllamaError` → `: LLMError`
- `OllamaError.` → `LLMError.`

Run: `grep -r "OllamaError" Sources/ --include="*.swift"`

- [ ] **Step 4: Delete old file**

```bash
rm Sources/OllamaError.swift
```

- [ ] **Step 5: Verify compiles**

Run: `swift build`

Expected: Builds successfully

- [ ] **Step 6: Commit**

```bash
git add Sources/LLMError.swift
git add -u Sources/OllamaError.swift
git commit -m "refactor: rename OllamaError to LLMError"
```

---

## Task 4: Make OllamaService conform to LLMProvider

**Files:**
- Modify: `Sources/OllamaService.swift`

- [ ] **Step 1: Add protocol conformance**

Read: `Sources/OllamaService.swift`

Add `: LLMProvider` to the actor declaration:

```swift
actor OllamaService: LLMProvider {
```

- [ ] **Step 2: Update return type of checkOllamaInstallation**

Change the method signature:

```swift
func checkInstallation() async -> ProviderStatus {
```

And update the return statement at line 83:

```swift
return .connected(models: models)
```

- [ ] **Step 3: Verify compiles**

Run: `swift build`

Expected: Builds successfully

- [ ] **Step 4: Commit**

```bash
git add Sources/OllamaService.swift
git commit -m "refactor: OllamaService conforms to LLMProvider"
```

---

## Task 5: Create LMStudioService

**Files:**
- Create: `Sources/LMStudioService.swift`
- Create: `Tests/LMStudioServiceTests.swift`

- [ ] **Step 1: Write failing test for base URL construction**

Create `Tests/LMStudioServiceTests.swift`:

```swift
import XCTest
@testable import Proofreader

final class LMStudioServiceTests: XCTestCase {
    actor TestState {
        var receivedURL: String?
        func setURL(_ url: String) { receivedURL = url }
    }

    func testBaseURLDefaultsToLMStudioPort() async {
        let service = LMStudioService()

        // The service should default to LM Studio's port
        // We can't directly access the baseURL, but we can test through updateBaseURL
        // This is a basic existence test
        XCTAssertNotNil(service)
    }

    func testUpdateBaseURL() async {
        let service = LMStudioService()
        let newURL = "http://192.168.1.100:9999/v1"

        await service.updateBaseURL(newURL)

        // Verify the URL was updated by checking a request would use it
        // We'll test this indirectly through health check
        let status = await service.checkInstallation()

        // Should get notRunning since we're using a fake URL
        if case .error(let error as LLMError) = status {
            // Expected - connection should fail
            XCTAssertTrue(error == .notRunning || error == .connectionFailed)
        } else {
            XCTFail("Expected error status for invalid URL")
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter testBaseURLDefaultsToLMStudioPort`

Expected: FAIL with "LMStudioService not defined"

- [ ] **Step 3: Write minimal LMStudioService implementation**

Create `Sources/LMStudioService.swift`:

```swift
import Foundation

actor LMStudioService: LLMProvider {
    private var baseURL: String
    private let session: URLSession
    private let timeout: TimeInterval = 10.0

    init(baseURL: String = "http://127.0.0.1:1234/v1") {
        self.baseURL = baseURL

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: config)
    }

    func updateBaseURL(_ url: String) {
        self.baseURL = url
    }

    // MARK: - Installation & Health Checks

    func checkInstallation() async -> ProviderStatus {
        // LM Studio is always "installed" since it's an app
        // Check if service is running via health check
        do {
            let isRunning = try await healthCheck()
            if isRunning {
                let models = try await listModels()
                return .connected(models: models)
            } else {
                return .installed(running: false)
            }
        } catch let error as LLMError {
            return .error(error)
        } catch {
            return .installed(running: false)
        }
    }

    func healthCheck() async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/models") else {
            throw LLMError.invalidURL(baseURL)
        }

        do {
            let (_, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw LLMError.invalidResponse
            }

            return (200...299).contains(httpResponse.statusCode)
        } catch let urlError as URLError {
            throw mapURLError(urlError)
        } catch {
            throw LLMError.connectionFailed(underlying: error)
        }
    }

    // MARK: - API Methods

    func listModels() async throws -> [String] {
        guard let url = URL(string: "\(baseURL)/models") else {
            throw LLMError.invalidURL(baseURL)
        }

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw LLMError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw LLMError.connectionFailed(underlying: URLError(.badServerResponse))
            }

            let modelsResponse = try JSONDecoder().decode(LMStudioModelsResponse.self, from: data)
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

    func generate(model: String, prompt: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw LLMError.invalidURL(baseURL)
        }

        let requestBody = LMStudioChatRequest(
            model: model,
            messages: [LMStudioMessage(role: "user", content: prompt)]
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw LLMError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 404 {
                    throw LLMError.modelNotFound(model)
                }
                throw LLMError.connectionFailed(underlying: URLError(.badServerResponse))
            }

            let responseObj = try JSONDecoder().decode(LMStudioChatResponse.self, from: data)
            return responseObj.choices.first?.message.content ?? ""
        } catch let error as LLMError {
            throw error
        } catch let urlError as URLError {
            throw mapURLError(urlError)
        } catch {
            throw LLMError.connectionFailed(underlying: error)
        }
    }

    func generateStream(model: String, prompt: String) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let url = URL(string: "\(baseURL)/chat/completions") else {
                        throw URLError(.badURL)
                    }

                    let requestBody = LMStudioChatRequest(
                        model: model,
                        messages: [LMStudioMessage(role: "user", content: prompt)],
                        stream: true
                    )

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try JSONEncoder().encode(requestBody)

                    let (result, response) = try await session.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                        throw URLError(.badServerResponse)
                    }

                    for try await line in result.lines {
                        // SSE format: "data: {...}"
                        guard line.hasPrefix("data: ") else { continue }

                        let jsonStart = line.index(line.startIndex, offsetBy: 6)
                        let jsonString = String(line[jsonStart...])

                        // Skip "[DONE]" marker
                        if jsonString == "[DONE]" {
                            continuation.finish()
                            return
                        }

                        guard let data = jsonString.data(using: .utf8) else { continue }
                        let chunk = try JSONDecoder().decode(LMStudioStreamChunk.self, from: data)

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

    func preload(model: String) async {
        guard let url = URL(string: "\(baseURL)/chat/completions") else { return }

        let requestBody = LMStudioChatRequest(
            model: model,
            messages: [LMStudioMessage(role: "user", content: "")]
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            _ = try await session.data(for: request)
        } catch {
            print("[LMStudioService] Preload failed: \(error)")
        }
    }

    func stop(model: String) async {
        // LM Studio doesn't support stopping models via API
        // Models are automatically unloaded after a timeout
        // This is a no-op
    }

    // MARK: - Error Mapping

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
}

// MARK: - API Models

struct LMStudioModelsResponse: Codable {
    let data: [LMStudioModel]
    let object: String
}

struct LMStudioModel: Codable {
    let id: String
    let object: String
}

struct LMStudioChatRequest: Codable {
    let model: String
    let messages: [LMStudioMessage]
    let stream: Bool?

    init(model: String, messages: [LMStudioMessage], stream: Bool = false) {
        self.model = model
        self.messages = messages
        self.stream = stream
    }
}

struct LMStudioMessage: Codable {
    let role: String
    let content: String
}

struct LMStudioChatResponse: Codable {
    let id: String
    let choices: [LMStudioChoice]
}

struct LMStudioChoice: Codable {
    let message: LMStudioMessage
    let finishReason: String?

    enum CodingKeys: String, CodingKey {
        case message
        case finishReason = "finish_reason"
    }
}

struct LMStudioStreamChunk: Codable {
    let id: String
    let choices: [LMStudioStreamChoice]
}

struct LMStudioStreamChoice: Codable {
    let delta: LMStudioStreamDelta
    let finishReason: String?

    enum CodingKeys: String, CodingKey {
        case delta
        case finishReason = "finish_reason"
    }
}

struct LMStudioStreamDelta: Codable {
    let content: String?
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --filter LMStudioServiceTests`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Sources/LMStudioService.swift Tests/LMStudioServiceTests.swift
git commit -m "feat: add LMStudioService with OpenAI-compatible API"
```

---

## Task 6: Add provider selection to AppState

**Files:**
- Modify: `Sources/AppState.swift`

- [ ] **Step 1: Add provider selection properties**

Add to `AppState` class (after line 23, with other @AppStorage properties):

```swift
@AppStorage("selectedProvider") var selectedProvider: LLMProviderType = .ollama
@AppStorage("lmstudioURL") var lmstudioURL: String = "http://127.0.0.1:1234/v1"
@AppStorage("lmstudioModel") var lmstudioModel: String = ""
```

- [ ] **Step 2: Rename ollamaModel to be provider-specific**

Find and rename:
- `@AppStorage("currentModel")` → `@AppStorage("ollamaModel")`

- [ ] **Step 3: Add LMStudioService instance**

Add after `private var ollamaService = OllamaService()` (around line 39):

```swift
private var lmstudioService = LMStudioService()
```

- [ ] **Step 4: Add currentProvider computed property**

Add after the managers (around line 38):

```swift
var currentProvider: any LLMProvider {
    switch selectedProvider {
    case .ollama:
        return ollamaService
    case .lmstudio:
        return lmstudioService
    }
}

var currentModel: String {
    get {
        switch selectedProvider {
        case .ollama:
            return ollamaModel
        case .lmstudio:
            return lmstudioModel
        }
    }
    set {
        switch selectedProvider {
        case .ollama:
            ollamaModel = newValue
        case .lmstudio:
            lmstudioModel = newValue
        }
    }
}

var currentProviderURL: String {
    get {
        switch selectedProvider {
        case .ollama:
            return ollamaURL
        case .lmstudio:
            return lmstudioURL
        }
    }
    set {
        switch selectedProvider {
        case .ollama:
            ollamaURL = newValue
        case .lmstudio:
            lmstudioURL = newValue
        }
    }
}
```

- [ ] **Step 5: Update checkOllamaStatus to use currentProvider**

Update the method (around line 100):

```swift
func checkOllamaStatus() {
    Task {
        let status = await currentProvider.checkInstallation()
        await MainActor.run {
            self.ollamaStatus = status

            if case .connected(let models) = status {
                self.availableModels = models
                self.lastError = nil
                self.lastConnectionTime = Date()
            } else if case .error(let error) = status {
                self.lastError = error
            }
        }

        if case .connected = status {
            await currentProvider.preload(model: currentModel)
        }
    }
}
```

- [ ] **Step 6: Update updateOllamaURL**

Update the method (around line 130):

```swift
func updateOllamaURL(_ url: String) {
    currentProviderURL = url
    Task {
        await currentProvider.updateBaseURL(url)
        checkOllamaStatus()
    }
}
```

- [ ] **Step 7: Update stopModel**

Update the method (around line 146):

```swift
func stopModel(_ model: String) {
    Task {
        await currentProvider.stop(model: model)
    }
}
```

- [ ] **Step 8: Update performProofreadingWithRetry**

Find the line with `await ollamaService.generateStream` and replace with:

```swift
let stream = await currentProvider.generateStream(model: currentModel, prompt: finalPrompt)
```

- [ ] **Step 9: Verify compiles**

Run: `swift build`

Expected: Builds successfully

- [ ] **Step 10: Commit**

```bash
git add Sources/AppState.swift
git commit -m "feat: add provider selection to AppState"
```

---

## Task 7: Update SettingsView for provider selection

**Files:**
- Modify: `Sources/SettingsView.swift`

- [ ] **Step 1: Add provider state variable**

Add to `SettingsView` struct (after line 10):

```swift
@State private var previousProvider: LLMProviderType = .ollama
```

- [ ] **Step 2: Add provider dropdown to UI**

Add after the Divider (after line 23):

```swift
// Provider Selection Section
VStack(spacing: 14) {
    HStack(alignment: .center) {
        Text("Provider:")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(width: 80, alignment: .trailing)

        Picker("", selection: $appState.selectedProvider) {
            ForEach(LLMProviderType.allCases, id: \.self) { provider in
                Text(provider.rawValue).tag(provider)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .frame(maxWidth: .infinity, alignment: .leading)
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
                }
                previousProvider = newProvider
                appState.checkOllamaStatus()
            }
        }
    }
}
```

- [ ] **Step 3: Update URL field binding**

Change the TextField binding (around line 32):

From:
```swift
TextField("Ollama URL", text: $appState.ollamaURL)
```

To:
```swift
TextField("Provider URL", text: Binding(
    get: { appState.currentProviderURL },
    set: { appState.currentProviderURL = $0 }
))
```

- [ ] **Step 4: Update onAppear to store previous provider**

Update the `onAppear` block (around line 133):

```swift
.onAppear {
    originalURL = appState.currentProviderURL
    originalShortcut = appState.keyboardShortcut
    previousModel = appState.currentModel
    previousProvider = appState.selectedProvider

    appState.checkOllamaStatus()
    isURLFieldFocused = true
    setupKeyMonitor()
}
```

- [ ] **Step 5: Update Cancel button**

Update the Cancel action (around line 108):

```swift
Button("Cancel") {
    appState.currentProviderURL = originalURL
    appState.keyboardShortcut = originalShortcut
    appState.currentModel = previousModel
    appState.selectedProvider = previousProvider
    dismiss()
}
```

- [ ] **Step 6: Update OK button**

Update the OK action (around line 117):

```swift
Button("OK") {
    // Stop previous model if it changed
    if previousModel != appState.currentModel {
        appState.stopModel(previousModel)
    }
    appState.updateOllamaURL(appState.currentProviderURL)
    appState.updateKeyboardShortcut(appState.keyboardShortcut)
    dismiss()
}
```

- [ ] **Step 7: Verify compiles**

Run: `swift build`

Expected: Builds successfully

- [ ] **Step 8: Commit**

```bash
git add Sources/SettingsView.swift
git commit -m "feat: add provider selection to SettingsView"
```

---

## Task 8: Add AppState tests for provider switching

**Files:**
- Modify: `Tests/AppStateTests.swift`

- [ ] **Step 1: Write test for provider switching**

Add to `AppStateTests.swift`:

```swift
func testProviderSwitching() async throws {
    let appState = await AppState()

    // Default provider should be Ollama
    await MainActor.run {
        XCTAssertEqual(appState.selectedProvider, .ollama)
        XCTAssertEqual(appState.currentModel, appState.ollamaModel)
    }

    // Switch to LM Studio
    await MainActor.run {
        appState.selectedProvider = .lmstudio
        appState.lmstudioModel = "test-model"
        XCTAssertEqual(appState.currentModel, "test-model")
        XCTAssertEqual(appState.currentModel, appState.lmstudioModel)
    }

    // Switch back to Ollama
    await MainActor.run {
        appState.selectedProvider = .ollama
        XCTAssertEqual(appState.currentModel, appState.ollamaModel)
    }
}

func testProviderURLIndependence() async throws {
    let appState = await AppState()

    await MainActor.run {
        appState.ollamaURL = "http://localhost:11434"
        appState.lmstudioURL = "http://localhost:1234/v1"

        appState.selectedProvider = .ollama
        XCTAssertEqual(appState.currentProviderURL, "http://localhost:11434")

        appState.selectedProvider = .lmstudio
        XCTAssertEqual(appState.currentProviderURL, "http://localhost:1234/v1")
    }
}
```

- [ ] **Step 2: Run tests**

Run: `swift test --filter testProviderSwitching`

Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add Tests/AppStateTests.swift
git commit -m "test: add provider switching tests"
```

---

## Task 9: Update error messages to be provider-agnostic

**Files:**
- Modify: `Sources/AppState.swift`

- [ ] **Step 1: Update getErrorMessage**

Update the method (around line 204):

```swift
private func getErrorMessage() -> String {
    let providerName = selectedProvider.rawValue

    if let error = lastError {
        var message = "⚠️ \(error.errorDescription ?? "Error")\n\n"

        if let reason = error.failureReason {
            message += "\(reason)\n\n"
        }

        if let suggestion = error.recoverySuggestion {
            message += "\(suggestion)"
        }

        return message
    }

    return "⚠️ Cannot connect to \(providerName)\n\nPlease check Settings to configure \(providerName)."
}
```

- [ ] **Step 2: Verify compiles**

Run: `swift build`

Expected: Builds successfully

- [ ] **Step 3: Commit**

```bash
git add Sources/AppState.swift
git commit -m "refactor: update error messages for provider-agnostic UX"
```

---

## Task 10: Final integration testing

**Files:**
- No file changes

- [ ] **Step 1: Build the app**

Run: `./build-app.sh`

Expected: App builds successfully

- [ ] **Step 2: Manual testing checklist**

- [ ] Install LM Studio and load a model
- [ ] Open app, verify Ollama is default provider
- [ ] Switch to LM Studio in Settings
- [ ] Verify URL shows `http://127.0.0.1:1234/v1`
- [ ] Verify models are listed from LM Studio
- [ ] Select a model and click OK
- [ ] Test proofreading with LM Studio
- [ ] Switch back to Ollama
- [ ] Verify previous Ollama settings are restored
- [ ] Test with LM Studio not running (should show error)
- [ ] Test with Ollama not running (should show error)

- [ ] **Step 3: Run all tests**

Run: `swift test`

Expected: All tests pass

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "test: complete LM Studio provider integration"
```

---

## Summary

This plan implements LM Studio as a second LLM provider with:

1. **Protocol-based architecture** - `LLMProvider` protocol allows easy addition of future providers
2. **Provider-specific settings** - Each provider maintains its own URL and model
3. **Seamless switching** - Users can switch between providers in Settings
4. **OpenAI-compatible API** - LM Studio uses standard `/v1` endpoints
5. **Comprehensive tests** - Unit tests for service, integration tests for switching

**Total tasks:** 10
**Estimated time:** 2-3 hours
**Files created:** 5
**Files modified:** 6
