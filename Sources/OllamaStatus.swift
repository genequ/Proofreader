import SwiftUI

/// Represents the current state of Ollama installation and connection
enum OllamaStatus: Equatable {
    case checking
    case notInstalled
    case installed(running: Bool)
    case connected(models: [String])
    case error(OllamaError)
    
    /// Whether Ollama is in a healthy, usable state
    var isHealthy: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
    
    /// Whether the app can perform proofreading
    var canProofread: Bool {
        if case .connected(let models) = self, !models.isEmpty {
            return true
        }
        return false
    }
    
    /// User-facing status text
    var statusText: String {
        switch self {
        case .checking:
            return "Checking Ollama..."
        case .notInstalled:
            return "Ollama Not Installed"
        case .installed(running: false):
            return "Ollama Not Running"
        case .installed(running: true):
            return "Ollama Running"
        case .connected(let models):
            if models.isEmpty {
                return "No Models Available"
            }
            return "Connected (\(models.count) model\(models.count == 1 ? "" : "s"))"
        case .error(let error):
            return error.errorDescription ?? "Error"
        }
    }
    
    /// SF Symbol icon name for this status
    var statusIcon: String {
        switch self {
        case .checking:
            return "arrow.clockwise"
        case .notInstalled:
            return "xmark.circle.fill"
        case .installed(running: false):
            return "pause.circle.fill"
        case .installed(running: true):
            return "checkmark.circle"
        case .connected(let models):
            return models.isEmpty ? "exclamationmark.triangle.fill" : "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
    
    /// Color for status indicator
    var statusColor: Color {
        switch self {
        case .checking:
            return .gray
        case .notInstalled, .error:
            return .red
        case .installed(running: false):
            return .orange
        case .installed(running: true):
            return .yellow
        case .connected(let models):
            return models.isEmpty ? .yellow : .green
        }
    }
    
    /// Detailed help text for this status
    var helpText: String? {
        switch self {
        case .checking:
            return nil
        case .notInstalled:
            return "Install Ollama to enable AI-powered proofreading."
        case .installed(running: false):
            return "Start Ollama to use proofreading features."
        case .installed(running: true):
            return "Ollama is running but connection not verified."
        case .connected(let models):
            if models.isEmpty {
                return "Download at least one model to start proofreading."
            }
            return nil
        case .error(let error):
            return error.failureReason
        }
    }
    
    // Equatable conformance
    static func == (lhs: OllamaStatus, rhs: OllamaStatus) -> Bool {
        switch (lhs, rhs) {
        case (.checking, .checking):
            return true
        case (.notInstalled, .notInstalled):
            return true
        case (.installed(let lRunning), .installed(let rRunning)):
            return lRunning == rRunning
        case (.connected(let lModels), .connected(let rModels)):
            return lModels == rModels
        case (.error(let lError), .error(let rError)):
            return lError.localizedDescription == rError.localizedDescription
        default:
            return false
        }
    }
}
