import Foundation

/// Comprehensive error type for Ollama-related failures
enum OllamaError: LocalizedError {
    case notInstalled
    case notRunning
    case noModelsAvailable
    case connectionFailed(underlying: Error)
    case modelNotFound(String)
    case networkTimeout
    case invalidURL(String)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .notInstalled:
            return "Ollama Not Installed"
        case .notRunning:
            return "Ollama Not Running"
        case .noModelsAvailable:
            return "No Models Available"
        case .connectionFailed:
            return "Connection Failed"
        case .modelNotFound(let model):
            return "Model '\(model)' Not Found"
        case .networkTimeout:
            return "Connection Timeout"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .invalidResponse:
            return "Invalid Response from Ollama"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .notInstalled:
            return "Ollama is not installed on your system."
        case .notRunning:
            return "Ollama is installed but the service is not running."
        case .noModelsAvailable:
            return "Ollama is running but no models are downloaded."
        case .connectionFailed(let error):
            return "Could not connect to Ollama: \(error.localizedDescription)"
        case .modelNotFound(let model):
            return "The selected model '\(model)' is not available."
        case .networkTimeout:
            return "The connection to Ollama timed out."
        case .invalidURL(let url):
            return "The Ollama URL '\(url)' is not valid."
        case .invalidResponse:
            return "Ollama returned an unexpected response."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .notInstalled:
            return "Install Ollama using Homebrew:\n\nbrew install ollama"
        case .notRunning:
            return "Start Ollama with this command:\n\nollama serve"
        case .noModelsAvailable:
            return "Download a model to get started:\n\nollama pull gemma2:2b\n\nRecommended models:\n• gemma2:2b (small, fast)\n• llama3.2:3b (balanced)\n• qwen2.5:7b (larger, more accurate)"
        case .connectionFailed:
            return "Check that Ollama is running and accessible at the configured URL."
        case .modelNotFound(let model):
            return "Download the model:\n\nollama pull \(model)"
        case .networkTimeout:
            return "Ensure Ollama is running and not overloaded. Try restarting it:\n\nkillall ollama\nollama serve"
        case .invalidURL:
            return "Check the Ollama URL in Settings. The default is:\n\nhttp://127.0.0.1:11434"
        case .invalidResponse:
            return "Try restarting Ollama or check for updates."
        }
    }
    
    /// Terminal command that can fix this error (if applicable)
    var helpCommand: String? {
        switch self {
        case .notInstalled:
            return "brew install ollama"
        case .notRunning:
            return "ollama serve"
        case .noModelsAvailable:
            return "ollama pull gemma2:2b"
        case .modelNotFound(let model):
            return "ollama pull \(model)"
        case .networkTimeout:
            return "killall ollama && ollama serve"
        default:
            return nil
        }
    }
    
    /// Severity level for UI presentation
    var severity: ErrorSeverity {
        switch self {
        case .notInstalled, .notRunning, .noModelsAvailable:
            return .critical
        case .modelNotFound, .invalidURL:
            return .high
        case .connectionFailed, .networkTimeout, .invalidResponse:
            return .medium
        }
    }
}

enum ErrorSeverity {
    case critical  // Prevents app from working at all
    case high      // Major functionality broken
    case medium    // Temporary or recoverable issue
}
