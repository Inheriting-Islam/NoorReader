# Phase 4: Study Tools & Spaced Repetition - Development Prompt

بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ

**In the name of Allah, the Most Gracious, the Most Merciful.**

---

> "Seeking knowledge is an obligation upon every Muslim."
> — Prophet Muhammad ﷺ (Sunan Ibn Majah 224)

Phase 4 transforms NoorReader from a reading application into a complete study system. By implementing spaced repetition, study sessions, and progress tracking, we help users not just read but truly retain and understand their texts — turning fleeting knowledge into lasting comprehension, insha'Allah.

---

## Table of Contents

1. [Phase 4 Overview](#phase-4-overview)
2. [Prerequisites](#prerequisites)
3. [Architecture Overview](#architecture-overview)
4. [Implementation Tasks](#implementation-tasks)
   - [Task 1: Flashcard System with Spaced Repetition](#task-1-flashcard-system-with-spaced-repetition)
   - [Task 2: Study Session Management](#task-2-study-session-management)
   - [Task 3: Study Statistics Dashboard](#task-3-study-statistics-dashboard)
   - [Task 4: Focus Mode](#task-4-focus-mode)
   - [Task 5: Reading Goals & Streaks](#task-5-reading-goals--streaks)
   - [Task 6: Study Timer with Pomodoro](#task-6-study-timer-with-pomodoro)
   - [Task 7: Quick Review from Highlights](#task-7-quick-review-from-highlights)
5. [Data Models](#data-models)
6. [Quality Standards](#quality-standards)
7. [Testing Requirements](#testing-requirements)
8. [Phase 4 Completion Criteria](#phase-4-completion-criteria)

---

## Phase 4 Overview

**Objective:** Build a comprehensive study system that helps users retain knowledge through spaced repetition flashcards, track their learning progress, maintain study streaks, and create focused study sessions.

**Building Upon:** Phase 1 (PDF viewing, library, themes), Phase 2 (annotations, notes, search, export), and Phase 3 (AI integration for flashcard generation)

**Deliverable:** Enhanced NoorReader with:
- SM-2 spaced repetition flashcard system
- Study sessions with break reminders
- Statistics dashboard with learning analytics
- Focus mode with distraction blocking
- Reading goals and streak tracking
- Pomodoro timer integration
- Quick review mode for highlights

---

## Prerequisites

Before starting Phase 4, ensure Phases 1-3 are complete:

- [ ] PDF import and library management working
- [ ] PDF viewing with smooth rendering
- [ ] Full highlight system with 8 colors
- [ ] Notes attached to highlights functional
- [ ] Annotations sidebar working
- [ ] In-document search functional
- [ ] Markdown export working
- [ ] Islamic reminders functional
- [ ] AI summarization working (local or cloud)
- [ ] AI flashcard generation from highlights working
- [ ] All Phase 1-3 tests passing
- [ ] Zero compiler warnings

---

## Architecture Overview

### Study System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     STUDY SYSTEM                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   FLASHCARDS              SESSIONS              ANALYTICS    │
│   ─────────────           ─────────             ──────────   │
│   ✓ SM-2 Algorithm        ✓ Focus Mode          ✓ Dashboard  │
│   ✓ Review Queue          ✓ Pomodoro Timer      ✓ Streaks    │
│   ✓ Due Cards             ✓ Break Reminders     ✓ Goals      │
│   ✓ Card States           ✓ Session History     ✓ Heatmap    │
│   ✓ Learning Steps        ✓ Auto-save           ✓ Charts     │
│                                                              │
│   ┌──────────────────────────────────────────────────────┐  │
│   │              QUICK REVIEW MODE                        │  │
│   │   Browse highlights → Flip to review → Rate recall    │  │
│   └──────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### New Files to Create

```
NoorReader/
├── Shared/
│   ├── Models/
│   │   ├── Flashcard.swift              # NEW: Flashcard with SM-2 data
│   │   ├── StudySession.swift           # NEW: Study session tracking
│   │   ├── StudyStreak.swift            # NEW: Streak and goals data
│   │   └── ReviewLog.swift              # NEW: Review history
│   │
│   ├── Services/
│   │   ├── FlashcardService.swift       # NEW: Flashcard CRUD & scheduling
│   │   ├── SpacedRepetitionService.swift # NEW: SM-2 algorithm
│   │   ├── StudySessionService.swift    # NEW: Session management
│   │   ├── StudyStatsService.swift      # NEW: Analytics computation
│   │   └── GoalService.swift            # NEW: Goals and streaks
│   │
│   ├── ViewModels/
│   │   ├── FlashcardViewModel.swift     # NEW: Flashcard study state
│   │   ├── StudySessionViewModel.swift  # NEW: Session state
│   │   └── StatsViewModel.swift         # NEW: Statistics state
│   │
│   └── Components/
│       ├── FlashcardView.swift          # NEW: Single card display
│       ├── FlashcardDeck.swift          # NEW: Card stack with gestures
│       ├── ReviewRatingButtons.swift    # NEW: Again/Hard/Good/Easy
│       ├── StudyTimerView.swift         # NEW: Pomodoro timer
│       ├── StreakBadge.swift            # NEW: Streak display
│       ├── StudyProgressRing.swift      # NEW: Circular progress
│       ├── HeatmapCalendar.swift        # NEW: Activity heatmap
│       └── StatsCard.swift              # NEW: Stat display card
│
└── macOS/
    └── Views/
        ├── FlashcardReviewView.swift    # NEW: Flashcard study UI
        ├── StudyDashboardView.swift     # NEW: Statistics dashboard
        ├── FocusModeView.swift          # NEW: Distraction-free mode
        ├── StudySessionSheet.swift      # NEW: Session setup
        └── GoalSettingsView.swift       # NEW: Goal configuration
```

### Files to Modify

```
Shared/
├── Models/
│   ├── Book.swift                       # MODIFY: Add flashcards relationship
│   └── Highlight.swift                  # MODIFY: Add flashcard relationship
│
├── Services/
│   └── AIService.swift                  # MODIFY: Connect to FlashcardService
│
├── ViewModels/
│   ├── ReaderViewModel.swift            # MODIFY: Focus mode integration
│   └── SettingsViewModel.swift          # MODIFY: Study preferences
│
└── Components/
    └── SelectionPopover.swift           # MODIFY: Add "Create Flashcard" action

macOS/
├── MacContentView.swift                 # MODIFY: Add study views
├── MacSidebarView.swift                 # MODIFY: Add flashcards section
├── SettingsView.swift                   # MODIFY: Add study settings tab
└── MacMenuCommands.swift                # MODIFY: Study menu items
```

---

## Implementation Tasks

### Task 1: Flashcard System with Spaced Repetition

**Objective:** Implement a full flashcard system using the SM-2 spaced repetition algorithm for optimal learning retention.

#### 1.1 Create Flashcard Model

```swift
// Shared/Models/Flashcard.swift
// NEW FILE

import SwiftData
import Foundation

/// A flashcard for spaced repetition learning
@Model
final class Flashcard {
    // MARK: - Core Properties

    @Attribute(.unique)
    var id: UUID

    var question: String
    var answer: String
    var dateCreated: Date
    var dateModified: Date

    // MARK: - SM-2 Algorithm Properties

    /// Number of times reviewed
    var repetitions: Int

    /// Easiness factor (default 2.5, range 1.3-2.5)
    var easeFactor: Double

    /// Current interval in days
    var interval: Int

    /// Next review date
    var dueDate: Date

    /// Current learning state
    var stateRaw: String

    // MARK: - Source References

    /// Page number where content originated
    var sourcePageNumber: Int?

    /// Text excerpt that generated this card
    var sourceText: String?

    // MARK: - Relationships

    @Relationship
    var book: Book?

    @Relationship
    var highlight: Highlight?

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

    // MARK: - Initialization

    init(
        question: String,
        answer: String,
        sourcePageNumber: Int? = nil,
        sourceText: String? = nil
    ) {
        self.id = UUID()
        self.question = question
        self.answer = answer
        self.dateCreated = Date()
        self.dateModified = Date()
        self.repetitions = 0
        self.easeFactor = 2.5
        self.interval = 0
        self.dueDate = Date()
        self.stateRaw = FlashcardState.new.rawValue
        self.sourcePageNumber = sourcePageNumber
        self.sourceText = sourceText
    }

    // MARK: - Methods

    func updateContent(question: String, answer: String) {
        self.question = question
        self.answer = answer
        self.dateModified = Date()
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
}
```

#### 1.2 Create Review Log Model

```swift
// Shared/Models/ReviewLog.swift
// NEW FILE

import SwiftData
import Foundation

/// Records each flashcard review for analytics
@Model
final class ReviewLog {
    var id: UUID
    var flashcardID: UUID
    var reviewDate: Date
    var qualityRaw: Int
    var previousInterval: Int
    var newInterval: Int
    var previousEaseFactor: Double
    var newEaseFactor: Double
    var responseTimeSeconds: Double?

    var quality: ReviewQuality {
        ReviewQuality(rawValue: qualityRaw) ?? .good
    }

    init(
        flashcardID: UUID,
        quality: ReviewQuality,
        previousInterval: Int,
        newInterval: Int,
        previousEaseFactor: Double,
        newEaseFactor: Double,
        responseTimeSeconds: Double? = nil
    ) {
        self.id = UUID()
        self.flashcardID = flashcardID
        self.reviewDate = Date()
        self.qualityRaw = quality.rawValue
        self.previousInterval = previousInterval
        self.newInterval = newInterval
        self.previousEaseFactor = previousEaseFactor
        self.newEaseFactor = newEaseFactor
        self.responseTimeSeconds = responseTimeSeconds
    }
}
```

#### 1.3 Create Spaced Repetition Service (SM-2 Algorithm)

```swift
// Shared/Services/SpacedRepetitionService.swift
// NEW FILE

import Foundation

/// Implements the SM-2 spaced repetition algorithm
/// Reference: https://www.supermemo.com/en/archives1990-2015/english/ol/sm2
actor SpacedRepetitionService {

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

    // MARK: - Review Processing

    struct ReviewResult: Sendable {
        let newState: FlashcardState
        let newInterval: Int
        let newEaseFactor: Double
        let newDueDate: Date
        let newRepetitions: Int
    }

    /// Process a review and calculate new scheduling parameters
    func processReview(
        card: Flashcard,
        quality: ReviewQuality
    ) -> ReviewResult {
        var newState = card.state
        var newInterval = card.interval
        var newEaseFactor = card.easeFactor
        var newRepetitions = card.repetitions

        switch card.state {
        case .new, .learning:
            let result = processLearningReview(
                card: card,
                quality: quality
            )
            newState = result.state
            newInterval = result.interval
            if result.graduated {
                newRepetitions = 1
            }

        case .review:
            let result = processReviewReview(
                card: card,
                quality: quality
            )
            newState = result.state
            newInterval = result.interval
            newEaseFactor = result.easeFactor
            if quality != .again {
                newRepetitions = card.repetitions + 1
            }

        case .relearning:
            let result = processRelearningReview(
                card: card,
                quality: quality
            )
            newState = result.state
            newInterval = result.interval
        }

        // Ensure ease factor stays in bounds
        newEaseFactor = max(minimumEaseFactor, min(maximumEaseFactor, newEaseFactor))

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
            newRepetitions: newRepetitions
        )
    }

    // MARK: - Learning State Processing

    private struct LearningResult {
        let state: FlashcardState
        let interval: Int
        let graduated: Bool
    }

    private func processLearningReview(
        card: Flashcard,
        quality: ReviewQuality
    ) -> LearningResult {
        switch quality {
        case .again:
            // Reset to first step
            return LearningResult(
                state: .learning,
                interval: learningSteps[0],
                graduated: false
            )

        case .hard:
            // Stay at current step (repeat)
            let currentStep = getCurrentLearningStep(interval: card.interval)
            return LearningResult(
                state: .learning,
                interval: learningSteps[currentStep],
                graduated: false
            )

        case .good:
            // Move to next step or graduate
            let currentStep = getCurrentLearningStep(interval: card.interval)
            if currentStep >= learningSteps.count - 1 {
                // Graduate to review
                return LearningResult(
                    state: .review,
                    interval: graduatingInterval,
                    graduated: true
                )
            } else {
                // Next learning step
                return LearningResult(
                    state: .learning,
                    interval: learningSteps[currentStep + 1],
                    graduated: false
                )
            }

        case .easy:
            // Graduate immediately with easy interval
            return LearningResult(
                state: .review,
                interval: easyInterval,
                graduated: true
            )
        }
    }

    private func getCurrentLearningStep(interval: Int) -> Int {
        for (index, step) in learningSteps.enumerated() {
            if interval <= step {
                return index
            }
        }
        return learningSteps.count - 1
    }

    // MARK: - Review State Processing

    private struct ReviewResult2 {
        let state: FlashcardState
        let interval: Int
        let easeFactor: Double
    }

    private func processReviewReview(
        card: Flashcard,
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

        let newEaseFactor = card.easeFactor + easeModifier

        // Calculate new interval
        let newInterval: Int
        let newState: FlashcardState

        switch quality {
        case .again:
            // Lapse - go to relearning
            newInterval = relearningSteps[0]
            newState = .relearning

        case .hard:
            // Reduce interval slightly
            newInterval = Int(Double(card.interval) * 1.2 * intervalModifier)
            newState = .review

        case .good:
            // Normal progression
            newInterval = Int(Double(card.interval) * newEaseFactor * intervalModifier)
            newState = .review

        case .easy:
            // Bonus interval
            newInterval = Int(Double(card.interval) * newEaseFactor * 1.3 * intervalModifier)
            newState = .review
        }

        return ReviewResult2(
            state: newState,
            interval: max(1, newInterval),
            easeFactor: newEaseFactor
        )
    }

    // MARK: - Relearning State Processing

    private func processRelearningReview(
        card: Flashcard,
        quality: ReviewQuality
    ) -> (state: FlashcardState, interval: Int) {
        switch quality {
        case .again:
            // Stay in relearning
            return (.relearning, relearningSteps[0])

        case .hard:
            // Extend relearning slightly
            return (.relearning, relearningSteps[0] * 2)

        case .good, .easy:
            // Return to review with reduced interval
            let newInterval = max(1, card.interval / 2)
            return (.review, newInterval)
        }
    }

    // MARK: - Queue Management

    /// Get cards due for review, sorted by priority
    func getDueCards(from cards: [Flashcard], limit: Int = 20) -> [Flashcard] {
        let now = Date()

        // Filter due cards
        let dueCards = cards.filter { $0.dueDate <= now }

        // Sort by priority: new > learning > relearning > review
        let sorted = dueCards.sorted { card1, card2 in
            // Learning/relearning cards first (they're time-sensitive)
            if card1.state == .learning || card1.state == .relearning {
                if card2.state != .learning && card2.state != .relearning {
                    return true
                }
            }

            // Then new cards
            if card1.state == .new && card2.state != .new {
                return true
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
            if card.state == .new && card.repetitions == 0 {
                newCount += 1
            } else if card.state == .learning || card.state == .relearning {
                if card.dueDate <= now {
                    learningCount += 1
                }
            } else if card.state == .review && card.dueDate <= now {
                dueCount += 1
            }
        }

        return (newCount, learningCount, dueCount)
    }
}
```

#### 1.4 Create Flashcard Service

```swift
// Shared/Services/FlashcardService.swift
// NEW FILE

import SwiftData
import Foundation

/// Manages flashcard CRUD operations and study queue
@MainActor
@Observable
final class FlashcardService {

    // MARK: - Properties

    private let modelContext: ModelContext
    private let spacedRepetition = SpacedRepetitionService()

    var isLoading = false
    var error: Error?

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD Operations

    func createFlashcard(
        question: String,
        answer: String,
        book: Book?,
        highlight: Highlight? = nil,
        sourcePageNumber: Int? = nil,
        sourceText: String? = nil
    ) async throws -> Flashcard {
        let flashcard = Flashcard(
            question: question,
            answer: answer,
            sourcePageNumber: sourcePageNumber ?? highlight?.pageNumber,
            sourceText: sourceText ?? highlight?.text
        )

        flashcard.book = book
        flashcard.highlight = highlight

        modelContext.insert(flashcard)
        try modelContext.save()

        return flashcard
    }

    func createFlashcards(
        from suggestions: [FlashcardSuggestion],
        book: Book?,
        highlight: Highlight? = nil
    ) async throws -> [Flashcard] {
        var created: [Flashcard] = []

        for suggestion in suggestions where suggestion.isSelected {
            let flashcard = try await createFlashcard(
                question: suggestion.question,
                answer: suggestion.answer,
                book: book,
                highlight: highlight,
                sourceText: highlight?.text
            )
            created.append(flashcard)
        }

        return created
    }

    func updateFlashcard(_ flashcard: Flashcard, question: String, answer: String) throws {
        flashcard.updateContent(question: question, answer: answer)
        try modelContext.save()
    }

    func deleteFlashcard(_ flashcard: Flashcard) throws {
        modelContext.delete(flashcard)
        try modelContext.save()
    }

    // MARK: - Fetching

    func fetchAllFlashcards() throws -> [Flashcard] {
        let descriptor = FetchDescriptor<Flashcard>(
            sortBy: [SortDescriptor(\.dateCreated, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchFlashcards(for book: Book) throws -> [Flashcard] {
        let bookID = book.id
        let descriptor = FetchDescriptor<Flashcard>(
            predicate: #Predicate { $0.book?.id == bookID },
            sortBy: [SortDescriptor(\.dateCreated, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchDueFlashcards(for book: Book? = nil, limit: Int = 20) async throws -> [Flashcard] {
        let allCards: [Flashcard]

        if let book {
            allCards = try fetchFlashcards(for: book)
        } else {
            allCards = try fetchAllFlashcards()
        }

        return await spacedRepetition.getDueCards(from: allCards, limit: limit)
    }

    // MARK: - Review

    func processReview(
        flashcard: Flashcard,
        quality: ReviewQuality,
        responseTime: TimeInterval? = nil
    ) async throws {
        let previousInterval = flashcard.interval
        let previousEaseFactor = flashcard.easeFactor

        // Calculate new scheduling
        let result = await spacedRepetition.processReview(
            card: flashcard,
            quality: quality
        )

        // Update flashcard
        flashcard.state = result.newState
        flashcard.interval = result.newInterval
        flashcard.easeFactor = result.newEaseFactor
        flashcard.dueDate = result.newDueDate
        flashcard.repetitions = result.newRepetitions
        flashcard.dateModified = Date()

        // Log the review
        let reviewLog = ReviewLog(
            flashcardID: flashcard.id,
            quality: quality,
            previousInterval: previousInterval,
            newInterval: result.newInterval,
            previousEaseFactor: previousEaseFactor,
            newEaseFactor: result.newEaseFactor,
            responseTimeSeconds: responseTime
        )
        modelContext.insert(reviewLog)

        try modelContext.save()
    }

    // MARK: - Statistics

    func getCardCounts(for book: Book? = nil) async throws -> (new: Int, learning: Int, due: Int) {
        let cards: [Flashcard]

        if let book {
            cards = try fetchFlashcards(for: book)
        } else {
            cards = try fetchAllFlashcards()
        }

        return await spacedRepetition.getCardCounts(from: cards)
    }

    func getTotalCardCount(for book: Book? = nil) throws -> Int {
        if let book {
            return try fetchFlashcards(for: book).count
        } else {
            return try fetchAllFlashcards().count
        }
    }
}
```

#### 1.5 Create Flashcard View Model

```swift
// Shared/ViewModels/FlashcardViewModel.swift
// NEW FILE

import SwiftUI
import SwiftData

/// Manages flashcard study session state
@MainActor
@Observable
final class FlashcardViewModel {

    // MARK: - Dependencies

    private let flashcardService: FlashcardService

    // MARK: - State

    var currentBook: Book?
    var studyQueue: [Flashcard] = []
    var currentCardIndex: Int = 0
    var isFlipped: Bool = false
    var isLoading: Bool = false
    var error: Error?

    // Session tracking
    var sessionStartTime: Date?
    var cardsReviewedCount: Int = 0
    var currentCardStartTime: Date?

    // Counts
    var newCount: Int = 0
    var learningCount: Int = 0
    var dueCount: Int = 0

    // MARK: - Computed Properties

    var currentCard: Flashcard? {
        guard currentCardIndex < studyQueue.count else { return nil }
        return studyQueue[currentCardIndex]
    }

    var hasCardsRemaining: Bool {
        currentCardIndex < studyQueue.count
    }

    var remainingCards: Int {
        max(0, studyQueue.count - currentCardIndex)
    }

    var sessionDuration: TimeInterval {
        guard let start = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(start)
    }

    var formattedSessionDuration: String {
        let duration = Int(sessionDuration)
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var averageTimePerCard: TimeInterval {
        guard cardsReviewedCount > 0 else { return 0 }
        return sessionDuration / Double(cardsReviewedCount)
    }

    // MARK: - Initialization

    init(flashcardService: FlashcardService) {
        self.flashcardService = flashcardService
    }

    // MARK: - Session Management

    func startStudySession(for book: Book? = nil) async {
        isLoading = true
        currentBook = book
        sessionStartTime = Date()
        cardsReviewedCount = 0
        currentCardIndex = 0
        isFlipped = false

        do {
            studyQueue = try await flashcardService.fetchDueFlashcards(for: book)
            let counts = try await flashcardService.getCardCounts(for: book)
            newCount = counts.new
            learningCount = counts.learning
            dueCount = counts.due
            currentCardStartTime = Date()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func endSession() {
        sessionStartTime = nil
        studyQueue = []
        currentCardIndex = 0
        isFlipped = false
    }

    // MARK: - Card Actions

    func flipCard() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isFlipped.toggle()
        }
    }

    func rateCard(_ quality: ReviewQuality) async {
        guard let card = currentCard else { return }

        let responseTime = currentCardStartTime.map { Date().timeIntervalSince($0) }

        do {
            try await flashcardService.processReview(
                flashcard: card,
                quality: quality,
                responseTime: responseTime
            )

            cardsReviewedCount += 1
            moveToNextCard()

            // Refresh counts
            let counts = try await flashcardService.getCardCounts(for: currentBook)
            newCount = counts.new
            learningCount = counts.learning
            dueCount = counts.due

        } catch {
            self.error = error
        }
    }

    private func moveToNextCard() {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentCardIndex += 1
            isFlipped = false
            currentCardStartTime = Date()
        }
    }

    // MARK: - Keyboard Shortcuts

    func handleKeyPress(_ key: KeyEquivalent) {
        if !isFlipped {
            // Space to flip
            if key == .space {
                flipCard()
            }
        } else {
            // Number keys to rate
            switch key {
            case "1":
                Task { await rateCard(.again) }
            case "2":
                Task { await rateCard(.hard) }
            case "3":
                Task { await rateCard(.good) }
            case "4":
                Task { await rateCard(.easy) }
            default:
                break
            }
        }
    }
}
```

#### 1.6 Create Flashcard View Components

```swift
// Shared/Components/FlashcardView.swift
// NEW FILE

import SwiftUI

/// Displays a single flashcard with flip animation
struct FlashcardView: View {
    let flashcard: Flashcard
    let isFlipped: Bool
    let onFlip: () -> Void

    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Back (Answer)
            cardFace(
                content: flashcard.answer,
                label: "Answer",
                icon: "lightbulb.fill",
                color: .green
            )
            .rotation3DEffect(.degrees(rotation + 180), axis: (x: 0, y: 1, z: 0))
            .opacity(isFlipped ? 1 : 0)

            // Front (Question)
            cardFace(
                content: flashcard.question,
                label: "Question",
                icon: "questionmark.circle.fill",
                color: .blue
            )
            .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
            .opacity(isFlipped ? 0 : 1)
        }
        .onChange(of: isFlipped) { _, flipped in
            withAnimation(.easeInOut(duration: 0.4)) {
                rotation = flipped ? 180 : 0
            }
        }
        .onTapGesture {
            onFlip()
        }
    }

    @ViewBuilder
    private func cardFace(
        content: String,
        label: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()

                // State badge
                HStack(spacing: 4) {
                    Image(systemName: flashcard.state.icon)
                    Text(flashcard.state.displayName)
                }
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(flashcard.state.color).opacity(0.2))
                .clipShape(Capsule())
            }

            Divider()

            // Content
            ScrollView {
                Text(content)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            Spacer()

            // Source info
            if let page = flashcard.sourcePageNumber {
                HStack {
                    Image(systemName: "book.pages")
                        .font(.caption2)
                    Text("Page \(page)")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }

            // Flip hint
            if !isFlipped {
                Text("Tap or press Space to reveal answer")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
}
```

```swift
// Shared/Components/ReviewRatingButtons.swift
// NEW FILE

import SwiftUI

/// Rating buttons for flashcard review
struct ReviewRatingButtons: View {
    let onRate: (ReviewQuality) -> Void
    let intervals: [ReviewQuality: String]

    init(
        flashcard: Flashcard,
        onRate: @escaping (ReviewQuality) -> Void
    ) {
        self.onRate = onRate

        // Calculate preview intervals for each rating
        // This is a simplified version - actual implementation would use SpacedRepetitionService
        self.intervals = [
            .again: "<1m",
            .hard: flashcard.state == .review ? "×1.2" : "<10m",
            .good: flashcard.state == .review ? "×\(String(format: "%.1f", flashcard.easeFactor))" : "1d",
            .easy: flashcard.state == .review ? "×\(String(format: "%.1f", flashcard.easeFactor * 1.3))" : "4d"
        ]
    }

    var body: some View {
        HStack(spacing: 12) {
            ForEach(ReviewQuality.allCases) { quality in
                ratingButton(quality)
            }
        }
    }

    @ViewBuilder
    private func ratingButton(_ quality: ReviewQuality) -> some View {
        Button {
            onRate(quality)
        } label: {
            VStack(spacing: 4) {
                Text(intervals[quality] ?? "")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(quality.displayName)
                    .font(.headline)

                Text(quality.shortcut)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(quality.color).opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .keyboardShortcut(KeyEquivalent(Character(quality.shortcut)), modifiers: [])
    }
}
```

#### 1.7 Create Flashcard Review View

```swift
// macOS/Views/FlashcardReviewView.swift
// NEW FILE

import SwiftUI

/// Main flashcard study view
struct FlashcardReviewView: View {
    @Bindable var viewModel: FlashcardViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            if viewModel.isLoading {
                loadingView
            } else if viewModel.hasCardsRemaining {
                studyView
            } else {
                completionView
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color(.windowBackgroundColor))
        .onKeyPress { press in
            viewModel.handleKeyPress(press.key)
            return .handled
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            // Card counts
            HStack(spacing: 16) {
                countBadge(count: viewModel.newCount, label: "New", color: .blue)
                countBadge(count: viewModel.learningCount, label: "Learning", color: .orange)
                countBadge(count: viewModel.dueCount, label: "Due", color: .green)
            }

            Spacer()

            // Session info
            HStack(spacing: 8) {
                Image(systemName: "clock")
                Text(viewModel.formattedSessionDuration)
                    .monospacedDigit()

                Divider()
                    .frame(height: 16)

                Image(systemName: "checkmark.circle")
                Text("\(viewModel.cardsReviewedCount) reviewed")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()

            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    private func countBadge(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.headline)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 60)
    }

    // MARK: - Study View

    private var studyView: some View {
        VStack(spacing: 24) {
            // Progress
            ProgressView(value: Double(viewModel.currentCardIndex), total: Double(viewModel.studyQueue.count))
                .padding(.horizontal)

            Text("\(viewModel.remainingCards) cards remaining")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Current card
            if let card = viewModel.currentCard {
                FlashcardView(
                    flashcard: card,
                    isFlipped: viewModel.isFlipped,
                    onFlip: { viewModel.flipCard() }
                )
                .frame(maxWidth: 500, maxHeight: 350)
                .padding()

                // Rating buttons (only show when flipped)
                if viewModel.isFlipped {
                    ReviewRatingButtons(flashcard: card) { quality in
                        Task {
                            await viewModel.rateCard(quality)
                        }
                    }
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            Spacer()
        }
        .animation(.easeInOut, value: viewModel.isFlipped)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading flashcards...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Session Complete!")
                .font(.title)

            VStack(spacing: 8) {
                Text("\(viewModel.cardsReviewedCount) cards reviewed")
                Text("Time: \(viewModel.formattedSessionDuration)")
                if viewModel.cardsReviewedCount > 0 {
                    Text("Average: \(String(format: "%.1f", viewModel.averageTimePerCard))s per card")
                }
            }
            .foregroundStyle(.secondary)

            // Islamic completion message
            VStack(spacing: 8) {
                Text("جَزَاكَ ٱللَّٰهُ خَيْرًا")
                    .font(.title2)
                Text("May Allah reward you for your effort")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top)

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FlashcardReviewView(viewModel: FlashcardViewModel(
        flashcardService: FlashcardService(modelContext: try! ModelContext(ModelContainer(for: Flashcard.self)))
    ))
}
```

---

### Task 2: Study Session Management

**Objective:** Create a study session system that tracks reading time, provides break reminders, and maintains session history.

#### 2.1 Create Study Session Model

```swift
// Shared/Models/StudySession.swift
// NEW FILE

import SwiftData
import Foundation

/// Records a study session for analytics
@Model
final class StudySession {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var durationSeconds: Int

    // Session type
    var typeRaw: String

    // Related content
    var bookID: UUID?
    var bookTitle: String?

    // Activity metrics
    var pagesRead: Int
    var highlightsCreated: Int
    var notesCreated: Int
    var flashcardsReviewed: Int

    // Focus metrics
    var focusModeUsed: Bool
    var breaksTaken: Int

    var type: SessionType {
        get { SessionType(rawValue: typeRaw) ?? .reading }
        set { typeRaw = newValue.rawValue }
    }

    var isActive: Bool {
        endTime == nil
    }

    var formattedDuration: String {
        let hours = durationSeconds / 3600
        let minutes = (durationSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    init(
        type: SessionType,
        bookID: UUID? = nil,
        bookTitle: String? = nil
    ) {
        self.id = UUID()
        self.startTime = Date()
        self.endTime = nil
        self.durationSeconds = 0
        self.typeRaw = type.rawValue
        self.bookID = bookID
        self.bookTitle = bookTitle
        self.pagesRead = 0
        self.highlightsCreated = 0
        self.notesCreated = 0
        self.flashcardsReviewed = 0
        self.focusModeUsed = false
        self.breaksTaken = 0
    }

    func end() {
        endTime = Date()
        durationSeconds = Int(endTime!.timeIntervalSince(startTime))
    }

    func addPage() {
        pagesRead += 1
    }

    func addHighlight() {
        highlightsCreated += 1
    }

    func addNote() {
        notesCreated += 1
    }

    func addFlashcardReview() {
        flashcardsReviewed += 1
    }

    func addBreak() {
        breaksTaken += 1
    }
}

// MARK: - Session Type

enum SessionType: String, CaseIterable, Identifiable {
    case reading = "reading"
    case review = "review"
    case mixed = "mixed"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .reading: return "Reading"
        case .review: return "Flashcard Review"
        case .mixed: return "Study Session"
        }
    }

    var icon: String {
        switch self {
        case .reading: return "book"
        case .review: return "rectangle.on.rectangle"
        case .mixed: return "brain.head.profile"
        }
    }
}
```

#### 2.2 Create Study Session Service

```swift
// Shared/Services/StudySessionService.swift
// NEW FILE

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

    // MARK: - Initialization

    private init() {}

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
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

        startTimers()
    }

    func endSession() throws {
        guard let modelContext, let session = activeSession else { return }

        session.end()
        try modelContext.save()

        stopTimers()
        activeSession = nil
        elapsedSeconds = 0
    }

    func pauseSession() {
        stopTimers()
    }

    func resumeSession() {
        startTimers()
    }

    // MARK: - Timer Management

    private func startTimers() {
        // Elapsed time timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.elapsedSeconds += 1
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

        if minutesSinceBreak >= breakIntervalMinutes {
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

    func getTodayTotalMinutes() throws -> Int {
        let sessions = try fetchTodaySessions()
        let totalSeconds = sessions.reduce(0) { $0 + $1.durationSeconds }
        return totalSeconds / 60
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
```

---

### Task 3: Study Statistics Dashboard

**Objective:** Create a comprehensive dashboard showing study analytics, progress, and trends.

#### 3.1 Create Study Streak Model

```swift
// Shared/Models/StudyStreak.swift
// NEW FILE

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

    init() {
        self.id = UUID()
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastStudyDate = nil
        self.dailyGoalMinutes = 30  // Default 30 min/day
        self.todayMinutes = 0
        self.weeklyGoalDays = 5  // Default 5 days/week
        self.totalStudyDays = 0
        self.totalMinutes = 0
        self.totalFlashcardsReviewed = 0
        self.totalPagesRead = 0
    }

    func recordStudy(minutes: Int, flashcards: Int = 0, pages: Int = 0) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Check if this is a new day
        if let lastDate = lastStudyDate {
            let lastDay = calendar.startOfDay(for: lastDate)

            if lastDay == today {
                // Same day - just add time
                todayMinutes += minutes
            } else if calendar.isDate(lastDay, equalTo: today, toGranularity: .day) == false {
                // Different day
                let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

                if daysBetween == 1 {
                    // Consecutive day - extend streak
                    currentStreak += 1
                } else {
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

    func resetTodayProgress() {
        todayMinutes = 0
    }
}
```

#### 3.2 Create Stats View Model

```swift
// Shared/ViewModels/StatsViewModel.swift
// NEW FILE

import SwiftUI
import SwiftData

/// View model for study statistics dashboard
@MainActor
@Observable
final class StatsViewModel {

    // MARK: - Dependencies

    private var modelContext: ModelContext?

    // MARK: - State

    var streak: StudyStreak?
    var recentSessions: [StudySession] = []
    var weeklyActivity: [DayActivity] = []
    var monthlyHeatmap: [Date: Int] = [:]
    var isLoading = false

    // Computed stats
    var totalStudyTime: String = "0h"
    var averageSessionLength: String = "0m"
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

        do {
            // Load or create streak
            let descriptor = FetchDescriptor<StudyStreak>()
            let streaks = try modelContext.fetch(descriptor)
            if let existingStreak = streaks.first {
                streak = existingStreak
            } else {
                let newStreak = StudyStreak()
                modelContext.insert(newStreak)
                try modelContext.save()
                streak = newStreak
            }

            // Load recent sessions
            let sessionDescriptor = FetchDescriptor<StudySession>(
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
            recentSessions = Array(try modelContext.fetch(sessionDescriptor).prefix(10))

            // Calculate weekly activity
            weeklyActivity = calculateWeeklyActivity()

            // Calculate monthly heatmap
            monthlyHeatmap = calculateMonthlyHeatmap()

            // Calculate aggregate stats
            calculateAggregateStats()

        } catch {
            print("Error loading stats: \(error)")
        }

        isLoading = false
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
                flashcardsReviewed: sessionsForDay.reduce(0) { $0 + $1.flashcardsReviewed }
            ))
        }

        return activities
    }

    private func calculateMonthlyHeatmap() -> [Date: Int] {
        let calendar = Calendar.current
        let today = Date()
        var heatmap: [Date: Int] = [:]

        guard let monthStart = calendar.date(byAdding: .day, value: -30, to: today) else {
            return heatmap
        }

        for session in recentSessions where session.startTime >= monthStart {
            let dayStart = calendar.startOfDay(for: session.startTime)
            let minutes = session.durationSeconds / 60
            heatmap[dayStart, default: 0] += minutes
        }

        return heatmap
    }

    private func calculateAggregateStats() {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

        let thisWeekSessions = recentSessions.filter { $0.startTime >= weekAgo }

        let totalSeconds = recentSessions.reduce(0) { $0 + $1.durationSeconds }
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        totalStudyTime = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"

        if !recentSessions.isEmpty {
            let avgSeconds = totalSeconds / recentSessions.count
            averageSessionLength = "\(avgSeconds / 60)m"
        }

        cardsReviewedThisWeek = thisWeekSessions.reduce(0) { $0 + $1.flashcardsReviewed }
        pagesReadThisWeek = thisWeekSessions.reduce(0) { $0 + $1.pagesRead }
    }
}

// MARK: - Supporting Types

struct DayActivity: Identifiable {
    let id = UUID()
    let date: Date
    let minutes: Int
    let flashcardsReviewed: Int

    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    var intensity: Double {
        // Normalize to 0-1 range (60 min = full intensity)
        min(1.0, Double(minutes) / 60.0)
    }
}
```

#### 3.3 Create Statistics Dashboard View

```swift
// macOS/Views/StudyDashboardView.swift
// NEW FILE

import SwiftUI
import Charts

/// Main statistics dashboard view
struct StudyDashboardView: View {
    @Bindable var viewModel: StatsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Streak and Daily Goal
                HStack(spacing: 20) {
                    streakCard
                    dailyGoalCard
                }

                // Weekly Activity Chart
                weeklyActivityCard

                // Stats Grid
                statsGrid

                // Recent Sessions
                recentSessionsCard
            }
            .padding()
        }
        .navigationTitle("Study Dashboard")
        .task {
            await viewModel.loadStats()
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("Current Streak")
                    .font(.headline)
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(viewModel.streak?.currentStreak ?? 0)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                Text("days")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            if let longest = viewModel.streak?.longestStreak, longest > 0 {
                Text("Longest: \(longest) days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Daily Goal Card

    private var dailyGoalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .foregroundStyle(.green)
                Text("Daily Goal")
                    .font(.headline)
            }

            ZStack {
                Circle()
                    .stroke(.gray.opacity(0.2), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: viewModel.streak?.goalProgressPercent ?? 0)
                    .stroke(.green, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack {
                    Text("\(viewModel.streak?.todayMinutes ?? 0)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("/ \(viewModel.streak?.dailyGoalMinutes ?? 30) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 100, height: 100)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Weekly Activity Card

    private var weeklyActivityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.blue)
                Text("This Week")
                    .font(.headline)
            }

            if #available(macOS 14.0, *) {
                Chart(viewModel.weeklyActivity) { activity in
                    BarMark(
                        x: .value("Day", activity.dayName),
                        y: .value("Minutes", activity.minutes)
                    )
                    .foregroundStyle(.blue.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 150)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            } else {
                // Fallback for older macOS
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(viewModel.weeklyActivity) { activity in
                        VStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.blue)
                                .frame(width: 30, height: CGFloat(activity.minutes) * 2)

                            Text(activity.dayName)
                                .font(.caption2)
                        }
                    }
                }
                .frame(height: 150)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "Total Time",
                value: viewModel.totalStudyTime,
                icon: "clock.fill",
                color: .blue
            )
            StatCard(
                title: "Avg Session",
                value: viewModel.averageSessionLength,
                icon: "timer",
                color: .orange
            )
            StatCard(
                title: "Cards/Week",
                value: "\(viewModel.cardsReviewedThisWeek)",
                icon: "rectangle.on.rectangle",
                color: .green
            )
            StatCard(
                title: "Pages/Week",
                value: "\(viewModel.pagesReadThisWeek)",
                icon: "book.pages",
                color: .purple
            )
        }
    }

    // MARK: - Recent Sessions Card

    private var recentSessionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.purple)
                Text("Recent Sessions")
                    .font(.headline)
            }

            if viewModel.recentSessions.isEmpty {
                Text("No sessions yet. Start studying to see your progress!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(viewModel.recentSessions.prefix(5), id: \.id) { session in
                    HStack {
                        Image(systemName: session.type.icon)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading) {
                            Text(session.bookTitle ?? session.type.displayName)
                                .font(.subheadline)
                            Text(session.startTime, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(session.formattedDuration)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

---

### Task 4: Focus Mode

**Objective:** Create a distraction-free reading mode that hides unnecessary UI elements and optionally blocks notifications.

#### 4.1 Create Focus Mode View

```swift
// macOS/Views/FocusModeView.swift
// NEW FILE

import SwiftUI
import PDFKit

/// Distraction-free reading mode
struct FocusModeView: View {
    @Bindable var readerViewModel: ReaderViewModel
    @State private var showControls = false
    @State private var hideControlsTask: Task<Void, Never>?
    @Environment(\.dismiss) private var dismiss

    // Session tracking
    @State private var sessionService = StudySessionService.shared

    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea()

            // PDF Content
            if let document = readerViewModel.document {
                PDFViewRepresentable(
                    document: document,
                    currentPage: $readerViewModel.currentPage,
                    displayMode: .singlePage,
                    scaleFactor: $readerViewModel.scaleFactor,
                    highlights: readerViewModel.book?.highlights ?? [],
                    onSelectionChanged: { _ in },
                    onPageChanged: { page in
                        sessionService.trackPageRead()
                    }
                )
                .frame(maxWidth: 800)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 20)
            }

            // Minimal controls overlay
            VStack {
                if showControls {
                    focusHeader
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()

                if showControls {
                    focusFooter
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showControls)
        }
        .onHover { hovering in
            showControls = hovering
            scheduleHideControls()
        }
        .onTapGesture {
            showControls.toggle()
            if showControls {
                scheduleHideControls()
            }
        }
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
        .onAppear {
            try? sessionService.startSession(
                type: .reading,
                book: readerViewModel.book,
                focusMode: true
            )
        }
        .onDisappear {
            try? sessionService.endSession()
        }
    }

    // MARK: - Header

    private var focusHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.7))

            Spacer()

            // Session timer
            HStack(spacing: 8) {
                Image(systemName: "clock")
                Text(sessionService.formattedElapsedTime)
                    .monospacedDigit()
            }
            .font(.headline)
            .foregroundStyle(.white.opacity(0.8))

            Spacer()

            // Page indicator
            Text("Page \(readerViewModel.currentPage + 1) of \(readerViewModel.totalPages)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.black.opacity(0.8), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Footer

    private var focusFooter: some View {
        HStack(spacing: 40) {
            // Previous page
            Button {
                readerViewModel.previousPage()
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.7))
            .disabled(readerViewModel.currentPage == 0)

            // Progress bar
            ProgressView(value: readerViewModel.progress)
                .progressViewStyle(.linear)
                .frame(width: 200)
                .tint(.white)

            // Next page
            Button {
                readerViewModel.nextPage()
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.7))
            .disabled(readerViewModel.currentPage >= readerViewModel.totalPages - 1)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Helpers

    private func scheduleHideControls() {
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            try? await Task.sleep(for: .seconds(3))
            if !Task.isCancelled {
                showControls = false
            }
        }
    }
}
```

---

### Task 5: Reading Goals & Streaks

**Objective:** Implement a goal-setting system with streak tracking to encourage consistent study habits.

#### 5.1 Create Goal Service

```swift
// Shared/Services/GoalService.swift
// NEW FILE

import SwiftData
import Foundation
import UserNotifications

/// Manages reading goals and streak tracking
@MainActor
@Observable
final class GoalService {

    // MARK: - Singleton

    static let shared = GoalService()

    // MARK: - Properties

    private var modelContext: ModelContext?
    var streak: StudyStreak?

    // Goal settings
    var dailyGoalMinutes: Int {
        get { streak?.dailyGoalMinutes ?? 30 }
        set {
            streak?.dailyGoalMinutes = newValue
            saveStreak()
        }
    }

    var weeklyGoalDays: Int {
        get { streak?.weeklyGoalDays ?? 5 }
        set {
            streak?.weeklyGoalDays = newValue
            saveStreak()
        }
    }

    // Computed
    var currentStreak: Int { streak?.currentStreak ?? 0 }
    var longestStreak: Int { streak?.longestStreak ?? 0 }
    var todayMinutes: Int { streak?.todayMinutes ?? 0 }
    var hasStudiedToday: Bool { streak?.hasStudiedToday ?? false }
    var goalProgress: Double { streak?.goalProgressPercent ?? 0 }
    var hasMetDailyGoal: Bool { streak?.hasMetDailyGoal ?? false }

    // MARK: - Initialization

    private init() {}

    func configure(modelContext: ModelContext) async {
        self.modelContext = modelContext
        await loadOrCreateStreak()
        checkDayRollover()
    }

    // MARK: - Streak Management

    private func loadOrCreateStreak() async {
        guard let modelContext else { return }

        do {
            let descriptor = FetchDescriptor<StudyStreak>()
            let streaks = try modelContext.fetch(descriptor)

            if let existing = streaks.first {
                streak = existing
            } else {
                let newStreak = StudyStreak()
                modelContext.insert(newStreak)
                try modelContext.save()
                streak = newStreak
            }
        } catch {
            print("Error loading streak: \(error)")
        }
    }

    private func checkDayRollover() {
        guard let streak, let lastDate = streak.lastStudyDate else { return }

        let calendar = Calendar.current
        if !calendar.isDateInToday(lastDate) {
            // It's a new day - reset today's progress
            streak.resetTodayProgress()
            saveStreak()
        }
    }

    private func saveStreak() {
        try? modelContext?.save()
    }

    // MARK: - Recording Progress

    func recordStudyTime(
        minutes: Int,
        flashcards: Int = 0,
        pages: Int = 0
    ) {
        streak?.recordStudy(
            minutes: minutes,
            flashcards: flashcards,
            pages: pages
        )
        saveStreak()

        // Check if goal just met
        if hasMetDailyGoal {
            sendGoalCompletionNotification()
        }
    }

    // MARK: - Notifications

    private func sendGoalCompletionNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Daily Goal Complete! 🎉"
        content.body = "You've studied for \(dailyGoalMinutes) minutes today. Great work!"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "dailyGoalComplete",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleStudyReminder(at hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Study 📚"
        content.body = "Keep your streak going! You've studied \(currentStreak) days in a row."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "studyReminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelStudyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["studyReminder"]
        )
    }
}
```

#### 5.2 Create Streak Badge Component

```swift
// Shared/Components/StreakBadge.swift
// NEW FILE

import SwiftUI

/// Displays current streak with fire animation
struct StreakBadge: View {
    let streak: Int
    let isAnimated: Bool

    @State private var flameScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .foregroundStyle(streakColor)
                .scaleEffect(flameScale)
                .animation(
                    isAnimated ? Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .default,
                    value: flameScale
                )

            Text("\(streak)")
                .font(.headline)
                .fontWeight(.bold)

            Text("day streak")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(streakColor.opacity(0.15))
        .clipShape(Capsule())
        .onAppear {
            if isAnimated && streak >= 7 {
                flameScale = 1.15
            }
        }
    }

    private var streakColor: Color {
        switch streak {
        case 0:
            return .gray
        case 1...6:
            return .orange
        case 7...29:
            return .red
        case 30...99:
            return .purple
        default:
            return .yellow  // 100+ days - golden flame!
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StreakBadge(streak: 0, isAnimated: false)
        StreakBadge(streak: 3, isAnimated: false)
        StreakBadge(streak: 7, isAnimated: true)
        StreakBadge(streak: 30, isAnimated: true)
        StreakBadge(streak: 100, isAnimated: true)
    }
    .padding()
}
```

---

### Task 6: Study Timer with Pomodoro

**Objective:** Implement a Pomodoro-style study timer with configurable work/break intervals.

#### 6.1 Create Study Timer View

```swift
// Shared/Components/StudyTimerView.swift
// NEW FILE

import SwiftUI

/// Pomodoro-style study timer
struct StudyTimerView: View {
    @State private var timeRemaining: Int = 25 * 60  // 25 minutes default
    @State private var isRunning = false
    @State private var isBreak = false
    @State private var completedPomodoros = 0

    // Settings
    @State private var workDuration: Int = 25  // minutes
    @State private var shortBreakDuration: Int = 5
    @State private var longBreakDuration: Int = 15
    @State private var pomodorosBeforeLongBreak: Int = 4

    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 24) {
            // Timer display
            timerDisplay

            // Controls
            controlButtons

            // Pomodoro count
            pomodoroIndicators

            // Settings
            settingsSection
        }
        .padding()
        .frame(width: 300)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Timer Display

    private var timerDisplay: some View {
        VStack(spacing: 8) {
            Text(isBreak ? "Break Time" : "Focus Time")
                .font(.headline)
                .foregroundStyle(isBreak ? .green : .blue)

            Text(formattedTime)
                .font(.system(size: 64, weight: .light, design: .rounded))
                .monospacedDigit()

            // Progress ring
            ZStack {
                Circle()
                    .stroke(.gray.opacity(0.2), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        isBreak ? Color.green : Color.blue,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
            }
            .frame(width: 200, height: 200)
            .overlay {
                Text(formattedTime)
                    .font(.system(size: 48, weight: .light, design: .rounded))
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Controls

    private var controlButtons: some View {
        HStack(spacing: 20) {
            // Reset
            Button {
                resetTimer()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .disabled(!isRunning && timeRemaining == totalDuration)

            // Start/Pause
            Button {
                if isRunning {
                    pauseTimer()
                } else {
                    startTimer()
                }
            } label: {
                Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(isBreak ? .green : .blue)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.space, modifiers: [])

            // Skip
            Button {
                skipToNext()
            } label: {
                Image(systemName: "forward.end")
                    .font(.title2)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Pomodoro Indicators

    private var pomodoroIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<pomodorosBeforeLongBreak, id: \.self) { index in
                Circle()
                    .fill(index < completedPomodoros ? Color.red : Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
            }
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        DisclosureGroup("Settings") {
            VStack(spacing: 12) {
                Stepper("Work: \(workDuration) min", value: $workDuration, in: 15...60, step: 5)
                Stepper("Short break: \(shortBreakDuration) min", value: $shortBreakDuration, in: 3...15)
                Stepper("Long break: \(longBreakDuration) min", value: $longBreakDuration, in: 10...30)
            }
            .font(.caption)
        }
        .font(.caption)
    }

    // MARK: - Computed Properties

    private var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var totalDuration: Int {
        (isBreak ? (shouldTakeLongBreak ? longBreakDuration : shortBreakDuration) : workDuration) * 60
    }

    private var progress: Double {
        Double(totalDuration - timeRemaining) / Double(totalDuration)
    }

    private var shouldTakeLongBreak: Bool {
        completedPomodoros > 0 && completedPomodoros % pomodorosBeforeLongBreak == 0
    }

    // MARK: - Timer Control

    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timerCompleted()
            }
        }
    }

    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func resetTimer() {
        pauseTimer()
        timeRemaining = totalDuration
    }

    private func skipToNext() {
        if !isBreak {
            completedPomodoros += 1
        }
        isBreak.toggle()
        timeRemaining = totalDuration
    }

    private func timerCompleted() {
        pauseTimer()

        // Play sound
        NSSound.beep()

        if !isBreak {
            completedPomodoros += 1
        }

        // Switch to break or work
        isBreak.toggle()
        timeRemaining = totalDuration
    }
}

#Preview {
    StudyTimerView()
        .padding()
}
```

---

### Task 7: Quick Review from Highlights

**Objective:** Enable users to quickly review their highlights as informal flashcards without creating permanent cards.

#### 7.1 Create Quick Review View

```swift
// macOS/Views/QuickReviewView.swift
// NEW FILE

import SwiftUI

/// Quick review mode for browsing highlights as flashcards
struct QuickReviewView: View {
    let book: Book
    @State private var currentIndex = 0
    @State private var isRevealed = false
    @State private var highlights: [Highlight] = []
    @State private var shuffled = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            if highlights.isEmpty {
                emptyState
            } else {
                // Card area
                cardArea

                Divider()

                // Navigation
                navigationBar
            }
        }
        .frame(width: 600, height: 500)
        .onAppear {
            highlights = book.highlights.sorted { $0.dateCreated > $1.dateCreated }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Quick Review")
                    .font(.headline)
                Text(book.displayTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("Shuffle", isOn: $shuffled)
                .toggleStyle(.switch)
                .onChange(of: shuffled) { _, shuffle in
                    if shuffle {
                        highlights.shuffle()
                    } else {
                        highlights = book.highlights.sorted { $0.dateCreated > $1.dateCreated }
                    }
                    currentIndex = 0
                }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    // MARK: - Card Area

    private var cardArea: some View {
        VStack(spacing: 20) {
            // Progress
            Text("\(currentIndex + 1) of \(highlights.count)")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Card
            if currentIndex < highlights.count {
                let highlight = highlights[currentIndex]

                VStack(spacing: 16) {
                    // Color indicator
                    HStack {
                        Circle()
                            .fill(Color(highlight.color.color))
                            .frame(width: 12, height: 12)
                        Text(highlight.color.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Page \(highlight.pageNumber)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    // Highlight text
                    ScrollView {
                        Text(highlight.text)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxHeight: 200)

                    // Note (if exists)
                    if isRevealed, let note = highlight.note, !note.content.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Note", systemImage: "note.text")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(note.content)
                                .font(.body)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.yellow.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    if !isRevealed && highlight.hasNote {
                        Button("Show Note") {
                            withAnimation {
                                isRevealed = true
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 5)
                .padding()
            }

            Spacer()
        }
        .onTapGesture {
            if highlights[safe: currentIndex]?.hasNote == true {
                withAnimation {
                    isRevealed.toggle()
                }
            }
        }
    }

    // MARK: - Navigation

    private var navigationBar: some View {
        HStack(spacing: 40) {
            Button {
                withAnimation {
                    currentIndex = max(0, currentIndex - 1)
                    isRevealed = false
                }
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title)
            }
            .buttonStyle(.plain)
            .disabled(currentIndex == 0)
            .keyboardShortcut(.leftArrow, modifiers: [])

            // Create flashcard button
            Button {
                // TODO: Integrate with flashcard creation
            } label: {
                Label("Create Flashcard", systemImage: "rectangle.on.rectangle.badge.plus")
            }
            .buttonStyle(.bordered)

            Button {
                withAnimation {
                    currentIndex = min(highlights.count - 1, currentIndex + 1)
                    isRevealed = false
                }
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title)
            }
            .buttonStyle(.plain)
            .disabled(currentIndex >= highlights.count - 1)
            .keyboardShortcut(.rightArrow, modifiers: [])
        }
        .padding()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "highlighter")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Highlights Yet")
                .font(.headline)

            Text("Create highlights while reading to review them here.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Safe Array Access

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
```

---

## Data Models

### Summary of New Models

| Model | Purpose | Key Properties |
|-------|---------|----------------|
| `Flashcard` | Spaced repetition cards | question, answer, easeFactor, interval, dueDate, state |
| `ReviewLog` | Review history | flashcardID, quality, intervals, responseTime |
| `StudySession` | Session tracking | startTime, endTime, type, activity metrics |
| `StudyStreak` | Streak & goals | currentStreak, dailyGoal, totalStats |

### Model Relationships

```
Book
├── highlights: [Highlight]
├── flashcards: [Flashcard]
└── studySessions: [StudySession] (via bookID)

Highlight
├── note: Note?
└── flashcard: Flashcard?

Flashcard
├── book: Book?
└── highlight: Highlight?
└── reviewLogs: [ReviewLog] (via flashcardID)
```

---

## Quality Standards

### Code Quality
- [ ] All new code follows existing patterns (@Observable, @Model, actor for services)
- [ ] SM-2 algorithm correctly implemented with proper bounds checking
- [ ] All user-facing text is clear and grammatically correct
- [ ] Keyboard shortcuts work correctly (1-4 for ratings, Space for flip)
- [ ] Animations are smooth and performant
- [ ] Memory management is proper (no retain cycles)

### Islamic Integration
- [ ] Session completion shows Islamic congratulation
- [ ] Streak badges use appropriate colors (no gambling-like mechanics)
- [ ] Study reminders can be linked to prayer times
- [ ] Focus mode doesn't block prayer notifications

### Accessibility
- [ ] VoiceOver support for flashcards
- [ ] Keyboard navigation throughout
- [ ] Sufficient color contrast for all states
- [ ] Dynamic Type support

---

## Testing Requirements

### Unit Tests

```swift
// Tests/SpacedRepetitionTests.swift

import XCTest
@testable import NoorReader

final class SpacedRepetitionTests: XCTestCase {

    var srs: SpacedRepetitionService!

    override func setUp() async throws {
        srs = SpacedRepetitionService()
    }

    func testNewCardGoodRating() async throws {
        let card = Flashcard(question: "Q", answer: "A")

        let result = await srs.processReview(card: card, quality: .good)

        XCTAssertEqual(result.newState, .learning)
        XCTAssertEqual(result.newInterval, 10)  // Second learning step
    }

    func testNewCardEasyRating() async throws {
        let card = Flashcard(question: "Q", answer: "A")

        let result = await srs.processReview(card: card, quality: .easy)

        XCTAssertEqual(result.newState, .review)
        XCTAssertEqual(result.newInterval, 4)  // Easy interval
    }

    func testReviewCardGoodRating() async throws {
        let card = Flashcard(question: "Q", answer: "A")
        card.state = .review
        card.interval = 10
        card.easeFactor = 2.5
        card.repetitions = 3

        let result = await srs.processReview(card: card, quality: .good)

        XCTAssertEqual(result.newState, .review)
        XCTAssertEqual(result.newInterval, 25)  // 10 * 2.5
        XCTAssertEqual(result.newEaseFactor, 2.5)  // Unchanged for good
    }

    func testReviewCardAgainRating() async throws {
        let card = Flashcard(question: "Q", answer: "A")
        card.state = .review
        card.interval = 10
        card.easeFactor = 2.5

        let result = await srs.processReview(card: card, quality: .again)

        XCTAssertEqual(result.newState, .relearning)
        XCTAssertEqual(result.newEaseFactor, 2.3)  // Reduced by 0.2
    }

    func testEaseFactorMinimum() async throws {
        let card = Flashcard(question: "Q", answer: "A")
        card.state = .review
        card.easeFactor = 1.4  // Already low

        let result = await srs.processReview(card: card, quality: .again)

        XCTAssertGreaterThanOrEqual(result.newEaseFactor, 1.3)
    }
}
```

### UI Tests

```swift
// UITests/FlashcardUITests.swift

import XCTest

final class FlashcardUITests: XCTestCase {

    func testFlashcardFlip() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to flashcard review
        // ... navigation steps ...

        // Tap to flip
        let card = app.otherElements["flashcard"]
        card.tap()

        // Verify answer is shown
        XCTAssertTrue(app.staticTexts["Answer"].exists)
    }

    func testRatingButtons() throws {
        let app = XCUIApplication()
        app.launch()

        // ... setup ...

        // Use keyboard shortcut
        app.typeKey("3", modifierFlags: [])  // Good rating

        // Verify card advanced
        // ...
    }
}
```

---

## Phase 4 Completion Criteria

### Required Features
- [ ] Flashcard creation from highlights works
- [ ] SM-2 scheduling correctly calculates next review
- [ ] Flashcard review UI with flip animation
- [ ] Rating buttons (Again/Hard/Good/Easy) work with keyboard shortcuts
- [ ] Study session tracking active
- [ ] Break reminders appear at configured intervals
- [ ] Study dashboard shows accurate statistics
- [ ] Streak tracking works across days
- [ ] Focus mode hides distracting UI
- [ ] Pomodoro timer functions correctly
- [ ] Quick review from highlights works
- [ ] All keyboard shortcuts documented

### Performance Targets
- [ ] Flashcard flip animation at 60fps
- [ ] Card queue loads in <100ms
- [ ] Statistics dashboard renders in <200ms
- [ ] No memory leaks during extended study sessions

### Islamic Integration
- [ ] Session completion shows appropriate message
- [ ] Break reminders optionally show duas
- [ ] Streak system doesn't mimic gambling mechanics
- [ ] Study reminders respect prayer times

### Documentation
- [ ] All new models documented
- [ ] SM-2 algorithm explained in comments
- [ ] Keyboard shortcuts listed in Help menu
- [ ] Settings options explained

---

## Implementation Order

1. **Week 1: Flashcard Foundation**
   - Flashcard and ReviewLog models
   - SpacedRepetitionService (SM-2)
   - FlashcardService CRUD
   - Basic FlashcardReviewView

2. **Week 2: Study Sessions**
   - StudySession model
   - StudySessionService with timers
   - Break reminders
   - Focus Mode

3. **Week 3: Analytics & Goals**
   - StudyStreak model
   - GoalService
   - StatsViewModel
   - StudyDashboardView

4. **Week 4: Polish**
   - Pomodoro timer
   - Quick Review from highlights
   - Keyboard shortcuts
   - Testing and bug fixes

---

بِاللَّهِ التَّوْفِيقُ

*With Allah is all success.*

---

*Phase 4 Complete - Ready for Phase 5: iOS & Sync*
