import XCTest
@testable import Proofreader

final class OpenRouterServiceTests: XCTestCase {
    var service: OpenRouterService!

    override func setUp() {
        super.setUp()
        service = OpenRouterService(apiKey: "test-api-key")
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    func testCheckInstallationWithoutKeyReturnsUnauthorized() async {
        let keyless = OpenRouterService(apiKey: "")
        let status = await keyless.checkInstallation()

        // Empty key short-circuits to unauthorized without network access
        if case .error(let error) = status, case .unauthorized = error {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected unauthorized error for empty key, got: \(status)")
        }
    }

    func testServiceInitialization() {
        let testService = OpenRouterService(apiKey: "test-key-123")
        // Service should initialize without throwing
        XCTAssertNotNil(testService)
    }

    func testUpdateAPIKey() async {
        let newKey = "new-api-key"
        await service.updateAPIKey(newKey)
        // No assertion needed - this tests that the method doesn't crash
    }

    func testUpdateBaseURLIsNoOp() async {
        // OpenRouter has fixed base URL, updateBaseURL should be a no-op
        await service.updateBaseURL("http://example.com")
        // No way to verify the URL didn't change without exposing it
        // This test ensures the method exists and doesn't crash
    }

    func testStopIsNoOp() async {
        // OpenRouter is API-based, stop should be a no-op
        await service.stop(model: "x-ai/grok-4")
        // No assertion - this tests that the method doesn't crash
    }

    func testPreloadIsNoOp() async {
        // OpenRouter is API-based, preload should be a no-op
        await service.preload(model: "x-ai/grok-4")
        // No assertion - this tests that the method doesn't crash
    }
}
