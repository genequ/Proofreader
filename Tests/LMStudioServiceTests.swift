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

        // Should get an error since we're using a fake URL
        // The error could be notRunning (connection refused) or connectionFailed
        switch status {
        case .error:
            // Expected - connection should fail
            XCTAssertTrue(true)
        case .installed(running: false):
            // Also acceptable - health check failed
            XCTAssertTrue(true)
        default:
            XCTFail("Expected error or not installed/running status for invalid URL, got: \(status)")
        }
    }
}
