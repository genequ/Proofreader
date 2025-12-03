import SwiftUI

/// Reusable status indicator component for Ollama connection state
struct OllamaStatusView: View {
    let status: OllamaStatus
    let lastError: OllamaError?
    let onRefresh: () -> Void
    let onOpenSettings: (() -> Void)?
    
    @State private var isExpanded: Bool = false
    
    init(status: OllamaStatus, lastError: OllamaError? = nil, onRefresh: @escaping () -> Void, onOpenSettings: (() -> Void)? = nil) {
        self.status = status
        self.lastError = lastError
        self.onRefresh = onRefresh
        self.onOpenSettings = onOpenSettings
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Status header
            HStack(spacing: 8) {
                Image(systemName: status.statusIcon)
                    .foregroundColor(status.statusColor)
                    .font(.system(size: 14))
                
                Text(status.statusText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if case .checking = status {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 16, height: 16)
                }
                
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help("Refresh status")
            }
            
            // Help text and actions
            if let helpText = status.helpText {
                Text(helpText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Error details and actions
            if let error = lastError {
                errorDetailsView(error)
            } else if !status.isHealthy {
                quickActionsView()
            }
        }
        .padding(12)
        .background(backgroundColor)
        .cornerRadius(8)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .connected:
            return Color.green.opacity(0.1)
        case .checking:
            return Color.gray.opacity(0.1)
        case .notInstalled, .error:
            return Color.red.opacity(0.1)
        case .installed:
            return Color.orange.opacity(0.1)
        }
    }
    
    @ViewBuilder
    private func errorDetailsView(_ error: OllamaError) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let command = error.helpCommand {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Run this command:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text(command)
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(4)
                        
                        Button("Copy") {
                            copyToClipboard(command)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
            
            HStack(spacing: 8) {
                if onOpenSettings != nil {
                    Button("Open Settings") {
                        onOpenSettings?()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                if error.recoverySuggestion != nil, isExpanded {
                    Button("Hide Details") {
                        isExpanded = false
                    }
                    .buttonStyle(.plain)
                    .controlSize(.small)
                } else if error.recoverySuggestion != nil {
                    Button("Show Details") {
                        isExpanded = true
                    }
                    .buttonStyle(.plain)
                    .controlSize(.small)
                }
            }
            
            if isExpanded, let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
        }
    }
    
    @ViewBuilder
    private func quickActionsView() -> some View {
        HStack(spacing: 8) {
            switch status {
            case .notInstalled:
                Button("Show Install Guide") {
                    showInstallGuide()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
            case .installed(running: false):
                Button("How to Start") {
                    showStartGuide()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
            case .connected(let models) where models.isEmpty:
                Button("Download Models") {
                    showModelGuide()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
            default:
                EmptyView()
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    private func showInstallGuide() {
        let alert = NSAlert()
        alert.messageText = "Install Ollama"
        alert.informativeText = "Install Ollama using Homebrew:\n\nbrew install ollama\n\nAfter installation, start it with:\n\nollama serve"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Copy Install Command")
        alert.addButton(withTitle: "OK")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            copyToClipboard("brew install ollama")
        }
    }
    
    private func showStartGuide() {
        let alert = NSAlert()
        alert.messageText = "Start Ollama"
        alert.informativeText = "Start Ollama with this command:\n\nollama serve\n\nRun this in a terminal and keep it running while using Proofreader."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Copy Command")
        alert.addButton(withTitle: "OK")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            copyToClipboard("ollama serve")
        }
    }
    
    private func showModelGuide() {
        let alert = NSAlert()
        alert.messageText = "Download a Model"
        alert.informativeText = "Download a model to get started:\n\nollama pull gemma2:2b\n\nRecommended models:\n• gemma2:2b (small, fast)\n• llama3.2:3b (balanced)\n• qwen2.5:7b (larger, more accurate)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Copy Command")
        alert.addButton(withTitle: "OK")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            copyToClipboard("ollama pull gemma2:2b")
        }
    }
}
