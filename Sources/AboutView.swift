import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var monitor: Any?
    
    var body: some View {
        VStack(spacing: 16) {
            // App Icon and Title
            VStack(spacing: 10) {
                if let appIcon = NSApp.applicationIconImage {
                    Image(nsImage: appIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.accentColor)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        )
                }
                
                Text("Proofreader")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("AI-Powered Text Proofreading for macOS")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Divider()
            
            // Version Information
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "Version:", value: appVersion)
                InfoRow(label: "Build:", value: buildNumber)
            }
            
            Divider()
            
            // Description
            Text("A lightweight menu bar utility that uses Ollama's AI models to proofread and correct text anywhere on your Mac with a global keyboard shortcut.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
            
            // Buttons
            HStack(spacing: 12) {
                Button("GitHub") {
                    if let url = URL(string: "https://github.com/genequ/Proofreader") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
            }
        }
        .padding(20)
        .frame(width: 320, height: 300)
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
    
    // Version Information Getters
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .trailing)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .textSelection(.enabled)
            
            Spacer()
        }
    }
}

#Preview {
    AboutView()
}