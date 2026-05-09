import AppKit
import Carbon
import Foundation

class ClipboardManager {
    static let shared = ClipboardManager()

    private init() {}

    /// Get the currently selected text by simulating Command+C
    /// Returns the selected text, or nil if nothing was selected
    func getSelectedText() -> String? {
        let pasteboard = NSPasteboard.general
        let previousContents = pasteboard.string(forType: .string)
        let changeCount = pasteboard.changeCount

        // Simulate Command+C to copy selected text
        guard simulateCopy() else {
            return nil
        }

        // Wait for the copy to complete asynchronously
        Thread.sleep(forTimeInterval: 0.05)  // 50ms initial wait

        // Poll for clipboard change with timeout
        let selectedText = waitForClipboardChange(previousChangeCount: changeCount, timeout: 0.2)

        // Restore previous clipboard contents if we successfully copied something different
        if let previousContents = previousContents,
           let selectedText = selectedText,
           selectedText != previousContents {
            pasteboard.clearContents()
            pasteboard.setString(previousContents, forType: .string)
        }

        return selectedText
    }

    /// Copy text to clipboard
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    /// Simulate Command+V key press (paste)
    func simulatePaste() -> Bool {
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            return false
        }

        // V key code is 0x09
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
            return false
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cgSessionEventTap)
        keyUp.post(tap: .cgSessionEventTap)

        return true
    }

    // MARK: - Private Helpers

    /// Simulate Command+C key press
    private func simulateCopy() -> Bool {
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            return false
        }

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false) else {
            return false
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)

        return true
    }

    /// Wait for clipboard to change with timeout
    private func waitForClipboardChange(previousChangeCount: Int, timeout: TimeInterval) -> String? {
        let startTime = Date()
        let pasteboard = NSPasteboard.general
        let pollInterval: TimeInterval = 0.01  // 10ms

        while Date().timeIntervalSince(startTime) < timeout {
            // Check if clipboard changed
            if pasteboard.changeCount != previousChangeCount {
                return pasteboard.string(forType: .string)
            }
            Thread.sleep(forTimeInterval: pollInterval)
        }

        // Timeout - check final state
        return pasteboard.string(forType: .string)
    }
}
