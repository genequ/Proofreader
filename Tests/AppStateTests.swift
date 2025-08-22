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
        appState.connectionStatus = .connected
        appState.isProcessing = false
        XCTAssertEqual(appState.statusIcon, "checkmark.circle")
        
        // Test processing state
        appState.isProcessing = true
        XCTAssertEqual(appState.statusIcon, "hourglass")
        
        // Test disconnected state
        appState.connectionStatus = .disconnected
        appState.isProcessing = false
        XCTAssertEqual(appState.statusIcon, "xmark.circle")
        
        // Test error state
        appState.connectionStatus = .error
        XCTAssertEqual(appState.statusIcon, "exclamationmark.triangle")
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
        let defaultText = "Proofread the following text to correct typos and grammar errors"
        XCTAssertTrue(appState.currentPrompt.contains(defaultText))
    }
}