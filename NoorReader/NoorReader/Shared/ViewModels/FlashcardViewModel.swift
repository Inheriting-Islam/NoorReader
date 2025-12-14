// FlashcardViewModel.swift
// NoorReader
//
// Manages flashcard study session state

import SwiftUI
import SwiftData

/// Manages flashcard study session state
@MainActor
@Observable
final class FlashcardViewModel {

    // MARK: - Dependencies

    private let flashcardService: FlashcardService
    private let sessionService: StudySessionService

    // MARK: - State

    var currentBook: Book?
    var studyQueue: [Flashcard] = []
    var currentCardIndex: Int = 0
    var isFlipped: Bool = false
    var isLoading: Bool = false
    var error: Error?

    // Session tracking
    var sessionStartTime: Date?
    var cardsReviewedCount: Int = 0
    var currentCardStartTime: Date?

    // Counts
    var newCount: Int = 0
    var learningCount: Int = 0
    var dueCount: Int = 0

    // Interval previews for current card
    var intervalPreviews: [ReviewQuality: String] = [:]

    // MARK: - Computed Properties

    var currentCard: Flashcard? {
        guard currentCardIndex < studyQueue.count else { return nil }
        return studyQueue[currentCardIndex]
    }

    var hasCardsRemaining: Bool {
        currentCardIndex < studyQueue.count
    }

    var remainingCards: Int {
        max(0, studyQueue.count - currentCardIndex)
    }

    var sessionDuration: TimeInterval {
        guard let start = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(start)
    }

    var formattedSessionDuration: String {
        let duration = Int(sessionDuration)
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var averageTimePerCard: TimeInterval {
        guard cardsReviewedCount > 0 else { return 0 }
        return sessionDuration / Double(cardsReviewedCount)
    }

    var totalCardCount: Int {
        newCount + learningCount + dueCount
    }

    var isSessionComplete: Bool {
        !hasCardsRemaining && cardsReviewedCount > 0
    }

    // MARK: - Initialization

    init(flashcardService: FlashcardService = .shared, sessionService: StudySessionService = .shared) {
        self.flashcardService = flashcardService
        self.sessionService = sessionService
    }

    // MARK: - Session Management

    func startStudySession(for book: Book? = nil) async {
        isLoading = true
        currentBook = book
        sessionStartTime = Date()
        cardsReviewedCount = 0
        currentCardIndex = 0
        isFlipped = false
        error = nil

        do {
            studyQueue = try await flashcardService.fetchDueFlashcards(for: book)
            await refreshCounts()
            currentCardStartTime = Date()

            // Update interval previews for first card
            if let card = currentCard {
                intervalPreviews = await flashcardService.getIntervalPreviews(for: card)
            }

            // Start a study session
            try? sessionService.startSession(type: .review, book: book)

        } catch {
            self.error = error
        }

        isLoading = false
    }

    func endSession() {
        sessionStartTime = nil
        studyQueue = []
        currentCardIndex = 0
        isFlipped = false

        // End the study session
        try? sessionService.endSession()
    }

    private func refreshCounts() async {
        do {
            let counts = try await flashcardService.getCardCounts(for: currentBook)
            newCount = counts.new
            learningCount = counts.learning
            dueCount = counts.due
        } catch {
            // Ignore count refresh errors
        }
    }

    // MARK: - Card Actions

    func flipCard() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isFlipped.toggle()
        }
    }

    func rateCard(_ quality: ReviewQuality) async {
        guard let card = currentCard else { return }

        let responseTime = currentCardStartTime.map { Date().timeIntervalSince($0) }

        do {
            try await flashcardService.processReview(
                flashcard: card,
                quality: quality,
                responseTime: responseTime
            )

            cardsReviewedCount += 1
            sessionService.trackFlashcardReviewed()

            // Check if card needs to be re-queued (for learning cards)
            let cardState = FlashcardState(rawValue: card.stateRaw) ?? .new
            if (cardState == .learning || cardState == .relearning) && card.isDue {
                // Add back to end of queue
                studyQueue.append(card)
            }

            moveToNextCard()

            // Refresh counts
            await refreshCounts()

        } catch {
            self.error = error
        }
    }

    private func moveToNextCard() {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentCardIndex += 1
            isFlipped = false
            currentCardStartTime = Date()
        }

        // Update interval previews for next card
        Task {
            if let card = currentCard {
                intervalPreviews = await flashcardService.getIntervalPreviews(for: card)
            }
        }
    }

    func skipCard() {
        guard currentCard != nil else { return }

        // Move current card to end of queue
        if let card = currentCard {
            studyQueue.append(card)
        }

        moveToNextCard()
    }

    // MARK: - Keyboard Shortcuts

    func handleKeyPress(_ key: KeyEquivalent) -> Bool {
        if !isFlipped {
            // Space to flip
            if key == .space {
                flipCard()
                return true
            }
        } else {
            // Number keys to rate
            switch key {
            case "1":
                Task { await rateCard(.again) }
                return true
            case "2":
                Task { await rateCard(.hard) }
                return true
            case "3":
                Task { await rateCard(.good) }
                return true
            case "4":
                Task { await rateCard(.easy) }
                return true
            default:
                break
            }
        }
        return false
    }

    // MARK: - Card Management

    func editCurrentCard(front: String, back: String) async {
        guard let card = currentCard else { return }

        do {
            try flashcardService.updateFlashcard(card, front: front, back: back)
        } catch {
            self.error = error
        }
    }

    func deleteCurrentCard() async {
        guard let card = currentCard else { return }

        do {
            try flashcardService.deleteFlashcard(card)
            studyQueue.remove(at: currentCardIndex)

            // Don't increment index since we removed the current card
            if currentCardIndex >= studyQueue.count && currentCardIndex > 0 {
                currentCardIndex = studyQueue.count - 1
            }

            isFlipped = false
            currentCardStartTime = Date()

            await refreshCounts()
        } catch {
            self.error = error
        }
    }

    // MARK: - Undo

    private var lastReviewedCard: Flashcard?
    private var lastReviewQuality: ReviewQuality?

    func canUndo() -> Bool {
        lastReviewedCard != nil && currentCardIndex > 0
    }

    func undoLastReview() {
        // This would require storing more state and reverting the flashcard
        // For now, this is a placeholder
    }
}
