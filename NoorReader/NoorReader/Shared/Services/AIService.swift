// AIService.swift
// NoorReader
//
// Coordinates AI features between local and cloud services

import Foundation
import PDFKit

/// Main AI service coordinator
/// Handles routing between local (on-device) and cloud (Claude API) AI providers
@MainActor
@Observable
final class AIService {

    // MARK: - Singleton

    static let shared = AIService()

    // MARK: - Services

    private let cloudService = CloudAIService()
    private let embeddingService = EmbeddingService()

    // MARK: - Observable State

    var isProcessing = false
    var currentTask: String?
    var progress: Double = 0
    var lastError: AIError?

    // MARK: - Configuration

    var preferredProvider: AIProvider = .cloud  // Default to cloud since MLX requires additional setup
    var isCloudConfigured: Bool {
        get async { await cloudService.isConfigured() }
    }

    // Feature toggles (loaded from settings)
    var summarizationEnabled = true
    var explainEnabled = true
    var flashcardsEnabled = true
    var semanticSearchEnabled = true

    // MARK: - Initialization

    private init() {}

    // MARK: - Configuration Methods

    func configureCloudAPI(key: String) async {
        await cloudService.configure(apiKey: key)
    }

    func clearCloudAPI() async {
        await cloudService.clearAPIKey()
    }

    func validateCloudAPIKey() async throws -> Bool {
        try await cloudService.validateAPIKey()
    }

    // MARK: - Feature Availability

    func isFeatureAvailable(_ feature: AIFeature) async -> Bool {
        switch feature {
        case .summarize:
            guard summarizationEnabled else { return false }
        case .explain:
            guard explainEnabled else { return false }
        case .flashcards:
            guard flashcardsEnabled else { return false }
        case .semanticSearch:
            guard semanticSearchEnabled else { return false }
            return await embeddingService.isReady()
        case .chat:
            return await cloudService.isConfigured()
        }

        // For non-semantic features, check provider availability
        if preferredProvider == .cloud {
            return await cloudService.isConfigured()
        } else {
            // Local MLX would be checked here
            // For now, fall back to cloud if available
            return await cloudService.isConfigured()
        }
    }

    // MARK: - Summarization

    func summarize(
        text: String,
        style: SummarizationStyle = .concise
    ) async throws -> AIResponse {
        guard summarizationEnabled else {
            throw AIError.featureDisabled
        }

        isProcessing = true
        currentTask = "Summarizing..."
        lastError = nil
        let startTime = Date()

        defer {
            isProcessing = false
            currentTask = nil
        }

        do {
            let result = try await cloudService.summarize(text: text, style: style)
            let processingTime = Date().timeIntervalSince(startTime)

            return AIResponse(
                content: result,
                provider: .cloud,
                feature: .summarize,
                processingTime: processingTime
            )
        } catch {
            lastError = error as? AIError ?? AIError.inferenceFailed(error.localizedDescription)
            throw lastError!
        }
    }

    // MARK: - Explanation

    func explain(text: String, context: String? = nil) async throws -> AIResponse {
        guard explainEnabled else {
            throw AIError.featureDisabled
        }

        isProcessing = true
        currentTask = "Explaining..."
        lastError = nil
        let startTime = Date()

        defer {
            isProcessing = false
            currentTask = nil
        }

        do {
            let result = try await cloudService.explain(text: text, context: context)
            let processingTime = Date().timeIntervalSince(startTime)

            return AIResponse(
                content: result,
                provider: .cloud,
                feature: .explain,
                processingTime: processingTime
            )
        } catch {
            lastError = error as? AIError ?? AIError.inferenceFailed(error.localizedDescription)
            throw lastError!
        }
    }

    // MARK: - Flashcard Generation

    func generateFlashcards(
        from highlights: [Highlight],
        count: Int = 5
    ) async throws -> [FlashcardSuggestion] {
        guard flashcardsEnabled else {
            throw AIError.featureDisabled
        }

        guard !highlights.isEmpty else {
            return []
        }

        isProcessing = true
        currentTask = "Generating flashcards..."
        lastError = nil

        defer {
            isProcessing = false
            currentTask = nil
        }

        // Format highlights for the prompt
        let highlightText = highlights.enumerated().map { index, highlight in
            "[\(index + 1)] \(highlight.text)"
        }.joined(separator: "\n\n")

        do {
            return try await cloudService.generateFlashcards(from: highlightText, count: count)
        } catch {
            lastError = error as? AIError ?? AIError.inferenceFailed(error.localizedDescription)
            throw lastError!
        }
    }

