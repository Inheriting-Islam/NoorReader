// ReminderService.swift
// NoorReader
//
// Enhanced Islamic content delivery service with multiple triggers

import Foundation
import SwiftUI

@MainActor
@Observable
final class ReminderService {
    static let shared = ReminderService()

    enum ReminderTrigger {
        case appLaunch
        case sessionStart
        case studyBreak(minutes: Int)
        case bookCompletion
        case highlightCreated(count: Int)
        case dailyReminder
    }

    // Current reminder being displayed
    var currentReminder: IslamicReminder?
    var showReminder = false

    // Settings
    private(set) var showLaunchDua: Bool
    private(set) var dailyReminder: IslamicReminder

    // Statistics for triggers
    private var highlightCount = 0
    private var sessionStartTime: Date?
    private var lastBreakReminder: Date?

    private init() {
        // Get a random reminder for the day
        self.dailyReminder = Self.getRandomReminder()

        // Check if launch dua should be shown (default: true)
        self.showLaunchDua = UserDefaults.standard.object(forKey: "showLaunchDua") as? Bool ?? true
    }

    // MARK: - Trigger Handlers

    func onAppLaunch() {
        currentReminder = IslamicReminder.launchDua
        showReminder = true
    }

    func onSessionStart() {
        sessionStartTime = Date()
        currentReminder = getRandomReminder(for: .sessionStart)
        showReminder = true
    }

    func onHighlightCreated() {
        highlightCount += 1

        // Show encouragement every 5 highlights
        if highlightCount % 5 == 0 {
            currentReminder = getRandomReminder(for: .highlightCreated(count: highlightCount))
            showReminder = true
        }
    }

    func checkForBreakReminder() {
        guard let sessionStart = sessionStartTime else { return }

        let minutesElapsed = Int(Date().timeIntervalSince(sessionStart) / 60)

        // Remind every 45 minutes
        if minutesElapsed >= 45 {
            if lastBreakReminder == nil ||
               Date().timeIntervalSince(lastBreakReminder!) >= 45 * 60 {
                currentReminder = getRandomReminder(for: .studyBreak(minutes: minutesElapsed))
                showReminder = true
                lastBreakReminder = Date()
            }
        }
    }

    func onBookCompletion(book: Book) {
        currentReminder = IslamicReminder.bookCompletionDua(bookTitle: book.displayTitle)
        showReminder = true
    }

