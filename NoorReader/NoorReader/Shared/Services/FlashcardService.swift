// FlashcardService.swift
// NoorReader
//
// Manages flashcard CRUD operations and study queue

import SwiftData
import Foundation

/// Manages flashcard CRUD operations and study queue
@MainActor
@Observable
final class FlashcardService {

    // MARK: - Properties

    private var modelContext: ModelContext?
    private let spacedRepetition = SpacedRepetitionService.shared

    var isLoading = false
    var error: Error?

    // MARK: - Singleton

    static let shared = FlashcardService()

    private init() {}

    // MARK: - Configuration

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD Operations

    func createFlashcard(
        front: String,
        back: String,
        book: Book?,
        sourcePageNumber: Int? = nil,
        sourceText: String? = nil,
        sourceHighlightID: UUID? = nil
    ) throws -> Flashcard {
        guard let modelContext else {
            throw FlashcardError.notConfigured
        }

        let flashcard = Flashcard(
            front: front,
            back: back,
            sourcePageNumber: sourcePageNumber,
            sourceText: sourceText,
            sourceHighlightID: sourceHighlightID
        )

        flashcard.book = book
        modelContext.insert(flashcard)
        try modelContext.save()

        return flashcard
    }

    func createFlashcards(
        from suggestions: [FlashcardSuggestion],
        book: Book?,
        sourceHighlightID: UUID? = nil
    ) throws -> [Flashcard] {
        guard let modelContext else {
            throw FlashcardError.notConfigured
        }

        var created: [Flashcard] = []

        for suggestion in suggestions where suggestion.isSelected {
            let flashcard = Flashcard(
                front: suggestion.question,
                back: suggestion.answer,
                sourceHighlightID: sourceHighlightID
            )
            flashcard.book = book
            modelContext.insert(flashcard)
            created.append(flashcard)
        }

        try modelContext.save()
        return created
    }

    func updateFlashcard(_ flashcard: Flashcard, front: String, back: String) throws {
        guard let modelContext else {
            throw FlashcardError.notConfigured
        }

        flashcard.updateContent(front: front, back: back)
        try modelContext.save()
    }

    func deleteFlashcard(_ flashcard: Flashcard) throws {
        guard let modelContext else {
            throw FlashcardError.notConfigured
        }

        modelContext.delete(flashcard)
        try modelContext.save()
    }

    func deleteFlashcards(_ flashcards: [Flashcard]) throws {
        guard let modelContext else {
            throw FlashcardError.notConfigured
        }

        for flashcard in flashcards {
            modelContext.delete(flashcard)
        }
        try modelContext.save()
    }

    // MARK: - Fetching

