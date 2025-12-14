// AIConversationService.swift
// NoorReader
//
// Enhanced AI interactions including Socratic mode, quizzes, and concept connections

import Foundation
import SwiftData

/// Service for enhanced AI interactions beyond basic summarization
@MainActor
@Observable
final class AIConversationService {

    // MARK: - Properties

    private var modelContext: ModelContext?
    private var apiKey: String?
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-3-haiku-20240307"

    var isProcessing = false
    var currentConversation: ConversationHistory?
    var error: Error?

    // Rate limiting
    private var lastRequestTime: Date?
    private let minimumRequestInterval: TimeInterval = 0.5

    // MARK: - Singleton

    static let shared = AIConversationService()

    private init() {}

    // MARK: - Configuration

    func configure(modelContext: ModelContext, apiKey: String?) {
        self.modelContext = modelContext
        self.apiKey = apiKey
    }

    var isConfigured: Bool {
        apiKey != nil && !apiKey!.isEmpty
    }

    // MARK: - Conversation Management

    func startConversation(
        bookID: UUID,
        context: String?,
        pageNumber: Int,
        mode: ConversationMode
    ) throws -> ConversationHistory {
        guard let modelContext else {
            throw AIConversationError.notConfigured
        }

        let conversation = ConversationHistory(
            bookID: bookID,
            context: context,
            pageNumber: pageNumber,
            mode: mode
        )

        modelContext.insert(conversation)
        try modelContext.save()

        currentConversation = conversation
        return conversation
    }

    func loadConversation(id: UUID) throws -> ConversationHistory? {
        guard let modelContext else {
            throw AIConversationError.notConfigured
        }

        let descriptor = FetchDescriptor<ConversationHistory>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func loadConversations(for bookID: UUID, limit: Int = 20) throws -> [ConversationHistory] {
        guard let modelContext else {
            throw AIConversationError.notConfigured
        }

        var descriptor = FetchDescriptor<ConversationHistory>(
            predicate: #Predicate { $0.bookID == bookID },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        return try modelContext.fetch(descriptor)
    }

    func deleteConversation(_ conversation: ConversationHistory) throws {
        guard let modelContext else {
            throw AIConversationError.notConfigured
        }

        modelContext.delete(conversation)
        try modelContext.save()

        if currentConversation?.id == conversation.id {
            currentConversation = nil
        }
    }

    // MARK: - Send Message

    func sendMessage(
        _ content: String,
        in conversation: ConversationHistory
    ) async throws -> String {
        guard isConfigured else {
            throw AIConversationError.notConfigured
        }

        // Rate limiting
        await enforceRateLimit()

        isProcessing = true
        defer { isProcessing = false }

        // Add user message
        conversation.addUserMessage(content)

        // Build messages for API
        let apiMessages = buildAPIMessages(for: conversation)

        // Make API request
        let response = try await makeAPIRequest(
            messages: apiMessages,
            systemPrompt: conversation.mode.systemPrompt
        )

        // Add assistant response
        conversation.addAssistantMessage(response)

        // Save
        try modelContext?.save()

        return response
    }

    // MARK: - Mode-Specific Features

    /// Generate quiz questions from text
    func generateQuiz(
        from text: String,
        count: Int = 5,
        bookContext: String? = nil
    ) async throws -> [QuizQuestion] {
        guard isConfigured else {
            throw AIConversationError.notConfigured
        }

        await enforceRateLimit()
        isProcessing = true
        defer { isProcessing = false }

        let prompt = """
        Generate \(count) quiz questions based on this text:

        \(text)

        \(bookContext.map { "Book context: \($0)" } ?? "")

        Return the questions in this exact JSON format:
        [
            {
                "question": "Question text here",
                "options": ["A) Option 1", "B) Option 2", "C) Option 3", "D) Option 4"],
                "correctAnswer": "The correct answer text",
                "explanation": "Brief explanation of why this is correct",
                "difficulty": "easy|medium|hard"
            }
        ]

        Include a mix of difficulties. Make questions that test understanding, not just memorization.
        """

        let response = try await makeAPIRequest(
            messages: [["role": "user", "content": prompt]],
            systemPrompt: "You are an educational quiz generator. Return only valid JSON array, no other text."
        )

        return parseQuizResponse(response)
    }

    /// Find concept connections across library
    func findConnections(
        for concept: String,
        relatedTexts: [(bookID: UUID, text: String)]
    ) async throws -> [ConceptConnection] {
        guard isConfigured else {
            throw AIConversationError.notConfigured
        }

        await enforceRateLimit()
        isProcessing = true
        defer { isProcessing = false }

        let textsDescription = relatedTexts.enumerated().map { index, item in
            "Text \(index + 1): \(item.text)"
        }.joined(separator: "\n\n")

        let prompt = """
        Analyze how this concept connects across different texts:

        Main concept: \(concept)

        Related passages:
        \(textsDescription)

        Identify:
        1. Common themes and ideas
        2. Different perspectives on the same concept
        3. How the texts complement each other
        4. Key insights from comparing these sources

        Be concise but insightful.
        """

        let response = try await makeAPIRequest(
            messages: [["role": "user", "content": prompt]],
            systemPrompt: ConversationMode.connect.systemPrompt
        )

        return [ConceptConnection(
            concept: concept,
            relatedConcepts: extractConcepts(from: response),
            explanation: response,
            sourceBookIDs: relatedTexts.map(\.bookID)
        )]
    }

    /// Explain Arabic terms
    func explainArabic(
        text: String,
        context: String? = nil
    ) async throws -> String {
        guard isConfigured else {
            throw AIConversationError.notConfigured
        }

        await enforceRateLimit()
        isProcessing = true
        defer { isProcessing = false }

        let prompt = """
        Explain the Arabic in this text:

        \(text)

        \(context.map { "Context: \($0)" } ?? "")

        Please provide:
        1. Transliteration of Arabic terms
        2. Root word analysis where relevant
        3. Grammatical notes if helpful
        4. How the meaning might vary in different contexts
        5. Common usage in Islamic texts
        """

        return try await makeAPIRequest(
            messages: [["role": "user", "content": prompt]],
            systemPrompt: ConversationMode.arabicHelp.systemPrompt
        )
    }

    /// Socratic dialogue - ask probing questions
    func askSocraticQuestion(
        about text: String,
        previousExchanges: [ConversationMessage]
    ) async throws -> String {
        guard isConfigured else {
            throw AIConversationError.notConfigured
        }

        await enforceRateLimit()
        isProcessing = true
        defer { isProcessing = false }

        var messages: [[String: String]] = []

        // Add context
        messages.append([
            "role": "user",
            "content": "I'm studying this text: \(text)"
        ])

        // Add previous exchanges
        for exchange in previousExchanges {
            messages.append([
                "role": exchange.role == .user ? "user" : "assistant",
                "content": exchange.content
            ])
        }

        // If no exchanges yet, ask initial question
        if previousExchanges.isEmpty {
            messages.append([
                "role": "user",
                "content": "Help me understand this through Socratic questioning."
            ])
        }

        return try await makeAPIRequest(
            messages: messages,
            systemPrompt: ConversationMode.socratic.systemPrompt
        )
    }

    // MARK: - Private Helpers

    private func buildAPIMessages(for conversation: ConversationHistory) -> [[String: String]] {
        var messages: [[String: String]] = []

        // Add context if available
        if let context = conversation.context, !context.isEmpty {
            messages.append([
                "role": "user",
                "content": "I'm studying this text: \(context)"
            ])
            messages.append([
                "role": "assistant",
                "content": "I see. What would you like to know about this text?"
            ])
        }

        // Add conversation messages
        for message in conversation.messages {
            messages.append([
                "role": message.role == .user ? "user" : "assistant",
                "content": message.content
            ])
        }

        return messages
    }

    private func makeAPIRequest(
        messages: [[String: String]],
        systemPrompt: String,
        maxTokens: Int = 1024
    ) async throws -> String {
        guard let apiKey else {
            throw AIConversationError.notConfigured
        }

        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": systemPrompt,
            "messages": messages
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIConversationError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw AIConversationError.invalidAPIKey
        }

        if httpResponse.statusCode == 429 {
            throw AIConversationError.rateLimited
        }

        if httpResponse.statusCode != 200 {
            throw AIConversationError.apiError(httpResponse.statusCode)
        }

        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw AIConversationError.parseError
        }

        lastRequestTime = Date()
        return text
    }

