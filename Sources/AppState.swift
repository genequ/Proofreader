import SwiftUI
import Combine
import AppKit

@MainActor
final class AppState: ObservableObject {
    @AppStorage("currentModel") var currentModel: String = "gemma3:4b"
    @AppStorage("currentPrompt") var currentPrompt: String = "Proofread the following text to correct typos and grammar errors while strictly preserving the original meaning, formatting, and style. Maintain the input format exactly (e.g., Markdown remains Markdown, plain text remains plain text). Do not add explanations, notes, or extra output—only return the corrected text."
    @Published var availableModels: [String] = []
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var isProcessing: Bool = false
    @Published var showProofreadingDialog: Bool = false
    @Published var correctedText: String = ""
    @Published var originalText: String = ""
    @AppStorage("ollamaURL") var ollamaURL: String = "http://127.0.0.1:11434"
    @AppStorage("keyboardShortcut") var keyboardShortcut: String = "command+/"
    
    private var ollamaService = OllamaService()
    private var cancellables = Set<AnyCancellable>()
    private var eventMonitor: Any?
    
    var statusIcon: String {
        switch connectionStatus {
        case .connected: return isProcessing ? "hourglass" : "checkmark.circle"
        case .disconnected: return "xmark.circle"
        case .error: return "exclamationmark.triangle"
        }
    }
    
    init() {
        setupKeyboardShortcut()
        checkConnection()
    }
    
    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    private func setupKeyboardShortcut() {
        // Remove existing monitor
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        
        // Parse shortcut string
        let (keyCode, modifiers) = parseShortcut(keyboardShortcut)
        
        // Set up new global event monitor
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == keyCode && event.modifierFlags.intersection(.deviceIndependentFlagsMask) == modifiers {
                self?.handleProofreadingShortcut()
            }
        }
    }
    
    func checkConnection() {
        Task {
            do {
                let models = try await ollamaService.listModels()
                await MainActor.run {
                    self.availableModels = models
                    self.connectionStatus = .connected
                }
            } catch {
                await MainActor.run {
                    self.connectionStatus = .error
                }
            }
        }
    }
    
    func updateOllamaURL(_ url: String) {
        ollamaURL = url
        Task {
            await ollamaService.updateBaseURL(url)
            checkConnection()
        }
    }
    
    func updateKeyboardShortcut(_ shortcut: String) {
        keyboardShortcut = shortcut
        setupKeyboardShortcut()
    }
    
    func handleProofreadingShortcut() {
        guard let selectedText = getSelectedText() else { return }
        
        // Store original text for comparison
        self.originalText = selectedText
        
        // Show dialog immediately with loading state
        self.correctedText = ""
        self.isProcessing = true
        self.showProofreadingDialog(nil)
        
        Task {
            do {
                let corrected = try await ollamaService.generate(
                    model: currentModel,
                    prompt: currentPrompt + "\n\n" + selectedText
                )
                
                await MainActor.run {
                    self.correctedText = corrected
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.correctedText = "Error: \(error.localizedDescription)"
                    self.connectionStatus = .error
                }
            }
        }
    }
    
    private func getSelectedText() -> String? {
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
        
        usleep(100000)
        
        let selectedText = pasteboard.string(forType: .string)
        
        // Restore previous clipboard contents only if we actually copied something
        if let previousContents = previousContents, selectedText != previousContents {
            pasteboard.clearContents()
            pasteboard.setString(previousContents, forType: .string)
        }
        
        return selectedText
    }
    
    private func parseShortcut(_ shortcut: String) -> (UInt16, NSEvent.ModifierFlags) {
        var keyCode: UInt16 = 0
        var modifiers: NSEvent.ModifierFlags = []
        
        let components = shortcut.lowercased().components(separatedBy: "+")
        
        for component in components {
            switch component.trimmingCharacters(in: .whitespaces) {
            case "command", "cmd":
                modifiers.insert(.command)
            case "control", "ctrl":
                modifiers.insert(.control)
            case "option", "opt":
                modifiers.insert(.option)
            case "shift":
                modifiers.insert(.shift)
            case "/":
                keyCode = 44 // Forward slash key code
            case "a": keyCode = 0
            case "b": keyCode = 11
            case "c": keyCode = 8
            case "d": keyCode = 2
            case "e": keyCode = 14
            case "f": keyCode = 3
            case "g": keyCode = 5
            case "h": keyCode = 4
            case "i": keyCode = 34
            case "j": keyCode = 38
            case "k": keyCode = 40
            case "l": keyCode = 37
            case "m": keyCode = 46
            case "n": keyCode = 45
            case "o": keyCode = 31
            case "p": keyCode = 35
            case "q": keyCode = 12
            case "r": keyCode = 15
            case "s": keyCode = 1
            case "t": keyCode = 17
            case "u": keyCode = 32
            case "v": keyCode = 9
            case "w": keyCode = 13
            case "x": keyCode = 7
            case "y": keyCode = 16
            case "z": keyCode = 6
            case "0": keyCode = 29
            case "1": keyCode = 18
            case "2": keyCode = 19
            case "3": keyCode = 20
            case "4": keyCode = 21
            case "5": keyCode = 23
            case "6": keyCode = 22
            case "7": keyCode = 26
            case "8": keyCode = 28
            case "9": keyCode = 25
            case "f1": keyCode = 122
            case "f2": keyCode = 120
            case "f3": keyCode = 99
            case "f4": keyCode = 118
            case "f5": keyCode = 96
            case "f6": keyCode = 97
            case "f7": keyCode = 98
            case "f8": keyCode = 100
            case "f9": keyCode = 101
            case "f10": keyCode = 109
            case "f11": keyCode = 103
            case "f12": keyCode = 111
            case "space": keyCode = 49
            case "return", "enter": keyCode = 36
            case "tab": keyCode = 48
            case "escape", "esc": keyCode = 53
            case "delete": keyCode = 51
            case "up": keyCode = 126
            case "down": keyCode = 125
            case "left": keyCode = 123
            case "right": keyCode = 124
            default:
                break
            }
        }
        
        return (keyCode, modifiers)
    }
    
    @objc func showPromptEditor(_ sender: Any?) {
        WindowManager.shared.showWindow(
            id: "prompt-editor",
            title: "Change Prompt",
            content: { PromptEditorView().environmentObject(self) },
            size: NSSize(width: 400, height: 300)
        )
    }
    
    @objc func showProofreadingDialog(_ sender: Any?) {
        WindowManager.shared.showWindow(
            id: "proofreading-dialog",
            title: "Proofreading Results",
            content: { ProofreadingDialog().environmentObject(self) },
            size: NSSize(width: 800, height: 500)
        )
    }
    
    @objc func showSettings(_ sender: Any?) {
        WindowManager.shared.showWindow(
            id: "settings",
            title: "Settings",
            content: { SettingsView().environmentObject(self) },
            size: NSSize(width: 400, height: 250)
        )
    }
    
    @objc func showAbout(_ sender: Any?) {
        WindowManager.shared.showWindow(
            id: "about",
            title: "About Proofreader",
            content: { AboutView().environmentObject(self) },
            size: NSSize(width: 320, height: 300)
        )
    }
}

enum ConnectionStatus {
    case connected, disconnected, error
}