    func fetchAllFlashcards() throws -> [Flashcard] {
        guard let modelContext else {
            throw FlashcardError.notConfigured
        }

        let descriptor = FetchDescriptor<Flashcard>(
            sortBy: [SortDescriptor(\.dateCreated, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchFlashcards(for book: Book) throws -> [Flashcard] {
        guard let modelContext else {
            throw FlashcardError.notConfigured
        }

        let bookID = book.id
        let descriptor = FetchDescriptor<Flashcard>(
            predicate: #Predicate { $0.book?.id == bookID },
            sortBy: [SortDescriptor(\.dateCreated, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchDueFlashcards(for book: Book? = nil, limit: Int = 20) async throws -> [Flashcard] {
        let allCards: [Flashcard]

        if let book {
            allCards = try fetchFlashcards(for: book)
        } else {
            allCards = try fetchAllFlashcards()
        }

        return await spacedRepetition.getDueCards(from: allCards, limit: limit)
    }

    // MARK: - Review

    func processReview(
        flashcard: Flashcard,
        quality: ReviewQuality,
        responseTime: TimeInterval? = nil
    ) async throws {
        guard let modelContext else {
            throw FlashcardError.notConfigured
        }

        let previousInterval = flashcard.interval
        let previousEaseFactor = flashcard.easeFactor

        // Calculate new scheduling
        let result = await spacedRepetition.processReview(
            card: flashcard,
            quality: quality
        )

        // Update flashcard
        flashcard.stateRaw = result.newState.rawValue
        flashcard.interval = result.newInterval
        flashcard.easeFactor = result.newEaseFactor
        flashcard.dueDate = result.newDueDate
        flashcard.repetitions = result.newRepetitions
        flashcard.learningStep = result.newLearningStep
        flashcard.dateModified = Date()

        // Log the review
        let reviewLog = ReviewLog(
            flashcardID: flashcard.id,
            quality: quality,
            previousInterval: previousInterval,
            newInterval: result.newInterval,
            previousEaseFactor: previousEaseFactor,
            newEaseFactor: result.newEaseFactor,
            responseTimeSeconds: responseTime
        )
        modelContext.insert(reviewLog)

        try modelContext.save()
    }

    // MARK: - Statistics

    func getCardCounts(for book: Book? = nil) async throws -> (new: Int, learning: Int, due: Int) {
        let cards: [Flashcard]

        if let book {
            cards = try fetchFlashcards(for: book)
        } else {
            cards = try fetchAllFlashcards()
        }

        return await spacedRepetition.getCardCounts(from: cards)
    }

    func getTotalCardCount(for book: Book? = nil) throws -> Int {
        if let book {
            return try fetchFlashcards(for: book).count
        } else {
            return try fetchAllFlashcards().count
        }
    }

    func getIntervalPreviews(for flashcard: Flashcard) async -> [ReviewQuality: String] {
        await spacedRepetition.getIntervalPreviews(for: flashcard)
    }

    // MARK: - Review History

    func fetchReviewLogs(for flashcard: Flashcard, limit: Int = 50) throws -> [ReviewLog] {
        guard let modelContext else {
            throw FlashcardError.notConfigured
        }

        let flashcardID = flashcard.id
        let descriptor = FetchDescriptor<ReviewLog>(
            predicate: #Predicate { $0.flashcardID == flashcardID },
            sortBy: [SortDescriptor(\.reviewDate, order: .reverse)]
        )
        var limitedDescriptor = descriptor
        limitedDescriptor.fetchLimit = limit

        return try modelContext.fetch(limitedDescriptor)
    }

    func fetchRecentReviewLogs(limit: Int = 100) throws -> [ReviewLog] {
        guard let modelContext else {
            throw FlashcardError.notConfigured
        }

        var descriptor = FetchDescriptor<ReviewLog>(
            sortBy: [SortDescriptor(\.reviewDate, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        return try modelContext.fetch(descriptor)
    }

    func getTodayReviewCount() throws -> Int {
        guard let modelContext else {
            throw FlashcardError.notConfigured
        }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<ReviewLog>(
            predicate: #Predicate { $0.reviewDate >= startOfDay }
        )

        return try modelContext.fetchCount(descriptor)
    }

    // MARK: - Reset

    func resetFlashcard(_ flashcard: Flashcard) throws {
        guard let modelContext else {
            throw FlashcardError.notConfigured
        }

        flashcard.stateRaw = FlashcardState.new.rawValue
        flashcard.repetitions = 0
        flashcard.easeFactor = 2.5
        flashcard.interval = 0
        flashcard.dueDate = Date()
        flashcard.learningStep = 0
        flashcard.dateModified = Date()

        try modelContext.save()
    }

    func resetAllFlashcards(for book: Book? = nil) throws {
        let cards: [Flashcard]
        if let book {
            cards = try fetchFlashcards(for: book)
        } else {
            cards = try fetchAllFlashcards()
        }

        for card in cards {
            card.stateRaw = FlashcardState.new.rawValue
            card.repetitions = 0
            card.easeFactor = 2.5
            card.interval = 0
            card.dueDate = Date()
            card.learningStep = 0
            card.dateModified = Date()
        }

        try modelContext?.save()
    }
}

// MARK: - Errors

enum FlashcardError: LocalizedError {
    case notConfigured
    case cardNotFound
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Flashcard service not configured"
        case .cardNotFound:
            return "Flashcard not found"
        case .saveFailed:
            return "Failed to save flashcard"
        }
    }
}
