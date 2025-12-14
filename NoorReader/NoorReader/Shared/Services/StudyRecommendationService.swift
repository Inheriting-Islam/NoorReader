// StudyRecommendationService.swift
// NoorReader
//
// AI-powered study recommendations based on user's reading patterns and performance

import Foundation
import SwiftData

// MARK: - Study Plan Types

/// A personalized daily study plan
struct StudyPlan: Identifiable, Sendable {
    let id: UUID
    let date: Date
    let suggestedFlashcards: [FlashcardRecommendation]
    let suggestedReadingSections: [ReadingSuggestion]
    let estimatedDuration: TimeInterval
    let focusAreas: [FocusArea]
    let motivationalMessage: String
    let prayerTimeOptimization: PrayerTimeStudySuggestion?

    var formattedDuration: String {
        let minutes = Int(estimatedDuration / 60)
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
        return "\(minutes)m"
    }
}

/// Flashcard recommendation with context
struct FlashcardRecommendation: Identifiable, Sendable {
    let id: UUID
    let flashcardID: UUID
    let front: String
    let back: String
    let priority: ReviewPriority
    let reason: String
    let bookTitle: String?

    enum ReviewPriority: Int, Comparable, Sendable {
        case critical = 3   // Overdue, low retention
        case high = 2       // Due today, challenging
        case normal = 1     // Due today, normal
        case optional = 0   // Not due, but good to review

        static func < (lhs: ReviewPriority, rhs: ReviewPriority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        var displayName: String {
            switch self {
            case .critical: return "Critical"
            case .high: return "High Priority"
            case .normal: return "Review"
            case .optional: return "Optional"
            }
        }

        var color: String {
            switch self {
            case .critical: return "red"
            case .high: return "orange"
            case .normal: return "blue"
            case .optional: return "gray"
            }
        }
    }
}

/// Reading suggestion based on retention analysis
struct ReadingSuggestion: Identifiable, Sendable {
    let id: UUID
    let bookID: UUID
    let bookTitle: String
    let pageRange: ClosedRange<Int>
    let reason: String
    let estimatedMinutes: Int
    let weakAreas: [String]

    var pageRangeDescription: String {
        "Pages \(pageRange.lowerBound + 1)-\(pageRange.upperBound + 1)"
    }
}

/// Area needing additional focus
struct FocusArea: Identifiable, Sendable {
    let id: UUID
    let topic: String
    let retentionRate: Double
    let reviewsNeeded: Int
    let associatedBookTitle: String?

    var formattedRetentionRate: String {
        "\(Int(retentionRate * 100))%"
    }
}

/// Weak area identified from review history
struct WeakArea: Identifiable, Sendable {
    let id: UUID
    let topic: String
    let failureRate: Double
    let averageResponseTime: TimeInterval
    let flashcardCount: Int
    let lastReviewDate: Date?

    var severity: Severity {
        if failureRate >= 0.5 { return .high }
        if failureRate >= 0.3 { return .medium }
        return .low
    }

    enum Severity: Sendable {
        case low, medium, high

        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "orange"
            case .high: return "red"
            }
        }
    }
}

/// Suggestion based on prayer times
struct PrayerTimeStudySuggestion: Sendable {
    let nextPrayer: String
    let timeUntilPrayer: TimeInterval
    let suggestedActivity: StudyActivity
    let message: String

    enum StudyActivity: Sendable {
        case quickReview       // < 15 min
        case focusedStudy      // 15-45 min
        case readingSession    // > 45 min
        case takeBreak         // Too close to prayer

        var displayName: String {
            switch self {
            case .quickReview: return "Quick Review"
            case .focusedStudy: return "Focused Study"
            case .readingSession: return "Reading Session"
            case .takeBreak: return "Prepare for Prayer"
            }
        }
    }
}

// MARK: - Recommendation Engine Actor

