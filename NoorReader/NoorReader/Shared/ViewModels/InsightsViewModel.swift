// InsightsViewModel.swift
// NoorReader
//
// ViewModel for reading insights and analytics UI

import Foundation
import SwiftData

/// ViewModel for managing analytics state and operations
@MainActor
@Observable
final class InsightsViewModel {

    // MARK: - Properties

    private let analyticsService: AnalyticsService
    private var modelContext: ModelContext?

    // State
    var isLoading = false
    var analytics: ReadingAnalytics?
    var weeklyReport: WeeklyReport?
    var velocityHistory: [ReadingVelocity] = []
    var heatmapData: ActivityHeatmapData?
    var achievements: [Achievement] = []

    // Filters
    var selectedTimeRange: TimeRange = .month

    // Error handling
    var error: Error?
    var showError = false

    // MARK: - Computed Properties

    var hasData: Bool {
        analytics != nil
    }

    var totalStudyHours: String {
        guard let analytics else { return "0h" }
        let hours = Int(analytics.totalReadingTime / 3600)
        let minutes = Int((analytics.totalReadingTime.truncatingRemainder(dividingBy: 3600)) / 60)
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }

    var averageSessionTime: String {
        guard let analytics else { return "0m" }
        let minutes = Int(analytics.averageSessionDuration / 60)
        return "\(minutes)m"
    }

    var readingSpeedDescription: String {
        guard let analytics else { return "N/A" }
        let wpm = Int(analytics.averageWordsPerMinute)
        return "\(wpm) words/min"
    }

    var completionRatePercent: Int {
        guard let analytics else { return 0 }
        return Int(analytics.averageCompletionRate * 100)
    }

    var retentionRatePercent: Int {
        guard let analytics else { return 0 }
        return Int(analytics.averageRetentionRate * 100)
    }

    var weeklyComparisonText: String {
        guard let report = weeklyReport else { return "" }
        let change = report.comparedToLastWeek
        let direction = change >= 0 ? "+" : ""
        return "\(direction)\(Int(change))% vs last week"
    }

    var weeklyComparisonIsPositive: Bool {
        weeklyReport?.comparedToLastWeek ?? 0 >= 0
    }

    var mostProductiveHour: String {
        guard let analytics else { return "N/A" }
        let hour = analytics.mostActiveHour
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }

    var mostProductiveDay: String {
        guard let analytics else { return "N/A" }
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return days[analytics.mostActiveDay - 1]
    }

    // MARK: - Initialization

    init() {
        self.analyticsService = AnalyticsService.shared
    }

    // MARK: - Configuration

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        analyticsService.configure(modelContext: modelContext)
    }

    // MARK: - Data Loading

    func loadAnalytics() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            try await analyticsService.loadAnalytics()
            analytics = analyticsService.currentAnalytics
            weeklyReport = analyticsService.weeklyReport
            velocityHistory = analyticsService.velocityHistory
            heatmapData = analyticsService.heatmapData
            achievements = analyticsService.achievements
        } catch {
            self.error = error
            showError = true
        }

        isLoading = false
    }

    func refreshData() async {
        await loadAnalytics()
    }

    // MARK: - Time Range

    func setTimeRange(_ range: TimeRange) {
        selectedTimeRange = range
        // Reload data with new range
        Task {
            await loadAnalytics()
        }
    }

    // MARK: - Velocity Chart Data

    var velocityChartData: [(date: Date, value: Double)] {
        velocityHistory
            .sorted { $0.date < $1.date }
            .suffix(30)  // Last 30 data points
            .map { ($0.date, $0.pagesPerHour) }
    }

    // MARK: - Weekly Activity Data

    var weeklyActivityData: [(day: String, minutes: Int)] {
        guard let report = weeklyReport else {
            return []
        }

        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return zip(days, report.dailyMinutes).map { ($0, $1) }
    }

    // MARK: - Completion Estimates

    var bookCompletionEstimates: [(bookID: UUID, estimatedDate: Date)] {
        guard let analytics else { return [] }
        return analytics.estimatedCompletionDates.map { ($0.key, $0.value) }
            .sorted { $0.estimatedDate < $1.estimatedDate }
    }
}

// MARK: - Time Range

enum TimeRange: String, CaseIterable, Identifiable {
    case week = "week"
    case month = "month"
    case year = "year"
    case allTime = "all_time"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .week: return "This Week"
        case .month: return "This Month"
        case .year: return "This Year"
        case .allTime: return "All Time"
        }
    }

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .year: return 365
        case .allTime: return 3650  // ~10 years
        }
    }
}

// MARK: - Summary Stats

extension InsightsViewModel {

    struct SummaryStats {
        let totalHours: Double
        let booksCompleted: Int
        let pagesRead: Int
        let flashcardsMastered: Int
        let currentStreak: Int
        let highlightsCreated: Int
    }

    var summaryStats: SummaryStats {
        SummaryStats(
            totalHours: (analytics?.totalReadingTime ?? 0) / 3600,
            booksCompleted: analytics?.booksCompleted ?? 0,
            pagesRead: 0,  // Would calculate from sessions
            flashcardsMastered: 0,  // Would calculate from flashcards
            currentStreak: 0,  // Would get from StudyStreak
            highlightsCreated: analytics?.totalHighlights ?? 0
        )
    }
}