    private func enforceRateLimit() async {
        if let lastTime = lastRequestTime {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed < minimumRequestInterval {
                try? await Task.sleep(nanoseconds: UInt64((minimumRequestInterval - elapsed) * 1_000_000_000))
            }
        }
    }

    private func parseQuizResponse(_ response: String) -> [QuizQuestion] {
        // Try to extract JSON from response
        var jsonString = response

        // Find JSON array in response
        if let startIndex = response.firstIndex(of: "["),
           let endIndex = response.lastIndex(of: "]") {
            jsonString = String(response[startIndex...endIndex])
        }

        guard let data = jsonString.data(using: .utf8),
              let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }

        return jsonArray.compactMap { dict -> QuizQuestion? in
            guard let question = dict["question"] as? String,
                  let correctAnswer = dict["correctAnswer"] as? String,
                  let explanation = dict["explanation"] as? String else {
                return nil
            }

            let options = dict["options"] as? [String]
            let difficultyStr = dict["difficulty"] as? String ?? "medium"
            let difficulty = QuizDifficulty(rawValue: difficultyStr) ?? .medium

            return QuizQuestion(
                question: question,
                options: options,
                correctAnswer: correctAnswer,
                explanation: explanation,
                difficulty: difficulty
            )
        }
    }

    private func extractConcepts(from text: String) -> [String] {
        // Simple extraction - could be enhanced
        let patterns = [
            "key concept",
            "main idea",
            "theme",
            "principle"
        ]

        // For now, return empty - full implementation would parse the response
        return []
    }
}

// MARK: - Errors

enum AIConversationError: LocalizedError {
    case notConfigured
    case invalidResponse
    case invalidAPIKey
    case rateLimited
    case apiError(Int)
    case parseError
    case conversationNotFound

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "AI service not configured. Please add your API key in Settings."
        case .invalidResponse:
            return "Invalid response from AI service."
        case .invalidAPIKey:
            return "Invalid API key. Please check your settings."
        case .rateLimited:
            return "Too many requests. Please wait a moment."
        case .apiError(let code):
            return "API error (code \(code)). Please try again."
        case .parseError:
            return "Failed to parse AI response."
        case .conversationNotFound:
            return "Conversation not found."
        }
    }
}
