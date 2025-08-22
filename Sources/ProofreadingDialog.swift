import SwiftUI

struct ProofreadingDialog: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 8) {
            if appState.isProcessing {
                LoadingView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TextEditor(text: .constant(appState.correctedText))
                    .font(.body)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                HStack {
                    Button("Copy") {
                        copyToClipboard(appState.correctedText)
                    }
                    
                    Button("Close") {
                        dismiss()
                    }
                    .keyboardShortcut(.escape)
                }
                .padding(.bottom, 8)
                .padding(.horizontal, 8)
            }
        }
        .frame(width: 700, height: 350)
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}