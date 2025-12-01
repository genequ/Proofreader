import AppKit
import Carbon

class ClipboardManager {
    static let shared = ClipboardManager()
    
    private init() {}
    
    func getSelectedText() -> String? {
        print("[ClipboardManager] Attempting to get selected text...")
        let pasteboard = NSPasteboard.general
        let previousContents = pasteboard.string(forType: .string)
        
        // Use Command+C to copy instead of Command+X to cut
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true) // 0x08 = 'C' key
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        
        keyDown?.post(tap: .cgAnnotatedSessionEventTap)
        keyUp?.post(tap: .cgAnnotatedSessionEventTap)
        
        // Wait a bit for the copy to happen
        usleep(100000)
        
        let selectedText = pasteboard.string(forType: .string)
        
        // Restore previous clipboard contents only if we actually copied something
        // and if it's different from what was there before (to avoid clearing if user just copied)
        // Note: This logic is a bit tricky because we don't know if the copy failed or if the user selected the same text.
        // But generally, we want to return the text we just copied.
        
        // If we want to be polite, we should restore the clipboard if we're done.
        // But for "get selected text", we usually leave it in the clipboard or restore it immediately.
        // The original code restored it.
        
        if let previousContents = previousContents, selectedText != previousContents {
            // Restore previous content
            pasteboard.clearContents()
            pasteboard.setString(previousContents, forType: .string)
        }
        
        return selectedText
    }
    
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
