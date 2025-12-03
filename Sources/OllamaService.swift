import Foundation

actor OllamaService {
    private var baseURL: String
    private let session: URLSession
    private let timeout: TimeInterval = 10.0
    
    init(baseURL: String = "http://127.0.0.1:11434") {
        self.baseURL = baseURL
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: config)
    }
    
    func updateBaseURL(_ url: String) {
        self.baseURL = url
    }
    
    // MARK: - Installation & Health Checks
    
    /// Check if Ollama is installed on the system
    func checkOllamaInstallation() async -> OllamaStatus {
        // First check if we can find the ollama binary
        let installationPath = detectInstallationPath()
        
        if installationPath == nil {
            return .notInstalled
        }
        
        // Binary exists, now check if service is running
        do {
            let isRunning = try await healthCheck()
            if isRunning {
                // Service is running, get models
                let models = try await listModels()
                return .connected(models: models)
            } else {
                return .installed(running: false)
            }
        } catch let error as OllamaError {
            return .error(error)
        } catch {
            // If health check fails, assume not running
            return .installed(running: false)
        }
    }
    
    /// Detect Ollama installation path
    func detectInstallationPath() -> String? {
        let possiblePaths = [
            "/opt/homebrew/bin/ollama",
            "/usr/local/bin/ollama",
            "/usr/bin/ollama",
            "~/bin/ollama"
        ]
        
        let fileManager = FileManager.default
        
        for path in possiblePaths {
            let expandedPath = NSString(string: path).expandingTildeInPath
            if fileManager.fileExists(atPath: expandedPath) {
                return expandedPath
            }
        }
        
        // Also check PATH using 'which'
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["ollama"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !path.isEmpty {
                    return path
                }
            }
        } catch {
            // which command failed, continue
        }
        
        return nil
    }
    
    /// Perform a health check on the Ollama service
    func healthCheck() async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/api/tags") else {
            throw OllamaError.invalidURL(baseURL)
        }
        
        do {
            let (_, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OllamaError.invalidResponse
            }
            
            return (200...299).contains(httpResponse.statusCode)
        } catch let error as OllamaError {
            throw error
        } catch let urlError as URLError {
            throw mapURLError(urlError)
        } catch {
            throw OllamaError.connectionFailed(underlying: error)
        }
    }
    
    // MARK: - API Methods
    
    func listModels() async throws -> [String] {
        guard let url = URL(string: "\(baseURL)/api/tags") else {
            throw OllamaError.invalidURL(baseURL)
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OllamaError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw OllamaError.connectionFailed(underlying: URLError(.badServerResponse))
            }
            
            let modelsResponse = try JSONDecoder().decode(OllamaModelsResponse.self, from: data)
            let models = modelsResponse.models.map { $0.name }
            
            if models.isEmpty {
                throw OllamaError.noModelsAvailable
            }
            
            return models
        } catch let error as OllamaError {
            throw error
        } catch let urlError as URLError {
            throw mapURLError(urlError)
        } catch {
            throw OllamaError.connectionFailed(underlying: error)
        }
    }
    
    func generate(model: String, prompt: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/generate") else {
            throw OllamaError.invalidURL(baseURL)
        }
        
        let parameters: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "stream": false
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OllamaError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 404 {
                    throw OllamaError.modelNotFound(model)
                }
                throw OllamaError.connectionFailed(underlying: URLError(.badServerResponse))
            }
            
            let generateResponse = try JSONDecoder().decode(OllamaGenerateResponse.self, from: data)
            return generateResponse.response
        } catch let error as OllamaError {
            throw error
        } catch let urlError as URLError {
            throw mapURLError(urlError)
        } catch {
            throw OllamaError.connectionFailed(underlying: error)
        }
    }

    func generateStream(model: String, prompt: String) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let url = URL(string: "\(baseURL)/api/generate") else {
                        throw URLError(.badURL)
                    }
                    
                    let parameters: [String: Any] = [
                        "model": model,
                        "prompt": prompt,
                        "stream": true
                    ]
                    
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
                    
                    let (result, response) = try await session.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                        throw URLError(.badServerResponse)
                    }
                    
                    var isThinking = false
                    var buffer = ""
                    let thinkStart = "<think>"
                    let thinkEnd = "</think>"
                    
                    for try await line in result.lines {
                        guard let data = line.data(using: .utf8) else { continue }
                        let generateResponse = try JSONDecoder().decode(OllamaGenerateResponse.self, from: data)
                        let chunk = generateResponse.response
                        
                        if isThinking {
                            buffer += chunk
                            if let endIndex = buffer.range(of: thinkEnd)?.upperBound {
                                isThinking = false
                                let remaining = String(buffer[endIndex...])
                                buffer = ""
                                continuation.yield(remaining)
                            }
                        } else {
                            buffer += chunk
                            if let startIndex = buffer.range(of: thinkStart)?.lowerBound {
                                isThinking = true
                                let safeContent = String(buffer[..<startIndex])
                                continuation.yield(safeContent)
                                buffer = String(buffer[startIndex...])
                            } else {
                                // Check if buffer ends with partial tag starting with '<'
                                // Only keep in buffer if it could be the start of "<think>"
                                var safeLength = buffer.count
                                if buffer.count > 0 {
                                    for i in 1...min(buffer.count, thinkStart.count) {
                                        let suffix = String(buffer.suffix(i))
                                        // Only match if suffix starts with '<' (actual tag start)
                                        if suffix.hasPrefix("<") && thinkStart.hasPrefix(suffix) {
                                            safeLength = buffer.count - i
                                            break
                                        }
                                    }
                                }
                                
                                if safeLength > 0 {
                                    let safeContent = String(buffer.prefix(safeLength))
                                    continuation.yield(safeContent)
                                    buffer = String(buffer.suffix(buffer.count - safeLength))
                                }
                            }
                        }
                        
                        if generateResponse.done ?? false {
                            // If we finish and still have buffer (and not thinking), yield it
                            if !isThinking && !buffer.isEmpty {
                                continuation.yield(buffer)
                            }
                            continuation.finish()
                            return
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func preload(model: String) async {
        guard let url = URL(string: "\(baseURL)/api/generate") else { return }
        
        // Send an empty prompt to load the model into memory
        let parameters: [String: Any] = [
            "model": model,
            "prompt": "",
            "stream": false
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
            // We don't care about the response, just that the request completes (or fails after trying)
            _ = try await session.data(for: request)
        } catch {
            // Ignore errors during preload, it's just an optimization
            print("Preload failed: \(error)")
        }
    }
    
    // MARK: - Error Mapping
    
    /// Map URLError to OllamaError for better user feedback
    private func mapURLError(_ error: URLError) -> OllamaError {
        switch error.code {
        case .timedOut:
            return .networkTimeout
        case .cannotConnectToHost, .cannotFindHost, .networkConnectionLost:
            return .notRunning
        case .badURL:
            return .invalidURL(baseURL)
        default:
            return .connectionFailed(underlying: error)
        }
    }
}

struct OllamaModelsResponse: Codable {
    let models: [OllamaModel]
}

struct OllamaModel: Codable {
    let name: String
}

struct OllamaGenerateResponse: Codable {
    let response: String
    let done: Bool?
}