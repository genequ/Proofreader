import SwiftUI

struct PromptEditorView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var editedPrompt: String = ""
    @FocusState private var isEditorFocused: Bool
    @State private var monitor: Any?
    
    var body: some View {
        VStack(spacing: 16) {
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Proofreading Instructions:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $editedPrompt)
                    .font(.system(size: 13, design: .monospaced))
                    .padding(8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .frame(height: 180)
                    .focused($isEditorFocused)
                
                Text("Note: System rules for consistent AI behavior are automatically added.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            HStack(spacing: 12) {
                Button("Reset to Default") {
                    editedPrompt = defaultPrompt
                }
                .buttonStyle(.borderless)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Button("OK") {
                    appState.currentPrompt = editedPrompt
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
            }
            .padding(.top, 8)
        }
        .padding(20)
        .frame(width: 460, height: 320)
        .onAppear {
            editedPrompt = appState.currentPrompt
            isEditorFocused = true
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
    
    private var defaultPrompt: String {
        "You are an English proofreading assistant for non-native speakers. Correct grammar, spelling, punctuation, and word choice errors. Pay special attention to: articles (a/an/the), prepositions, verb tenses, subject-verb agreement, plural forms, and natural English phrasing. Preserve the original meaning, tone, and formatting exactly."
    }
}