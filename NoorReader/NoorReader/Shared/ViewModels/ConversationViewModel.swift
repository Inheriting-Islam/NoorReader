// ConversationViewModel.swift
// NoorReader
//
// ViewModel for AI conversation UI

import Foundation
import SwiftData

/// ViewModel for managing AI conversation state
@MainActor
@Observable
final class ConversationViewModel {

    // MARK: - Properties

    private let conversationService: AIConversationService
    private var modelContext: ModelContext?

    // State
    var currentConversation: ConversationHistory?
    var messages: [ConversationMessage] = []
    var inputText: String = ""
    var isProcessing = false
    var selectedMode: ConversationMode = .explain

    // Quiz state
    var quizQuestions: [QuizQuestion] = []
    var currentQuizIndex: Int = 0
    var userAnswers: [UUID: String] = [:]
    var showQuizResults = false

    // Error handling
    var error: Error?
    var showError = false

    // History
    var conversationHistory: [ConversationHistory] = []

    // MARK: - Computed Properties

    var hasConversation: Bool {
        currentConversation != nil
    }

    var canSendMessage: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isProcessing &&
        hasConversation
    }

    var isQuizMode: Bool {
        selectedMode == .quizMe
    }

    var currentQuizQuestion: QuizQuestion? {
        guard currentQuizIndex < quizQuestions.count else { return nil }
        return quizQuestions[currentQuizIndex]
    }

    var quizProgress: Double {
        guard !quizQuestions.isEmpty else { return 0 }
        return Double(currentQuizIndex) / Double(quizQuestions.count)
    }

    var quizScore: Int {
        var correct = 0
        for question in quizQuestions {
            if let answer = userAnswers[question.id],
               answer.lowercased().contains(question.correctAnswer.lowercased()) {
                correct += 1
            }
        }
        return correct
    }

    // MARK: - Initialization

    init() {
        self.conversationService = AIConversationService.shared
    }

    // MARK: - Configuration

    func configure(modelContext: ModelContext, apiKey: String?) {
        self.modelContext = modelContext
        conversationService.configure(modelContext: modelContext, apiKey: apiKey)
    }

    var isConfigured: Bool {
        conversationService.isConfigured
    }

    // MARK: - Conversation Lifecycle

    func startConversation(
        bookID: UUID,
        context: String?,
        pageNumber: Int
    ) async {
        do {
            currentConversation = try conversationService.startConversation(
                bookID: bookID,
                context: context,
                pageNumber: pageNumber,
                mode: selectedMode
            )
            messages = currentConversation?.messages ?? []

            // Auto-start based on mode
            if let context, !context.isEmpty {
                await sendInitialMessage(for: context)
            }
        } catch {
            self.error = error
            showError = true
        }
    }

    func loadConversation(_ conversation: ConversationHistory) {
        currentConversation = conversation
        selectedMode = conversation.mode
        messages = conversation.messages
    }

    func loadHistory(for bookID: UUID) async {
        do {
            conversationHistory = try conversationService.loadConversations(for: bookID)
        } catch {
            conversationHistory = []
        }
    }

    func clearConversation() {
        currentConversation = nil
        messages = []
        inputText = ""
        quizQuestions = []
        currentQuizIndex = 0
        userAnswers = [:]
        showQuizResults = false
    }

    func deleteConversation(_ conversation: ConversationHistory) async {
        do {
            try conversationService.deleteConversation(conversation)
            conversationHistory.removeAll { $0.id == conversation.id }
            if currentConversation?.id == conversation.id {
                clearConversation()
            }
        } catch {
            self.error = error
            showError = true
        }
    }

    // MARK: - Messaging

    func sendMessage() async {
        guard canSendMessage, let conversation = currentConversation else { return }

        let messageText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        inputText = ""

        isProcessing = true
        error = nil

        // Add user message immediately for UI
        let userMessage = ConversationMessage(role: .user, content: messageText)
        messages.append(userMessage)

        do {
            let response = try await conversationService.sendMessage(messageText, in: conversation)

            // Add assistant response
            let assistantMessage = ConversationMessage(role: .assistant, content: response)
            messages.append(assistantMessage)
        } catch {
            self.error = error
            showError = true
            // Remove user message on failure
            messages.removeLast()
        }

        isProcessing = false
    }

    private func sendInitialMessage(for context: String) async {
        guard let conversation = currentConversation else { return }

        isProcessing = true

        let initialPrompt: String
        switch selectedMode {
        case .explain:
            initialPrompt = "Please explain this text in detail."
        case .quizMe:
            await generateQuiz(from: context)
            isProcessing = false
            return
        case .connect:
            initialPrompt = "What concepts in this text connect to broader Islamic teachings?"
        case .simplify:
            initialPrompt = "Please explain this in simpler terms."
        case .arabicHelp:
            initialPrompt = "Please help me understand the Arabic terms in this text."
        case .socratic:
            initialPrompt = "Let's explore this text together through questions."
        }

        inputText = initialPrompt
        await sendMessage()
    }

    // MARK: - Mode Switching

    func setMode(_ mode: ConversationMode) {
        selectedMode = mode

        // Update conversation mode if exists
        if let conversation = currentConversation {
            conversation.mode = mode
            try? modelContext?.save()
        }
    }

    // MARK: - Quiz Functions

    func generateQuiz(from text: String) async {
        isProcessing = true
        quizQuestions = []
        currentQuizIndex = 0
        userAnswers = [:]
        showQuizResults = false

        do {
            quizQuestions = try await conversationService.generateQuiz(from: text)
        } catch {
            self.error = error
            showError = true
        }

        isProcessing = false
    }

    func submitQuizAnswer(_ answer: String) {
        guard let question = currentQuizQuestion else { return }
        userAnswers[question.id] = answer

        // Move to next question or show results
        if currentQuizIndex < quizQuestions.count - 1 {
            currentQuizIndex += 1
        } else {
            showQuizResults = true
        }
    }

    func restartQuiz() {
        currentQuizIndex = 0
        userAnswers = [:]
        showQuizResults = false
    }

    func isAnswerCorrect(for question: QuizQuestion) -> Bool {
        guard let answer = userAnswers[question.id] else { return false }
        return answer.lowercased().contains(question.correctAnswer.lowercased())
    }

    // MARK: - Arabic Help

    func explainArabic(in text: String, context: String? = nil) async {
        isProcessing = true

        do {
            let explanation = try await conversationService.explainArabic(text: text, context: context)

            // Add to conversation
            messages.append(ConversationMessage(role: .user, content: "Explain the Arabic: \(text)"))
            messages.append(ConversationMessage(role: .assistant, content: explanation))

            // Save if in conversation
            if let conversation = currentConversation {
                conversation.addUserMessage("Explain the Arabic: \(text)")
                conversation.addAssistantMessage(explanation)
                try? modelContext?.save()
            }
        } catch {
            self.error = error
            showError = true
        }

        isProcessing = false
    }

    // MARK: - Socratic Mode

    func askSocraticQuestion(about text: String) async {
        isProcessing = true

        do {
            let question = try await conversationService.askSocraticQuestion(
                about: text,
                previousExchanges: messages
            )

            messages.append(ConversationMessage(role: .assistant, content: question))

            if let conversation = currentConversation {
                conversation.addAssistantMessage(question)
                try? modelContext?.save()
            }
        } catch {
            self.error = error
            showError = true
        }

        isProcessing = false
    }
}

