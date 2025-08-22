import SwiftUI
import AppKit

@available(macOS 13.0, *)
@main
struct ProofreaderApp: App {
    @StateObject private var appState = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra("Proofreader", systemImage: appState.statusIcon) {
            StatusMenuView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.menu)
    }
}