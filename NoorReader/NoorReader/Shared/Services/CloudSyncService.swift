// CloudSyncService.swift
// NoorReader
//
// iCloud sync service for cross-device synchronization

import Foundation
import SwiftData
import CloudKit

// MARK: - Syncable Protocol

/// Protocol for models that can be synced to iCloud
protocol Syncable {
    var syncID: UUID { get }
    var lastModified: Date { get }
    var isSynced: Bool { get set }
    var cloudRecordID: String? { get set }

    func toCloudRecord() -> CKRecord
    static func fromCloudRecord(_ record: CKRecord) -> Self?
}

// MARK: - Sync Status

enum SyncStatus: String, Sendable {
    case idle = "idle"
    case syncing = "syncing"
    case synced = "synced"
    case error = "error"
    case offline = "offline"
    case disabled = "disabled"

    var displayName: String {
        switch self {
        case .idle: return "Ready"
        case .syncing: return "Syncing..."
        case .synced: return "Synced"
        case .error: return "Error"
        case .offline: return "Offline"
        case .disabled: return "Disabled"
        }
    }

    var icon: String {
        switch self {
        case .idle: return "icloud"
        case .syncing: return "arrow.triangle.2.circlepath.icloud"
        case .synced: return "checkmark.icloud"
        case .error: return "exclamationmark.icloud"
        case .offline: return "icloud.slash"
        case .disabled: return "xmark.icloud"
        }
    }

    var color: String {
        switch self {
        case .idle: return "blue"
        case .syncing: return "blue"
        case .synced: return "green"
        case .error: return "red"
        case .offline: return "gray"
        case .disabled: return "gray"
        }
    }
}

// MARK: - Sync Record Types

struct SyncRecordTypes {
    static let bookProgress = "BookProgress"
    static let highlight = "Highlight"
    static let bookmark = "Bookmark"
    static let note = "Note"
    static let flashcard = "Flashcard"
    static let studyStreak = "StudyStreak"
    static let studySession = "StudySession"
    static let userSettings = "UserSettings"
}

// MARK: - Sync Conflict

struct SyncConflict: Identifiable {
    let id: UUID
    let recordType: String
    let localVersion: Any
    let cloudVersion: Any
    let localModified: Date
    let cloudModified: Date

    var resolution: ConflictResolution?

    enum ConflictResolution {
        case useLocal
        case useCloud
        case merge
    }
}

// MARK: - Cloud Sync Service

/// Service for syncing data across devices using iCloud
@MainActor
@Observable
final class CloudSyncService {

    // MARK: - Properties

    private var modelContext: ModelContext?
    private let container: CKContainer
    private let privateDatabase: CKDatabase

    var status: SyncStatus = .idle
    var lastSyncDate: Date?
    var pendingChanges: Int = 0
    var isSyncEnabled: Bool = false
    var conflicts: [SyncConflict] = []
    var error: Error?

    // Sync configuration
    private let syncInterval: TimeInterval = 300  // 5 minutes
    private var syncTimer: Timer?
    private var isBackgroundSyncEnabled = true

    // MARK: - Singleton

    static let shared = CloudSyncService()

    private init() {
        self.container = CKContainer.default()
        self.privateDatabase = container.privateCloudDatabase
    }

