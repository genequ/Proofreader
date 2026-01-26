import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set activation policy for menu bar app to allow windows to receive focus
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Force save statistics before quitting
        // Access through shared instance to ensure save completes
        let statsManager = StatisticsManager()
        statsManager.forceSave()

        // Get the current model from UserDefaults (since AppState might be gone/hard to reach)
        guard let currentModel = UserDefaults.standard.string(forKey: "currentModel") else {
            return
        }

        print("[AppDelegate] Stopping Ollama model: \(currentModel)")

        let process = Process()
        process.arguments = ["stop", currentModel]

        // Use shared path detection from OllamaService
        if let ollamaPath = OllamaService.findOllamaPath() {
            process.executableURL = URL(fileURLWithPath: ollamaPath)
        } else {
            // Fallback: run via shell if we can't find the path directly
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", "ollama stop \(currentModel)"]
        }

        do {
            try process.run()
            process.waitUntilExit()
            print("[AppDelegate] Ollama stop command finished with status: \(process.terminationStatus)")
        } catch {
            print("[AppDelegate] Failed to stop Ollama model: \(error)")
        }
    }
}