/// Actor for generating personalized study recommendations
actor RecommendationEngine {

    // MARK: - Configuration

    private let optimalSessionMinutes = 25  // Pomodoro-style
    private let minDueCardsForCritical = 10
    private let retentionThreshold = 0.7     // Below this needs attention

    // Islamic motivational messages
    private let motivationalMessages = [
        "\"Seeking knowledge is an obligation upon every Muslim.\" - Prophet Muhammad (PBUH)",
        "\"The ink of the scholar is more sacred than the blood of the martyr.\" - Prophet Muhammad (PBUH)",
        "\"Whoever takes a path in search of knowledge, Allah will make easy for them a path to Paradise.\"",
        "\"Read! In the Name of your Lord who created.\" - Quran 96:1",
        "\"Are those who know equal to those who know not?\" - Quran 39:9",
        "\"My Lord, increase me in knowledge.\" - Quran 20:114",
        "\"The best among you are those who learn the Quran and teach it.\" - Prophet Muhammad (PBUH)",
        "\"Acquire knowledge and teach it to the people.\" - Prophet Muhammad (PBUH)",
        "May your study today bring you closer to understanding and wisdom.",
        "Begin with Bismillah, and may your efforts be blessed."
    ]

    // MARK: - Main Plan Generation

    /// Generate a personalized daily study plan
    func generateDailyPlan(
        flashcards: [Flashcard],
        reviewLogs: [ReviewLog],
        studySessions: [StudySession],
        books: [Book],
        streak: StudyStreak?
    ) async -> StudyPlan {

        // Analyze flashcard performance
        let flashcardRecommendations = await analyzeFlashcards(
            flashcards: flashcards,
            reviewLogs: reviewLogs
        )

        // Identify weak areas
        let weakAreas = await analyzeWeakAreas(from: reviewLogs, flashcards: flashcards)

        // Generate reading suggestions based on weak areas
        let readingSuggestions = generateReadingSuggestions(
            weakAreas: weakAreas,
            books: books,
            flashcards: flashcards
        )

        // Generate focus areas
        let focusAreas = generateFocusAreas(weakAreas: weakAreas, books: books)

        // Calculate estimated duration
        let flashcardDuration = Double(flashcardRecommendations.count) * 0.5 * 60  // 30 sec per card
        let readingDuration = readingSuggestions.reduce(0) { $0 + Double($1.estimatedMinutes * 60) }
        let totalDuration = min(flashcardDuration + readingDuration, Double(optimalSessionMinutes * 3 * 60))

        // Pick motivational message
        let message = motivationalMessages.randomElement() ?? motivationalMessages[0]

        return StudyPlan(
            id: UUID(),
            date: Date(),
            suggestedFlashcards: flashcardRecommendations,
            suggestedReadingSections: readingSuggestions,
            estimatedDuration: totalDuration,
            focusAreas: focusAreas,
            motivationalMessage: message,
            prayerTimeOptimization: nil  // Will be set by caller if needed
        )
    }

    // MARK: - Flashcard Analysis

    private func analyzeFlashcards(
        flashcards: [Flashcard],
        reviewLogs: [ReviewLog]
    ) async -> [FlashcardRecommendation] {

        let now = Date()
        var recommendations: [FlashcardRecommendation] = []

        // Create lookup for review history
        let reviewsByCard = Dictionary(grouping: reviewLogs, by: \.flashcardID)

        for card in flashcards {
            let cardReviews = reviewsByCard[card.id] ?? []
            let recommendation = analyzeCard(card, reviews: cardReviews, now: now)
            if let rec = recommendation {
                recommendations.append(rec)
            }
        }

        // Sort by priority
        recommendations.sort { $0.priority > $1.priority }

        // Limit to reasonable number
        return Array(recommendations.prefix(30))
    }

    private func analyzeCard(
        _ card: Flashcard,
        reviews: [ReviewLog],
        now: Date
    ) -> FlashcardRecommendation? {

        // Check if due
        let isDue = card.dueDate <= now
        let isOverdue = card.dueDate < Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now

        // Calculate recent performance
        let recentReviews = reviews.filter {
            $0.reviewDate > Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        }
        let failureRate = recentReviews.isEmpty ? 0 :
            Double(recentReviews.filter { $0.qualityRaw < 2 }.count) / Double(recentReviews.count)

        // Determine priority and reason
        let priority: FlashcardRecommendation.ReviewPriority
        let reason: String

        if isOverdue && failureRate > 0.3 {
            priority = .critical
            reason = "Overdue with low retention - needs immediate review"
        } else if isOverdue {
            priority = .high
            reason = "Overdue - schedule was missed"
        } else if isDue && failureRate > 0.3 {
            priority = .high
            reason = "Due today with recent struggles"
        } else if isDue {
            priority = .normal
            reason = "Scheduled for review today"
        } else if failureRate > 0.5 {
            priority = .optional
            reason = "Consider extra practice - challenging material"
        } else {
            // Not due and performing well
            return nil
        }

        return FlashcardRecommendation(
            id: UUID(),
            flashcardID: card.id,
            front: card.front,
            back: card.back,
            priority: priority,
            reason: reason,
            bookTitle: card.book?.title
        )
    }

    // MARK: - Weak Area Analysis

    func analyzeWeakAreas(
        from reviewLogs: [ReviewLog],
        flashcards: [Flashcard]
    ) async -> [WeakArea] {

        let cardLookup = Dictionary(uniqueKeysWithValues: flashcards.map { ($0.id, $0) })
        var topicPerformance: [String: (failures: Int, total: Int, responseTimes: [Double], lastReview: Date?)] = [:]

        // Analyze last 30 days of reviews
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        for log in reviewLogs where log.reviewDate >= cutoff {
            guard let card = cardLookup[log.flashcardID],
                  let book = card.book else { continue }

            let topic = book.title  // Use book as topic proxy

            var current = topicPerformance[topic] ?? (0, 0, [], nil)
            current.total += 1
            if log.qualityRaw < 2 {
                current.failures += 1
            }
            if let responseTime = log.responseTimeSeconds {
                current.responseTimes.append(responseTime)
            }
            if current.lastReview == nil || log.reviewDate > current.lastReview! {
                current.lastReview = log.reviewDate
            }
            topicPerformance[topic] = current
        }

        // Convert to weak areas
        var weakAreas: [WeakArea] = []

        for (topic, performance) in topicPerformance {
            let failureRate = performance.total > 0 ?
                Double(performance.failures) / Double(performance.total) : 0

            // Only include if there's actual weakness
            guard failureRate > 0.2 || performance.failures >= 3 else { continue }

            let avgResponseTime = performance.responseTimes.isEmpty ? 0 :
                performance.responseTimes.reduce(0, +) / Double(performance.responseTimes.count)

            weakAreas.append(WeakArea(
                id: UUID(),
                topic: topic,
                failureRate: failureRate,
                averageResponseTime: avgResponseTime,
                flashcardCount: performance.total,
                lastReviewDate: performance.lastReview
            ))
        }

        // Sort by severity
        weakAreas.sort { $0.failureRate > $1.failureRate }

        return weakAreas
    }

    // MARK: - Reading Suggestions

    private func generateReadingSuggestions(
        weakAreas: [WeakArea],
        books: [Book],
        flashcards: [Flashcard]
    ) -> [ReadingSuggestion] {

        var suggestions: [ReadingSuggestion] = []
        let bookLookup = Dictionary(uniqueKeysWithValues: books.map { ($0.id, $0) })

        // Group flashcards by book and page
        let flashcardsByBook = Dictionary(grouping: flashcards) { $0.book?.id }

        for weakArea in weakAreas.prefix(3) {
            // Find the book related to this weak area
            guard let book = books.first(where: { $0.title == weakArea.topic }) else { continue }

            // Find pages with problematic flashcards
            let bookCards = flashcardsByBook[book.id] ?? []
            let pageNumbers = bookCards.compactMap { $0.sourcePageNumber }.sorted()

            if let minPage = pageNumbers.min(), let maxPage = pageNumbers.max() {
                let estimatedMinutes = max(5, (maxPage - minPage + 1) * 2)  // ~2 min per page

                suggestions.append(ReadingSuggestion(
                    id: UUID(),
                    bookID: book.id,
                    bookTitle: book.title,
                    pageRange: minPage...maxPage,
                    reason: "Re-read to strengthen understanding (retention: \(Int(weakArea.failureRate * 100))% failure rate)",
                    estimatedMinutes: estimatedMinutes,
                    weakAreas: [weakArea.topic]
                ))
            }
        }

        return suggestions
    }

    // MARK: - Focus Areas

    private func generateFocusAreas(
        weakAreas: [WeakArea],
        books: [Book]
    ) -> [FocusArea] {

        return weakAreas.prefix(5).map { weak in
            FocusArea(
                id: UUID(),
                topic: weak.topic,
                retentionRate: 1.0 - weak.failureRate,
                reviewsNeeded: max(3, Int(weak.failureRate * 10)),
                associatedBookTitle: weak.topic
            )
        }
    }

    // MARK: - Optimal Study Time

    func predictOptimalStudyTime(
        from sessions: [StudySession]
    ) -> DateComponents {

        // Analyze past sessions to find most productive times
        var hourCounts: [Int: Int] = [:]
        var hourDurations: [Int: Int] = [:]

        for session in sessions {
            let hour = Calendar.current.component(.hour, from: session.startTime)
            hourCounts[hour, default: 0] += 1
            hourDurations[hour, default: 0] += session.durationSeconds
        }

        // Find the hour with most sessions or longest duration
        let bestHour = hourCounts.max { $0.value < $1.value }?.key ?? 9  // Default to 9 AM

        var components = DateComponents()
        components.hour = bestHour
        components.minute = 0
        return components
    }

    // MARK: - Prayer Time Integration

    func suggestActivityForPrayerTime(
        nextPrayer: String,
        timeUntilPrayer: TimeInterval
    ) -> PrayerTimeStudySuggestion {

        let minutes = timeUntilPrayer / 60

        let activity: PrayerTimeStudySuggestion.StudyActivity
        let message: String

        if minutes < 10 {
            activity = .takeBreak
            message = "\(nextPrayer) is in \(Int(minutes)) minutes. Time to prepare."
        } else if minutes < 20 {
            activity = .quickReview
            message = "Perfect time for a quick flashcard review before \(nextPrayer)."
        } else if minutes < 50 {
            activity = .focusedStudy
            message = "You have time for a focused study session before \(nextPrayer)."
        } else {
            activity = .readingSession
            message = "Plenty of time for deep reading before \(nextPrayer)."
        }

        return PrayerTimeStudySuggestion(
            nextPrayer: nextPrayer,
            timeUntilPrayer: timeUntilPrayer,
            suggestedActivity: activity,
            message: message
        )
    }
}