// MARK: - Quick Actions

extension ConversationViewModel {

    struct QuickAction: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let prompt: String
    }

    var quickActions: [QuickAction] {
        switch selectedMode {
        case .explain:
            return [
                QuickAction(title: "Key Points", icon: "list.bullet", prompt: "What are the key points?"),
                QuickAction(title: "Examples", icon: "lightbulb", prompt: "Can you give examples?"),
                QuickAction(title: "Summary", icon: "doc.text", prompt: "Summarize this briefly.")
            ]
        case .quizMe:
            return [
                QuickAction(title: "More Questions", icon: "plus.circle", prompt: "Generate more questions"),
                QuickAction(title: "Harder", icon: "arrow.up.circle", prompt: "Make questions harder"),
                QuickAction(title: "Easier", icon: "arrow.down.circle", prompt: "Make questions easier")
            ]
        case .connect:
            return [
                QuickAction(title: "Related Verses", icon: "book", prompt: "Are there related Quranic verses?"),
                QuickAction(title: "Scholars", icon: "person.2", prompt: "What do scholars say?"),
                QuickAction(title: "Applications", icon: "hand.point.right", prompt: "How does this apply today?")
            ]
        case .simplify:
            return [
                QuickAction(title: "Even Simpler", icon: "arrow.down", prompt: "Can you explain even more simply?"),
                QuickAction(title: "Analogy", icon: "arrow.left.arrow.right", prompt: "Can you use an analogy?"),
                QuickAction(title: "Step by Step", icon: "list.number", prompt: "Explain step by step")
            ]
        case .arabicHelp:
            return [
                QuickAction(title: "Root Words", icon: "tree", prompt: "What are the root words?"),
                QuickAction(title: "Grammar", icon: "textformat", prompt: "Explain the grammar"),
                QuickAction(title: "Usage", icon: "quote.bubble", prompt: "How is this used in other texts?")
            ]
        case .socratic:
            return [
                QuickAction(title: "Hint", icon: "lightbulb", prompt: "Can I have a hint?"),
                QuickAction(title: "Rephrase", icon: "arrow.triangle.2.circlepath", prompt: "Can you rephrase the question?"),
                QuickAction(title: "Next Topic", icon: "arrow.right", prompt: "Let's explore a different aspect")
            ]
        }
    }

    func executeQuickAction(_ action: QuickAction) async {
        inputText = action.prompt
        await sendMessage()
    }
}
