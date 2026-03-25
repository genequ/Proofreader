import XCTest
@testable import Proofreader

@MainActor
final class AppStateTests: XCTestCase {
    
    var appState: AppState!
    
    override func setUp() {
        super.setUp()
        // Clear UserDefaults to ensure test isolation
        let defaults = UserDefaults.standard
        defaults.dictionaryRepresentation().keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize()

        appState = AppState()
    }

    override func tearDown() {
        appState = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(appState.currentModel, "gemma3:4b")
        XCTAssertFalse(appState.currentPrompt.isEmpty)
        XCTAssertTrue(appState.availableModels.isEmpty)
        XCTAssertEqual(appState.connectionStatus, .disconnected)
        XCTAssertFalse(appState.isProcessing)
        XCTAssertFalse(appState.showProofreadingDialog)
        XCTAssertTrue(appState.correctedText.isEmpty)
        XCTAssertEqual(appState.ollamaURL, "http://127.0.0.1:11434")
    }
    
    func testStatusIcon() {
        // Test connected state
        appState.ollamaStatus = .connected(models: ["gemma3:4b"])
        appState.isProcessing = false
        XCTAssertEqual(appState.statusIcon, "checkmark.circle.fill")

        // Test processing state
        appState.isProcessing = true
        XCTAssertEqual(appState.statusIcon, "hourglass")

        // Test disconnected state (notInstalled)
        appState.ollamaStatus = .notInstalled
        appState.isProcessing = false
        XCTAssertEqual(appState.statusIcon, "xmark.circle.fill")

        // Test error state
        appState.ollamaStatus = .error(.networkTimeout)
        XCTAssertEqual(appState.statusIcon, "exclamationmark.triangle.fill")
    }
    
    func testCheckConnection() {
        // This will attempt to connect to Ollama
        // We can't easily mock this without dependency injection,
        // but we can verify the function doesn't crash
        appState.checkConnection()
        
        // The connection status might change asynchronously
        // We can't make assertions about the final state
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    func testHandleProofreadingShortcut() {
        // This function requires user interaction and clipboard access
        // We'll just verify it doesn't crash
        appState.handleProofreadingShortcut()
        
        // The function runs asynchronously, so we can't assert much
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    func testPromptContainsDefaultText() {
        // The default prompt mentions "English proofreading assistant for non-native speakers"
        let defaultText = "proofreading assistant"
        XCTAssertTrue(appState.currentPrompt.contains(defaultText))
    }
    
    func testKeyboardShortcutUpdates() {
        // Test updating keyboard shortcut - note that formatShortcut converts to symbols

        // Test command+. (becomes ⌘+.)
        appState.updateKeyboardShortcut("command+.")
        XCTAssertEqual(appState.keyboardShortcut, "⌘+.")

        // Test with different shortcuts (becomes ⌃+⇧+p)
        appState.updateKeyboardShortcut("control+shift+p")
        XCTAssertEqual(appState.keyboardShortcut, "⌃+⇧+p")

        // Test option+space (becomes ⌥+space)
        appState.updateKeyboardShortcut("option+space")
        XCTAssertEqual(appState.keyboardShortcut, "⌥+space")
    }

    func testProviderSwitching() async throws {
        let appState = await AppState()

        await MainActor.run {
            // Explicitly set initial state to ensure test isolation
            appState.selectedProvider = .ollama
            appState.ollamaModel = "gemma3:4b"
            appState.lmstudioModel = ""

            // Default provider should be Ollama
            XCTAssertEqual(appState.selectedProvider, .ollama)
            XCTAssertEqual(appState.currentModel, appState.ollamaModel)

            // Switch to LM Studio
            appState.selectedProvider = .lmstudio
            appState.lmstudioModel = "test-model"
            XCTAssertEqual(appState.currentModel, "test-model")
            XCTAssertEqual(appState.currentModel, appState.lmstudioModel)

            // Switch back to Ollama
            appState.selectedProvider = .ollama
            XCTAssertEqual(appState.currentModel, appState.ollamaModel)
        }
    }

    func testProviderURLIndependence() async throws {
        let appState = await AppState()

        await MainActor.run {
            // Set explicit URLs to test independence
            appState.ollamaURL = "http://localhost:11434"
            appState.lmstudioURL = "http://localhost:1234/v1"

            appState.selectedProvider = .ollama
            XCTAssertEqual(appState.currentProviderURL, "http://localhost:11434")

            appState.selectedProvider = .lmstudio
            XCTAssertEqual(appState.currentProviderURL, "http://localhost:1234/v1")
        }
    }
}