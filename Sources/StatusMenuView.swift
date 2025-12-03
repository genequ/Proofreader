import SwiftUI

struct StatusMenuView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            statusSection
                .padding(.bottom, 12)
            
            Divider()
            
            actionButtons
                .padding(.vertical, 12)
            
            Divider()
            
            quitButton
                .padding(.top, 12)
        }
        .padding(16)
        .frame(width: 340)
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Proofreader")
                .font(.headline)
                .foregroundColor(.primary)
            
            (Text("Model: ")
                .font(.system(size: 11))
                .foregroundColor(.secondary) +
            Text(appState.currentModel.trimmingCharacters(in: .whitespacesAndNewlines))
                .font(.system(size: 11))
                .foregroundColor(.primary))
                .lineLimit(1)

            
            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text("Status: \(statusText)")
                    .font(.system(size: 11))
                    .foregroundColor(statusColor)
            }
            
            Divider()
            
            Button(action: { appState.handleProofreadingShortcut() }) {
                HStack(spacing: 8) {
                    Image(systemName: "text.cursor")
                        .frame(width: 16)
                    Text("Proofread Selection (\(appState.keyboardShortcut))")
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
            
            Button(action: { appState.proofreadClipboard() }) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.on.clipboard")
                        .frame(width: 16)
                    Text("Proofread Clipboard")
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
        }
    }
    

    
    private var actionButtons: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Template selector
            Menu {
                ForEach(appState.templateManager.templates) { template in
                    Button(action: {
                        appState.selectedTemplate = template.id
                    }) {
                        HStack {
                            Text(template.name)
                            if appState.selectedTemplate == template.id {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                
                Divider()
                
                Button("Manage Templates...") {
                    appState.showPromptEditor(nil)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "text.quote")
                        .frame(width: 16)
                    Text("Template")
                    Spacer()
                    Text(currentTemplateName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.primary)
            }
            .menuStyle(.borderlessButton)
            
            Button(action: { appState.showSettings(nil) }) {
                HStack(spacing: 8) {
                    Image(systemName: "gear")
                        .frame(width: 16)
                    Text("Settings")
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
            
            Button(action: { appState.showStatistics(nil) }) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar")
                        .frame(width: 16)
                    Text("Statistics")
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
            
            Button(action: { appState.showAbout(nil) }) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .frame(width: 16)
                    Text("About Proofreader")
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var quitButton: some View {
        Button(action: { NSApplication.shared.terminate(nil) }) {
            HStack(spacing: 8) {
                Image(systemName: "power")
                    .frame(width: 16)
                Text("Quit")
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(.primary)
        }
        .buttonStyle(.plain)
    }
    
    private var statusText: String {
        switch appState.ollamaStatus {
        case .connected: return "Connected"
        case .checking: return "Checking..."
        default: return "Error"
        }
    }
    
    private var statusColor: Color {
        switch appState.ollamaStatus {
        case .connected: return Color(.systemGreen)
        case .checking: return Color(.systemOrange)
        default: return Color(.systemRed)
        }
    }
    
    private var currentTemplateName: String {
        appState.templateManager.template(withId: appState.selectedTemplate)?.name ?? "Default"
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes)m ago"
        } else {
            let hours = Int(seconds / 3600)
            return "\(hours)h ago"
        }
    }
}