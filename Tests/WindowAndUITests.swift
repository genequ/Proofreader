import XCTest
import SwiftUI
import AppKit
@testable import Proofreader

/// UI regression tests. These run headless: they instantiate the real SwiftUI
/// views inside NSHostingView and assert layout invariants — no XCUITest
/// needed (SPM has no host-app UI testing bundle).
@MainActor
final class WindowAndUITests: XCTestCase {

    // MARK: - Window metrics (clipping regression)

    /// The macOS 27 clipping bug: NSWindow created with size X, SwiftUI view
    /// fixed-framed at size Y — NSHostingView centers the frame in the window
    /// and content clips top+bottom. Both sides now read WindowMetrics; this
    /// test fails if a view's frame ever drifts from the shared constants.
    func testHostingViewFittingSizeMatchesWindowMetrics() {
        let appState = AppState()
        let cases: [(view: NSView, expected: NSSize, name: String)] = [
            (NSHostingView(rootView: AboutView().environmentObject(appState)),
             WindowMetrics.about, "AboutView"),
            (NSHostingView(rootView: SettingsView().environmentObject(appState)),
             WindowMetrics.settings, "SettingsView"),
            (NSHostingView(rootView: StatisticsView().environmentObject(appState)),
             WindowMetrics.statistics, "StatisticsView"),
            (NSHostingView(rootView: ProofreadingDialog().environmentObject(appState)),
             WindowMetrics.proofreadingDialog, "ProofreadingDialog"),
        ]
        for entry in cases {
            XCTAssertEqual(entry.view.fittingSize.width, CGFloat(Int(entry.expected.width)),
                           "\(entry.name) width must match WindowMetrics")
            XCTAssertEqual(entry.view.fittingSize.height, CGFloat(Int(entry.expected.height)),
                           "\(entry.name) height must match WindowMetrics")
        }
    }

    func testWindowMetricsAreSane() {
        // Every window must at least clear the title bar plus action row.
        for size in [WindowMetrics.settings, WindowMetrics.about,
                     WindowMetrics.statistics, WindowMetrics.proofreadingDialog] {
            XCTAssertGreaterThanOrEqual(size.height, 300, "window too short to hold content")
            XCTAssertGreaterThanOrEqual(size.width, 300)
        }
    }

    // MARK: - Crash regressions

    /// grok-4.6 crash: model returns empty text → LCS hit `1...0` and trapped.
    /// recordSession must survive empty corrected text.
    func testRecordSessionWithEmptyCorrectedTextDoesNotCrash() {
        let manager = StatisticsManager.shared
        let saved = manager.statistics
        defer { manager.statistics = saved; manager.forceSave() }

        let before = manager.statistics.totalSessions
        manager.recordSession(originalText: "She go to store.",
                              correctedText: "",
                              processingTime: 1.0,
                              modelUsed: "test",
                              success: true)
        XCTAssertEqual(manager.statistics.totalSessions, before + 1)
    }

    /// Quit-flush bug: AppDelegate must flush the SAME instance AppState
    /// writes to, otherwise pending debounced sessions are lost on quit.
    func testStatisticsManagerIsSharedSingleton() {
        let appState = AppState()
        XCTAssertTrue(appState.statisticsManager === StatisticsManager.shared)
    }

    // MARK: - Template menu logic

    func testTemplateManagerDefaultProtectionAndCustomLifecycle() {
        let defaults = UserDefaults.standard
        let savedCustoms = defaults.data(forKey: "customPromptTemplates")
        defer {
            if let savedCustoms {
                defaults.set(savedCustoms, forKey: "customPromptTemplates")
            } else {
                defaults.removeObject(forKey: "customPromptTemplates")
            }
        }

        let manager = TemplateManager()
        let initialCount = manager.templates.count

        // Default template exists and cannot be deleted
        let fallback = manager.template(withId: "default")
        XCTAssertNotNil(fallback)
        manager.deleteTemplate(fallback!)
        XCTAssertNotNil(manager.template(withId: "default"))

        // Custom template can be added and deleted
        let custom = PromptTemplate(name: "QA Test",
                                    description: "test",
                                    prompt: "p",
                                    isBuiltIn: false,
                                    category: .general)
        manager.addTemplate(custom)
        XCTAssertEqual(manager.templates.count, initialCount + 1)
        manager.deleteTemplate(custom)
        XCTAssertEqual(manager.templates.count, initialCount)
        XCTAssertNil(manager.template(withId: custom.id))
    }
}
