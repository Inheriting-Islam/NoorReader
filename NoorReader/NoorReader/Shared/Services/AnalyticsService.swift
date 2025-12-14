// AnalyticsService.swift
// NoorReader
//
// Reading analytics and insights service

import Foundation
import SwiftData

// MARK: - Reading Analytics Model

struct ReadingAnalytics: Sendable {
    // Speed metrics
    let averagePagesPerMinute: Double
    let averageWordsPerMinute: Double
    let fastestReadingSpeed: Double
    let slowestReadingSpeed: Double

    // Time distribution
    let totalReadingTime: TimeInterval
    let averageSessionDuration: TimeInterval
    let longestSession: TimeInterval
    let mostActiveHour: Int
    let mostActiveDay: Int  // 1 = Sunday, 7 = Saturday

    // Completion metrics
    let booksStarted: Int
    let booksCompleted: Int
    let averageCompletionRate: Double
    let estimatedCompletionDates: [UUID: Date]

    // Engagement metrics
    let totalHighlights: Int
    let totalNotes: Int
    let highlightsPerBook: Double
    let annotationDensity: Double  // annotations per 100 pages

    // Learning metrics
    let flashcardsCreated: Int
    let flashcardsReviewed: Int
    let averageRetentionRate: Double
    let knowledgeGrowthRate: Double  // new cards mastered per week
}

// MARK: - Weekly Report

struct WeeklyReport: Identifiable, Sendable {
    let id: UUID
    let weekStartDate: Date
    let weekEndDate: Date

    // Time stats
    let totalMinutes: Int
    let dailyMinutes: [Int]  // 7 days, Sunday first
    let comparedToLastWeek: Double  // percentage change

    // Activity stats
    let pagesRead: Int
    let highlightsCreated: Int
    let flashcardsReviewed: Int
    let sessionsCompleted: Int

    // Achievements
    let streakMaintained: Bool
    let goalsAchieved: Int
    let newRecords: [String]

    // Insights
    let insights: [String]
    let suggestions: [String]

    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: weekStartDate)) - \(formatter.string(from: weekEndDate))"
    }

    var totalHours: Double {
        Double(totalMinutes) / 60.0
    }
}

// MARK: - Reading Velocity

struct ReadingVelocity: Identifiable, Sendable {
    let id: UUID
    let date: Date
    let pagesPerHour: Double
    let wordsPerMinute: Double
    let bookID: UUID?
    let sessionDuration: TimeInterval
}

// MARK: - Activity Heatmap Data

struct ActivityHeatmapData: Sendable {
    let data: [[Int]]  // 7 rows (days) x 24 columns (hours)
    let maxValue: Int
    let totalCells: Int

    init(sessions: [StudySession]) {
        var heatmap = Array(repeating: Array(repeating: 0, count: 24), count: 7)
        var maxVal = 0

        let calendar = Calendar.current

        for session in sessions {
            let weekday = calendar.component(.weekday, from: session.startTime) - 1  // 0-6
            let hour = calendar.component(.hour, from: session.startTime)

            heatmap[weekday][hour] += session.durationSeconds / 60  // Minutes
            maxVal = max(maxVal, heatmap[weekday][hour])
        }

        self.data = heatmap
        self.maxValue = maxVal
        self.totalCells = 7 * 24
    }

    func intensity(day: Int, hour: Int) -> Double {
        guard maxValue > 0 else { return 0 }
        return Double(data[day][hour]) / Double(maxValue)
    }
}

// MARK: - Achievement

struct Achievement: Identifiable, Sendable {
    let id: UUID
    let type: AchievementType
    let title: String
    let description: String
    let dateEarned: Date
    let value: Int?

    enum AchievementType: String, Sendable {
        case streak
        case pages
        case flashcards
        case books
        case time
        case consistency

