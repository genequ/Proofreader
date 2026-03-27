import SwiftUI

/// Reusable status indicator component for provider connection state
struct OllamaStatusView: View {
    let status: ProviderStatus
    let lastError: LLMError?
    let onRefresh: () -> Void
    let onOpenSettings: (() -> Void)?
    let provider: LLMProviderType

    @State private var isExpanded: Bool = false

    init(status: ProviderStatus, lastError: LLMError? = nil, onRefresh: @escaping () -> Void, onOpenSettings: (() -> Void)? = nil, provider: LLMProviderType = .ollama) {
        self.status = status
        self.lastError = lastError
        self.onRefresh = onRefresh
        self.onOpenSettings = onOpenSettings
        self.provider = provider
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
    private func errorDetailsView(_ error: LLMError) -> some View {
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

        switch provider {
        case .ollama:
            alert.messageText = "Install Ollama"
            alert.informativeText = "Install Ollama using Homebrew:\n\nbrew install ollama\n\nAfter installation, start it with:\n\nollama serve"
            alert.addButton(withTitle: "Copy Install Command")
            alert.addButton(withTitle: "OK")
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                copyToClipboard("brew install ollama")
            }

        case .lmstudio:
            alert.messageText = "Install LM Studio"
            alert.informativeText = "Download LM Studio from:\n\nhttps://lmstudio.ai/\n\nAfter installation, start the app and enable the API server in settings."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Open Website")
            alert.addButton(withTitle: "OK")
            let response = alert.runModal()
            if response == .alertFirstButtonReturn, let url = URL(string: "https://lmstudio.ai/") {
                NSWorkspace.shared.open(url)
            }

        case .deepseek:
            alert.messageText = "DeepSeek API Key Required"
            alert.informativeText = "To use DeepSeek, you need an API key:\n\n1. Get your key from: https://platform.deepseek.com/\n2. Enter the key in Settings\n3. Select a model from the dropdown"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Open Website")
            alert.addButton(withTitle: "OK")
            let response = alert.runModal()
            if response == .alertFirstButtonReturn, let url = URL(string: "https://platform.deepseek.com/") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private func showStartGuide() {
        let alert = NSAlert()

        switch provider {
        case .ollama:
            alert.messageText = "Start Ollama"
            alert.informativeText = "Start Ollama with this command:\n\nollama serve\n\nRun this in a terminal and keep it running while using Proofreader."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Copy Command")
            alert.addButton(withTitle: "OK")
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                copyToClipboard("ollama serve")
            }

        case .lmstudio:
            alert.messageText = "Enable LM Studio API Server"
            alert.informativeText = "1. Open LM Studio\n2. Go to Settings (gear icon)\n3. Enable \"Enable Server\"\n4. Use default port 1234"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()

        case .deepseek:
            alert.messageText = "Check API Key"
            alert.informativeText = "Make sure your API key is valid and entered correctly in Settings.\n\nGet your key from: https://platform.deepseek.com/"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "OK")
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                onOpenSettings?()
            }
        }
    }

    private func showModelGuide() {
        let alert = NSAlert()

        switch provider {
        case .ollama:
            alert.messageText = "Download a Model"
            alert.informativeText = "Download a model to get started:\n\nollama pull gemma2:2b\n\nRecommended models:\n• gemma2:2b (small, fast)\n• llama3.2:3b (balanced)\n• qwen2.5:7b (larger, more accurate)"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Copy Command")
            alert.addButton(withTitle: "OK")
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                copyToClipboard("ollama pull gemma2:2b")
            }

        case .lmstudio:
            alert.messageText = "Load a Model in LM Studio"
            alert.informativeText = "1. Open LM Studio\n2. Go to the AI Models tab\n3. Search and download a model\n4. Load the model for chatting\n\nThe model will be available in Proofreader once loaded."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()

        case .deepseek:
            alert.messageText = "Select a Model"
            alert.informativeText = "DeepSeek models should appear in the Model dropdown in Settings.\n\nAvailable models:\n• deepseek-chat\n• deepseek-coder\n\nIf no models appear, check your API key."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "OK")
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                onOpenSettings?()
            }
        }
    }
}
