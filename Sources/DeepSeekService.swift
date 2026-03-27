import Foundation

@preconcurrency actor DeepSeekService: @preconcurrency LLMProvider {
    private var apiKey: String
    private let baseURL = "https://api.deepseek.com/v1"
    private let session: URLSession
    private let timeout: TimeInterval = 120.0

    init(apiKey: String) {
        self.apiKey = apiKey
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: config)
    }

    func updateAPIKey(_ key: String) {
        self.apiKey = key
    }

    func updateBaseURL(_ url: String) {
        // DeepSeek uses fixed base URL, this is a no-op
    }

    func stop(model: String) async {
        // API-based provider, no-op
    }

    func preload(model: String) async {
        // API-based provider, no-op needed
    }

    func checkInstallation() async -> ProviderStatus {
        do {
            let models = try await listModels()
            return .connected(models: models)
        } catch let error as LLMError {
            return .error(error)
        } catch {
            return .error(.connectionFailed(underlying: error))
        }
    }

    func listModels() async throws -> [String] {
        guard let url = URL(string: "\(baseURL)/models") else {
            throw LLMError.invalidURL(baseURL)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw LLMError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                break
            case 401:
                throw LLMError.unauthorized("DeepSeek")
            case 429:
                throw LLMError.rateLimitExceeded
            default:
                throw LLMError.connectionFailed(underlying: URLError(.badServerResponse))
            }

            let modelsResponse = try JSONDecoder().decode(DeepSeekModelsResponse.self, from: data)
            let models = modelsResponse.data.map { $0.id }

            if models.isEmpty {
                throw LLMError.noModelsAvailable
            }

            return models
        } catch let error as LLMError {
            throw error
        } catch let urlError as URLError {
            throw mapURLError(urlError)
        } catch {
            throw LLMError.connectionFailed(underlying: error)
        }
    }

    func generateStream(model: String, prompt: String) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let url = URL(string: "\(baseURL)/chat/completions") else {
                        throw URLError(.badURL)
                    }

                    let requestBody = DeepSeekChatRequest(
                        model: model,
                        messages: [DeepSeekMessage(role: "user", content: prompt)],
                        stream: true
                    )

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try JSONEncoder().encode(requestBody)

                    let (result, response) = try await session.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                        if let httpResponse = response as? HTTPURLResponse {
                            if httpResponse.statusCode == 401 {
                                throw LLMError.unauthorized("DeepSeek")
                            }
                            if httpResponse.statusCode == 429 {
                                throw LLMError.rateLimitExceeded
                            }
                        }
                        throw URLError(.badServerResponse)
                    }

                    for try await line in result.lines {
                        guard line.hasPrefix("data: ") else { continue }

                        let jsonStart = line.index(line.startIndex, offsetBy: 6)
                        let jsonString = String(line[jsonStart...])

                        if jsonString == "[DONE]" {
                            continuation.finish()
                            return
                        }

                        guard let data = jsonString.data(using: .utf8) else { continue }
                        let chunk = try JSONDecoder().decode(DeepSeekStreamChunk.self, from: data)

                        if let content = chunk.choices.first?.delta.content {
                            continuation.yield(content)
                        }

                        if chunk.choices.first?.finishReason == "stop" {
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

    private func mapURLError(_ error: URLError) -> LLMError {
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

// MARK: - API Models

struct DeepSeekModelsResponse: Codable {
    let data: [DeepSeekModel]
    let object: String
}

struct DeepSeekModel: Codable {
    let id: String
    let object: String
}

struct DeepSeekChatRequest: Codable {
    let model: String
    let messages: [DeepSeekMessage]
    let stream: Bool?

    init(model: String, messages: [DeepSeekMessage], stream: Bool = false) {
        self.model = model
        self.messages = messages
        self.stream = stream
    }
}

struct DeepSeekMessage: Codable {
    let role: String
    let content: String
}

struct DeepSeekStreamChunk: Codable {
    let id: String
    let choices: [DeepSeekStreamChoice]
}

struct DeepSeekStreamChoice: Codable {
    let delta: DeepSeekStreamDelta
    let finishReason: String?

    enum CodingKeys: String, CodingKey {
        case delta
        case finishReason = "finish_reason"
    }
}

struct DeepSeekStreamDelta: Codable {
    let content: String?
}
