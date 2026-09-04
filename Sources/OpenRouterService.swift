import Foundation

@preconcurrency actor OpenRouterService: @preconcurrency LLMProvider {
    private var apiKey: String
    private let baseURL = "https://openrouter.ai/api/v1"
    private let session: URLSession
    /// 15s. Two layers use this value:
    /// 1. URLSession timeouts (connection + headers — reliable pre-response).
    /// 2. A progress watchdog during streaming: URLSession's idle timeout
    ///    cannot protect a stream because OpenRouter sends SSE comment
    ///    keepalives (": OPENROUTER PROCESSING") while the upstream model
    ///    stalls, and every keepalive byte resets the idle timer — so a hung
    ///    stream (grok-4.5/4.6) would wait forever. The watchdog instead
    ///    requires a parsed `data:` line every 15s; comments don't count.
    private let timeout: TimeInterval = 15.0
    /// Per-model reasoning capabilities, populated from `/models` so we know
    /// whether a model accepts `effort: "none"`. Mandatory-reasoning models
    /// (e.g. `x-ai/grok-4.5`) reject it with HTTP 400.
    private var supportedEffortsByModel: [String: Set<String>] = [:]

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
        // OpenRouter uses a fixed base URL, this is a no-op
    }

    func stop(model: String) async {
        // API-based provider, no-op
    }

    func preload(model: String) async {
        // API-based provider, no-op needed
    }

    func checkInstallation() async -> ProviderStatus {
        guard apiKey.isEmpty else {
            return await checkInstallationViaModels()
        }
        // No key yet — surface an auth error so the UI can prompt for setup,
        // rather than hammering the network with a request we know will 401.
        return .error(.unauthorized("OpenRouter"))
    }

    private func checkInstallationViaModels() async -> ProviderStatus {
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
        guard !apiKey.isEmpty else {
            throw LLMError.unauthorized("OpenRouter")
        }
        guard let url = URL(string: "\(baseURL)/models") else {
            throw LLMError.invalidURL(baseURL)
        }

        var request = URLRequest(url: url)
        applyAuthHeaders(to: &request)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw LLMError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                break
            case 401:
                throw LLMError.unauthorized("OpenRouter")
            case 429:
                throw LLMError.rateLimitExceeded
            default:
                throw makeAPIError(status: httpResponse.statusCode, data: data)
            }

            let modelsResponse = try JSONDecoder().decode(OpenRouterModelsResponse.self, from: data)
            // OpenRouter model IDs use a `{vendor}/{model}` slug format
            // (e.g. "x-ai/grok-4", "openai/gpt-4o-mini"). Keep only the
            // x-ai entries so the picker only surfaces Grok models.
            let xaiModels = modelsResponse.data.filter { $0.id.hasPrefix("x-ai/") }
            // Cache each model's supported reasoning efforts so generateStream
            // knows whether it may disable reasoning.
            for model in xaiModels {
                supportedEffortsByModel[model.id] = Set(model.reasoning?.supportedEfforts ?? [])
            }
            let models = xaiModels
                .map { $0.id }
                .sorted()

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
                    guard !apiKey.isEmpty else {
                        throw LLMError.unauthorized("OpenRouter")
                    }
                    guard let url = URL(string: "\(baseURL)/chat/completions") else {
                        throw URLError(.badURL)
                    }

                    // Reasoning stays off (or lowest) to keep proofreading fast
                    // and cheap. Candidates in order: cached preference (`none`,
                    // or `low` for mandatory-reasoning models), defaulting to
                    // `none` when unknown, then `low`, then omitted. A 400 that
                    // mentions reasoning/effort falls through to the next
                    // candidate instead of failing outright.
                    let preferred = preferredReasoningEffort(for: model) ?? "none"
                    var candidates: [String?] = [preferred]
                    if preferred != "low" { candidates.append("low") }
                    candidates.append(nil)

                    var lastError: Error?
                    for effort in candidates {
                        do {
                            try await self.performStreamRequest(
                                url: url, model: model, prompt: prompt,
                                reasoningEffort: effort, continuation: continuation
                            )
                            return
                        } catch let error as LLMError {
                            if effort != nil, isReasoningEffortRejection(error) {
                                lastError = error
                                continue
                            }
                            throw error
                        }
                    }
                    if let lastError { throw lastError }
                    throw LLMError.apiError(status: 400, message: "OpenRouter rejected the request (HTTP 400).")
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Single streaming attempt with the given reasoning effort. Finishes
    /// `continuation` on success; throws (without finishing) on error.
    /// Reasoning tokens stream via `delta.reasoning`, not `delta.content`,
    /// so proofread output stays clean either way.
    /// See: https://openrouter.ai/docs/guides/best-practices/reasoning-tokens
    private func performStreamRequest(
        url: URL,
        model: String,
        prompt: String,
        reasoningEffort: String?,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        let requestBody = OpenRouterChatRequest(
            model: model,
            messages: [OpenRouterMessage(role: "user", content: prompt)],
            stream: true,
            reasoning: reasoningEffort.map { ["effort": $0] }
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyAuthHeaders(to: &request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (result, response) = try await session.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        if !(200...299).contains(httpResponse.statusCode) {
            switch httpResponse.statusCode {
            case 401:
                throw LLMError.unauthorized("OpenRouter")
            case 429:
                throw LLMError.rateLimitExceeded
            default:
                // Drain the error body so we can surface OpenRouter's
                // actual message instead of a generic "connection failed".
                var bodyData = Data()
                for try await byte in result {
                    bodyData.append(byte)
                }
                throw makeAPIError(status: httpResponse.statusCode, data: bodyData)
            }
        }

        // Stream consumption runs in a child task racing a watchdog (see
        // `timeout` doc above). `lastProgress` only advances on parsed
        // `data:` lines, so keepalive comments can't keep a dead stream
        // alive. If the watchdog fires it throws `networkTimeout`, which
        // cancels the consumer and propagates to the dialog.
        var lastProgress = Date()
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                for try await line in result.lines {
                    guard line.hasPrefix("data: ") else { continue }
                    lastProgress = Date()

                    let jsonStart = line.index(line.startIndex, offsetBy: 6)
                    let jsonString = String(line[jsonStart...])

                    if jsonString == "[DONE]" {
                        continuation.finish()
                        return
                    }

                    guard let data = jsonString.data(using: .utf8) else { continue }
                    let chunk = try JSONDecoder().decode(OpenRouterStreamChunk.self, from: data)

                    if let content = chunk.choices.first?.delta.content {
                        continuation.yield(content)
                    }

                    if chunk.choices.first?.finishReason == "stop" {
                        continuation.finish()
                        return
                    }
                }
                continuation.finish()
            }
            group.addTask {
                while true {
                    try Task.checkCancellation()
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    if Date().timeIntervalSince(lastProgress) > self.timeout {
                        throw LLMError.networkTimeout
                    }
                }
            }
            defer { group.cancelAll() }
            try await group.next()
        }
    }

    /// True only for HTTP 400s that complain about reasoning/effort — the
    /// signal to retry with the next-lowest effort. Other 400s (bad model,
    /// malformed request) must fail immediately, not burn retries.
    private func isReasoningEffortRejection(_ error: LLMError) -> Bool {
        guard case .apiError(let status, let message) = error, status == 400 else {
            return false
        }
        let lower = message.lowercased()
        return lower.contains("reasoning") || lower.contains("effort") || lower.contains("thinking")
    }

    /// OpenRouter accepts a Bearer token plus optional attribution headers
    /// (`HTTP-Referer`, `X-Title`) used for ranking on their leaderboard.
    private func applyAuthHeaders(to request: inout URLRequest) {
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("Proofreader", forHTTPHeaderField: "X-Title")
        request.setValue("https://github.com/genequ/Proofreader", forHTTPHeaderField: "HTTP-Referer")
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

    /// The lowest reasoning effort the model supports, in priority order:
    /// `none` (disabled) → `low` → nil. On a cache miss the caller defaults
    /// to `none`; a 400 rejection falls through to `low`, then omitted.
    private func preferredReasoningEffort(for model: String) -> String? {
        guard let efforts = supportedEffortsByModel[model] else { return nil }
        if efforts.contains("none") { return "none" }
        if efforts.contains("low") { return "low" }
        return nil
    }

    /// Decodes OpenRouter's `{"error":{"message","code"}}` body into an
    /// `LLMError.apiError` so the UI shows the real upstream reason instead of
    /// a misleading "connection failed".
    private func makeAPIError(status: Int, data: Data) -> LLMError {
        if let body = try? JSONDecoder().decode(OpenRouterErrorBody.self, from: data),
           let message = body.error?.message, !message.isEmpty {
            return .apiError(status: status, message: message)
        }
        return .apiError(status: status, message: "OpenRouter returned HTTP \(status).")
    }
}

