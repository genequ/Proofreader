import Foundation

/// Protocol that all LLM providers must conform to
@preconcurrency protocol LLMProvider {
    /// Check if the provider is installed and running
    func checkInstallation() async -> ProviderStatus

    /// List available models
    func listModels() async throws -> [String]

    /// Generate text with streaming response
    func generateStream(model: String, prompt: String) -> AsyncThrowingStream<String, Error>

    /// Stop a running model (no-op if not supported)
    func stop(model: String) async

    /// Preload a model into memory
    func preload(model: String) async

    /// Update the base URL for API requests
    func updateBaseURL(_ url: String)
}

/// Available LLM provider types
enum LLMProviderType: String, CaseIterable, Codable {
    case ollama = "Ollama"
    case lmstudio = "LM Studio"
}
