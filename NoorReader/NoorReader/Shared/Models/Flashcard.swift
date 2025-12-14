// Flashcard.swift
// NoorReader
//
// SwiftData model for AI-generated flashcards with spaced repetition (SM-2)

import SwiftData
import Foundation

@Model
final class Flashcard {
    // MARK: - Core Properties

    @Attribute(.unique)
    var id: UUID

    var front: String  // Question
    var back: String   // Answer
    var dateCreated: Date
    var dateModified: Date

    // MARK: - SM-2 Algorithm Properties

    /// Number of times reviewed successfully
    var repetitions: Int

    /// Easiness factor (default 2.5, range 1.3-2.5)
    var easeFactor: Double

    /// Current interval in days (or minutes for learning cards)
    var interval: Int

    /// Next review date
    var dueDate: Date

    /// Current learning state (stored as String for SwiftData)
    var stateRaw: String

    /// Current step index for learning/relearning cards
    var learningStep: Int

    // MARK: - Source References

    /// Page number where content originated
    var sourcePageNumber: Int?

    /// Text excerpt that generated this card
    var sourceText: String?

    /// ID of the highlight this card was generated from
    var sourceHighlightID: UUID?

    // MARK: - Relationships

    @Relationship
    var book: Book?

    // MARK: - Computed Properties

    var state: FlashcardState {
        get { FlashcardState(rawValue: stateRaw) ?? .new }
        set { stateRaw = newValue.rawValue }
    }

    var isDue: Bool {
        dueDate <= Date()
    }

    var isNew: Bool {
        state == .new && repetitions == 0
    }

    var isLearning: Bool {
        state == .learning
    }

    var isReview: Bool {
        state == .review
    }

    var isRelearning: Bool {
        state == .relearning
    }

    var daysSinceLastReview: Int {
        Calendar.current.dateComponents([.day], from: dateModified, to: Date()).day ?? 0
    }

    var formattedDueDate: String {
        if isDue {
            return "Due now"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: dueDate, relativeTo: Date())
    }

    /// For backward compatibility with existing code
    var nextReviewDate: Date {
        get { dueDate }
        set { dueDate = newValue }
    }

    /// For backward compatibility
    var dateLastReviewed: Date? {
        get { dateModified }
        set { if let date = newValue { dateModified = date } }
    }

    var masteryLevel: MasteryLevel {
        switch state {
        case .new: return .new
        case .learning, .relearning: return .learning
        case .review:
            if repetitions >= 6 { return .mastered }
            if repetitions >= 3 { return .reviewing }
            return .learning
        }
    }

    // MARK: - Initialization

    init(
        front: String,
        back: String,
        sourcePageNumber: Int? = nil,
        sourceText: String? = nil,
        sourceHighlightID: UUID? = nil
    ) {
        self.id = UUID()
        self.front = front
        self.back = back
        self.dateCreated = Date()
        self.dateModified = Date()
        self.repetitions = 0
        self.easeFactor = 2.5
        self.interval = 0
        self.dueDate = Date()
        self.stateRaw = FlashcardState.new.rawValue
        self.learningStep = 0
        self.sourcePageNumber = sourcePageNumber
        self.sourceText = sourceText
        self.sourceHighlightID = sourceHighlightID
    }

    // MARK: - Methods

    func updateContent(front: String, back: String) {
        self.front = front
        self.back = back
        self.dateModified = Date()
    }

    /// Legacy method for backward compatibility - use SpacedRepetitionService instead
    func processReview(quality: ReviewQuality) {
        dateModified = Date()

        if quality.rawValue < 2 {
            // Failed review - go to relearning
            if state == .review {
                state = .relearning
                learningStep = 0
                interval = 10  // 10 minutes
                dueDate = Calendar.current.date(byAdding: .minute, value: 10, to: Date()) ?? Date()
            } else {
                // Reset learning progress
                learningStep = 0
                interval = 1  // 1 minute
                dueDate = Calendar.current.date(byAdding: .minute, value: 1, to: Date()) ?? Date()
            }
        } else {
            // Successful review
            if state == .new || state == .learning {
                // Progress through learning steps
                if learningStep >= 1 {
                    // Graduate to review
                    state = .review
                    repetitions = 1
                    interval = quality == .easy ? 4 : 1
                    dueDate = Calendar.current.date(byAdding: .day, value: interval, to: Date()) ?? Date()
                } else {
                    learningStep += 1
                    state = .learning
                    interval = 10  // 10 minutes
                    dueDate = Calendar.current.date(byAdding: .minute, value: 10, to: Date()) ?? Date()
                }
            } else if state == .relearning {
                // Return to review with reduced interval
                state = .review
                interval = max(1, interval / 2)
                dueDate = Calendar.current.date(byAdding: .day, value: interval, to: Date()) ?? Date()
            } else {
                // Normal review progression
                repetitions += 1

                // Update ease factor
                let q = Double(quality.rawValue)
                easeFactor = max(1.3, easeFactor + (0.1 - (3 - q) * (0.08 + (3 - q) * 0.02)))

                // Calculate new interval
                let multiplier: Double
                switch quality {
                case .again: multiplier = 0.0  // Handled above
                case .hard: multiplier = 1.2
                case .good: multiplier = easeFactor
                case .easy: multiplier = easeFactor * 1.3
                }

                interval = max(1, Int(Double(interval) * multiplier))
                dueDate = Calendar.current.date(byAdding: .day, value: interval, to: Date()) ?? Date()
            }
        }
    }
}

// MARK: - Flashcard State

enum FlashcardState: String, CaseIterable, Identifiable, Sendable {
    case new = "new"
    case learning = "learning"
    case review = "review"
    case relearning = "relearning"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .new: return "New"
        case .learning: return "Learning"
        case .review: return "Review"
        case .relearning: return "Relearning"
        }
    }

    var icon: String {
        switch self {
        case .new: return "sparkles"
        case .learning: return "brain.head.profile"
        case .review: return "arrow.clockwise"
        case .relearning: return "arrow.counterclockwise"
        }
    }

    var color: String {
        switch self {
        case .new: return "blue"
        case .learning: return "orange"
        case .review: return "green"
        case .relearning: return "red"
        }
    }
}

// MARK: - Review Quality

enum ReviewQuality: Int, CaseIterable, Identifiable, Sendable {
    case again = 0   // Complete failure, reset
    case hard = 1    // Difficult, reduce interval
    case good = 2    // Correct with effort
    case easy = 3    // Perfect, increase interval

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .again: return "Again"
        case .hard: return "Hard"
        case .good: return "Good"
        case .easy: return "Easy"
        }
    }

    var shortcut: String {
        switch self {
        case .again: return "1"
        case .hard: return "2"
        case .good: return "3"
        case .easy: return "4"
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
        case .hard: return "Hard"
        case .good: return "Good"
        case .easy: return "Easy"
        }
    }
}

// MARK: - Mastery Level

enum MasteryLevel: String, CaseIterable, Sendable {
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
