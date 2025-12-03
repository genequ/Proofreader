import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage: Int = 0
    @State private var isCheckingOllama: Bool = false
    @State private var ollamaInstalled: Bool = false
    @State private var selectedModel: String = "gemma3:4b"
    @State private var customShortcut: String = "command+."
    
    private let totalPages = 5
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(index <= currentPage ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 20)
            
            // Content
            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                ollamaSetupPage.tag(1)
                modelSelectionPage.tag(2)
                shortcutSetupPage.tag(3)
                readyPage.tag(4)
            }
            .tabViewStyle(.automatic)
            
            // Navigation buttons
            HStack(spacing: 12) {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                Button("Skip") {
                    completeOnboarding()
                }
                .buttonStyle(.borderless)
                
                if currentPage < totalPages - 1 {
                    Button("Continue") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canContinue)
                } else {
                    Button("Get Started") {
                        completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
        }
        .frame(width: 600, height: 500)
    }
    
    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            Text("Welcome to Proofreader")
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
            
            Text("AI-powered text proofreading for macOS")
                .font(.title3)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "keyboard", title: "Global Keyboard Shortcut", description: "Proofread text anywhere with a hotkey")
                FeatureRow(icon: "cpu", title: "Ollama Integration", description: "Works with any Ollama AI model")
                FeatureRow(icon: "bolt.fill", title: "Real-time Processing", description: "Instant proofreading with visual feedback")
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
    }
    
    private var ollamaSetupPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: ollamaInstalled ? "checkmark.circle.fill" : "server.rack")
                .font(.system(size: 64))
                .foregroundColor(ollamaInstalled ? .green : .accentColor)
            
            Text("Ollama Setup")
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
            
            Text("Proofreader requires Ollama to be installed and running")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                if isCheckingOllama {
                    ProgressView()
                        .scaleEffect(1.2)
                } else if ollamaInstalled {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Ollama is running!")
                            .fontWeight(.medium)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.orange)
                            Text("Ollama not detected")
                                .fontWeight(.medium)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                        
                        Button("Download Ollama") {
                            if let url = URL(string: "https://ollama.ai/download") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Button(ollamaInstalled ? "Check Again" : "Check Connection") {
                    checkOllamaConnection()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            checkOllamaConnection()
        }
    }
    
    private var modelSelectionPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "cpu.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            Text("Select AI Model")
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
            
            Text("Choose a model for proofreading. Smaller models are faster but less accurate.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                if appState.availableModels.isEmpty {
                    VStack(spacing: 12) {
                        Text("No models found")
                            .foregroundColor(.secondary)
                        
                        Text("Install a model using: ollama pull gemma3:4b")
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                        
                        Button("Refresh") {
                            appState.checkConnection()
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    Picker("Model", selection: $selectedModel) {
                        ForEach(appState.availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: 300)
                    
                    Text("Recommended: gemma3:4b or llama3.2:3b")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var shortcutSetupPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "keyboard.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            Text("Keyboard Shortcut")
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
            
            Text("Set a global keyboard shortcut to proofread selected text from any application")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                HStack {
                    Text("Shortcut:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .trailing)
                    
                    TextField("command+.", text: $customShortcut)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 200)
                }
                
                Text("Examples: command+., control+shift+p, option+space")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("How to use:")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Text("1")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .frame(width: 24, height: 24)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(12)
                    Text("Select text in any application")
                }
                
                HStack(spacing: 12) {
                    Text("2")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .frame(width: 24, height: 24)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(12)
                    Text("Press your keyboard shortcut")
                }
                
                HStack(spacing: 12) {
                    Text("3")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .frame(width: 24, height: 24)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(12)
                    Text("Review and copy corrected text")
                }
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
    
    private var readyPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            Text("You're All Set!")
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
            
            Text("Proofreader is ready to use")
                .font(.title3)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                SummaryRow(label: "Ollama Status", value: ollamaInstalled ? "Connected" : "Not connected", isGood: ollamaInstalled)
                SummaryRow(label: "Selected Model", value: selectedModel, isGood: !appState.availableModels.isEmpty)
                SummaryRow(label: "Keyboard Shortcut", value: customShortcut, isGood: true)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            
            Text("You can change these settings anytime from the menu bar")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
    
    private var canContinue: Bool {
        switch currentPage {
        case 1: return ollamaInstalled
        case 2: return !appState.availableModels.isEmpty
        default: return true
        }
    }
    
    private func checkOllamaConnection() {
        isCheckingOllama = true
        appState.checkConnection()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isCheckingOllama = false
            ollamaInstalled = appState.connectionStatus == .connected
        }
    }
    
    private func completeOnboarding() {
        // Apply settings
        if !appState.availableModels.isEmpty {
            appState.currentModel = selectedModel
        }
        appState.updateKeyboardShortcut(customShortcut)
        
        // Mark onboarding as complete
        appState.hasCompletedOnboarding = true
        appState.appLaunchCount += 1
        
        dismiss()
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct SummaryRow: View {
    let label: String
    let value: String
    let isGood: Bool
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack(spacing: 6) {
                Image(systemName: isGood ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(isGood ? .green : .orange)
                    .font(.caption)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
