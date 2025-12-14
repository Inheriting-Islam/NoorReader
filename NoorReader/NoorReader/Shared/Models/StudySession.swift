// StudySession.swift
// NoorReader
//
// SwiftData model for tracking study sessions

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

    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: startTime)
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

    func updateDuration() {
        if endTime == nil {
            durationSeconds = Int(Date().timeIntervalSince(startTime))
        }
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

enum SessionType: String, CaseIterable, Identifiable, Sendable {
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
