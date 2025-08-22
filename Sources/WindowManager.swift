import SwiftUI
import AppKit

@MainActor
final class WindowManager: NSObject {
    static let shared = WindowManager()
    
    private var windows: [String: NSWindow] = [:]
    
    private override init() {
        super.init()
    }
    
    func showWindow<Content: View>(id: String, title: String, content: @escaping () -> Content, size: NSSize) {
        if let existingWindow = windows[id] {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = title
        window.contentView = NSHostingView(rootView: content())
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.level = .floating
        
        windows[id] = window
        window.makeKeyAndOrderFront(nil)
        window.makeMain()
        NSApp.activate(ignoringOtherApps: true)
        window.orderFrontRegardless()
    }
    
    func closeWindow(id: String) {
        windows[id]?.close()
        windows.removeValue(forKey: id)
    }
}

extension WindowManager: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        // Remove the window from our tracking
        for (id, trackedWindow) in windows where trackedWindow === window {
            windows.removeValue(forKey: id)
            break
        }
    }
}