import AppKit
import Carbon

// C-convention callback for Carbon events
private func globalHotKeyHandler(nextHandler: EventHandlerCallRef?, theEvent: EventRef?, userData: UnsafeMutableRawPointer?) -> OSStatus {
    var hotKeyID = EventHotKeyID()
    
    let status = GetEventParameter(
        theEvent,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    
    if status == noErr && hotKeyID.signature == 0x50524652 { // 'PRFR'
        DispatchQueue.main.async {
            ShortcutManager.shared.performAction()
        }
        return noErr
    }
    
    return CallNextEventHandler(nextHandler, theEvent)
}

class ShortcutManager {
    static let shared = ShortcutManager()
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerEntry: EventHandlerRef?
    private var action: (() -> Void)?
    
    private init() {}
    
    func performAction() {
        print("[ShortcutManager] HotKey triggered!")
        action?()
    }
    
    func registerShortcut(_ shortcut: String, action: @escaping () -> Void) {
        print("[ShortcutManager] Registering Carbon HotKey: \(shortcut)")
        self.action = action
        
        // Cleanup old
        unregisterShortcut()
        
        // Parse
        let (keyCode, modifiers) = parseShortcut(shortcut)
        print("[ShortcutManager] Parsed: Code=\(keyCode), Mods=\(modifiers)")
        
        // Register Event Handler (if not already)
        if eventHandlerEntry == nil {
            let eventSpec = [
                EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            ]
            
            var handlerRef: EventHandlerRef?
            let ptr = UnsafeMutablePointer<EventTypeSpec>.allocate(capacity: 1)
            ptr.initialize(to: eventSpec[0])
            
            let status = InstallEventHandler(
                GetApplicationEventTarget(),
                globalHotKeyHandler,
                1,
                ptr,
                nil,
                &handlerRef
            )
            
            ptr.deallocate()
            
            if status == noErr {
                eventHandlerEntry = handlerRef
                print("[ShortcutManager] Event handler installed")
            } else {
                print("[ShortcutManager] Failed to install event handler: \(status)")
            }
        }
        
        // Register HotKey
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = 0x50524652 // 'PRFR'
        hotKeyID.id = 1
        
        let status = RegisterEventHotKey(
            UInt32(keyCode),
            UInt32(modifiers),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr {
            print("[ShortcutManager] HotKey registered successfully")
        } else {
            print("[ShortcutManager] Failed to register HotKey: \(status)")
        }
    }
    
    func unregisterShortcut() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }
    
    private func parseShortcut(_ shortcut: String) -> (UInt32, UInt32) {
        var keyCode: UInt32 = 0
        var modifiers: UInt32 = 0
        var remaining = shortcut.lowercased()
        
        // Helper to check and remove modifier
        // Use Carbon modifier constants
        func checkModifier(_ keys: [String], _ flag: Int) {
            for key in keys {
                if remaining.contains(key) {
                    modifiers |= UInt32(flag)
                    remaining = remaining.replacingOccurrences(of: key, with: "")
                }
            }
        }
        
        checkModifier(["command", "cmd", "⌘"], cmdKey)
        checkModifier(["control", "ctrl", "⌃"], controlKey)
        checkModifier(["option", "opt", "⌥"], optionKey)
        checkModifier(["shift", "⇧"], shiftKey)
        
        // Clean up remaining string
        remaining = remaining.replacingOccurrences(of: "+", with: "")
        remaining = remaining.trimmingCharacters(in: .whitespaces)
        
        // Map characters
        switch remaining {
        case "a": keyCode = 0x00
        case "s": keyCode = 0x01
        case "d": keyCode = 0x02
        case "f": keyCode = 0x03
        case "h": keyCode = 0x04
        case "g": keyCode = 0x05
        case "z": keyCode = 0x06
        case "x": keyCode = 0x07
        case "c": keyCode = 0x08
        case "v": keyCode = 0x09
        case "b": keyCode = 0x0B
        case "q": keyCode = 0x0C
        case "w": keyCode = 0x0D
        case "e": keyCode = 0x0E
        case "r": keyCode = 0x0F
        case "y": keyCode = 0x10
        case "t": keyCode = 0x11
        case "1": keyCode = 0x12
        case "2": keyCode = 0x13
        case "3": keyCode = 0x14
        case "4": keyCode = 0x15
        case "6": keyCode = 0x16
        case "5": keyCode = 0x17
        case "=": keyCode = 0x18
        case "9": keyCode = 0x19
        case "7": keyCode = 0x1A
        case "-": keyCode = 0x1B
        case "8": keyCode = 0x1C
        case "0": keyCode = 0x1D
        case "]": keyCode = 0x1E
        case "o": keyCode = 0x1F
        case "u": keyCode = 0x20
        case "[": keyCode = 0x21
        case "i": keyCode = 0x22
        case "p": keyCode = 0x23
        case "l": keyCode = 0x25
        case "j": keyCode = 0x26
        case "'": keyCode = 0x27
        case "k": keyCode = 0x28
        case ";": keyCode = 0x29
        case "\\": keyCode = 0x2A
        case ",": keyCode = 0x2B
        case "/": keyCode = 0x2C
        case "n": keyCode = 0x2D
        case "m": keyCode = 0x2E
        case ".": keyCode = 0x2F
        case "tab": keyCode = 0x30
        case "space": keyCode = 0x31
        case "`": keyCode = 0x32
        case "delete": keyCode = 0x33
        case "enter", "return": keyCode = 0x24
        case "esc", "escape": keyCode = 0x35
        case "f1": keyCode = 0x7A
        case "f2": keyCode = 0x78
        case "f3": keyCode = 0x63
        case "f4": keyCode = 0x76
        case "f5": keyCode = 0x60
        case "f6": keyCode = 0x61
        case "f7": keyCode = 0x62
        case "f8": keyCode = 0x64
        case "f9": keyCode = 0x65
        case "f10": keyCode = 0x6D
        default: break
        }
        
        return (keyCode, modifiers)
    }
}
