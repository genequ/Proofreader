import Foundation

@preconcurrency actor LMStudioService: @preconcurrency LLMProvider {
    private var baseURL: String
    private let session: URLSession
    private let timeout: TimeInterval = 120.0

    init(baseURL: String = "http://127.0.0.1:1234/v1") {
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

    func checkInstallation() async -> ProviderStatus {
        // LM Studio is always "installed" since it's an app
        // Check if service is running via health check
        do {
            let isRunning = try await healthCheck()
            if isRunning {
                let models = try await listModels()
                return .connected(models: models)
            } else {
                return .installed(running: false)
            }
        } catch let error as LLMError {
            return .error(error)
        } catch {
            return .installed(running: false)
        }
    }

    func healthCheck() async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/models") else {
            throw LLMError.invalidURL(baseURL)
        }

        do {
            let (_, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw LLMError.invalidResponse
            }

            return (200...299).contains(httpResponse.statusCode)
        } catch let urlError as URLError {
            throw mapURLError(urlError)
        } catch {
            throw LLMError.connectionFailed(underlying: error)
        }
    }

    // MARK: - API Methods

    func listModels() async throws -> [String] {
        guard let url = URL(string: "\(baseURL)/models") else {
            throw LLMError.invalidURL(baseURL)
        }

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw LLMError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw LLMError.connectionFailed(underlying: URLError(.badServerResponse))
            }

            let modelsResponse = try JSONDecoder().decode(LMStudioModelsResponse.self, from: data)
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

    func generate(model: String, prompt: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw LLMError.invalidURL(baseURL)
        }

        let requestBody = LMStudioChatRequest(
            model: model,
            messages: [LMStudioMessage(role: "user", content: prompt)]
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw LLMError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 404 {
                    throw LLMError.modelNotFound(model)
                }
                throw LLMError.connectionFailed(underlying: URLError(.badServerResponse))
            }

            let responseObj = try JSONDecoder().decode(LMStudioChatResponse.self, from: data)
            return responseObj.choices.first?.message.content ?? ""
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

                    let requestBody = LMStudioChatRequest(
                        model: model,
                        messages: [LMStudioMessage(role: "user", content: prompt)],
                        stream: true
                    )

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try JSONEncoder().encode(requestBody)

                    let (result, response) = try await session.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                        throw URLError(.badServerResponse)
                    }

                    for try await line in result.lines {
                        // SSE format: "data: {...}"
                        guard line.hasPrefix("data: ") else { continue }

                        let jsonStart = line.index(line.startIndex, offsetBy: 6)
                        let jsonString = String(line[jsonStart...])

                        // Skip "[DONE]" marker
                        if jsonString == "[DONE]" {
                            continuation.finish()
                            return
                        }

                        guard let data = jsonString.data(using: .utf8) else { continue }
                        let chunk = try JSONDecoder().decode(LMStudioStreamChunk.self, from: data)

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

    func preload(model: String) async {
        guard let url = URL(string: "\(baseURL)/chat/completions") else { return }

        let requestBody = LMStudioChatRequest(
            model: model,
            messages: [LMStudioMessage(role: "user", content: "")]
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            _ = try await session.data(for: request)
        } catch {
            print("[LMStudioService] Preload failed: \(error)")
        }
    }

    func stop(model: String) async {
        // LM Studio doesn't support stopping models via API
        // Models are automatically unloaded after a timeout
        // This is a no-op
    }

    // MARK: - Error Mapping

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

struct LMStudioModelsResponse: Codable {
    let data: [LMStudioModel]
    let object: String
}

struct LMStudioModel: Codable {
    let id: String
    let object: String
}

struct LMStudioChatRequest: Codable {
    let model: String
    let messages: [LMStudioMessage]
    let stream: Bool?

    init(model: String, messages: [LMStudioMessage], stream: Bool = false) {
        self.model = model
        self.messages = messages
        self.stream = stream
    }
}

struct LMStudioMessage: Codable {
    let role: String
    let content: String
}

struct LMStudioChatResponse: Codable {
    let id: String
    let choices: [LMStudioChoice]
}

struct LMStudioChoice: Codable {
    let message: LMStudioMessage
    let finishReason: String?

    enum CodingKeys: String, CodingKey {
        case message
        case finishReason = "finish_reason"
    }
}

struct LMStudioStreamChunk: Codable {
    let id: String
    let choices: [LMStudioStreamChoice]
}

struct LMStudioStreamChoice: Codable {
    let delta: LMStudioStreamDelta
    let finishReason: String?

    enum CodingKeys: String, CodingKey {
        case delta
        case finishReason = "finish_reason"
    }
}

struct LMStudioStreamDelta: Codable {
    let content: String?
}