// MARK: - API Models

struct OpenRouterModelsResponse: Codable {
    let data: [OpenRouterModel]
    let object: String?
}

struct OpenRouterModel: Codable {
    let id: String
    let object: String?
    let reasoning: OpenRouterModelReasoning?
}

struct OpenRouterModelReasoning: Codable {
    let mandatory: Bool?
    let supportedEfforts: [String]?

    enum CodingKeys: String, CodingKey {
        case mandatory
        case supportedEfforts = "supported_efforts"
    }
}

/// OpenRouter error envelope: `{"error":{"message":..., "code":...}}`.
struct OpenRouterErrorBody: Codable {
    let error: OpenRouterErrorDetail?
}

struct OpenRouterErrorDetail: Codable {
    let message: String?
    let code: Int?
}

struct OpenRouterChatRequest: Codable {
    let model: String
    let messages: [OpenRouterMessage]
    let stream: Bool?
    /// OpenRouter unified reasoning control. `{"effort": "none"}` disables
    /// thinking/reasoning tokens entirely for clean proofreading output.
    /// Modeled as a free-form map so we don't couple this struct to every
    /// reasoning sub-field OpenRouter may add (max_tokens, exclude, …).
    let reasoning: [String: String]?
}

struct OpenRouterMessage: Codable {
    let role: String
    let content: String
}

struct OpenRouterStreamChunk: Codable {
    let id: String?
    let choices: [OpenRouterStreamChoice]
}

struct OpenRouterStreamChoice: Codable {
    let delta: OpenRouterStreamDelta
    let finishReason: String?

    enum CodingKeys: String, CodingKey {
        case delta
        case finishReason = "finish_reason"
    }
}

struct OpenRouterStreamDelta: Codable {
    let content: String?
}
