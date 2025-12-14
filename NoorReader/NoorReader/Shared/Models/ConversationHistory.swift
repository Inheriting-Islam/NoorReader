// ConversationHistory.swift
// NoorReader
//
// SwiftData model for storing AI conversation history

import SwiftData
import Foundation

/// Stores AI conversation history for a specific context in a book
@Model
final class ConversationHistory {
    // MARK: - Properties

    @Attribute(.unique)
    var id: UUID

    /// ID of the book this conversation is about
    var bookID: UUID

    /// The selected text that started the conversation (if any)
    var context: String?

    /// Page number where conversation started
    var pageNumber: Int

    /// Serialized messages data
    @Attribute(.externalStorage)
    var messagesData: Data?

    /// Conversation mode
    var modeRaw: String

    /// When conversation was created
    var createdAt: Date

    /// When conversation was last updated
    var updatedAt: Date

    /// Optional title for the conversation
    var title: String?

    // MARK: - Computed Properties

    var mode: ConversationMode {
        get { ConversationMode(rawValue: modeRaw) ?? .explain }
        set { modeRaw = newValue.rawValue }
    }

    var messages: [ConversationMessage] {
        get {
            guard let data = messagesData else { return [] }
            return (try? JSONDecoder().decode([ConversationMessage].self, from: data)) ?? []
        }
        set {
            messagesData = try? JSONEncoder().encode(newValue)
            updatedAt = Date()
        }
    }

    var messageCount: Int {
        messages.count
    }

    var lastMessage: ConversationMessage? {
        messages.last
    }

    var preview: String {
        if let context, !context.isEmpty {
            return String(context.prefix(100)) + (context.count > 100 ? "..." : "")
        }
        return messages.first?.content.prefix(100).description ?? "New conversation"
    }

    var displayTitle: String {
        if let title, !title.isEmpty {
            return title
        }
        return "\(mode.displayName) - Page \(pageNumber + 1)"
    }

    // MARK: - Initialization

    init(
        bookID: UUID,
        context: String? = nil,
        pageNumber: Int,
        mode: ConversationMode = .explain
    ) {
        self.id = UUID()
        self.bookID = bookID
        self.context = context
        self.pageNumber = pageNumber
        self.modeRaw = mode.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Methods

    func addMessage(_ message: ConversationMessage) {
        var current = messages
        current.append(message)
        messages = current
    }

    func addUserMessage(_ content: String) {
        addMessage(ConversationMessage(role: .user, content: content))
    }

    func addAssistantMessage(_ content: String) {
        addMessage(ConversationMessage(role: .assistant, content: content))
    }

    func clearMessages() {
        messages = []
    }
}

// MARK: - Conversation Message

struct ConversationMessage: Codable, Identifiable, Sendable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date

    init(role: MessageRole, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}

// MARK: - Message Role

enum MessageRole: String, Codable, Sendable {
    case user
    case assistant
    case system

    var displayName: String {
        switch self {
        case .user: return "You"
        case .assistant: return "Noor AI"
        case .system: return "System"
        }
    }

    var icon: String {
        switch self {
        case .user: return "person.circle.fill"
        case .assistant: return "sparkles"
        case .system: return "gear"
        }
    }
}

// MARK: - Conversation Mode

enum ConversationMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case explain = "explain"
    case quizMe = "quiz_me"
    case connect = "connect"
    case simplify = "simplify"
    case arabicHelp = "arabic_help"
    case socratic = "socratic"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .explain: return "Explain"
        case .quizMe: return "Quiz Me"
        case .connect: return "Connect Ideas"
        case .simplify: return "Simplify"
        case .arabicHelp: return "Arabic Help"
        case .socratic: return "Socratic Mode"
        }
    }

    var description: String {
        switch self {
        case .explain: return "Deep dive into the selected text"
        case .quizMe: return "Generate questions to test understanding"
        case .connect: return "Find related concepts across books"
        case .simplify: return "Explain in simpler terms"
        case .arabicHelp: return "Help with Arabic terms and grammar"
        case .socratic: return "Learn through guided questioning"
        }
    }

    var icon: String {
        switch self {
        case .explain: return "lightbulb"
        case .quizMe: return "questionmark.circle"
        case .connect: return "arrow.triangle.branch"
        case .simplify: return "text.badge.minus"
        case .arabicHelp: return "character.book.closed.ar"
        case .socratic: return "bubble.left.and.bubble.right"
        }
    }

    var systemPrompt: String {
        switch self {
        case .explain:
            return """
            You are a knowledgeable Islamic studies tutor helping a student understand complex texts. \
            Provide clear, detailed explanations while being respectful of Islamic scholarship. \
            Use examples and analogies when helpful. Reference relevant Quranic verses or hadith when appropriate.
            """

        case .quizMe:
            return """
            You are an educational assistant creating questions to test understanding. \
            Generate thoughtful questions that test comprehension, not just memorization. \
            Include a mix of factual recall, comprehension, and application questions. \
            After each answer, provide brief feedback and the correct answer if needed.
            """

        case .connect:
            return """
            You are a scholarly assistant helping find connections between Islamic concepts. \
            Identify how the current text relates to broader Islamic teachings, other scholars' views, \
            and practical applications. Draw connections across different areas of Islamic knowledge.
            """

        case .simplify:
            return """
            You are a patient teacher explaining complex Islamic concepts in simple terms. \
            Use everyday language and relatable examples. Avoid jargon unless you explain it. \
            Break down complex ideas into digestible parts.
            """

        case .arabicHelp:
            return """
            You are an Arabic language expert specializing in Islamic texts. \
            Help with understanding Arabic terms, grammar, and classical Arabic usage. \
            Explain root words, grammatical constructions, and how meaning changes in different contexts. \
            Use transliteration when needed.
            """

        case .socratic:
            return """
            You are a Socratic teacher guiding learning through questions. \
            Instead of giving direct answers, ask probing questions that lead the student to discover insights. \
            Build understanding step by step. Affirm correct reasoning and gently redirect misconceptions. \
            End with a summarizing question that helps consolidate learning.
            """
        }
    }
}

// MARK: - Quiz Question

struct QuizQuestion: Identifiable, Codable, Sendable {
    let id: UUID
    let question: String
    let options: [String]?  // nil for open-ended
    let correctAnswer: String
    let explanation: String
    let difficulty: QuizDifficulty

    init(
        question: String,
        options: [String]? = nil,
        correctAnswer: String,
        explanation: String,
        difficulty: QuizDifficulty = .medium
    ) {
        self.id = UUID()
        self.question = question
        self.options = options
        self.correctAnswer = correctAnswer
        self.explanation = explanation
        self.difficulty = difficulty
    }
}

enum QuizDifficulty: String, Codable, Sendable {
    case easy
    case medium
    case hard

    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Challenging"
        }
    }

    var color: String {
        switch self {
        case .easy: return "green"
        case .medium: return "orange"
        case .hard: return "red"
        }
    }
}

// MARK: - Concept Connection

struct ConceptConnection: Identifiable, Sendable {
    let id: UUID
    let concept: String
    let relatedConcepts: [String]
    let explanation: String
    let sourceBookIDs: [UUID]?

    init(
        concept: String,
        relatedConcepts: [String],
        explanation: String,
        sourceBookIDs: [UUID]? = nil
    ) {
        self.id = UUID()
        self.concept = concept
        self.relatedConcepts = relatedConcepts
        self.explanation = explanation
        self.sourceBookIDs = sourceBookIDs
    }
}
