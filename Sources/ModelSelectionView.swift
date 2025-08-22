import SwiftUI

struct ModelSelectionView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var monitor: Any?
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Select Model")
                .font(.title3)
                .fontWeight(.semibold)
            
            Divider()
            
            if appState.availableModels.isEmpty {
                ProgressView("Loading models...")
                    .onAppear {
                        appState.checkConnection()
                    }
            } else {
                List(appState.availableModels, id: \.self, selection: Binding(
                    get: { appState.currentModel },
                    set: { newValue in
                        if let newValue = newValue {
                            appState.currentModel = newValue
                        }
                    }
                )) { model in
                    Text(model)
                }
                .listStyle(.bordered)
                .frame(height: 200)
            }
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Button("Refresh") {
                    appState.checkConnection()
                }
                
                Button("Select") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
                .disabled(appState.availableModels.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 300, height: 300)
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
}