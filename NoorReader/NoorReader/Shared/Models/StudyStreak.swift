// StudyStreak.swift
// NoorReader
//
// SwiftData model for tracking study streaks and goals

import SwiftData
import Foundation

/// Tracks daily study streaks and goals
@Model
final class StudyStreak {
    var id: UUID
    var currentStreak: Int
    var longestStreak: Int
    var lastStudyDate: Date?

    // Daily goal
    var dailyGoalMinutes: Int
    var todayMinutes: Int
    var todayDate: Date?  // Track which day todayMinutes is for

    // Weekly goal
    var weeklyGoalDays: Int

    // Total stats
    var totalStudyDays: Int
    var totalMinutes: Int
    var totalFlashcardsReviewed: Int
    var totalPagesRead: Int

    var hasStudiedToday: Bool {
        guard let lastDate = lastStudyDate else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }

    var goalProgressPercent: Double {
        guard dailyGoalMinutes > 0 else { return 0 }
        return min(1.0, Double(todayMinutes) / Double(dailyGoalMinutes))
    }

    var hasMetDailyGoal: Bool {
        todayMinutes >= dailyGoalMinutes
    }

    var formattedTodayTime: String {
        let hours = todayMinutes / 60
        let minutes = todayMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var formattedTotalTime: String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    init() {
        self.id = UUID()
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastStudyDate = nil
        self.dailyGoalMinutes = 30  // Default 30 min/day
        self.todayMinutes = 0
        self.todayDate = nil
        self.weeklyGoalDays = 5  // Default 5 days/week
        self.totalStudyDays = 0
        self.totalMinutes = 0
        self.totalFlashcardsReviewed = 0
        self.totalPagesRead = 0
    }

    /// Records study activity and updates streak
    func recordStudy(minutes: Int, flashcards: Int = 0, pages: Int = 0) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Reset today's minutes if it's a new day
        if let storedDate = todayDate {
            let storedDay = calendar.startOfDay(for: storedDate)
            if storedDay != today {
                todayMinutes = 0
            }
        }
        todayDate = Date()

        // Check if this is a new day for streak
        if let lastDate = lastStudyDate {
            let lastDay = calendar.startOfDay(for: lastDate)

            if lastDay == today {
                // Same day - just add time
                todayMinutes += minutes
            } else {
                // Different day
                let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

                if daysBetween == 1 {
                    // Consecutive day - extend streak
                    currentStreak += 1
                } else if daysBetween > 1 {
                    // Streak broken
                    currentStreak = 1
                }

                todayMinutes = minutes
                totalStudyDays += 1
            }
        } else {
            // First study session ever
            currentStreak = 1
            todayMinutes = minutes
            totalStudyDays = 1
        }

        lastStudyDate = Date()
        totalMinutes += minutes
        totalFlashcardsReviewed += flashcards
        totalPagesRead += pages

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
    }

    /// Check and update streak status (call at app launch)
    func checkStreakStatus() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Reset today's minutes if it's a new day
        if let storedDate = todayDate {
            let storedDay = calendar.startOfDay(for: storedDate)
            if storedDay != today {
                todayMinutes = 0
                todayDate = today
            }
        }

        // Check if streak should be reset
        guard let lastDate = lastStudyDate else { return }

        let lastDay = calendar.startOfDay(for: lastDate)
        let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

        // If more than 1 day has passed without study, streak is broken
        if daysBetween > 1 {
            currentStreak = 0
        }
    }

    func resetTodayProgress() {
        todayMinutes = 0
        todayDate = Date()
    }

    func updateDailyGoal(minutes: Int) {
        dailyGoalMinutes = max(5, min(480, minutes))  // 5 min to 8 hours
    }

    func updateWeeklyGoal(days: Int) {
        weeklyGoalDays = max(1, min(7, days))
    }
}
