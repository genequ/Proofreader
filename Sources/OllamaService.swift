import Foundation

actor OllamaService {
    private var baseURL: String
    private let session: URLSession
    
    init(baseURL: String = "http://127.0.0.1:11434") {
        self.baseURL = baseURL
        self.session = URLSession.shared
    }
    
    func updateBaseURL(_ url: String) {
        self.baseURL = url
    }
    
    func listModels() async throws -> [String] {
        guard let url = URL(string: "\(baseURL)/api/tags") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let modelsResponse = try JSONDecoder().decode(OllamaModelsResponse.self, from: data)
        return modelsResponse.models.map { $0.name }
    }
    
    func generate(model: String, prompt: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/generate") else {
            throw URLError(.badURL)
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
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let generateResponse = try JSONDecoder().decode(OllamaGenerateResponse.self, from: data)
        return generateResponse.response
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