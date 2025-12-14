// AIConversationSheet.swift
// NoorReader
//
// Chat-style interface for extended AI interaction

import SwiftUI
import SwiftData

struct AIConversationSheet: View {
    @Bindable var viewModel: ConversationViewModel
    let context: String?
    let bookID: UUID
    let pageNumber: Int
    let onDismiss: () -> Void

    @State private var showHistory = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            conversationHeader

            Divider()

            // Mode selector
            modeSelector

            Divider()

            // Main content area
            if viewModel.isQuizMode && !viewModel.quizQuestions.isEmpty {
                quizView
            } else {
                conversationView
            }

            Divider()

            // Input area
            inputArea
        }
        .frame(minWidth: 500, minHeight: 500)
        .background(Color(.windowBackgroundColor))
        .task {
            if !viewModel.hasConversation {
                await viewModel.startConversation(
                    bookID: bookID,
                    context: context,
                    pageNumber: pageNumber
                )
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.error?.localizedDescription ?? "Unknown error")
        }
    }

    // MARK: - Header

    private var conversationHeader: some View {
        HStack {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("Noor AI")
                    .font(.headline)

                Text(viewModel.selectedMode.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // History button
            Button {
                showHistory.toggle()
            } label: {
                Image(systemName: "clock.arrow.circlepath")
            }
            .buttonStyle(.borderless)
            .popover(isPresented: $showHistory) {
                historyPopover
            }

            // Close button
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    // MARK: - Mode Selector

    private var modeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ConversationMode.allCases) { mode in
                    ModeButton(
                        mode: mode,
                        isSelected: viewModel.selectedMode == mode
                    ) {
                        viewModel.setMode(mode)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Conversation View

    private var conversationView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Context preview if available
                    if let context, !context.isEmpty {
                        ContextCard(text: context)
                            .id("context")
                    }

                    // Messages
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    // Loading indicator
                    if viewModel.isProcessing {
                        TypingIndicator()
                            .id("typing")
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation {
                    if let lastMessage = viewModel.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    } else {
                        proxy.scrollTo("context", anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Quiz View

    private var quizView: some View {
        VStack(spacing: 16) {
            if viewModel.showQuizResults {
                quizResultsView
            } else if let question = viewModel.currentQuizQuestion {
                quizQuestionView(question)
            } else {
                // Loading quiz
                ProgressView("Generating quiz...")
            }
        }
        .padding()
    }

    private func quizQuestionView(_ question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Progress
            VStack(spacing: 4) {
                ProgressView(value: viewModel.quizProgress)
                    .progressViewStyle(.linear)

                Text("Question \(viewModel.currentQuizIndex + 1) of \(viewModel.quizQuestions.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Difficulty badge
            DifficultyBadge(difficulty: question.difficulty)

            // Question
            Text(question.question)
                .font(.title3)
                .fontWeight(.medium)

            Spacer()

            // Options or free-form input
            if let options = question.options {
                VStack(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            viewModel.submitQuizAnswer(option)
                        } label: {
                            Text(option)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.controlBackgroundColor))
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                // Free-form answer
                TextField("Your answer...", text: $viewModel.inputText)
                    .textFieldStyle(.roundedBorder)

                Button("Submit") {
                    viewModel.submitQuizAnswer(viewModel.inputText)
                    viewModel.inputText = ""
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.inputText.isEmpty)
            }
        }
    }

    private var quizResultsView: some View {
        VStack(spacing: 20) {
            // Score
            VStack(spacing: 8) {
                Text("Quiz Complete!")
                    .font(.title)
                    .fontWeight(.bold)

                Text("\(viewModel.quizScore) / \(viewModel.quizQuestions.count)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(scoreColor)

                Text(scoreMessage)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Review answers
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.quizQuestions) { question in
                        QuizReviewRow(
                            question: question,
                            userAnswer: viewModel.userAnswers[question.id] ?? "",
                            isCorrect: viewModel.isAnswerCorrect(for: question)
                        )
                    }
                }
            }

            // Actions
            HStack {
                Button("Try Again") {
                    viewModel.restartQuiz()
                }
                .buttonStyle(.bordered)

                Button("New Quiz") {
                    Task {
                        if let context {
                            await viewModel.generateQuiz(from: context)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var scoreColor: Color {
        let percentage = Double(viewModel.quizScore) / Double(viewModel.quizQuestions.count)
        if percentage >= 0.8 { return .green }
        if percentage >= 0.6 { return .orange }
        return .red
    }

    private var scoreMessage: String {
        let percentage = Double(viewModel.quizScore) / Double(viewModel.quizQuestions.count)
        if percentage >= 0.9 { return "Excellent! MashaAllah!" }
        if percentage >= 0.8 { return "Great job!" }
        if percentage >= 0.6 { return "Good effort!" }
        if percentage >= 0.4 { return "Keep practicing!" }
        return "Review the material and try again"
    }

    // MARK: - Input Area

    private var inputArea: some View {
        VStack(spacing: 8) {
            // Quick actions
            if !viewModel.isQuizMode {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.quickActions) { action in
                            Button {
                                Task {
                                    await viewModel.executeQuickAction(action)
                                }
                            } label: {
                                Label(action.title, systemImage: action.icon)
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Text input
            HStack(spacing: 12) {
                TextField("Ask a question...", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .focused($isInputFocused)
                    .onSubmit {
                        Task {
                            await viewModel.sendMessage()
                        }
                    }

                Button {
                    Task {
                        await viewModel.sendMessage()
                    }
                } label: {
                    Image(systemName: viewModel.isProcessing ? "ellipsis.circle" : "arrow.up.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canSendMessage)
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
            }
            .padding()
        }
    }

    // MARK: - History Popover

    private var historyPopover: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Conversation History")
                .font(.headline)
                .padding()

            Divider()

            if viewModel.conversationHistory.isEmpty {
                Text("No previous conversations")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                List {
                    ForEach(viewModel.conversationHistory) { conversation in
                        Button {
                            viewModel.loadConversation(conversation)
                            showHistory = false
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(conversation.displayTitle)
                                    .font(.callout)

                                Text(conversation.preview)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)

                                Text(conversation.updatedAt, style: .relative)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { indexSet in
                        Task {
                            for index in indexSet {
                                await viewModel.deleteConversation(viewModel.conversationHistory[index])
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 300, height: 400)
        .task {
            await viewModel.loadHistory(for: bookID)
        }
    }
}

// MARK: - Supporting Views

private struct ModeButton: View {
    let mode: ConversationMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(mode.displayName, systemImage: mode.icon)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
                }
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

private struct ContextCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Selected Text", systemImage: "text.quote")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(text)
                .font(.callout)
                .lineLimit(5)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.accentColor.opacity(0.1))
        }
    }
}

private struct MessageBubble: View {
    let message: ConversationMessage

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .assistant {
                Image(systemName: message.role.icon)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 32)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .textSelection(.enabled)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(message.role == .user ? Color.accentColor : Color(.controlBackgroundColor))
            }
            .foregroundStyle(message.role == .user ? .white : .primary)

            if message.role == .user {
                Image(systemName: message.role.icon)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 32)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }
}

private struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 8, height: 8)
                    .offset(y: animating ? -5 : 0)
                    .animation(
                        .easeInOut(duration: 0.4)
                        .repeatForever()
                        .delay(Double(index) * 0.1),
                        value: animating
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            animating = true
        }
    }
}

private struct DifficultyBadge: View {
    let difficulty: QuizDifficulty

    var body: some View {
        Text(difficulty.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule()
                    .fill(difficultyColor.opacity(0.2))
            }
            .foregroundStyle(difficultyColor)
    }

    private var difficultyColor: Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

private struct QuizReviewRow: View {
    let question: QuizQuestion
    let userAnswer: String
    let isCorrect: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(isCorrect ? .green : .red)

                Text(question.question)
                    .font(.callout)
                    .fontWeight(.medium)
            }

            if !isCorrect {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your answer: \(userAnswer)")
                        .font(.caption)
                        .foregroundStyle(.red)

                    Text("Correct: \(question.correctAnswer)")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Text(question.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.controlBackgroundColor))
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ConversationViewModel()

    return AIConversationSheet(
        viewModel: viewModel,
        context: "The concept of tawakkul (trust in Allah) is central to Islamic spirituality.",
        bookID: UUID(),
        pageNumber: 42,
        onDismiss: {}
    )
    .frame(width: 600, height: 600)
}
