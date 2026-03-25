import Foundation

enum LLMError: LocalizedError {
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
            return "Provider Not Installed"
        case .notRunning:
            return "Provider Not Running"
        case .noModelsAvailable:
            return "No Models Available"
        case .connectionFailed:
            return "Connection Failed"
        case .modelNotFound(let model):
            return "Model Not Found: \(model)"
        case .networkTimeout:
            return "Network Timeout"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .invalidResponse:
            return "Invalid Response"
        }
    }

    var failureReason: String? {
        switch self {
        case .notInstalled:
            return "The LLM provider application is not installed on this system."
        case .notRunning:
            return "The LLM provider is not running. Please start it first."
        case .noModelsAvailable:
            return "No models are available. Please download at least one model."
        case .connectionFailed(let error):
            return "Could not connect to the provider: \(error.localizedDescription)"
        case .modelNotFound(let model):
            return "The model '\(model)' was not found."
        case .networkTimeout:
            return "The request timed out. Please check your network connection."
        case .invalidURL:
            return "The configured URL is not valid."
        case .invalidResponse:
            return "The provider returned an invalid response."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notInstalled:
            return "Install the LLM provider application."
        case .notRunning:
            return "Start the LLM provider application."
        case .noModelsAvailable:
            return "Download and install a model in the provider application."
        case .connectionFailed:
            return "Check that the provider is running and the URL is correct."
        case .modelNotFound:
            return "Verify the model name or download the model."
        case .networkTimeout:
            return "Try again or check your network connection."
        case .invalidURL:
            return "Check the URL in Settings."
        case .invalidResponse:
            return "Try again or restart the provider."
        }
    }

    /// Terminal command that can fix this error (if applicable)
    /// Note: This is provider-specific and may be overridden by provider implementations
    var helpCommand: String? {
        switch self {
        case .notInstalled:
            return nil  // Provider-specific installation command
        case .notRunning:
            return nil  // Provider-specific start command
        case .noModelsAvailable:
            return nil  // Provider-specific model download command
        case .modelNotFound:
            return nil  // Provider-specific model pull command
        case .networkTimeout:
            return nil  // Provider-specific restart command
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
