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
        
        // Hidden window for onboarding
        WindowGroup(id: "onboarding") {
            OnboardingView()
                .environmentObject(appState)
                .onAppear {
                    // Show onboarding on first launch
                    if !appState.hasCompletedOnboarding && appState.appLaunchCount <= 1 {
                        appState.showOnboarding(nil)
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}