// MARK: - Study Recommendation Service

/// Main service for study recommendations
@MainActor
@Observable
final class StudyRecommendationService {

    // MARK: - Properties

    private let engine = RecommendationEngine()
    private var modelContext: ModelContext?

    var isLoading = false
    var currentPlan: StudyPlan?
    var weakAreas: [WeakArea] = []
    var error: Error?

    // MARK: - Singleton

    static let shared = StudyRecommendationService()

    private init() {}

    // MARK: - Configuration

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Plan Generation

    func generateDailyPlan() async throws {
        guard let modelContext else {
            throw RecommendationError.notConfigured
        }

        isLoading = true
        error = nil

        defer { isLoading = false }

        // Fetch all required data
        let flashcards = try fetchAllFlashcards()
        let reviewLogs = try fetchRecentReviewLogs(days: 30)
        let sessions = try fetchRecentSessions(days: 30)
        let books = try fetchBooks()
        let streak = try fetchStreak()

        // Generate plan
        currentPlan = await engine.generateDailyPlan(
            flashcards: flashcards,
            reviewLogs: reviewLogs,
            studySessions: sessions,
            books: books,
            streak: streak
        )

        // Update weak areas
        weakAreas = await engine.analyzeWeakAreas(from: reviewLogs, flashcards: flashcards)
    }

