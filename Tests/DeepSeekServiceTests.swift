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

    func testServiceInitialization() {
        let testKey = "test-key-123"
        let testService = DeepSeekService(apiKey: testKey)
        // Service should initialize without throwing
        XCTAssertNotNil(testService)
    }

    func testUpdateAPIKey() async {
        let newKey = "new-api-key"
        await service.updateAPIKey(newKey)
        // No assertion needed - this tests that the method doesn't crash
        // In a real scenario, we'd verify the key is used in subsequent requests
    }

    func testUpdateBaseURLIsNoOp() async {
        // DeepSeek has fixed base URL, updateBaseURL should be a no-op
        await service.updateBaseURL("http://example.com")
        // No way to verify the URL didn't change without exposing it
        // This test ensures the method exists and doesn't crash
    }

    func testStopIsNoOp() async {
        // DeepSeek is API-based, stop should be a no-op
        await service.stop(model: "deepseek-chat")
        // No assertion - this tests that the method doesn't crash
    }

    func testPreloadIsNoOp() async {
        // DeepSeek is API-based, preload should be a no-op
        await service.preload(model: "deepseek-chat")
        // No assertion - this tests that the method doesn't crash
    }
}