    func dismiss() {
        withAnimation {
            showReminder = false
        }

        // Clear after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.currentReminder = nil
        }
    }

    // MARK: - Public Methods

    func dismissLaunchDua() {
        showLaunchDua = false
    }

    func setShowLaunchDuaPreference(_ show: Bool) {
        UserDefaults.standard.set(show, forKey: "showLaunchDua")
    }

    func refreshDailyReminder() {
        dailyReminder = Self.getRandomReminder()
    }

    // MARK: - Content Selection

    private func getRandomReminder(for trigger: ReminderTrigger) -> IslamicReminder {
        switch trigger {
        case .appLaunch:
            return .launchDua

        case .sessionStart:
            return sessionStartReminders.randomElement() ?? .launchDua

        case .studyBreak(let minutes):
            return breakReminder(minutes: minutes)

        case .bookCompletion:
            return completionReminders.randomElement() ?? .launchDua

        case .highlightCreated(let count):
            return highlightEncouragement(count: count)

        case .dailyReminder:
            return dailyReminders.randomElement() ?? .launchDua
        }
    }

    private static func getRandomReminder() -> IslamicReminder {
        // Use date-based seed for consistent daily reminder
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        let seed = (components.year ?? 0) * 10000 + (components.month ?? 0) * 100 + (components.day ?? 0)

        var rng = SeededRandomNumberGenerator(seed: UInt64(seed))
        let reminders = IslamicReminder.studyDuas
        let index = Int.random(in: 0..<reminders.count, using: &rng)

        return reminders[index]
    }

    // MARK: - Reminder Content

    private var sessionStartReminders: [IslamicReminder] {
        [
            IslamicReminder(
                id: UUID(),
                type: .hadith,
                arabic: "مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الْجَنَّةِ",
                transliteration: "Man salaka tareeqan yaltamisu feehi 'ilman sahhala Allahu lahu bihi tareeqan ila al-jannah",
                english: "Whoever takes a path seeking knowledge, Allah will make easy for him a path to Paradise.",
                source: "Sahih Muslim",
                category: "seeking_knowledge"
            ),
            IslamicReminder(
                id: UUID(),
                type: .hadith,
                arabic: "طَلَبُ الْعِلْمِ فَرِيضَةٌ عَلَى كُلِّ مُسْلِمٍ",
                transliteration: "Talab al-'ilm fareeda 'ala kulli muslim",
                english: "Seeking knowledge is an obligation upon every Muslim.",
                source: "Ibn Majah",
                category: "seeking_knowledge"
            ),
            IslamicReminder(
                id: UUID(),
                type: .dua,
                arabic: "اللَّهُمَّ انْفَعْنِي بِمَا عَلَّمْتَنِي وَعَلِّمْنِي مَا يَنْفَعُنِي",
                transliteration: "Allahumma infa'ni bima 'allamtani wa 'allimni ma yanfa'uni",
                english: "O Allah, benefit me with what You have taught me, and teach me what will benefit me.",
                source: "Ibn Majah",
                category: "seeking_knowledge"
            )
        ]
    }

    private func breakReminder(minutes: Int) -> IslamicReminder {
        IslamicReminder(
            id: UUID(),
            type: .reminder,
            arabic: "وَاسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ",
            transliteration: "Wasta'eenu bis-sabri was-salah",
            english: "You have been studying for \(minutes) minutes. Take a break, stretch, and if it's prayer time, don't delay your salah.",
            source: "Quran 2:45",
            category: "reminder"
        )
    }

    private var completionReminders: [IslamicReminder] {
        [
            IslamicReminder(
                id: UUID(),
                type: .dua,
                arabic: "الْحَمْدُ لِلَّهِ الَّذِي بِنِعْمَتِهِ تَتِمُّ الصَّالِحَاتُ",
                transliteration: "Alhamdulillahil-ladhi bi ni'matihi tatimmus-salihat",
                english: "All praise is due to Allah, by Whose grace good deeds are completed.",
                source: "Ibn Majah",
                category: "gratitude"
            )
        ]
    }

    private func highlightEncouragement(count: Int) -> IslamicReminder {
        IslamicReminder(
            id: UUID(),
            type: .reminder,
            arabic: "مَا شَاءَ اللَّه",
            transliteration: "Ma sha Allah",
            english: "Masha'Allah! You've made \(count) highlights. May Allah bless your efforts in seeking knowledge.",
            source: "",
            category: "encouragement"
        )
    }

    private var dailyReminders: [IslamicReminder] {
        [
            IslamicReminder(
                id: UUID(),
                type: .hadith,
                arabic: "الْكَلِمَةُ الْحِكْمَةُ ضَالَّةُ الْمُؤْمِنِ",
                transliteration: "Al-kalimatul-hikmah daalatul-mu'min",
                english: "Wisdom is the lost property of the believer. Wherever he finds it, he has the most right to it.",
                source: "Tirmidhi",
                category: "wisdom"
            ),
            IslamicReminder(
                id: UUID(),
                type: .hadith,
                arabic: "اقْرَأْ وَارْتَقِ",
                transliteration: "Iqra' wa artaqi",
                english: "Read and ascend (in ranks).",
                source: "Abu Dawud, Tirmidhi",
                category: "reading"
            )
        ]
    }
}

// MARK: - Additional IslamicReminder initializers

extension IslamicReminder {
    static func bookCompletionDua(bookTitle: String) -> IslamicReminder {
        IslamicReminder(
            id: UUID(),
            type: .dua,
            arabic: "الْحَمْدُ لِلَّهِ الَّذِي بِنِعْمَتِهِ تَتِمُّ الصَّالِحَاتُ",
            transliteration: "Alhamdulillahil-ladhi bi ni'matihi tatimmus-salihat",
            english: "You completed \"\(bookTitle)\"! All praise is due to Allah, by Whose grace good deeds are completed.",
            source: "Ibn Majah",
            category: "gratitude"
        )
    }
}

// MARK: - Seeded Random Number Generator

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        // Simple xorshift64 algorithm
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
