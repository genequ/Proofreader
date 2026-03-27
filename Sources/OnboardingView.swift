import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage: Int = 0
    @State private var isCheckingProvider: Bool = false
    @State private var providerConnected: Bool = false
    @State private var selectedProvider: LLMProviderType = .ollama
    @State private var selectedModel: String = ""
    @State private var customShortcut: String = "command+."

    private let totalPages = 6  // Added provider selection page
    
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
                providerSelectionPage.tag(1)
                providerSetupPage.tag(2)
                modelSelectionPage.tag(3)
                shortcutSetupPage.tag(4)
                readyPage.tag(5)
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

                // Hide "Skip" on the final page
                if currentPage < totalPages - 1 {
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .buttonStyle(.borderless)
                }

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
                FeatureRow(icon: "square.stack.3d.up", title: "Multiple AI Providers", description: "Works with Ollama, LM Studio, or DeepSeek")
                FeatureRow(icon: "bolt.fill", title: "Real-time Processing", description: "Instant proofreading with visual feedback")
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
    }
    
    private var providerSelectionPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("Choose Your AI Provider")
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)

            Text("Select how you want to power proofreading. Each option has different requirements.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                ForEach(LLMProviderType.allCases, id: \.self) { provider in
                    Button(action: {
                        selectedProvider = provider
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: providerIcon(for: provider))
                                .font(.title2)
                                .foregroundColor(selectedProvider == provider ? .white : .accentColor)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(provider.rawValue)
                                    .font(.headline)
                                    .foregroundColor(selectedProvider == provider ? .white : .primary)

                                Text(providerDescription(for: provider))
                                    .font(.caption)
                                    .foregroundColor(selectedProvider == provider ? .white.opacity(0.8) : .secondary)
                            }

                            Spacer()

                            if selectedProvider == provider {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(selectedProvider == provider ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()

            Spacer()
        }
        .padding()
    }

    private var providerSetupPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: providerConnected ? "checkmark.circle.fill" : providerIcon(for: selectedProvider))
                .font(.system(size: 64))
                .foregroundColor(providerConnected ? .green : .accentColor)

            Text("\(selectedProvider.rawValue) Setup")
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)

            Text(providerSetupInstructions(for: selectedProvider))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 16) {
                if isCheckingProvider {
                    ProgressView()
                        .scaleEffect(1.2)
                } else if providerConnected {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(selectedProvider.rawValue) is ready!")
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
                            Text(providerErrorMessage(for: selectedProvider))
                                .fontWeight(.medium)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)

                        if let url = providerDownloadURL(for: selectedProvider) {
                            Button("Get \(selectedProvider.rawValue)") {
                                NSWorkspace.shared.open(url)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                Button(providerConnected ? "Check Again" : "Check Connection") {
                    checkProviderConnection()
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            checkProviderConnection()
        }
    }

    private func providerIcon(for provider: LLMProviderType) -> String {
        switch provider {
        case .ollama: return "server.rack"
        case .lmstudio: return "laptopcomputer"
        case .deepseek: return "cloud"
        }
    }

    private func providerDescription(for provider: LLMProviderType) -> String {
        switch provider {
        case .ollama: return "Run AI models locally on your Mac"
        case .lmstudio: return "Local models with a friendly interface"
        case .deepseek: return "Cloud API, no installation needed"
        }
    }

    private func providerSetupInstructions(for provider: LLMProviderType) -> String {
        switch provider {
        case .ollama:
            return "Install and start Ollama, then download a model."
        case .lmstudio:
            return "Install LM Studio, enable the API server, and load a model."
        case .deepseek:
            return "Get your API key from platform.deepseek.com"
        }
    }

    private func providerErrorMessage(for provider: LLMProviderType) -> String {
        switch provider {
        case .ollama: return "Ollama not detected"
        case .lmstudio: return "LM Studio not connected"
        case .deepseek: return "API key invalid or missing"
        }
    }

    private func providerDownloadURL(for provider: LLMProviderType) -> URL? {
        switch provider {
        case .ollama: return URL(string: "https://ollama.ai/download")
        case .lmstudio: return URL(string: "https://lmstudio.ai/")
        case .deepseek: return URL(string: "https://platform.deepseek.com/")
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
                SummaryRow(label: "Provider", value: selectedProvider.rawValue, isGood: true)
                SummaryRow(label: "Status", value: providerConnected ? "Connected" : "Not connected", isGood: providerConnected)
                SummaryRow(label: "Selected Model", value: selectedModel.isEmpty ? "None" : selectedModel, isGood: !appState.availableModels.isEmpty)
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
        case 1: return true  // Provider selection - always can continue
        case 2: return providerConnected  // Provider setup
        case 3: return !appState.availableModels.isEmpty  // Model selection
        default: return true
        }
    }

    /// Check if provider is truly connected with models
    private func isProviderConnected() -> Bool {
        if case .connected(let models) = appState.ollamaStatus, !models.isEmpty {
            return true
        }
        return false
    }

    private func checkProviderConnection() {
        // First update the provider in appState
        appState.selectedProvider = selectedProvider

        isCheckingProvider = true
        appState.checkOllamaStatus()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isCheckingProvider = false
            // Check if provider is connected with available models
            if case .connected(let models) = appState.ollamaStatus, !models.isEmpty {
                providerConnected = true
                // Auto-select first model
                selectedModel = models.first ?? ""
            } else {
                providerConnected = false
            }
        }
    }

    private func completeOnboarding() {
        // Apply settings
        appState.selectedProvider = selectedProvider
        if !appState.availableModels.isEmpty && !selectedModel.isEmpty {
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
