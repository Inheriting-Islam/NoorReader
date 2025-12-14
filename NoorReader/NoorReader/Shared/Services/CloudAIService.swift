// CloudAIService.swift
// NoorReader
//
// Claude API client for optional cloud AI features

import Foundation

/// Client for Claude API (optional cloud AI features)
actor CloudAIService {

    // MARK: - Configuration

    private var apiKey: String?
    private let baseURL = "https://api.anthropic.com/v1"
    private let modelID = "claude-3-haiku-20240307"  // Fast, cost-effective, widely available
    private let anthropicVersion = "2023-06-01"

    // Rate limiting
    private var lastRequestTime: Date?
    private let minimumRequestInterval: TimeInterval = 0.5  // 500ms between requests

    // MARK: - Public Configuration

    func configure(apiKey: String) {
        // Thoroughly clean the key - remove all whitespace, newlines, and control characters
        let trimmedKey = apiKey
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .filter { !$0.isWhitespace && !$0.isNewline }
        self.apiKey = trimmedKey
        print("CloudAIService: Configured")
        print("  - Original length: \(apiKey.count)")
        print("  - Cleaned length: \(trimmedKey.count)")
        print("  - Prefix: \(String(trimmedKey.prefix(30)))...")
        print("  - Suffix: ...\(String(trimmedKey.suffix(10)))")
    }

    func clearAPIKey() {
        self.apiKey = nil
    }

    func isConfigured() -> Bool {
        guard let key = apiKey else { return false }
        // API keys can start with sk-ant- or sk-ant-api03- etc.
        return !key.isEmpty && key.hasPrefix("sk-")
    }

    // MARK: - API Methods

    /// Summarize text using Claude API
    func summarize(text: String, style: SummarizationStyle) async throws -> String {
        let systemPrompt = """
        You are a helpful study assistant. Summarize the following text \(style.instruction).
        Focus on key points and main arguments. Be clear and concise.
        Do not include any preamble like "Here's a summary" - just provide the summary directly.
        """

        return try await sendMessage(
            userMessage: text,
            systemPrompt: systemPrompt,
            maxTokens: style.maxTokens
        )
    }

    /// Explain selected text in simpler terms
    func explain(text: String, context: String?) async throws -> String {
        var systemPrompt = """
        You are a patient teacher. Explain the following text in simple, clear language.
        Break down complex concepts into understandable parts.
        Use analogies where helpful.
        Do not include any preamble - just provide the explanation directly.
        """

        if let ctx = context {
            systemPrompt += "\n\nContext from the document: \(ctx)"
        }

        return try await sendMessage(
            userMessage: "Please explain this:\n\n\(text)",
            systemPrompt: systemPrompt,
            maxTokens: 512
        )
    }

    /// Generate flashcards from highlighted text
    func generateFlashcardsRaw(from highlightText: String, count: Int) async throws -> String {
        let systemPrompt = """
        You are a study assistant creating flashcards for spaced repetition learning.
        Generate exactly \(count) flashcards from the highlighted text.
        Each flashcard should have a clear question and concise answer.
        Focus on key concepts, definitions, and important facts.

        IMPORTANT: Return ONLY a valid JSON array, no markdown, no explanation:
        [{"question": "...", "answer": "..."}, {"question": "...", "answer": "..."}]
        """

        return try await sendMessage(
            userMessage: highlightText,
            systemPrompt: systemPrompt,
            maxTokens: 1024
        )
    }

    /// Parse flashcard JSON response into FlashcardSuggestion array
    func generateFlashcards(from highlightText: String, count: Int) async throws -> [FlashcardSuggestion] {
        let response = try await generateFlashcardsRaw(from: highlightText, count: count)
        return try parseFlashcardResponse(response)
    }

    /// Chat with context about the current book
    func chat(
        messages: [ChatMessage],
        bookContext: String?
    ) async throws -> String {
        guard isConfigured() else {
            throw AIError.notConfigured
        }

        var systemPrompt = """
        You are a knowledgeable study assistant helping the user understand their reading material.
        Be helpful, accurate, and concise. If you're unsure about something, say so.
        Use the context provided to give relevant answers.
        """

        if let context = bookContext {
            systemPrompt += "\n\nThe user is reading a document. Here's some context:\n\(context)"
        }

        return try await sendChatMessages(
            messages: messages,
            systemPrompt: systemPrompt
        )
    }

    /// Validate API key by making a minimal request
    /// Returns true if key is valid, throws specific error for credit/other issues
    func validateAPIKey() async throws -> Bool {
        guard isConfigured() else {
            return false
        }

        do {
            // Make a minimal request to validate the key
            _ = try await sendMessage(
                userMessage: "Hi",
                systemPrompt: "Reply with just 'ok'",
                maxTokens: 10
            )
            return true
        } catch AIError.invalidAPIKey {
            return false
        } catch AIError.insufficientCredits {
            // Key is valid but account has no credits - still throw so UI can show appropriate message
            throw AIError.insufficientCredits
        } catch {
            throw error
        }
    }

    // MARK: - Private API Communication

    private func sendMessage(
        userMessage: String,
        systemPrompt: String,
        maxTokens: Int
    ) async throws -> String {
        guard let apiKey else {
            throw AIError.notConfigured
        }

        // Rate limiting
        try await enforceRateLimit()

        let url = URL(string: "\(baseURL)/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 60

        let body: [String: Any] = [
            "model": modelID,
            "max_tokens": maxTokens,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userMessage]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Debug: log request details
        print("=== Claude API Request Debug ===")
        print("URL: \(url)")
        print("Method: \(request.httpMethod ?? "nil")")
        print("API Key length: \(apiKey.count)")
        print("API Key prefix: \(String(apiKey.prefix(30)))...")
        print("API Key suffix: ...\(String(apiKey.suffix(10)))")
        print("Content-Type: \(request.value(forHTTPHeaderField: "Content-Type") ?? "nil")")
        print("x-api-key header set: \(request.value(forHTTPHeaderField: "x-api-key") != nil)")
        print("anthropic-version: \(request.value(forHTTPHeaderField: "anthropic-version") ?? "nil")")
        print("Body size: \(request.httpBody?.count ?? 0) bytes")
        print("================================")

        let (data, response) = try await URLSession.shared.data(for: request)

        lastRequestTime = Date()

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        // Parse error response for more specific errors
        let errorBody = String(data: data, encoding: .utf8) ?? ""
        print("=== Claude API Response Debug ===")
        print("Status: \(httpResponse.statusCode)")
        print("Headers: \(httpResponse.allHeaderFields)")
        if httpResponse.statusCode != 200 {
            print("Error body: \(errorBody)")
        }
        print("=================================")

        switch httpResponse.statusCode {
        case 200:
            return try parseResponse(data)
        case 400:
            // Bad request - check for specific error types
            print("Claude API 400 Error: \(errorBody)")
            if errorBody.contains("credit balance is too low") {
                throw AIError.insufficientCredits
            }
            throw AIError.apiError(httpResponse.statusCode)
        case 401:
            print("Claude API 401 Error - Invalid API Key. Response: \(errorBody)")
            throw AIError.invalidAPIKey
        case 403:
            // Forbidden - could be permissions issue
            throw AIError.invalidAPIKey
        case 429:
            throw AIError.rateLimited
        case 500...599:
            throw AIError.apiError(httpResponse.statusCode)
        default:
            if !errorBody.isEmpty {
                print("Claude API Error \(httpResponse.statusCode): \(errorBody)")
            }
            throw AIError.apiError(httpResponse.statusCode)
        }
    }

    private func sendChatMessages(
        messages: [ChatMessage],
        systemPrompt: String
    ) async throws -> String {
        guard let apiKey else {
            throw AIError.notConfigured
        }

        // Rate limiting
        try await enforceRateLimit()

        let url = URL(string: "\(baseURL)/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 60

        // Format messages for Claude API
        let formattedMessages = messages.compactMap { message -> [String: String]? in
            guard message.role != .system else { return nil }
            return ["role": message.role.rawValue, "content": message.content]
        }

        let body: [String: Any] = [
            "model": modelID,
            "max_tokens": 1024,
            "system": systemPrompt,
            "messages": formattedMessages
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        lastRequestTime = Date()

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 {
                    throw AIError.invalidAPIKey
                } else if httpResponse.statusCode == 429 {
                    throw AIError.rateLimited
                }
                throw AIError.apiError(httpResponse.statusCode)
            }
            throw AIError.invalidResponse
        }

        return try parseResponse(data)
    }

    // MARK: - Response Parsing

    private func parseResponse(_ data: Data) throws -> String {
        struct ContentBlock: Codable {
            let type: String
            let text: String?
        }

        struct Response: Codable {
            let content: [ContentBlock]
        }

        let response = try JSONDecoder().decode(Response.self, from: data)

        // Find text content
        guard let textContent = response.content.first(where: { $0.type == "text" }),
              let text = textContent.text else {
            throw AIError.parseError("No text content in response")
        }

        return text
    }

    private func parseFlashcardResponse(_ response: String) throws -> [FlashcardSuggestion] {
        // Try to extract JSON from response (in case there's extra text)
        var jsonString = response

        // Find JSON array bounds
        if let jsonStart = response.firstIndex(of: "["),
           let jsonEnd = response.lastIndex(of: "]") {
            jsonString = String(response[jsonStart...jsonEnd])
        }

        let data = Data(jsonString.utf8)

        struct FlashcardJSON: Codable {
            let question: String
            let answer: String
        }

        do {
            let decoded = try JSONDecoder().decode([FlashcardJSON].self, from: data)
            return decoded.map { FlashcardSuggestion(question: $0.question, answer: $0.answer) }
        } catch {
            throw AIError.parseError("Could not parse flashcard JSON: \(error.localizedDescription)")
        }
    }

    // MARK: - Rate Limiting

    private func enforceRateLimit() async throws {
        if let lastTime = lastRequestTime {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed < minimumRequestInterval {
                let waitTime = minimumRequestInterval - elapsed
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
        }
    }
}