        var icon: String {
            switch self {
            case .streak: return "flame.fill"
            case .pages: return "book.pages"
            case .flashcards: return "rectangle.on.rectangle"
            case .books: return "books.vertical.fill"
            case .time: return "clock.fill"
            case .consistency: return "calendar"
            }
        }

        var color: String {
            switch self {
            case .streak: return "orange"
            case .pages: return "blue"
            case .flashcards: return "purple"
            case .books: return "green"
            case .time: return "indigo"
            case .consistency: return "teal"
            }
        }
    }
}

// MARK: - Analytics Service

@MainActor
@Observable
final class AnalyticsService {

    // MARK: - Properties

    private var modelContext: ModelContext?

    var isLoading = false
    var currentAnalytics: ReadingAnalytics?
    var weeklyReport: WeeklyReport?
    var velocityHistory: [ReadingVelocity] = []
    var heatmapData: ActivityHeatmapData?
    var achievements: [Achievement] = []
    var error: Error?

    // MARK: - Singleton

    static let shared = AnalyticsService()

    private init() {}

    // MARK: - Configuration

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Load Analytics

    func loadAnalytics() async throws {
        guard let modelContext else {
            throw AnalyticsError.notConfigured
        }

        isLoading = true
        defer { isLoading = false }

        // Fetch all required data
        let sessions = try fetchSessions(days: 365)
        let books = try fetchBooks()
        let flashcards = try fetchFlashcards()
        let reviewLogs = try fetchReviewLogs(days: 365)
        let highlights = try fetchAllHighlights(books: books)

        // Generate analytics
        currentAnalytics = generateAnalytics(
            sessions: sessions,
            books: books,
            flashcards: flashcards,
            reviewLogs: reviewLogs,
            highlights: highlights
        )

        // Generate weekly report
        weeklyReport = generateWeeklyReport(sessions: sessions, flashcards: flashcards, books: books)

        // Generate velocity history
        velocityHistory = generateVelocityHistory(sessions: sessions)

        // Generate heatmap
        heatmapData = ActivityHeatmapData(sessions: sessions)

        // Check achievements
        achievements = checkAchievements(
            sessions: sessions,
            books: books,
            flashcards: flashcards,
            reviewLogs: reviewLogs
        )
    }

    // MARK: - Generate Analytics

