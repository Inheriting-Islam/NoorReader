// QuickReviewView.swift
// NoorReader
//
// Quick review mode for browsing highlights as informal flashcards

import SwiftUI
import SwiftData

/// Quick review mode for highlights
struct QuickReviewView: View {
    let book: Book
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var highlights: [Highlight] = []
    @State private var currentIndex: Int = 0
    @State private var showNote: Bool = false
    @State private var isShuffled: Bool = false
    @State private var showCreateFlashcardSheet: Bool = false

    var currentHighlight: Highlight? {
        guard currentIndex < highlights.count else { return nil }
        return highlights[currentIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            if highlights.isEmpty {
                emptyState
            } else {
                // Main content
                VStack(spacing: 24) {
                    // Progress
                    progressBar

                    // Highlight card
                    if let highlight = currentHighlight {
                        highlightCard(highlight)
                    }

                    // Navigation
                    navigationButtons

                    Spacer()
                }
                .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color(.windowBackgroundColor))
        .onAppear {
            loadHighlights()
        }
        .sheet(isPresented: $showCreateFlashcardSheet) {
            if let highlight = currentHighlight {
                FlashcardFromHighlightSheet(highlight: highlight, book: book)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Quick Review")
                .font(.headline)

            Spacer()

            // Shuffle toggle
            Button {
                toggleShuffle()
            } label: {
                Label(isShuffled ? "Shuffled" : "Shuffle", systemImage: "shuffle")
            }
            .buttonStyle(.plain)
            .foregroundStyle(isShuffled ? .blue : .secondary)

            Spacer()

            // Close
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding()
    }

    // MARK: - Progress

    private var progressBar: some View {
        VStack(spacing: 8) {
            ProgressView(value: Double(currentIndex + 1), total: Double(highlights.count))

            Text("\(currentIndex + 1) of \(highlights.count) highlights")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Highlight Card

    private func highlightCard(_ highlight: Highlight) -> some View {
        VStack(spacing: 16) {
            // Color indicator
            HStack {
                Circle()
                    .fill(highlight.color.color)
                    .frame(width: 12, height: 12)

                Text(highlight.color.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Page \(highlight.pageNumber)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Highlight text
            ScrollView {
                Text(highlight.text)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: 200)

            // Note reveal
            if highlight.hasNote {
                VStack(spacing: 12) {
                    Button {
                        withAnimation {
                            showNote.toggle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: showNote ? "eye.slash" : "eye")
                            Text(showNote ? "Hide Note" : "Show Note")
                        }
                        .font(.subheadline)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)

                    if showNote, let note = highlight.note {
                        Text(note.content)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
            }

            // Create flashcard button
            Button {
                showCreateFlashcardSheet = true
            } label: {
                Label("Create Flashcard", systemImage: "rectangle.on.rectangle")
                    .font(.subheadline)
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
        .frame(maxWidth: 500, maxHeight: 400)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }

    // MARK: - Navigation

    private var navigationButtons: some View {
        HStack(spacing: 40) {
            Button {
                previousHighlight()
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(currentIndex > 0 ? .blue : .secondary.opacity(0.3))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.leftArrow, modifiers: [])
            .disabled(currentIndex <= 0)

            // Keyboard shortcut hints
            VStack(spacing: 4) {
                Text("← Previous")
                    .font(.caption2)
                Text("→ Next")
                    .font(.caption2)
                Text("Space: Show/Hide Note")
                    .font(.caption2)
            }
            .foregroundStyle(.tertiary)

            Button {
                nextHighlight()
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(currentIndex < highlights.count - 1 ? .blue : .secondary.opacity(0.3))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.rightArrow, modifiers: [])
            .disabled(currentIndex >= highlights.count - 1)
        }
        .onKeyPress(.space) {
            withAnimation {
                showNote.toggle()
            }
            return .handled
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "highlighter")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Highlights to Review")
                .font(.title2)

            Text("Create highlights while reading to review them here.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func loadHighlights() {
        highlights = book.highlights.sorted { $0.pageNumber < $1.pageNumber }
    }

    private func toggleShuffle() {
        isShuffled.toggle()
        if isShuffled {
            highlights.shuffle()
        } else {
            highlights.sort { $0.pageNumber < $1.pageNumber }
        }
        currentIndex = 0
        showNote = false
    }

    private func previousHighlight() {
        guard currentIndex > 0 else { return }
        withAnimation {
            currentIndex -= 1
            showNote = false
        }
    }

    private func nextHighlight() {
        guard currentIndex < highlights.count - 1 else { return }
        withAnimation {
            currentIndex += 1
            showNote = false
        }
    }
}

// MARK: - Flashcard from Highlight Sheet

struct FlashcardFromHighlightSheet: View {
    let highlight: Highlight
    let book: Book

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var question: String = ""
    @State private var answer: String = ""
    @State private var isGenerating = false
    @State private var aiService = AIService.shared

    var body: some View {
        VStack(spacing: 20) {
            Text("Create Flashcard")
                .font(.headline)

            // Source highlight
            VStack(alignment: .leading, spacing: 8) {
                Text("From highlight:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(highlight.text)
                    .font(.callout)
                    .lineLimit(3)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Question
            VStack(alignment: .leading, spacing: 8) {
                Text("Question")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Enter question...", text: $question, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color(.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .lineLimit(3...5)
            }

            // Answer
            VStack(alignment: .leading, spacing: 8) {
                Text("Answer")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Enter answer...", text: $answer, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color(.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .lineLimit(3...5)
            }

            // AI generate button
            Button {
                generateWithAI()
            } label: {
                Label(isGenerating ? "Generating..." : "Generate with AI", systemImage: "sparkles")
            }
            .disabled(isGenerating)

            Spacer()

            // Actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }

                Spacer()

                Button("Create") {
                    createFlashcard()
                }
                .buttonStyle(.borderedProminent)
                .disabled(question.isEmpty || answer.isEmpty)
            }
        }
        .padding()
        .frame(width: 450, height: 500)
    }

    private func generateWithAI() {
        isGenerating = true

        Task {
            do {
                let suggestions = try await aiService.generateFlashcards(fromText: highlight.text, count: 1)
                if let first = suggestions.first {
                    question = first.question
                    answer = first.answer
                }
            } catch {
                // Ignore errors, user can still type manually
            }
            isGenerating = false
        }
    }

    private func createFlashcard() {
        let flashcard = Flashcard(
            front: question,
            back: answer,
            sourcePageNumber: highlight.pageNumber,
            sourceText: highlight.text,
            sourceHighlightID: highlight.id
        )
        flashcard.book = book
        modelContext.insert(flashcard)

        dismiss()
    }
}

#Preview("Quick Review") {
    QuickReviewView(book: Book(title: "Sample Book", fileURL: URL(fileURLWithPath: "/")))
}
