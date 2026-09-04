import SwiftUI
import AppKit

@available(macOS 14.0, *)
@main
struct ProofreaderApp: App {
    @StateObject private var appState = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// Menu bar icon point size, in points. macOS menu-bar items default to
    /// ~16pt; ~18–19pt matches the visual weight of apps like GlobalProtect.
    /// NOTE: setting this via SwiftUI `.font(size:)` on an `Image` is silently
    /// ignored by the menu bar — it re-templates SF Symbols to its own size.
    /// We instead render the symbol into an `NSImage` at this exact size,
    /// which `MenuBarExtra` honors. Keep it under the ~22pt bar height.
    private let menuBarIconSize: CGFloat = 18

    /// Builds the menu bar icon as a sized `NSImage` (monochrome template so it
    /// follows the standard menu-bar tint, like other status items).
    private var menuBarIcon: NSImage {
        let configuration = NSImage.SymbolConfiguration(pointSize: menuBarIconSize, weight: .medium)
        let base = NSImage(systemSymbolName: appState.statusIcon, accessibilityDescription: "Proofreader status")
        let image = base?.withSymbolConfiguration(configuration) ?? base ?? NSImage()
        image.isTemplate = true
        return image
    }

    var body: some Scene {
        MenuBarExtra {
            StatusMenuView()
                .environmentObject(appState)
        } label: {
            Image(nsImage: menuBarIcon)
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