// ReviewLog.swift
// NoorReader
//
// SwiftData model for recording flashcard review history

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
