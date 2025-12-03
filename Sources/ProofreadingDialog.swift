import SwiftUI

struct ProofreadingDialog: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var monitor: Any?
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var toastIcon: String = "checkmark.circle.fill"
    
    // Use computed property to bind to AppState's persistent setting
    private var showDiff: Binding<Bool> {
        Binding(
            get: { appState.showDiffByDefault },
            set: { appState.showDiffByDefault = $0 }
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Processing feedback header
            if appState.isProcessing || appState.canRetry {
                processingHeader
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Error banner
            if appState.canRetry {
                errorBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Toggle for display mode
            HStack {
                Toggle("Show Differences", isOn: showDiff)
                    .toggleStyle(SwitchToggleStyle())
                Spacer()
                
                if appState.isProcessing {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Processing...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
            
            if showDiff.wrappedValue && !appState.originalText.isEmpty && !appState.isProcessing {
                // Show diff highlighting only when done processing
                DiffHighlightView(
                    originalText: appState.originalText,
                    correctedText: appState.correctedText,
                    highlightIntensity: appState.highlightIntensity
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 8)
            } else {
                // Plain text editor view - visible during streaming
                ScrollView {
                    TextEditor(text: .constant(appState.correctedText))
                        .font(.system(.body, design: .default))
                        .frame(minHeight: 300)
                }
                .background(Color(NSColor.textBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                )
                .cornerRadius(6)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    copyToClipboard(appState.correctedText)
                    showToastNotification("Copied to clipboard", icon: "checkmark.circle.fill")
                }) {
                    Label("Copy Corrected", systemImage: "doc.on.clipboard")
                }
                .buttonStyle(.bordered)
                .disabled(appState.isProcessing || appState.correctedText.isEmpty)
                
                if !appState.isProcessing && !appState.originalText.isEmpty && !appState.correctedText.isEmpty {
                    Button(action: {
                        copyChangesOnly()
                    }) {
                        Label("Copy Changes", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                    .help("Copy only the corrected portions")
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 800, height: 500)
        .toast(isShowing: $showToast, message: toastMessage, icon: toastIcon)
        .onAppear {
            setupKeyMonitor()
        }
        .onDisappear {
            removeKeyMonitor()
        }
    }
    
    private var processingHeader: some View {
        HStack(spacing: 16) {
            if appState.isProcessing {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .foregroundColor(.blue)
                    Text("\(appState.currentWordCount) words")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.medium)
                }
                
                Divider()
                    .frame(height: 16)
                
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundColor(.orange)
                    Text(formatElapsedTime(appState.elapsedTime))
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var errorBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Proofreading failed")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let error = appState.lastError {
                    Text(error.recoverySuggestion ?? "Please try again")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button("Retry") {
                appState.retryProofreading()
            }
            .buttonStyle(.bordered)
            
            Button("Settings") {
                appState.showSettings(nil)
            }
            .buttonStyle(.borderless)
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    private func formatElapsedTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        let ms = Int((seconds.truncatingRemainder(dividingBy: 1)) * 10)
        
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, secs)
        } else {
            return String(format: "%d.%ds", secs, ms)
        }
    }
    
    private func setupKeyMonitor() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // ESC key
                dismiss()
                return nil
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
    
    private func copyChangesOnly() {
        // Extract only the changed portions
        let changes = extractChanges(original: appState.originalText, corrected: appState.correctedText)
        if !changes.isEmpty {
            copyToClipboard(changes)
            showToastNotification("Changes copied to clipboard", icon: "doc.on.doc.fill")
        } else {
            showToastNotification("No changes found", icon: "info.circle.fill")
        }
    }
    
    private func extractChanges(original: String, corrected: String) -> String {
        // Simple implementation: return corrected text if different
        if original != corrected {
            return corrected
        }
        return ""
    }
    
    private func showToastNotification(_ message: String, icon: String) {
        toastMessage = message
        toastIcon = icon
        showToast = true
    }
}