// StatsViewModel.swift
// NoorReader
//
// View model for study statistics dashboard

import SwiftUI
import SwiftData

/// View model for study statistics dashboard
@MainActor
@Observable
final class StatsViewModel {

    // MARK: - Dependencies

    private var modelContext: ModelContext?
    private let sessionService = StudySessionService.shared
    private let flashcardService = FlashcardService.shared

    // MARK: - State

    var streak: StudyStreak?
    var recentSessions: [StudySession] = []
    var weeklyActivity: [DayActivity] = []
    var isLoading = false
    var error: Error?

    // Card stats
    var totalCards: Int = 0
    var newCards: Int = 0
    var learningCards: Int = 0
    var dueCards: Int = 0
    var masteredCards: Int = 0

    // Session stats
    var totalStudyTime: String = "0h"
    var averageSessionLength: String = "0m"
    var todayStudyTime: String = "0m"
    var thisWeekStudyTime: String = "0h"
    var cardsReviewedThisWeek: Int = 0
    var pagesReadThisWeek: Int = 0

    // MARK: - Initialization

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data Loading

    func loadStats() async {
        guard let modelContext else { return }

        isLoading = true
        error = nil

        do {
            // Load or create streak
            streak = try await loadOrCreateStreak()

            // Check streak status (may reset if user missed a day)
            streak?.checkStreakStatus()
            try modelContext.save()

            // Load recent sessions
            recentSessions = try sessionService.fetchSessions(limit: 50)

            // Calculate weekly activity
            weeklyActivity = calculateWeeklyActivity()

            // Calculate card stats
            await loadCardStats()

            // Calculate aggregate stats
            try calculateAggregateStats()

        } catch {
            self.error = error
        }

        isLoading = false
    }

    private func loadOrCreateStreak() async throws -> StudyStreak {
        guard let modelContext else {
            throw StatsError.notConfigured
        }

        let descriptor = FetchDescriptor<StudyStreak>()
        let streaks = try modelContext.fetch(descriptor)

        if let existingStreak = streaks.first {
            return existingStreak
        } else {
            let newStreak = StudyStreak()
            modelContext.insert(newStreak)
            try modelContext.save()
            return newStreak
        }
    }

    private func loadCardStats() async {
        do {
            let counts = try await flashcardService.getCardCounts()
            newCards = counts.new
            learningCards = counts.learning
            dueCards = counts.due

            totalCards = try flashcardService.getTotalCardCount()

            // Calculate mastered (cards with 6+ successful reviews)
            let allCards = try flashcardService.fetchAllFlashcards()
            masteredCards = allCards.filter { $0.repetitions >= 6 }.count
        } catch {
            // Ignore card loading errors
        }
    }

    private func calculateWeeklyActivity() -> [DayActivity] {
        let calendar = Calendar.current
        let today = Date()
        var activities: [DayActivity] = []

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let sessionsForDay = recentSessions.filter {
                $0.startTime >= startOfDay && $0.startTime < endOfDay
            }

            let totalMinutes = sessionsForDay.reduce(0) { $0 + $1.durationSeconds } / 60

            activities.append(DayActivity(
                date: date,
                minutes: totalMinutes,
                flashcardsReviewed: sessionsForDay.reduce(0) { $0 + $1.flashcardsReviewed },
                pagesRead: sessionsForDay.reduce(0) { $0 + $1.pagesRead }
            ))
        }

        return activities
    }

    private func calculateAggregateStats() throws {
        // Today's study time
        let todayMinutes = try sessionService.getTodayTotalMinutes()
        todayStudyTime = formatMinutes(todayMinutes)

        // This week's study time
        let weekMinutes = try sessionService.getThisWeekTotalMinutes()
        thisWeekStudyTime = formatMinutes(weekMinutes)

        // Total study time (from streak)
        if let streak = streak {
            totalStudyTime = formatMinutes(streak.totalMinutes)
        }

        // Average session length
        if !recentSessions.isEmpty {
            let avgSeconds = recentSessions.reduce(0) { $0 + $1.durationSeconds } / recentSessions.count
            averageSessionLength = formatMinutes(avgSeconds / 60)
        }

        // This week's cards and pages
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let thisWeekSessions = recentSessions.filter { $0.startTime >= weekAgo }

        cardsReviewedThisWeek = thisWeekSessions.reduce(0) { $0 + $1.flashcardsReviewed }
        pagesReadThisWeek = thisWeekSessions.reduce(0) { $0 + $1.pagesRead }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }

    // MARK: - Actions

    func recordStudyTime(minutes: Int, flashcards: Int = 0, pages: Int = 0) {
        streak?.recordStudy(minutes: minutes, flashcards: flashcards, pages: pages)
        try? modelContext?.save()
    }

    func updateDailyGoal(minutes: Int) {
        streak?.updateDailyGoal(minutes: minutes)
        try? modelContext?.save()
    }

    func updateWeeklyGoal(days: Int) {
        streak?.updateWeeklyGoal(days: days)
        try? modelContext?.save()
    }
}

// MARK: - Supporting Types

struct DayActivity: Identifiable {
    let id = UUID()
    let date: Date
    let minutes: Int
    let flashcardsReviewed: Int
    let pagesRead: Int

    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    var shortDayName: String {
        String(dayName.prefix(1))
    }

    var intensity: Double {
        // Normalize to 0-1 range (60 min = full intensity)
        min(1.0, Double(minutes) / 60.0)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

// MARK: - Errors

enum StatsError: LocalizedError {
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Stats service not configured"
        }
    }
}
