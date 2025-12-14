// Flashcard.swift
// NoorReader
//
// SwiftData model for AI-generated flashcards with spaced repetition (SM-2)

import SwiftData
import Foundation

@Model
final class Flashcard {
    // MARK: - Properties

    var id: UUID
    var front: String  // Question
    var back: String   // Answer
    var dateCreated: Date
    var dateLastReviewed: Date?
    var nextReviewDate: Date

    // Spaced repetition fields (SM-2 algorithm)
    var easeFactor: Double  // Default 2.5
    var interval: Int       // Days until next review
    var repetitions: Int    // Number of successful reviews

    // Source tracking
    var sourcePageNumber: Int?
    var sourceHighlightID: UUID?

    // Relationship
    var book: Book?

    // MARK: - Computed Properties

    var isDue: Bool {
        nextReviewDate <= Date()
    }

    var masteryLevel: MasteryLevel {
        switch repetitions {
        case 0: return .new
        case 1...2: return .learning
        case 3...5: return .reviewing
        default: return .mastered
        }
    }

    // MARK: - Initialization

    init(
        front: String,
        back: String,
        sourcePageNumber: Int? = nil,
        sourceHighlightID: UUID? = nil
    ) {
        self.id = UUID()
        self.front = front
        self.back = back
        self.dateCreated = Date()
        self.nextReviewDate = Date()  // Due immediately
        self.easeFactor = 2.5
        self.interval = 0
        self.repetitions = 0
        self.sourcePageNumber = sourcePageNumber
        self.sourceHighlightID = sourceHighlightID
    }

    // MARK: - SM-2 Spaced Repetition Algorithm

    /// Process a review using the SM-2 algorithm
    /// - Parameter quality: The quality of recall (0-3)
    func processReview(quality: ReviewQuality) {
        dateLastReviewed = Date()

        if quality.rawValue < 2 {
            // Failed review - reset progress
            repetitions = 0
            interval = 1
        } else {
            // Successful review
            repetitions += 1

            if repetitions == 1 {
                interval = 1
            } else if repetitions == 2 {
                interval = 6
            } else {
                interval = Int(Double(interval) * easeFactor)
            }
        }

        // Update ease factor based on quality
        let q = Double(quality.rawValue)
        easeFactor = max(1.3, easeFactor + (0.1 - (3 - q) * (0.08 + (3 - q) * 0.02)))

        // Calculate next review date
        nextReviewDate = Calendar.current.date(
            byAdding: .day,
            value: interval,
            to: Date()
        ) ?? Date()
    }
}

// MARK: - Review Quality

enum ReviewQuality: Int, CaseIterable {
    case again = 0      // Complete failure to recall
    case hard = 1       // Correct response with significant difficulty
    case good = 2       // Correct response with some hesitation
    case easy = 3       // Perfect recall with no hesitation

    var displayName: String {
        switch self {
        case .again: return "Again"
        case .hard: return "Hard"
        case .good: return "Good"
        case .easy: return "Easy"
        }
    }

    var color: String {
        switch self {
        case .again: return "red"
        case .hard: return "orange"
        case .good: return "green"
        case .easy: return "blue"
        }
    }

    var intervalDescription: String {
        switch self {
        case .again: return "< 1 min"
        case .hard: return "1 day"
        case .good: return "Next interval"
        case .easy: return "Extended"
        }
    }
}

// MARK: - Mastery Level

enum MasteryLevel: String, CaseIterable {
    case new = "New"
    case learning = "Learning"
    case reviewing = "Reviewing"
    case mastered = "Mastered"

    var color: String {
        switch self {
        case .new: return "gray"
        case .learning: return "orange"
        case .reviewing: return "blue"
        case .mastered: return "green"
        }
    }

    var icon: String {
        switch self {
        case .new: return "plus.circle"
        case .learning: return "brain"
        case .reviewing: return "arrow.clockwise"
        case .mastered: return "checkmark.seal.fill"
        }
    }
}
