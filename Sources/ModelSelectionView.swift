import SwiftUI

struct ModelSelectionView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Select Model")
                .font(.headline)
            
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
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Button("Refresh") {
                    appState.checkConnection()
                }
                
                Button("Select") {
                    dismiss()
                }
                .disabled(appState.availableModels.isEmpty)
            }
        }
        .padding()
        .frame(width: 300, height: 300)
    }
}