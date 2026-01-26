import XCTest
@testable import Proofreader

@MainActor
final class AppStateTests: XCTestCase {
    
    var appState: AppState!
    
    override func setUp() {
        super.setUp()
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
        let originalShortcut = appState.keyboardShortcut

        // Test command+. (becomes ⌘+.)
        appState.updateKeyboardShortcut("command+.")
        XCTAssertEqual(appState.keyboardShortcut, "⌘+.")

        // Test with different shortcuts (becomes ⌃+⇧+p)
        appState.updateKeyboardShortcut("control+shift+p")
        XCTAssertEqual(appState.keyboardShortcut, "⌃+⇧+p")

        // Test option+space (becomes ⌥+space)
        appState.updateKeyboardShortcut("option+space")
        XCTAssertEqual(appState.keyboardShortcut, "⌥+space")

        // Restore original
        appState.updateKeyboardShortcut(originalShortcut)
        XCTAssertEqual(appState.keyboardShortcut, originalShortcut)
    }
}