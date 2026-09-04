import AppKit
import Foundation

/// Single source of truth for window sizes.
///
/// `AppState.showX(...)` (NSWindow contentRect) AND each view's `.frame(...)`
/// must both read from here. A mismatch makes NSHostingView center fixed-frame
/// content in a differently-sized window, clipping content at the top
/// (under the title bar) and bottom (buttons cut off) — seen on macOS 27.
enum WindowMetrics {
    static let settings = NSSize(width: 450, height: 480)
    static let about = NSSize(width: 320, height: 380)
    static let statistics = NSSize(width: 600, height: 560)
    static let proofreadingDialog = NSSize(width: 800, height: 500)
}