    // MARK: - Configuration

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        checkiCloudStatus()
    }

    func enableSync(_ enabled: Bool) {
        isSyncEnabled = enabled

        if enabled {
            startBackgroundSync()
        } else {
            stopBackgroundSync()
            status = .disabled
        }

        UserDefaults.standard.set(enabled, forKey: "iCloudSyncEnabled")
    }

    // MARK: - iCloud Status

    private func checkiCloudStatus() {
        container.accountStatus { [weak self] status, error in
            Task { @MainActor in
                switch status {
                case .available:
                    self?.isSyncEnabled = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
                    if self?.isSyncEnabled == true {
                        self?.status = .idle
                        self?.startBackgroundSync()
                    } else {
                        self?.status = .disabled
                    }
                case .noAccount:
                    self?.status = .disabled
                    self?.error = CloudSyncError.noiCloudAccount
                case .restricted, .couldNotDetermine, .temporarilyUnavailable:
                    self?.status = .offline
                @unknown default:
                    self?.status = .offline
                }
            }
        }
    }

    // MARK: - Background Sync

    private func startBackgroundSync() {
        guard isBackgroundSyncEnabled else { return }

        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.syncAll()
            }
        }
    }

    private func stopBackgroundSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }

    // MARK: - Sync Operations

    /// Sync all data types
    func syncAll() async {
        guard isSyncEnabled, status != .syncing else { return }

        status = .syncing
        error = nil

        do {
            // Sync each data type
            try await syncBookProgress()
            try await syncHighlights()
            try await syncBookmarks()
            try await syncFlashcards()
            try await syncStudyData()

            status = .synced
            lastSyncDate = Date()
            pendingChanges = 0
            saveLastSyncDate()

        } catch {
            self.error = error
            status = .error
        }
    }

    /// Force sync now
    func syncNow() async {
        await syncAll()
    }

    // MARK: - Book Progress Sync

    private func syncBookProgress() async throws {
        guard let modelContext else { return }

        // Fetch all books
        let books = try modelContext.fetch(FetchDescriptor<Book>())

        for book in books {
            // Create or update cloud record
            let record = createBookProgressRecord(for: book)

            do {
                _ = try await privateDatabase.save(record)
            } catch let error as CKError {
                if error.code == .serverRecordChanged {
                    // Handle conflict
                    try await handleBookProgressConflict(book: book, error: error)
                } else {
                    throw error
                }
            }
        }

        // Fetch and apply remote changes
        try await fetchRemoteBookProgress()
    }

    private func createBookProgressRecord(for book: Book) -> CKRecord {
        let recordID = CKRecord.ID(recordName: book.id.uuidString)
        let record = CKRecord(recordType: SyncRecordTypes.bookProgress, recordID: recordID)

        record["bookID"] = book.id.uuidString as CKRecordValue
        record["title"] = book.title as CKRecordValue
        record["currentPage"] = book.currentPage as CKRecordValue
        record["totalPages"] = book.totalPages as CKRecordValue
        record["lastRead"] = (book.lastRead ?? Date()) as CKRecordValue
        record["isFavorite"] = (book.isFavorite ? 1 : 0) as CKRecordValue

        return record
    }

    private func fetchRemoteBookProgress() async throws {
        let query = CKQuery(
            recordType: SyncRecordTypes.bookProgress,
            predicate: NSPredicate(value: true)
        )

        let (results, _) = try await privateDatabase.records(matching: query)

        for (_, result) in results {
            if case .success(let record) = result {
                try await applyBookProgressRecord(record)
            }
        }
    }

    private func applyBookProgressRecord(_ record: CKRecord) async throws {
        guard let modelContext,
              let bookIDString = record["bookID"] as? String,
              let bookID = UUID(uuidString: bookIDString) else { return }

        let descriptor = FetchDescriptor<Book>(
            predicate: #Predicate { $0.id == bookID }
        )

        guard let book = try modelContext.fetch(descriptor).first else { return }

        // Check if remote is newer
        let remoteLastRead = record["lastRead"] as? Date ?? Date.distantPast
        let localLastRead = book.lastRead ?? Date.distantPast

        if remoteLastRead > localLastRead {
            // Apply remote changes
            if let currentPage = record["currentPage"] as? Int {
                book.currentPage = currentPage
            }
            book.lastRead = remoteLastRead
            if let isFavorite = record["isFavorite"] as? Int {
                book.isFavorite = isFavorite == 1
            }
            try modelContext.save()
        }
    }

    private func handleBookProgressConflict(book: Book, error: CKError) async throws {
        // Last-write-wins strategy
        guard let serverRecord = error.serverRecord else { return }

        let serverLastRead = serverRecord["lastRead"] as? Date ?? Date.distantPast
        let localLastRead = book.lastRead ?? Date()

        if localLastRead > serverLastRead {
            // Local is newer, overwrite server
            serverRecord["currentPage"] = book.currentPage as CKRecordValue
            serverRecord["lastRead"] = localLastRead as CKRecordValue
            _ = try await privateDatabase.save(serverRecord)
        } else {
            // Server is newer, apply to local
            try await applyBookProgressRecord(serverRecord)
        }
    }

    // MARK: - Highlights Sync

    private func syncHighlights() async throws {
        guard let modelContext else { return }

        let highlights = try modelContext.fetch(FetchDescriptor<Highlight>())

        for highlight in highlights {
            let record = createHighlightRecord(for: highlight)
            _ = try? await privateDatabase.save(record)
        }

        try await fetchRemoteHighlights()
    }

    private func createHighlightRecord(for highlight: Highlight) -> CKRecord {
        let recordID = CKRecord.ID(recordName: highlight.id.uuidString)
        let record = CKRecord(recordType: SyncRecordTypes.highlight, recordID: recordID)

        record["highlightID"] = highlight.id.uuidString as CKRecordValue
        record["text"] = highlight.text as CKRecordValue
        record["pageNumber"] = highlight.pageNumber as CKRecordValue
        record["colorName"] = highlight.colorName as CKRecordValue
        record["dateCreated"] = highlight.dateCreated as CKRecordValue

        if let bookID = highlight.book?.id {
            record["bookID"] = bookID.uuidString as CKRecordValue
        }

        return record
    }

    private func fetchRemoteHighlights() async throws {
        let lastSync = loadLastSyncDate() ?? Date.distantPast

        let query = CKQuery(
            recordType: SyncRecordTypes.highlight,
            predicate: NSPredicate(format: "modificationDate > %@", lastSync as NSDate)
        )

        let (results, _) = try await privateDatabase.records(matching: query)

        for (_, result) in results {
            if case .success(let record) = result {
                try await applyHighlightRecord(record)
            }
        }
    }

    private func applyHighlightRecord(_ record: CKRecord) async throws {
        guard let modelContext,
              let highlightIDString = record["highlightID"] as? String,
              let highlightID = UUID(uuidString: highlightIDString) else { return }

        // Check if highlight exists
        let descriptor = FetchDescriptor<Highlight>(
            predicate: #Predicate { $0.id == highlightID }
        )

        if try modelContext.fetch(descriptor).first == nil {
            // Create new highlight from remote
            guard let text = record["text"] as? String,
                  let pageNumber = record["pageNumber"] as? Int else { return }

            let colorName = record["colorName"] as? String ?? "yellow"
            let color = HighlightColor(rawValue: colorName) ?? .yellow

            let highlight = Highlight(
                text: text,
                pageNumber: pageNumber,
                bounds: nil,
                color: color
            )

            // Link to book if possible
            if let bookIDString = record["bookID"] as? String,
               let bookID = UUID(uuidString: bookIDString) {
                let bookDescriptor = FetchDescriptor<Book>(
                    predicate: #Predicate { $0.id == bookID }
                )
                highlight.book = try modelContext.fetch(bookDescriptor).first
            }

            modelContext.insert(highlight)
            try modelContext.save()
        }
    }

    // MARK: - Bookmarks Sync

    private func syncBookmarks() async throws {
        guard let modelContext else { return }

        let bookmarks = try modelContext.fetch(FetchDescriptor<Bookmark>())

        for bookmark in bookmarks {
            let record = createBookmarkRecord(for: bookmark)
            _ = try? await privateDatabase.save(record)
        }
    }

    private func createBookmarkRecord(for bookmark: Bookmark) -> CKRecord {
        let recordID = CKRecord.ID(recordName: bookmark.id.uuidString)
        let record = CKRecord(recordType: SyncRecordTypes.bookmark, recordID: recordID)

        record["bookmarkID"] = bookmark.id.uuidString as CKRecordValue
        record["pageNumber"] = bookmark.pageNumber as CKRecordValue
        record["dateCreated"] = bookmark.dateCreated as CKRecordValue
        record["title"] = bookmark.title as CKRecordValue

        if let bookID = bookmark.book?.id {
            record["bookID"] = bookID.uuidString as CKRecordValue
        }

        return record
    }

    // MARK: - Flashcards Sync

    private func syncFlashcards() async throws {
        guard let modelContext else { return }

        let flashcards = try modelContext.fetch(FetchDescriptor<Flashcard>())

        for flashcard in flashcards {
            let record = createFlashcardRecord(for: flashcard)
            _ = try? await privateDatabase.save(record)
        }

        try await fetchRemoteFlashcards()
    }

    private func createFlashcardRecord(for flashcard: Flashcard) -> CKRecord {
        let recordID = CKRecord.ID(recordName: flashcard.id.uuidString)
        let record = CKRecord(recordType: SyncRecordTypes.flashcard, recordID: recordID)

        record["flashcardID"] = flashcard.id.uuidString as CKRecordValue
        record["front"] = flashcard.front as CKRecordValue
        record["back"] = flashcard.back as CKRecordValue
        record["dateCreated"] = flashcard.dateCreated as CKRecordValue
        record["dateModified"] = flashcard.dateModified as CKRecordValue

        // SM-2 data
        record["repetitions"] = flashcard.repetitions as CKRecordValue
        record["easeFactor"] = flashcard.easeFactor as CKRecordValue
        record["interval"] = flashcard.interval as CKRecordValue
        record["dueDate"] = flashcard.dueDate as CKRecordValue
        record["stateRaw"] = flashcard.stateRaw as CKRecordValue
        record["learningStep"] = flashcard.learningStep as CKRecordValue

        if let bookID = flashcard.book?.id {
            record["bookID"] = bookID.uuidString as CKRecordValue
        }

        return record
    }

    private func fetchRemoteFlashcards() async throws {
        let lastSync = loadLastSyncDate() ?? Date.distantPast

        let query = CKQuery(
            recordType: SyncRecordTypes.flashcard,
            predicate: NSPredicate(format: "modificationDate > %@", lastSync as NSDate)
        )

        let (results, _) = try await privateDatabase.records(matching: query)

        for (_, result) in results {
            if case .success(let record) = result {
                try await applyFlashcardRecord(record)
            }
        }
    }

    private func applyFlashcardRecord(_ record: CKRecord) async throws {
        guard let modelContext,
              let flashcardIDString = record["flashcardID"] as? String,
              let flashcardID = UUID(uuidString: flashcardIDString) else { return }

        let descriptor = FetchDescriptor<Flashcard>(
            predicate: #Predicate { $0.id == flashcardID }
        )

        if let existingCard = try modelContext.fetch(descriptor).first {
            // Update if remote is newer
            let remoteModified = record.modificationDate ?? Date.distantPast
            if remoteModified > existingCard.dateModified {
                applyFlashcardData(record, to: existingCard)
                try modelContext.save()
            }
        } else {
            // Create new flashcard
            guard let front = record["front"] as? String,
                  let back = record["back"] as? String else { return }

            let flashcard = Flashcard(front: front, back: back)
            applyFlashcardData(record, to: flashcard)

            // Link to book
            if let bookIDString = record["bookID"] as? String,
               let bookID = UUID(uuidString: bookIDString) {
                let bookDescriptor = FetchDescriptor<Book>(
                    predicate: #Predicate { $0.id == bookID }
                )
                flashcard.book = try modelContext.fetch(bookDescriptor).first
            }

            modelContext.insert(flashcard)
            try modelContext.save()
        }
    }

    private func applyFlashcardData(_ record: CKRecord, to flashcard: Flashcard) {
        if let front = record["front"] as? String {
            flashcard.front = front
        }
        if let back = record["back"] as? String {
            flashcard.back = back
        }
        if let repetitions = record["repetitions"] as? Int {
            flashcard.repetitions = repetitions
        }
        if let easeFactor = record["easeFactor"] as? Double {
            flashcard.easeFactor = easeFactor
        }
        if let interval = record["interval"] as? Int {
            flashcard.interval = interval
        }
        if let dueDate = record["dueDate"] as? Date {
            flashcard.dueDate = dueDate
        }
        if let stateRaw = record["stateRaw"] as? String {
            flashcard.stateRaw = stateRaw
        }
        if let learningStep = record["learningStep"] as? Int {
            flashcard.learningStep = learningStep
        }
    }

    // MARK: - Study Data Sync

    private func syncStudyData() async throws {
        guard let modelContext else { return }

        // Sync study streak
        let streaks = try modelContext.fetch(FetchDescriptor<StudyStreak>())
        for streak in streaks {
            let record = createStudyStreakRecord(for: streak)
            _ = try? await privateDatabase.save(record)
        }

        // Fetch remote streak and merge
        try await fetchRemoteStudyStreak()
    }

    private func createStudyStreakRecord(for streak: StudyStreak) -> CKRecord {
        let recordID = CKRecord.ID(recordName: streak.id.uuidString)
        let record = CKRecord(recordType: SyncRecordTypes.studyStreak, recordID: recordID)

        record["streakID"] = streak.id.uuidString as CKRecordValue
        record["currentStreak"] = streak.currentStreak as CKRecordValue
        record["longestStreak"] = streak.longestStreak as CKRecordValue
        record["totalStudyDays"] = streak.totalStudyDays as CKRecordValue
        record["totalMinutes"] = streak.totalMinutes as CKRecordValue
        record["totalFlashcardsReviewed"] = streak.totalFlashcardsReviewed as CKRecordValue
        record["totalPagesRead"] = streak.totalPagesRead as CKRecordValue
        record["dailyGoalMinutes"] = streak.dailyGoalMinutes as CKRecordValue

        if let lastStudyDate = streak.lastStudyDate {
            record["lastStudyDate"] = lastStudyDate as CKRecordValue
        }

        return record
    }

    private func fetchRemoteStudyStreak() async throws {
        let query = CKQuery(
            recordType: SyncRecordTypes.studyStreak,
            predicate: NSPredicate(value: true)
        )

        let (results, _) = try await privateDatabase.records(matching: query)

        for (_, result) in results {
            if case .success(let record) = result {
                try await mergeStudyStreakRecord(record)
            }
        }
    }

    private func mergeStudyStreakRecord(_ record: CKRecord) async throws {
        guard let modelContext else { return }

        let streaks = try modelContext.fetch(FetchDescriptor<StudyStreak>())
        guard let localStreak = streaks.first else { return }

        // Merge by taking max values
        if let remoteLongest = record["longestStreak"] as? Int {
            localStreak.longestStreak = max(localStreak.longestStreak, remoteLongest)
        }
        if let remoteTotalDays = record["totalStudyDays"] as? Int {
            localStreak.totalStudyDays = max(localStreak.totalStudyDays, remoteTotalDays)
        }
        if let remoteTotalMinutes = record["totalMinutes"] as? Int {
            localStreak.totalMinutes = max(localStreak.totalMinutes, remoteTotalMinutes)
        }
        if let remoteFlashcards = record["totalFlashcardsReviewed"] as? Int {
            localStreak.totalFlashcardsReviewed = max(localStreak.totalFlashcardsReviewed, remoteFlashcards)
        }
        if let remotePages = record["totalPagesRead"] as? Int {
            localStreak.totalPagesRead = max(localStreak.totalPagesRead, remotePages)
        }

        try modelContext.save()
    }

    // MARK: - Last Sync Date

    private func saveLastSyncDate() {
        UserDefaults.standard.set(lastSyncDate, forKey: "CloudSyncLastDate")
    }

    private func loadLastSyncDate() -> Date? {
        UserDefaults.standard.object(forKey: "CloudSyncLastDate") as? Date
    }
}

// MARK: - Errors

enum CloudSyncError: LocalizedError {
    case noiCloudAccount
    case syncFailed(String)
    case conflictNotResolved
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .noiCloudAccount:
            return "No iCloud account configured. Please sign in to iCloud in System Settings."
        case .syncFailed(let reason):
            return "Sync failed: \(reason)"
        case .conflictNotResolved:
            return "Sync conflict could not be resolved automatically."
        case .networkUnavailable:
            return "Network unavailable. Sync will resume when connected."
        }
    }
}