    private func generateAnalytics(
        sessions: [StudySession],
        books: [Book],
        flashcards: [Flashcard],
        reviewLogs: [ReviewLog],
        highlights: [Highlight]
    ) -> ReadingAnalytics {

        // Time calculations
        let totalReadingTime = sessions.reduce(0) { $0 + TimeInterval($1.durationSeconds) }
        let averageSessionDuration = sessions.isEmpty ? 0 : totalReadingTime / Double(sessions.count)
        let longestSession = TimeInterval(sessions.map(\.durationSeconds).max() ?? 0)

        // Speed calculations
        let totalPages = sessions.reduce(0) { $0 + $1.pagesRead }
        let totalMinutes = totalReadingTime / 60
        let averagePagesPerMinute = totalMinutes > 0 ? Double(totalPages) / totalMinutes : 0

        // Most active time
        let hourCounts = Dictionary(grouping: sessions) {
            Calendar.current.component(.hour, from: $0.startTime)
        }.mapValues(\.count)
        let mostActiveHour = hourCounts.max { $0.value < $1.value }?.key ?? 9

        let dayCounts = Dictionary(grouping: sessions) {
            Calendar.current.component(.weekday, from: $0.startTime)
        }.mapValues(\.count)
        let mostActiveDay = dayCounts.max { $0.value < $1.value }?.key ?? 1

        // Completion metrics
        let completedBooks = books.filter(\.isCompleted).count
        let startedBooks = books.filter(\.isStarted).count
        let averageCompletion = books.isEmpty ? 0 : books.reduce(0) { $0 + $1.progress } / Double(books.count)

        // Estimate completion dates
        var estimatedCompletions: [UUID: Date] = [:]
        for book in books where !book.isCompleted && book.isStarted {
            if let estimate = estimateCompletion(for: book, sessions: sessions) {
                estimatedCompletions[book.id] = estimate
            }
        }

        // Engagement metrics
        let totalHighlights = highlights.count
        let totalNotes = highlights.filter { $0.note != nil }.count
        let highlightsPerBook = books.isEmpty ? 0 : Double(totalHighlights) / Double(books.count)
        let totalBookPages = books.reduce(0) { $0 + $1.totalPages }
        let annotationDensity = totalBookPages > 0 ? Double(totalHighlights) / Double(totalBookPages) * 100 : 0

        // Learning metrics
        let masteredCards = flashcards.filter { $0.masteryLevel == .mastered }.count
        let retentionRate = calculateRetentionRate(reviewLogs: reviewLogs)
        let weeklyMastered = calculateWeeklyMastered(flashcards: flashcards)

        return ReadingAnalytics(
            averagePagesPerMinute: averagePagesPerMinute,
            averageWordsPerMinute: averagePagesPerMinute * 250,  // Estimate 250 words per page
            fastestReadingSpeed: calculateFastestSpeed(sessions: sessions),
            slowestReadingSpeed: calculateSlowestSpeed(sessions: sessions),
            totalReadingTime: totalReadingTime,
            averageSessionDuration: averageSessionDuration,
            longestSession: longestSession,
            mostActiveHour: mostActiveHour,
            mostActiveDay: mostActiveDay,
            booksStarted: startedBooks,
            booksCompleted: completedBooks,
            averageCompletionRate: averageCompletion,
            estimatedCompletionDates: estimatedCompletions,
            totalHighlights: totalHighlights,
            totalNotes: totalNotes,
            highlightsPerBook: highlightsPerBook,
            annotationDensity: annotationDensity,
            flashcardsCreated: flashcards.count,
            flashcardsReviewed: reviewLogs.count,
            averageRetentionRate: retentionRate,
            knowledgeGrowthRate: weeklyMastered
        )
    }

    // MARK: - Generate Weekly Report

    private func generateWeeklyReport(
        sessions: [StudySession],
        flashcards: [Flashcard],
        books: [Book]
    ) -> WeeklyReport {

        let calendar = Calendar.current
        let now = Date()

        // Get this week's start
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!

        // Filter sessions for this week
        let weekSessions = sessions.filter {
            $0.startTime >= weekStart && $0.startTime <= weekEnd
        }

        // Daily breakdown
        var dailyMinutes = [Int](repeating: 0, count: 7)
        for session in weekSessions {
            let weekday = calendar.component(.weekday, from: session.startTime) - 1
            dailyMinutes[weekday] += session.durationSeconds / 60
        }

        let totalMinutes = dailyMinutes.reduce(0, +)

        // Compare to last week
        let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: weekStart)!
        let lastWeekSessions = sessions.filter {
            $0.startTime >= lastWeekStart && $0.startTime < weekStart
        }
        let lastWeekMinutes = lastWeekSessions.reduce(0) { $0 + $1.durationSeconds / 60 }
        let comparison = lastWeekMinutes > 0 ? Double(totalMinutes - lastWeekMinutes) / Double(lastWeekMinutes) * 100 : 0

        // Activity stats
        let pagesRead = weekSessions.reduce(0) { $0 + $1.pagesRead }
        let highlightsCreated = weekSessions.reduce(0) { $0 + $1.highlightsCreated }
        let flashcardsReviewed = weekSessions.reduce(0) { $0 + $1.flashcardsReviewed }

        // Generate insights
        let insights = generateInsights(dailyMinutes: dailyMinutes, totalMinutes: totalMinutes)
        let suggestions = generateSuggestions(dailyMinutes: dailyMinutes, pagesRead: pagesRead)

