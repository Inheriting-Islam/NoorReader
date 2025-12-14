// SpacedRepetitionService.swift
// NoorReader
//
// Implements the SM-2 spaced repetition algorithm
// Reference: https://www.supermemo.com/en/archives1990-2015/english/ol/sm2

import Foundation

/// Implements the SM-2 spaced repetition algorithm
actor SpacedRepetitionService {

    // MARK: - Singleton

    static let shared = SpacedRepetitionService()

    // MARK: - Learning Steps (in minutes)

    /// Steps for cards in learning state
    private let learningSteps: [Int] = [1, 10]  // 1 min, 10 min

    /// Steps for cards in relearning state
    private let relearningSteps: [Int] = [10]   // 10 min

    /// Graduating interval (days) - when card moves from learning to review
    private let graduatingInterval: Int = 1

    /// Easy interval (days) - when pressing Easy on learning card
    private let easyInterval: Int = 4

    // MARK: - SM-2 Parameters

    /// Minimum ease factor
    private let minimumEaseFactor: Double = 1.3

    /// Maximum ease factor
    private let maximumEaseFactor: Double = 2.5

    /// Starting ease factor
    private let startingEaseFactor: Double = 2.5

    /// Interval modifier (can be adjusted per user preference)
    var intervalModifier: Double = 1.0

    /// Maximum interval in days (prevents intervals from growing too large)
    private let maximumInterval: Int = 365

    // MARK: - Initialization

    private init() {}

    // MARK: - Review Result

    struct ReviewResult: Sendable {
        let newState: FlashcardState
        let newInterval: Int
        let newEaseFactor: Double
        let newDueDate: Date
        let newRepetitions: Int
        let newLearningStep: Int
    }

    // MARK: - Review Processing

    /// Process a review and calculate new scheduling parameters
    func processReview(
        card: Flashcard,
        quality: ReviewQuality
    ) -> ReviewResult {
        let currentState = FlashcardState(rawValue: card.stateRaw) ?? .new
        var newState = currentState
        var newInterval = card.interval
        var newEaseFactor = card.easeFactor
        var newRepetitions = card.repetitions
        var newLearningStep = card.learningStep

        switch currentState {
        case .new, .learning:
            let result = processLearningReview(
                currentStep: card.learningStep,
                quality: quality
            )
            newState = result.state
            newInterval = result.interval
            newLearningStep = result.step
            if result.graduated {
                newRepetitions = 1
            }

        case .review:
            let result = processReviewReview(
                currentInterval: card.interval,
                easeFactor: card.easeFactor,
                quality: quality
            )
            newState = result.state
            newInterval = result.interval
            newEaseFactor = result.easeFactor
            newLearningStep = result.state == .relearning ? 0 : newLearningStep
            if quality != .again {
                newRepetitions = card.repetitions + 1
            }

        case .relearning:
            let result = processRelearningReview(
                previousInterval: card.interval,
                quality: quality
            )
            newState = result.state
            newInterval = result.interval
            newLearningStep = result.step
        }

        // Ensure ease factor stays in bounds
        newEaseFactor = max(minimumEaseFactor, min(maximumEaseFactor, newEaseFactor))

        // Ensure interval doesn't exceed maximum
        if newState == .review {
            newInterval = min(newInterval, maximumInterval)
        }

        // Calculate due date
        let newDueDate: Date
        if newState == .learning || newState == .relearning {
            // Minutes for learning cards
            newDueDate = Calendar.current.date(
                byAdding: .minute,
                value: newInterval,
                to: Date()
            ) ?? Date()
        } else {
            // Days for review cards
            newDueDate = Calendar.current.date(
                byAdding: .day,
                value: newInterval,
                to: Date()
            ) ?? Date()
        }

        return ReviewResult(
            newState: newState,
            newInterval: newInterval,
            newEaseFactor: newEaseFactor,
            newDueDate: newDueDate,
            newRepetitions: newRepetitions,
            newLearningStep: newLearningStep
        )
    }

    // MARK: - Learning State Processing

    private struct LearningResult {
        let state: FlashcardState
        let interval: Int
        let step: Int
        let graduated: Bool
    }

    private func processLearningReview(
        currentStep: Int,
        quality: ReviewQuality
    ) -> LearningResult {
        switch quality {
        case .again:
            // Reset to first step
            return LearningResult(
                state: .learning,
                interval: learningSteps[0],
                step: 0,
                graduated: false
            )

        case .hard:
            // Stay at current step (repeat)
            let step = min(currentStep, learningSteps.count - 1)
            return LearningResult(
                state: .learning,
                interval: learningSteps[step],
                step: step,
                graduated: false
            )

        case .good:
            // Move to next step or graduate
            if currentStep >= learningSteps.count - 1 {
                // Graduate to review
                return LearningResult(
                    state: .review,
                    interval: graduatingInterval,
                    step: currentStep,
                    graduated: true
                )
            } else {
                // Next learning step
                let nextStep = currentStep + 1
                return LearningResult(
                    state: .learning,
                    interval: learningSteps[nextStep],
                    step: nextStep,
                    graduated: false
                )
            }

        case .easy:
            // Graduate immediately with easy interval
            return LearningResult(
                state: .review,
                interval: easyInterval,
                step: currentStep,
                graduated: true
            )
        }
    }

    // MARK: - Review State Processing

    private struct ReviewResult2 {
        let state: FlashcardState
        let interval: Int
        let easeFactor: Double
    }

    private func processReviewReview(
        currentInterval: Int,
        easeFactor: Double,
        quality: ReviewQuality
    ) -> ReviewResult2 {
        // Update ease factor based on quality
        let easeModifier: Double
        switch quality {
        case .again:
            easeModifier = -0.20
        case .hard:
            easeModifier = -0.15
        case .good:
            easeModifier = 0.0
        case .easy:
            easeModifier = 0.15
        }

        let newEaseFactor = max(minimumEaseFactor, easeFactor + easeModifier)

        // Calculate new interval
        let newInterval: Int
        let newState: FlashcardState

        switch quality {
        case .again:
            // Lapse - go to relearning
            newInterval = relearningSteps[0]
            newState = .relearning

        case .hard:
            // Reduce interval slightly (1.2 multiplier)
            newInterval = max(1, Int(Double(currentInterval) * 1.2 * intervalModifier))
            newState = .review

        case .good:
            // Normal progression
            newInterval = max(1, Int(Double(currentInterval) * newEaseFactor * intervalModifier))
            newState = .review

        case .easy:
            // Bonus interval (1.3 additional multiplier)
            newInterval = max(1, Int(Double(currentInterval) * newEaseFactor * 1.3 * intervalModifier))
            newState = .review
        }

        return ReviewResult2(
            state: newState,
            interval: newInterval,
            easeFactor: newEaseFactor
        )
    }

    // MARK: - Relearning State Processing

    private struct RelearningResult {
        let state: FlashcardState
        let interval: Int
        let step: Int
    }

    private func processRelearningReview(
        previousInterval: Int,
        quality: ReviewQuality
    ) -> RelearningResult {
        switch quality {
        case .again:
            // Stay in relearning
            return RelearningResult(
                state: .relearning,
                interval: relearningSteps[0],
                step: 0
            )

        case .hard:
            // Extend relearning slightly
            return RelearningResult(
                state: .relearning,
                interval: relearningSteps[0] * 2,
                step: 0
            )

        case .good, .easy:
            // Return to review with reduced interval
            let newInterval = max(1, previousInterval / 2)
            return RelearningResult(
                state: .review,
                interval: newInterval,
                step: 0
            )
        }
    }

    // MARK: - Queue Management

    /// Get cards due for review, sorted by priority
    func getDueCards(from cards: [Flashcard], limit: Int = 20) -> [Flashcard] {
        let now = Date()

        // Filter due cards
        let dueCards = cards.filter { $0.dueDate <= now }

        // Sort by priority: learning/relearning > new > review (by due date)
        let sorted = dueCards.sorted { card1, card2 in
            let state1 = FlashcardState(rawValue: card1.stateRaw) ?? .new
            let state2 = FlashcardState(rawValue: card2.stateRaw) ?? .new

            // Learning/relearning cards first (they're time-sensitive)
            let isTimeSensitive1 = state1 == .learning || state1 == .relearning
            let isTimeSensitive2 = state2 == .learning || state2 == .relearning

            if isTimeSensitive1 && !isTimeSensitive2 {
                return true
            }
            if !isTimeSensitive1 && isTimeSensitive2 {
                return false
            }

            // Then new cards
            if state1 == .new && state2 != .new {
                return true
            }
            if state1 != .new && state2 == .new {
                return false
            }

            // Then by due date
            return card1.dueDate < card2.dueDate
        }

        return Array(sorted.prefix(limit))
    }

    /// Get count of cards by state
    func getCardCounts(from cards: [Flashcard]) -> (new: Int, learning: Int, due: Int) {
        let now = Date()
        var newCount = 0
        var learningCount = 0
        var dueCount = 0

        for card in cards {
            let state = FlashcardState(rawValue: card.stateRaw) ?? .new

            if state == .new && card.repetitions == 0 {
                newCount += 1
            } else if state == .learning || state == .relearning {
                if card.dueDate <= now {
                    learningCount += 1
                }
            } else if state == .review && card.dueDate <= now {
                dueCount += 1
            }
        }

        return (newCount, learningCount, dueCount)
    }

    /// Get next interval preview for each quality rating
    func getIntervalPreviews(for card: Flashcard) -> [ReviewQuality: String] {
        var previews: [ReviewQuality: String] = [:]

        for quality in ReviewQuality.allCases {
            let result = processReview(card: card, quality: quality)

            if result.newState == .learning || result.newState == .relearning {
                // Minutes
                if result.newInterval < 60 {
                    previews[quality] = "\(result.newInterval)m"
                } else {
                    previews[quality] = "\(result.newInterval / 60)h"
                }
            } else {
                // Days
                if result.newInterval == 1 {
                    previews[quality] = "1d"
                } else if result.newInterval < 30 {
                    previews[quality] = "\(result.newInterval)d"
                } else if result.newInterval < 365 {
                    let months = result.newInterval / 30
                    previews[quality] = "\(months)mo"
                } else {
                    let years = result.newInterval / 365
                    previews[quality] = "\(years)y"
                }
            }
        }

        return previews
    }
}
