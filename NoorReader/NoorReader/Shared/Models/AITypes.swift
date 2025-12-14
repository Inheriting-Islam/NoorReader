// AITypes.swift
// NoorReader
//
// AI-related types, enums, and supporting structures

import Foundation

// MARK: - AI Provider

enum AIProvider: String, CaseIterable, Identifiable {
    case cloud = "cloud"
    case local = "local"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cloud: return "Cloud (Claude API)"
        case .local: return "Local (On-Device)"
        }
    }

    var description: String {
        switch self {
        case .cloud: return "AI powered by Claude API. Requires internet and API key."
        case .local: return "AI runs entirely on your Mac. No data leaves your device."
        }
    }

    var icon: String {
        switch self {
        case .cloud: return "cloud"
        case .local: return "desktopcomputer"
        }
    }

    var privacyIcon: String {
        switch self {
        case .cloud: return "network"
        case .local: return "lock.shield.fill"
        }
    }
}

// MARK: - AI Feature

enum AIFeature: String, CaseIterable, Identifiable {
    case summarize
    case explain
    case flashcards
    case semanticSearch
    case chat

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .summarize: return "Summarization"
        case .explain: return "Explain Selection"
        case .flashcards: return "Flashcard Generation"
        case .semanticSearch: return "Semantic Search"
        case .chat: return "Study Chat"
        }
    }

    var icon: String {
        switch self {
        case .summarize: return "text.alignleft"
        case .explain: return "questionmark.circle"
        case .flashcards: return "rectangle.on.rectangle"
        case .semanticSearch: return "sparkle.magnifyingglass"
        case .chat: return "bubble.left.and.bubble.right"
        }
    }

    /// Whether this feature is available locally
    var availableLocally: Bool {
        switch self {
        case .summarize, .explain, .flashcards, .semanticSearch:
            return true
        case .chat:
            return false  // Chat requires cloud
        }
    }
}

// MARK: - Summarization Style

enum SummarizationStyle: String, CaseIterable, Identifiable, Sendable {
    case concise
    case detailed
    case bulletPoints

    var id: String { rawValue }

    nonisolated var displayName: String {
        switch self {
        case .concise: return "Concise"
        case .detailed: return "Detailed"
        case .bulletPoints: return "Bullet Points"
        }
    }

    nonisolated var instruction: String {
        switch self {
        case .concise: return "in 2-3 sentences"
        case .detailed: return "in detail, covering all main points"
        case .bulletPoints: return "as bullet points highlighting key takeaways"
        }
    }

    nonisolated var maxTokens: Int {
        switch self {
        case .concise: return 256
        case .detailed: return 1024
        case .bulletPoints: return 512
        }
    }

    var icon: String {
        switch self {
        case .concise: return "text.badge.minus"
        case .detailed: return "text.badge.plus"
        case .bulletPoints: return "list.bullet"
        }
    }
}

// MARK: - AI Response

struct AIResponse: Identifiable {
    let id = UUID()
    let content: String
    let provider: AIProvider
    let feature: AIFeature
    let timestamp: Date
    let processingTime: TimeInterval?

    init(
        content: String,
        provider: AIProvider,
        feature: AIFeature,
        processingTime: TimeInterval? = nil
    ) {
        self.content = content
        self.provider = provider
        self.feature = feature
        self.timestamp = Date()
        self.processingTime = processingTime
    }
}

// MARK: - Flashcard Suggestion

struct FlashcardSuggestion: Identifiable, Sendable {
    let id: UUID
    let question: String
    let answer: String
    var isSelected: Bool

    init(question: String, answer: String, isSelected: Bool = true) {
        self.id = UUID()
        self.question = question
        self.answer = answer
        self.isSelected = isSelected
    }
}

// MARK: - Semantic Search Result

struct SemanticSearchResult: Identifiable, Sendable {
    let id: UUID
    let text: String
    let pageNumber: Int
    let relevanceScore: Double
    let chunkIndex: Int?

    init(
        text: String,
        pageNumber: Int,
        relevanceScore: Double,
        chunkIndex: Int? = nil
    ) {
        self.id = UUID()
        self.text = text
        self.pageNumber = pageNumber
        self.relevanceScore = relevanceScore
        self.chunkIndex = chunkIndex
    }

    var relevancePercentage: Int {
        Int(relevanceScore * 100)
    }
}

// MARK: - Text Chunk (for semantic indexing)

struct TextChunk: Identifiable, Sendable {
    let id: UUID
    let text: String
    let pageNumber: Int
    let chunkIndex: Int
    let embedding: [Double]

    init(text: String, pageNumber: Int, chunkIndex: Int, embedding: [Double]) {
        self.id = UUID()
        self.text = text
        self.pageNumber = pageNumber
        self.chunkIndex = chunkIndex
        self.embedding = embedding
    }
}

// MARK: - Semantic Index

struct SemanticIndex: Sendable {
    let bookID: UUID
    let chunks: [TextChunk]
    let dateBuilt: Date

    init(bookID: UUID, chunks: [TextChunk], dateBuilt: Date = Date()) {
        self.bookID = bookID
        self.chunks = chunks
        self.dateBuilt = dateBuilt
    }

    var chunkCount: Int { chunks.count }
}

// MARK: - Chat Message

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: ChatRole
    let content: String
    let timestamp: Date

    init(role: ChatRole, content: String) {
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}

enum ChatRole: String {
    case user
    case assistant
    case system
}

// MARK: - AI Errors

enum AIError: LocalizedError {
    case modelNotLoaded
    case modelDownloadFailed(String)
    case inferenceFailed(String)
    case insufficientMemory
    case parseError(String)
    case networkError(String)
    case quotaExceeded
    case invalidAPIKey
    case insufficientCredits
    case notConfigured
    case featureDisabled
    case indexNotBuilt
    case embeddingFailed
    case rateLimited
    case invalidResponse
    case apiError(Int)
    case timeout

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "AI model is not loaded. Please wait for initialization."
        case .modelDownloadFailed(let reason):
            return "Failed to download AI model: \(reason)"
        case .inferenceFailed(let reason):
            return "AI processing failed: \(reason)"
        case .insufficientMemory:
            return "Not enough memory. Try closing other apps or using a smaller model."
        case .parseError(let msg):
            return "Failed to parse AI response: \(msg)"
        case .networkError(let msg):
            return "Network error: \(msg)"
        case .quotaExceeded:
            return "API quota exceeded. Please try again later."
        case .invalidAPIKey:
            return "Invalid API key. Please check your settings."
        case .insufficientCredits:
            return "Insufficient API credits. Please add credits at console.anthropic.com."
        case .notConfigured:
            return "AI service not configured. Please add your API key in Settings."
        case .featureDisabled:
            return "This AI feature is currently disabled in Settings."
        case .indexNotBuilt:
            return "Semantic index not built. Please wait for indexing to complete."
        case .embeddingFailed:
            return "Failed to generate text embeddings."
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .invalidResponse:
            return "Invalid response from AI service."
        case .apiError(let code):
            return "API error (code \(code)). Please try again."
        case .timeout:
            return "Request timed out. Please try again."
        }
    }
}

// MARK: - Model Download Progress

struct ModelDownloadProgress {
    let bytesDownloaded: Int64
    let totalBytes: Int64
    let modelName: String

    var progress: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(bytesDownloaded) / Double(totalBytes)
    }

    var progressPercentage: Int {
        Int(progress * 100)
    }

    var formattedProgress: String {
        let downloaded = ByteCountFormatter.string(fromByteCount: bytesDownloaded, countStyle: .file)
        let total = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
        return "\(downloaded) / \(total)"
    }
}
