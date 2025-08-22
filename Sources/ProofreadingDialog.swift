import SwiftUI

struct ProofreadingDialog: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showDiff = true
    @State private var monitor: Any?
    
    var body: some View {
        VStack(spacing: 8) {
            if appState.isProcessing {
                LoadingView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Toggle for display mode
                HStack {
                    Toggle("Show Differences", isOn: $showDiff)
                        .toggleStyle(SwitchToggleStyle())
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                if showDiff && !appState.originalText.isEmpty {
                    // Show diff highlighting
                    DiffHighlightView(
                        originalText: appState.originalText,
                        correctedText: appState.correctedText
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Plain text editor view
                    TextEditor(text: .constant(appState.correctedText))
                        .font(.system(.body, design: .default))
                        .background(Color(NSColor.textBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                        )
                        .cornerRadius(6)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                HStack(spacing: 12) {
                    Button("Copy Corrected") {
                        copyToClipboard(appState.correctedText)
                    }
                    .buttonStyle(.bordered)
                    
                    if showDiff && !appState.originalText.isEmpty {
                        Button("Copy Original") {
                            copyToClipboard(appState.originalText)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return)
                }
                .padding(.bottom, 16)
                .padding(.horizontal, 16)
            }
        }
        .frame(width: 800, height: 500)
        .onAppear {
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
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}