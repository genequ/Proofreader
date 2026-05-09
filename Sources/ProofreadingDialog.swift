import SwiftUI

struct ProofreadingDialog: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var monitor: Any?
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var toastIcon: String = "checkmark.circle.fill"
    @State private var selectedTemplateOverride: String?
    @State private var hasReceivedResult: Bool = false
    
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
                    .disabled(appState.isProcessing)
                Spacer()

                // Template picker for regeneration
                HStack(spacing: 6) {
                    Text("Template:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("", selection: Binding(
                        get: { selectedTemplateOverride ?? appState.selectedTemplate },
                        set: { newValue in
                            let oldValue = selectedTemplateOverride ?? appState.selectedTemplate
                            selectedTemplateOverride = newValue
                            if newValue != oldValue {
                                appState.regenerateWithTemplate(templateId: newValue)
                            }
                        }
                    )) {
                        ForEach(appState.templateManager.templates) { template in
                            Text(template.name).tag(template.id)
                        }
                    }
                    .labelsHidden()
                    .disabled(appState.isProcessing)
                }

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
            
            if showDiff.wrappedValue && !appState.originalText.isEmpty {
                if appState.isProcessing && hasReceivedResult {
                    // Regenerating: show original as static, corrected streams in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Original:")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text(appState.originalText)
                                    .textSelection(.enabled)
                                    .lineSpacing(2)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                                    )
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Text("Corrected:")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    ProgressView()
                                        .scaleEffect(0.6)
                                }
                                TextEditor(text: .constant(appState.correctedText))
                                    .font(.system(.body, design: .default))
                                    .lineSpacing(2)
                                    .padding(4)
                                    .frame(minHeight: 150)
                            }
                            .padding(12)
                            .background(Color.green.opacity(0.05))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(16)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 8)
                } else if !appState.isProcessing && !appState.correctedText.isEmpty {
                    // Done: show full diff highlighting
                    DiffHighlightView(
                        originalText: appState.originalText,
                        correctedText: appState.correctedText,
                        highlightIntensity: appState.highlightIntensity
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 8)
                } else {
                    // First-time streaming: show original immediately, corrected streams in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Original:")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text(appState.originalText)
                                    .textSelection(.enabled)
                                    .lineSpacing(2)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                                    )
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Text("Corrected:")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    if appState.isProcessing {
                                        ProgressView()
                                            .scaleEffect(0.6)
                                    }
                                }
                                TextEditor(text: .constant(appState.correctedText))
                                    .font(.system(.body, design: .default))
                                    .lineSpacing(2)
                                    .padding(4)
                                    .frame(minHeight: 150)
                            }
                            .padding(12)
                            .background(Color.green.opacity(0.05))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(16)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 8)
                }
            } else {
                // No original text or diff disabled: plain text editor
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
                if !appState.isProcessing && !appState.originalText.isEmpty && !appState.correctedText.isEmpty {
                    Button(action: {
                        replaceInSource()
                    }) {
                        Label("Replace", systemImage: "arrow.uturn.backward")
                    }
                    .buttonStyle(.borderedProminent)
                    .help("Replace original text with corrected version in the source app")
                }

                Button(action: {
                    copyToClipboard(appState.correctedText)
                    showToastNotification("Copied to clipboard", icon: "checkmark.circle.fill")
                    dismiss()
                }) {
                    Label("Copy Result", systemImage: "doc.on.clipboard")
                }
                .buttonStyle(.bordered)
                .disabled(appState.isProcessing || appState.correctedText.isEmpty)

                Spacer()

                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.return)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 800, height: 500)
        .toast(isShowing: $showToast, message: toastMessage, icon: toastIcon)
        .onChange(of: appState.isProcessing) { _, newValue in
            if !newValue && !appState.correctedText.isEmpty {
                hasReceivedResult = true
            }
        }
        .onAppear {
            setupKeyMonitor()
            if !appState.correctedText.isEmpty {
                hasReceivedResult = true
            }
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

    private func replaceInSource() {
        // Copy corrected text to clipboard
        copyToClipboard(appState.correctedText)

        // Activate the source app and paste
        if let bundleId = appState.sourceAppBundle,
           let appUrl = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).first {
            appUrl.activate(options: [])

            // Wait briefly for app activation, then paste
            Task {
                try? await Task.sleep(nanoseconds: 150_000_000) // 150ms
                _ = ClipboardManager.shared.simulatePaste()
                showToastNotification("Replaced in source app", icon: "checkmark.circle.fill")
                dismiss()
            }
        } else {
            // No source app tracked, just copy and notify
            showToastNotification("Copied to clipboard", icon: "doc.on.clipboard")
        }
    }

    private func showToastNotification(_ message: String, icon: String) {
        toastMessage = message
        toastIcon = icon
        showToast = true
    }
}