    func refreshPlan() async {
        try? await generateDailyPlan()
    }

    // MARK: - Prayer Time Integration

    func updatePrayerTimeSuggestion(nextPrayer: String, timeUntilPrayer: TimeInterval) async {
        guard var plan = currentPlan else { return }

        let suggestion = await engine.suggestActivityForPrayerTime(
            nextPrayer: nextPrayer,
            timeUntilPrayer: timeUntilPrayer
        )

        currentPlan = StudyPlan(
            id: plan.id,
            date: plan.date,
            suggestedFlashcards: plan.suggestedFlashcards,
            suggestedReadingSections: plan.suggestedReadingSections,
            estimatedDuration: plan.estimatedDuration,
            focusAreas: plan.focusAreas,
            motivationalMessage: plan.motivationalMessage,
            prayerTimeOptimization: suggestion
        )
    }

    // MARK: - Optimal Study Time

    func getOptimalStudyTime() async -> DateComponents {
        guard let modelContext else {
            return DateComponents(hour: 9, minute: 0)
        }

        let sessions = (try? fetchRecentSessions(days: 90)) ?? []
        return await engine.predictOptimalStudyTime(from: sessions)
    }

    // MARK: - Data Fetching

    private func fetchAllFlashcards() throws -> [Flashcard] {
        guard let modelContext else { return [] }
        let descriptor = FetchDescriptor<Flashcard>()
        return try modelContext.fetch(descriptor)
    }

    private func fetchRecentReviewLogs(days: Int) throws -> [ReviewLog] {
        guard let modelContext else { return [] }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<ReviewLog>(
            predicate: #Predicate { $0.reviewDate >= cutoff },
            sortBy: [SortDescriptor(\.reviewDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchRecentSessions(days: Int) throws -> [StudySession] {
        guard let modelContext else { return [] }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<StudySession>(
            predicate: #Predicate { $0.startTime >= cutoff },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchBooks() throws -> [Book] {
        guard let modelContext else { return [] }
        let descriptor = FetchDescriptor<Book>()
        return try modelContext.fetch(descriptor)
    }

    private func fetchStreak() throws -> StudyStreak? {
        guard let modelContext else { return nil }
        let descriptor = FetchDescriptor<StudyStreak>()
        return try modelContext.fetch(descriptor).first
    }
}

// MARK: - Errors

enum RecommendationError: LocalizedError {
    case notConfigured
    case fetchFailed(String)
    case analysisError(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Recommendation service not configured"
        case .fetchFailed(let reason):
            return "Failed to fetch data: \(reason)"
        case .analysisError(let reason):
            return "Analysis failed: \(reason)"
        }
    }
}