        return WeeklyReport(
            id: UUID(),
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalMinutes: totalMinutes,
            dailyMinutes: dailyMinutes,
            comparedToLastWeek: comparison,
            pagesRead: pagesRead,
            highlightsCreated: highlightsCreated,
            flashcardsReviewed: flashcardsReviewed,
            sessionsCompleted: weekSessions.count,
            streakMaintained: true,  // Would check actual streak
            goalsAchieved: dailyMinutes.filter { $0 >= 30 }.count,  // Assuming 30 min daily goal
            newRecords: [],
            insights: insights,
            suggestions: suggestions
        )
    }

    // MARK: - Generate Velocity History

    private func generateVelocityHistory(sessions: [StudySession]) -> [ReadingVelocity] {
        sessions.compactMap { session in
            guard session.durationSeconds > 0, session.pagesRead > 0 else { return nil }

            let hours = Double(session.durationSeconds) / 3600
            let pagesPerHour = Double(session.pagesRead) / hours

            return ReadingVelocity(
                id: UUID(),
                date: session.startTime,
                pagesPerHour: pagesPerHour,
                wordsPerMinute: pagesPerHour * 250 / 60,
                bookID: session.bookID,
                sessionDuration: TimeInterval(session.durationSeconds)
            )
        }
    }

    // MARK: - Check Achievements

    private func checkAchievements(
        sessions: [StudySession],
        books: [Book],
        flashcards: [Flashcard],
        reviewLogs: [ReviewLog]
    ) -> [Achievement] {

        var achievements: [Achievement] = []

        // Streak achievements
        // (Would check actual streak from StudyStreak model)

        // Pages achievements
        let totalPages = sessions.reduce(0) { $0 + $1.pagesRead }
        if totalPages >= 100 {
            achievements.append(Achievement(
                id: UUID(),
                type: .pages,
                title: "Century Reader",
                description: "Read 100 pages",
                dateEarned: Date(),
                value: 100
            ))
        }
        if totalPages >= 500 {
            achievements.append(Achievement(
                id: UUID(),
                type: .pages,
                title: "Bookworm",
                description: "Read 500 pages",
                dateEarned: Date(),
                value: 500
            ))
        }

        // Flashcard achievements
        let masteredCards = flashcards.filter { $0.masteryLevel == .mastered }.count
        if masteredCards >= 50 {
            achievements.append(Achievement(
                id: UUID(),
                type: .flashcards,
                title: "Knowledge Keeper",
                description: "Mastered 50 flashcards",
                dateEarned: Date(),
                value: 50
            ))
        }

        // Book achievements
        let completedBooks = books.filter(\.isCompleted).count
        if completedBooks >= 1 {
            achievements.append(Achievement(
                id: UUID(),
                type: .books,
                title: "First Completion",
                description: "Completed your first book",
                dateEarned: Date(),
                value: 1
            ))
        }

        // Time achievements
        let totalHours = sessions.reduce(0) { $0 + $1.durationSeconds } / 3600
        if totalHours >= 10 {
            achievements.append(Achievement(
                id: UUID(),
                type: .time,
                title: "Dedicated Learner",
                description: "10 hours of study time",
                dateEarned: Date(),
                value: 10
            ))
        }

        return achievements
    }

    // MARK: - Helper Methods

    private func estimateCompletion(for book: Book, sessions: [StudySession]) -> Date? {
        let bookSessions = sessions.filter { $0.bookID == book.id }
        guard !bookSessions.isEmpty else { return nil }

        let totalMinutes = bookSessions.reduce(0) { $0 + $1.durationSeconds / 60 }
        let totalPages = bookSessions.reduce(0) { $0 + $1.pagesRead }

        guard totalPages > 0 else { return nil }

        let minutesPerPage = Double(totalMinutes) / Double(totalPages)
        let remainingPages = book.totalPages - book.currentPage
        let remainingMinutes = Double(remainingPages) * minutesPerPage

        // Estimate based on average daily reading time
        let avgDailyMinutes = Double(totalMinutes) / max(1, Double(Set(bookSessions.map {
            Calendar.current.startOfDay(for: $0.startTime)
        }).count))

        let daysRemaining = remainingMinutes / avgDailyMinutes

        return Calendar.current.date(byAdding: .day, value: Int(daysRemaining), to: Date())
    }

    private func calculateFastestSpeed(sessions: [StudySession]) -> Double {
        sessions.compactMap { session -> Double? in
            guard session.durationSeconds > 60, session.pagesRead > 0 else { return nil }
            return Double(session.pagesRead) / (Double(session.durationSeconds) / 60)
        }.max() ?? 0
    }

    private func calculateSlowestSpeed(sessions: [StudySession]) -> Double {
        sessions.compactMap { session -> Double? in
            guard session.durationSeconds > 60, session.pagesRead > 0 else { return nil }
            return Double(session.pagesRead) / (Double(session.durationSeconds) / 60)
        }.min() ?? 0
    }

    private func calculateRetentionRate(reviewLogs: [ReviewLog]) -> Double {
        guard !reviewLogs.isEmpty else { return 0 }
        let successfulReviews = reviewLogs.filter { $0.qualityRaw >= 2 }.count
        return Double(successfulReviews) / Double(reviewLogs.count)
    }

    private func calculateWeeklyMastered(flashcards: [Flashcard]) -> Double {
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

        let recentlyMastered = flashcards.filter {
            $0.masteryLevel == .mastered && $0.dateModified > oneWeekAgo
        }.count

        return Double(recentlyMastered)
    }

    private func generateInsights(dailyMinutes: [Int], totalMinutes: Int) -> [String] {
        var insights: [String] = []

        let avgDaily = totalMinutes / 7
        if avgDaily > 30 {
            insights.append("Excellent consistency! You're averaging \(avgDaily) minutes per day.")
        }

        let activeDays = dailyMinutes.filter { $0 > 0 }.count
        if activeDays >= 5 {
            insights.append("You studied \(activeDays) out of 7 days this week. Great dedication!")
        }

        if let maxDay = dailyMinutes.enumerated().max(by: { $0.element < $1.element }) {
            let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            insights.append("Your most productive day was \(dayNames[maxDay.offset]) with \(maxDay.element) minutes.")
        }

        return insights
    }

    private func generateSuggestions(dailyMinutes: [Int], pagesRead: Int) -> [String] {
        var suggestions: [String] = []

        let zeroDays = dailyMinutes.filter { $0 == 0 }.count
        if zeroDays > 2 {
            suggestions.append("Try to study a little each day, even just 10 minutes, to maintain momentum.")
        }

        if pagesRead < 20 {
            suggestions.append("Set a small daily page goal to gradually increase your reading pace.")
        }

        suggestions.append("Remember: 'Seeking knowledge is an obligation upon every Muslim.'")

        return suggestions
    }

    // MARK: - Data Fetching

    private func fetchSessions(days: Int) throws -> [StudySession] {
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
        return try modelContext.fetch(FetchDescriptor<Book>())
    }

    private func fetchFlashcards() throws -> [Flashcard] {
        guard let modelContext else { return [] }
        return try modelContext.fetch(FetchDescriptor<Flashcard>())
    }

    private func fetchReviewLogs(days: Int) throws -> [ReviewLog] {
        guard let modelContext else { return [] }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<ReviewLog>(
            predicate: #Predicate { $0.reviewDate >= cutoff }
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchAllHighlights(books: [Book]) throws -> [Highlight] {
        var allHighlights: [Highlight] = []
        for book in books {
            allHighlights.append(contentsOf: book.highlights)
        }
        return allHighlights
    }
}

// MARK: - Errors

enum AnalyticsError: LocalizedError {
    case notConfigured
    case dataFetchFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Analytics service not configured"
        case .dataFetchFailed(let reason):
            return "Failed to fetch data: \(reason)"
        }
    }
}
