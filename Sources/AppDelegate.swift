import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set activation policy for menu bar app to allow windows to receive focus
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Get the current model from UserDefaults (since AppState might be gone/hard to reach)
        if let currentModel = UserDefaults.standard.string(forKey: "currentModel") {
            print("[AppDelegate] Stopping Ollama model: \(currentModel)")
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/local/bin/ollama") // Typical path, might need fallback or environment path
            process.arguments = ["stop", currentModel]
            
            // If /usr/local/bin/ollama doesn't exist, try just "ollama" and letting shell resolve it?
            // Process requires absolute path usually. Let's try to be smart about finding it.
            if !FileManager.default.fileExists(atPath: process.executableURL!.path) {
                 // Try standard homebrew path or user path
                 if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/ollama") {
                     process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/ollama")
                 } else {
                     // Fallback: assume it's in path and try to run via /bin/sh
                     process.executableURL = URL(fileURLWithPath: "/bin/zsh")
                     process.arguments = ["-c", "ollama stop \(currentModel)"]
                 }
            }
            
            do {
                try process.run()
                process.waitUntilExit() // Wait briefly to ensure it sends the signal
                print("[AppDelegate] Ollama stop command finished")
            } catch {
                print("[AppDelegate] Failed to stop Ollama model: \(error)")
            }
        }
    }
}