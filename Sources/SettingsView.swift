import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isURLFieldFocused: Bool
    @State private var monitor: Any?
    @State private var originalURL: String = ""
    @State private var originalAPIKey: String = ""
    @State private var originalShortcut: String = ""
    @State private var previousModel: String = ""
    @State private var previousProvider: LLMProviderType = .ollama

    var body: some View {
        VStack(spacing: 16) {
            // Ollama Status Section
            OllamaStatusView(
                status: appState.ollamaStatus,
                lastError: appState.lastError,
                onRefresh: {
                    appState.checkOllamaStatus()
                }
            )
            
            Divider()

            // Provider Selection Section
            VStack(spacing: 14) {
                HStack(alignment: .center) {
                    Text("Provider:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .trailing)

                    Picker("", selection: $appState.selectedProvider) {
                        ForEach(LLMProviderType.allCases, id: \.self) { provider in
                            Text(provider.rawValue).tag(provider)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: appState.selectedProvider) { _, newProvider in
                        // Stop previous model if provider changed
                        if previousProvider != newProvider {
                            // Store the previous provider's model before switching
                            switch previousProvider {
                            case .ollama:
                                // Ollama model is already stored
                                break
                            case .lmstudio:
                                // LM Studio model is already stored
                                break
                            case .deepseek:
                                // DeepSeek model is already stored
                                break
                            }
                            previousProvider = newProvider
                            appState.checkOllamaStatus()
                        }
                    }
                }
            }

            Divider()

            // Settings Section
            VStack(spacing: 14) {
                // Show URL field for Ollama and LM Studio, API Key for DeepSeek
                if appState.selectedProvider == .deepseek {
                    HStack(alignment: .center) {
                        Text("API Key:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .trailing)
                        TextField("Enter API Key", text: Binding(
                            get: { appState.deepseekApiKey },
                            set: { appState.deepseekApiKey = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isURLFieldFocused)
                    }
                } else {
                    HStack(alignment: .center) {
                        Text("URL:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .trailing)
                        TextField("Provider URL", text: Binding(
                            get: { appState.currentProviderURL },
                            set: { appState.currentProviderURL = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isURLFieldFocused)
                    }
                }
                
                HStack(alignment: .center) {
                    Text("Model:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .trailing)

                    if appState.availableModels.isEmpty {
                        Text("No models available")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        Spacer()

                        Button(action: {
                            appState.checkOllamaStatus()
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.borderless)
                        .help("Refresh models")
                    } else {
                        Picker("", selection: $appState.currentModel) {
                            ForEach(appState.availableModels, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Button(action: {
                            appState.checkOllamaStatus()
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.borderless)
                        .help("Refresh models")
                    }
                }
                
                HStack(alignment: .center) {
                    Text("Shortcut:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .trailing)
                    TextField("command+.", text: $appState.keyboardShortcut)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            appState.updateKeyboardShortcut(appState.keyboardShortcut)
                        }
                }
                
                HStack(alignment: .top) {
                    Text("Highlights:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .trailing)
                        .padding(.top, 4)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Slider(value: $appState.highlightIntensity, in: 0.1...0.5)
                            .frame(maxWidth: .infinity)
                        
                        Text("Intensity: \(Int(appState.highlightIntensity * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            HStack(spacing: 12) {
                Spacer()

                Button("Cancel") {
                    // Revert changes
                    appState.currentProviderURL = originalURL
                    appState.deepseekApiKey = originalAPIKey
                    appState.keyboardShortcut = originalShortcut
                    appState.currentModel = previousModel
                    appState.selectedProvider = previousProvider
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Button("OK") {
                    // Stop previous model if it changed
                    if previousModel != appState.currentModel {
                        appState.stopModel(previousModel)
                    }
                    // Update URL or API Key based on provider
                    if appState.selectedProvider == .deepseek {
                        appState.updateDeepSeekAPIKey(appState.deepseekApiKey)
                    } else {
                        appState.updateOllamaURL(appState.currentProviderURL)
                    }
                    appState.updateKeyboardShortcut(appState.keyboardShortcut)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
            }
            .padding(.top, 8)
        }
        .padding(20)
        .frame(width: 450, height: 480)
        .onAppear {
            // Store original values for Cancel
            originalURL = appState.currentProviderURL
            originalAPIKey = appState.deepseekApiKey
            originalShortcut = appState.keyboardShortcut
            previousModel = appState.currentModel
            previousProvider = appState.selectedProvider

            appState.checkOllamaStatus()
            isURLFieldFocused = true
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