import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isURLFieldFocused: Bool
    @State private var monitor: Any?
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Text("URL:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .trailing)
                    TextField("Ollama URL", text: $appState.ollamaURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isURLFieldFocused)
                }
                
                HStack(alignment: .firstTextBaseline) {
                    Text("Model:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .trailing)
                    Picker("", selection: $appState.currentModel) {
                        ForEach(appState.availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: .infinity)
                }
                
                HStack(alignment: .firstTextBaseline) {
                    Text("Shortcut:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .trailing)
                    TextField("command+/", text: $appState.keyboardShortcut)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            appState.updateKeyboardShortcut(appState.keyboardShortcut)
                        }
                }
                
                Button("Test Connection") {
                    appState.checkConnection()
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
            
            HStack(spacing: 12) {
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Button("OK") {
                    appState.updateOllamaURL(appState.ollamaURL)
                    appState.updateKeyboardShortcut(appState.keyboardShortcut)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
            }
            .padding(.top, 8)
        }
        .padding(20)
        .frame(width: 400, height: 280)
        .onAppear {
            appState.checkConnection()
            isURLFieldFocused = true
            setupKeyMonitor()
        }
        .onDisappear {
            removeKeyMonitor()
        }
    }
    
    private func setupKeyMonitor() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // ESC key
                dismiss()
                return nil // Consume the event
            }
            return event
        }
    }
    
    private func removeKeyMonitor() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}