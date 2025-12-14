// TextChunk.swift
// NoorReader
//
// SwiftData model for storing text chunks with embeddings for semantic search

import SwiftData
import Foundation

/// A persisted chunk of text from a PDF with its embedding vector for semantic search
/// Note: Named PersistedTextChunk to avoid conflict with TextChunk in AITypes.swift
@Model
final class PersistedTextChunk {
    // MARK: - Properties

    @Attribute(.unique)
    var id: UUID

    /// ID of the book this chunk belongs to
    var bookID: UUID

    /// Page number (0-indexed) where this chunk appears
    var pageNumber: Int

    /// Index of this chunk within the page
    var chunkIndex: Int

    /// The actual text content
    var text: String

    /// Serialized embedding vector as Data (array of Float/Double)
    @Attribute(.externalStorage)
    var embeddingData: Data?

    /// When this chunk was created/indexed
    var createdAt: Date

    /// Hash of the text to detect changes
    var textHash: String

    // MARK: - Computed Properties

    /// Deserialize the embedding vector
    var embedding: [Double]? {
        get {
            guard let data = embeddingData else { return nil }
            return try? JSONDecoder().decode([Double].self, from: data)
        }
    }

    /// Set the embedding vector (serializes to Data)
    func setEmbedding(_ vector: [Double]) {
        self.embeddingData = try? JSONEncoder().encode(vector)
    }

    /// Preview of the text (first 100 characters)
    var textPreview: String {
        if text.count <= 100 {
            return text
        }
        return String(text.prefix(100)) + "..."
    }

    // MARK: - Initialization

    init(
        bookID: UUID,
        pageNumber: Int,
        chunkIndex: Int,
        text: String,
        embedding: [Double]? = nil
    ) {
        self.id = UUID()
        self.bookID = bookID
        self.pageNumber = pageNumber
        self.chunkIndex = chunkIndex
        self.text = text
        self.createdAt = Date()
        self.textHash = PersistedTextChunk.computeHash(for: text)

        if let embedding {
            setEmbedding(embedding)
        }
    }

    // MARK: - Helper Methods

    /// Compute a hash for the text to detect changes
    static func computeHash(for text: String) -> String {
        // Simple hash using SHA256-like approach
        var hash = 0
        for char in text.unicodeScalars {
            hash = hash &* 31 &+ Int(char.value)
        }
        return String(format: "%08x", abs(hash))
    }

    /// Check if the text has changed
    func hasTextChanged(newText: String) -> Bool {
        return PersistedTextChunk.computeHash(for: newText) != textHash
    }
}

// MARK: - Semantic Index Status

/// Tracks the indexing status for a book
@Model
final class SemanticIndexStatus {
    @Attribute(.unique)
    var id: UUID

    /// ID of the book being indexed
    @Attribute(.unique)
    var bookID: UUID

    /// When indexing was last started
    var lastIndexStarted: Date?

    /// When indexing was last completed
    var lastIndexCompleted: Date?

    /// Total pages in the book at time of indexing
    var totalPages: Int

    /// Number of pages indexed
    var pagesIndexed: Int

    /// Number of chunks created
    var chunksCreated: Int

    /// Current status
    var statusRaw: String

    /// Error message if failed
    var errorMessage: String?

    var status: IndexingStatus {
        get { IndexingStatus(rawValue: statusRaw) ?? .notStarted }
        set { statusRaw = newValue.rawValue }
    }

    var progress: Double {
        guard totalPages > 0 else { return 0 }
        return Double(pagesIndexed) / Double(totalPages)
    }

    var isComplete: Bool {
        status == .completed && pagesIndexed >= totalPages
    }

    var needsReindex: Bool {
        // Consider reindexing if more than 7 days old
        guard let completed = lastIndexCompleted else { return true }
        let daysSinceIndex = Calendar.current.dateComponents([.day], from: completed, to: Date()).day ?? 0
        return daysSinceIndex > 7
    }

    init(bookID: UUID, totalPages: Int) {
        self.id = UUID()
        self.bookID = bookID
        self.totalPages = totalPages
        self.pagesIndexed = 0
        self.chunksCreated = 0
        self.statusRaw = IndexingStatus.notStarted.rawValue
    }

    func startIndexing() {
        status = .inProgress
        lastIndexStarted = Date()
        pagesIndexed = 0
        chunksCreated = 0
        errorMessage = nil
    }

    func updateProgress(pagesIndexed: Int, chunksCreated: Int) {
        self.pagesIndexed = pagesIndexed
        self.chunksCreated = chunksCreated
    }

    func completeIndexing() {
        status = .completed
        lastIndexCompleted = Date()
    }

    func failIndexing(error: String) {
        status = .failed
        errorMessage = error
    }
}

// MARK: - Indexing Status

enum IndexingStatus: String, CaseIterable, Sendable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed = "completed"
    case failed = "failed"

    var displayName: String {
        switch self {
        case .notStarted: return "Not Indexed"
        case .inProgress: return "Indexing..."
        case .completed: return "Indexed"
        case .failed: return "Failed"
        }
    }

    var icon: String {
        switch self {
        case .notStarted: return "doc.text.magnifyingglass"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    var color: String {
        switch self {
        case .notStarted: return "gray"
        case .inProgress: return "blue"
        case .completed: return "green"
        case .failed: return "red"
        }
    }
}

// MARK: - Search Scope

enum SemanticSearchScope: String, CaseIterable, Identifiable {
    case currentBook = "current_book"
    case collection = "collection"
    case library = "library"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .currentBook: return "Current Book"
        case .collection: return "Collection"
        case .library: return "Entire Library"
        }
    }

    var icon: String {
        switch self {
        case .currentBook: return "book"
        case .collection: return "books.vertical"
        case .library: return "building.columns"
        }
    }
}