    func generateFlashcards(
        fromText text: String,
        count: Int = 5
    ) async throws -> [FlashcardSuggestion] {
        guard flashcardsEnabled else {
            throw AIError.featureDisabled
        }

        isProcessing = true
        currentTask = "Generating flashcards..."
        lastError = nil

        defer {
            isProcessing = false
            currentTask = nil
        }

        do {
            return try await cloudService.generateFlashcards(from: text, count: count)
        } catch {
            lastError = error as? AIError ?? AIError.inferenceFailed(error.localizedDescription)
            throw lastError!
        }
    }

    // MARK: - Semantic Search

    func buildSemanticIndex(for book: Book, document: PDFDocument) async throws {
        guard semanticSearchEnabled else {
            throw AIError.featureDisabled
        }

        isProcessing = true
        currentTask = "Building search index..."
        lastError = nil

        defer {
            isProcessing = false
            currentTask = nil
        }

        do {
            try await embeddingService.buildIndex(for: book, document: document)
        } catch {
            lastError = error as? AIError ?? AIError.embeddingFailed
            throw lastError!
        }
    }

    func semanticSearch(
        query: String,
        in book: Book,
        limit: Int = 10
    ) async throws -> [SemanticSearchResult] {
        guard semanticSearchEnabled else {
            throw AIError.featureDisabled
        }

        isProcessing = true
        currentTask = "Searching..."
        lastError = nil

        defer {
            isProcessing = false
            currentTask = nil
        }

        do {
            return try await embeddingService.search(query: query, in: book.id, limit: limit)
        } catch {
            lastError = error as? AIError ?? AIError.indexNotBuilt
            throw lastError!
        }
    }

    func hasSemanticIndex(for book: Book) async -> Bool {
        await embeddingService.hasIndex(for: book.id)
    }

    func removeSemanticIndex(for book: Book) async {
        await embeddingService.removeIndex(for: book.id)
    }

    // MARK: - Chat

    func chat(
        messages: [ChatMessage],
        bookContext: String? = nil
    ) async throws -> AIResponse {
        guard await cloudService.isConfigured() else {
            throw AIError.notConfigured
        }

        isProcessing = true
        currentTask = "Thinking..."
        lastError = nil
        let startTime = Date()

        defer {
            isProcessing = false
            currentTask = nil
        }

        do {
            let result = try await cloudService.chat(messages: messages, bookContext: bookContext)
            let processingTime = Date().timeIntervalSince(startTime)

            return AIResponse(
                content: result,
                provider: .cloud,
                feature: .chat,
                processingTime: processingTime
            )
        } catch {
            lastError = error as? AIError ?? AIError.inferenceFailed(error.localizedDescription)
            throw lastError!
        }
    }

    // MARK: - Settings Sync

    func syncSettings(from viewModel: SettingsViewModel) {
        summarizationEnabled = viewModel.aiSummarizationEnabled
        explainEnabled = viewModel.aiExplainEnabled
        flashcardsEnabled = viewModel.aiFlashcardsEnabled
        semanticSearchEnabled = viewModel.aiSemanticSearchEnabled

        if let providerString = UserDefaults.standard.string(forKey: "aiProvider") {
            preferredProvider = providerString == "cloud" ? .cloud : .local
        }

        // Configure cloud API if key is available
        Task {
            let apiKey = viewModel.claudeAPIKey
            if !apiKey.isEmpty {
                await configureCloudAPI(key: apiKey)
            }
        }
    }
}

// MARK: - Convenience Extensions

extension AIService {
    /// Quick check if any AI feature is available
    func checkAnyFeatureAvailable() async -> Bool {
        let summarize = await isFeatureAvailable(.summarize)
        let explain = await isFeatureAvailable(.explain)
        let flashcards = await isFeatureAvailable(.flashcards)
        let semanticSearch = await isFeatureAvailable(.semanticSearch)
        return summarize || explain || flashcards || semanticSearch
    }

    /// Get current provider status description
    func getProviderStatus() async -> String {
        if preferredProvider == .cloud {
            if await cloudService.isConfigured() {
                return "Claude API (Connected)"
            } else {
                return "Claude API (Not configured)"
            }
        } else {
            return "Local AI (MLX)"
        }
    }
}
