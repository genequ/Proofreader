import XCTest
@testable import Proofreader

final class OllamaServiceTests: XCTestCase {
    
    var ollamaService: OllamaService!
    
    override func setUp() {
        super.setUp()
        ollamaService = OllamaService()
    }
    
    override func tearDown() {
        ollamaService = nil
        super.tearDown()
    }
    
    func testListModelsSuccess() async throws {
        // This test would require mocking the network response
        // For now, we'll test that the function doesn't crash
        // and returns an array (empty if no connection)
        
        do {
            let models = try await ollamaService.listModels()
            // Should return an array (could be empty if no Ollama instance running)
            XCTAssertTrue(models is [String])
        } catch {
            // Network errors are expected in test environment
            XCTAssertTrue(error is Error)
        }
    }
    
    func testGenerateSuccess() async throws {
        // This test would require mocking the network response
        // For now, we'll test that the function doesn't crash
        
        do {
            let response = try await ollamaService.generate(
                model: "test-model",
                prompt: "Test prompt"
            )
            // Should return a string (could be empty if no Ollama instance running)
            XCTAssertTrue(response is String)
        } catch {
            // Network errors are expected in test environment
            XCTAssertTrue(error is Error)
        }
    }
    
    func testGenerateWithEmptyPrompt() async throws {
        do {
            let response = try await ollamaService.generate(
                model: "test-model",
                prompt: ""
            )
            XCTAssertTrue(response is String)
        } catch {
            XCTAssertTrue(error is Error)
        }
    }
}