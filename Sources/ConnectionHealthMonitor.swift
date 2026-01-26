import Foundation
import Combine

/// Monitors connection health to Ollama service
@MainActor
class ConnectionHealthMonitor: ObservableObject {
    private var ollamaService: OllamaService
    private var healthCheckTimer: Timer?
    private var reconnectAttempts: Int = 0
    private let maxReconnectAttempts = 5
    private let maxReconnectDelay: TimeInterval = 60.0  // Cap exponential backoff at 60 seconds

    @Published var isHealthy: Bool = false
    @Published var lastCheckTime: Date?
    @Published var latency: TimeInterval?
    @Published var isReconnecting: Bool = false

    init(ollamaService: OllamaService) {
        self.ollamaService = ollamaService
    }

    /// Start periodic health checks
    func startMonitoring(interval: TimeInterval = 30.0) {
        // Stop any existing timer
        stopMonitoring()

        // Perform initial check
        Task {
            await performHealthCheck()
        }

        // Set up periodic health checks
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performHealthCheck()
            }
        }
    }

    /// Stop monitoring
    func stopMonitoring() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
        isReconnecting = false
    }
    
    /// Perform a single health check
    func performHealthCheck() async {
        let startTime = Date()
        
        do {
            _ = try await ollamaService.listModels()
            let endTime = Date()
            
            self.isHealthy = true
            self.lastCheckTime = Date()
            self.latency = endTime.timeIntervalSince(startTime)
            self.reconnectAttempts = 0
            self.isReconnecting = false
        } catch {
            self.isHealthy = false
            self.lastCheckTime = Date()
            self.latency = nil
            
            // Attempt auto-reconnect
            await attemptReconnect()
        }
    }
    
    /// Attempt to reconnect with exponential backoff (capped at maxReconnectDelay)
    private func attemptReconnect() async {
        guard reconnectAttempts < maxReconnectAttempts else {
            self.isReconnecting = false
            return
        }

        self.isReconnecting = true

        reconnectAttempts += 1

        // Exponential backoff: 2^attempts seconds, capped at maxReconnectDelay
        let exponentialDelay = pow(2.0, Double(reconnectAttempts))
        let delay = min(exponentialDelay, maxReconnectDelay)

        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

        await performHealthCheck()
    }
    
    /// Force a reconnect attempt
    func forceReconnect() async {
        reconnectAttempts = 0
        await performHealthCheck()
    }
    
    /// Get connection quality description
    func getConnectionQuality() -> ConnectionQuality {
        guard isHealthy, let latency = latency else {
            return .disconnected
        }
        
        if latency < 0.5 {
            return .excellent
        } else if latency < 1.0 {
            return .good
        } else if latency < 2.0 {
            return .fair
        } else {
            return .poor
        }
    }
}

enum ConnectionQuality: String {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case disconnected = "Disconnected"
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "green"
        case .fair: return "orange"
        case .poor: return "orange"
        case .disconnected: return "red"
        }
    }
}

/// Error types for proofreading operations
enum ProofreadingError: Error, LocalizedError {
    case connectionFailed
    case modelNotFound(String)
    case timeout
    case invalidResponse
    case serviceUnavailable
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Failed to connect to Ollama service"
        case .modelNotFound(let model):
            return "Model '\(model)' not found"
        case .timeout:
            return "Request timed out"
        case .invalidResponse:
            return "Received invalid response from service"
        case .serviceUnavailable:
            return "Ollama service is unavailable"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .connectionFailed, .serviceUnavailable:
            return "Check that Ollama is running and the URL is correct"
        case .modelNotFound:
            return "Pull the model using 'ollama pull' command"
        case .timeout:
            return "Try again or check your connection"
        case .invalidResponse:
            return "Try restarting Ollama service"
        case .unknown:
            return "Check Ollama service status"
        }
    }
}
