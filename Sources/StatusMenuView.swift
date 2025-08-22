import SwiftUI

struct StatusMenuView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            statusSection
            Divider()
            actionButtons
            Divider()
            quitButton
        }
        .padding(16)
        .frame(width: 280)
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Proofreader")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Model: \(appState.currentModel)")
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text("Status: \(statusText)")
                        .font(.system(size: 12))
                        .foregroundColor(statusColor)
                }
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { appState.showSettings(nil) }) {
                Label("Settings", systemImage: "gear")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
            
            Button(action: { appState.showPromptEditor(nil) }) {
                Label("Change Prompt", systemImage: "text.quote")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
            
            Button(action: { appState.showAbout(nil) }) {
                Label("About Proofreader", systemImage: "info.circle")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var quitButton: some View {
        Button(action: { NSApplication.shared.terminate(nil) }) {
            Label("Quit", systemImage: "power")
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.primary)
        }
        .buttonStyle(.plain)
    }
    
    private var statusText: String {
        switch appState.connectionStatus {
        case .connected: return "Connected"
        case .disconnected: return "Disconnected"
        case .error: return "Error"
        }
    }
    
    private var statusColor: Color {
        switch appState.connectionStatus {
        case .connected: return .green
        case .disconnected: return .orange
        case .error: return .red
        }
    }
}