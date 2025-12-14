// StudySessionService.swift
// NoorReader
//
// Manages active and historical study sessions

import SwiftData
import Foundation
import Combine

/// Manages active and historical study sessions
@MainActor
@Observable
final class StudySessionService {

    // MARK: - Singleton

    static let shared = StudySessionService()

    // MARK: - Properties

    private var modelContext: ModelContext?
    private var timer: Timer?
    private var breakCheckTimer: Timer?

    var activeSession: StudySession?
    var elapsedSeconds: Int = 0
    var isSessionActive: Bool { activeSession != nil }

    // Break reminder settings
    var breakIntervalMinutes: Int = 25  // Pomodoro default
    var breakDurationMinutes: Int = 5
    var lastBreakTime: Date?
    var shouldShowBreakReminder: Bool = false

    // Callbacks
    var onBreakReminder: (() -> Void)?
    var onSessionEnded: ((StudySession) -> Void)?

    // MARK: - Initialization

    private init() {}

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext

        // Load settings from UserDefaults
        breakIntervalMinutes = UserDefaults.standard.integer(forKey: "breakIntervalMinutes")
        if breakIntervalMinutes == 0 {
            breakIntervalMinutes = 25
        }

        breakDurationMinutes = UserDefaults.standard.integer(forKey: "breakDurationMinutes")
        if breakDurationMinutes == 0 {
            breakDurationMinutes = 5
        }
    }

    // MARK: - Session Lifecycle

    func startSession(
        type: SessionType = .mixed,
        book: Book? = nil,
        focusMode: Bool = false
    ) throws {
        guard let modelContext else {
            throw SessionError.notConfigured
        }

        // End any existing session
        if activeSession != nil {
            try endSession()
        }

        // Create new session
        let session = StudySession(
            type: type,
            bookID: book?.id,
            bookTitle: book?.title
        )
        session.focusModeUsed = focusMode

        modelContext.insert(session)
        try modelContext.save()

        activeSession = session
        elapsedSeconds = 0
        lastBreakTime = Date()
        shouldShowBreakReminder = false

        startTimers()
    }

    func endSession() throws {
        guard let modelContext, let session = activeSession else { return }

        session.end()
        try modelContext.save()

        stopTimers()

        // Notify callback
        onSessionEnded?(session)

        activeSession = nil
        elapsedSeconds = 0
        shouldShowBreakReminder = false
    }

    func pauseSession() {
        stopTimers()
    }

    func resumeSession() {
        guard activeSession != nil else { return }
        startTimers()
    }

    // MARK: - Timer Management

    private func startTimers() {
        // Elapsed time timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.elapsedSeconds += 1
                self?.activeSession?.updateDuration()
            }
        }

        // Break reminder timer
        breakCheckTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkBreakReminder()
            }
        }
    }

    private func stopTimers() {
        timer?.invalidate()
        timer = nil
        breakCheckTimer?.invalidate()
        breakCheckTimer = nil
    }

    private func checkBreakReminder() {
        guard let lastBreak = lastBreakTime else { return }

        let minutesSinceBreak = Int(Date().timeIntervalSince(lastBreak) / 60)

        if minutesSinceBreak >= breakIntervalMinutes && !shouldShowBreakReminder {
            shouldShowBreakReminder = true
            onBreakReminder?()
        }
    }

    func takeBreak() {
        lastBreakTime = Date()
        shouldShowBreakReminder = false
        activeSession?.addBreak()
    }

    func dismissBreakReminder() {
        shouldShowBreakReminder = false
        lastBreakTime = Date()  // Reset the timer
    }

    // MARK: - Activity Tracking

    func trackPageRead() {
        activeSession?.addPage()
    }

    func trackHighlightCreated() {
        activeSession?.addHighlight()
    }

    func trackNoteCreated() {
        activeSession?.addNote()
    }

    func trackFlashcardReviewed() {
        activeSession?.addFlashcardReview()
    }

    // MARK: - Settings

    func updateBreakInterval(minutes: Int) {
        breakIntervalMinutes = max(5, min(120, minutes))
        UserDefaults.standard.set(breakIntervalMinutes, forKey: "breakIntervalMinutes")
    }

    func updateBreakDuration(minutes: Int) {
        breakDurationMinutes = max(1, min(30, minutes))
        UserDefaults.standard.set(breakDurationMinutes, forKey: "breakDurationMinutes")
    }

    // MARK: - Formatted Time

    var formattedElapsedTime: String {
        let hours = elapsedSeconds / 3600
        let minutes = (elapsedSeconds % 3600) / 60
        let seconds = elapsedSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var elapsedMinutes: Int {
        elapsedSeconds / 60
    }

    // MARK: - History

    func fetchSessions(
        from startDate: Date? = nil,
        to endDate: Date? = nil,
        limit: Int = 50
    ) throws -> [StudySession] {
        guard let modelContext else { return [] }

        var descriptor = FetchDescriptor<StudySession>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        if let start = startDate, let end = endDate {
            descriptor.predicate = #Predicate<StudySession> {
                $0.startTime >= start && $0.startTime <= end
            }
        }

        descriptor.fetchLimit = limit

        return try modelContext.fetch(descriptor)
    }

    func fetchTodaySessions() throws -> [StudySession] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return try fetchSessions(from: startOfDay, to: endOfDay)
    }

    func fetchWeekSessions() throws -> [StudySession] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(byAdding: .day, value: -7, to: Date())!

        return try fetchSessions(from: startOfWeek, to: Date(), limit: 200)
    }

    func getTodayTotalMinutes() throws -> Int {
        let sessions = try fetchTodaySessions()
        let totalSeconds = sessions.reduce(0) { $0 + $1.durationSeconds }
        return totalSeconds / 60
    }

    func getThisWeekTotalMinutes() throws -> Int {
        let sessions = try fetchWeekSessions()
        let totalSeconds = sessions.reduce(0) { $0 + $1.durationSeconds }
        return totalSeconds / 60
    }

    // MARK: - Statistics

    func getSessionStats() throws -> SessionStats {
        let allSessions = try fetchSessions(limit: 1000)
        let todaySessions = try fetchTodaySessions()

        let totalSeconds = allSessions.reduce(0) { $0 + $1.durationSeconds }
        let todaySeconds = todaySessions.reduce(0) { $0 + $1.durationSeconds }

        let avgSeconds = allSessions.isEmpty ? 0 : totalSeconds / allSessions.count

        return SessionStats(
            totalSessions: allSessions.count,
            totalMinutes: totalSeconds / 60,
            todayMinutes: todaySeconds / 60,
            averageSessionMinutes: avgSeconds / 60,
            totalPagesRead: allSessions.reduce(0) { $0 + $1.pagesRead },
            totalHighlights: allSessions.reduce(0) { $0 + $1.highlightsCreated },
            totalFlashcardsReviewed: allSessions.reduce(0) { $0 + $1.flashcardsReviewed }
        )
    }
}

// MARK: - Supporting Types

struct SessionStats {
    let totalSessions: Int
    let totalMinutes: Int
    let todayMinutes: Int
    let averageSessionMinutes: Int
    let totalPagesRead: Int
    let totalHighlights: Int
    let totalFlashcardsReviewed: Int

    var formattedTotalTime: String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var formattedTodayTime: String {
        let hours = todayMinutes / 60
        let minutes = todayMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Errors

enum SessionError: LocalizedError {
    case notConfigured
    case noActiveSession

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Study session service not configured"
        case .noActiveSession:
            return "No active study session"
        }
    }
}
