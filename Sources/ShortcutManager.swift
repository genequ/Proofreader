import AppKit
import Carbon

class ShortcutManager {
    static let shared = ShortcutManager()
    
    private var eventMonitor: Any?
    
    private init() {}
    
    func registerShortcut(_ shortcut: String, action: @escaping () -> Void) {
        print("[ShortcutManager] Registering shortcut: \(shortcut)")
        
        if !AXIsProcessTrusted() {
            print("[ShortcutManager] WARNING: Accessibility permissions not granted. Global shortcuts will not work.")
            // Prompt user to grant permissions
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            AXIsProcessTrustedWithOptions(options as CFDictionary)
        }
        
        // Remove existing monitor
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        
        // Parse shortcut string
        let (keyCode, modifiers) = parseShortcut(shortcut)
        print("[ShortcutManager] Parsed shortcut: keyCode=\(keyCode), modifiers=\(modifiers)")
        
        // Set up new global event monitor
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if event.keyCode == keyCode && flags == modifiers {
                print("[ShortcutManager] Shortcut triggered!")
                action()
            }
        }
    }
    
    func unregisterShortcut() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
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
            case ".":
                keyCode = 47 // Period key code
            case ",":
                keyCode = 43 // Comma key code
            case ";":
                keyCode = 41 // Semicolon key code
            case "'":
                keyCode = 39 // Apostrophe key code
            case "[":
                keyCode = 33 // Left bracket key code
            case "]":
                keyCode = 30 // Right bracket key code
            case "\\":
                keyCode = 42 // Backslash key code
            case "`":
                keyCode = 50 // Grave accent key code
            case "=":
                keyCode = 24 // Equal sign key code
            case "-":
                keyCode = 27 // Minus key code
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
}
