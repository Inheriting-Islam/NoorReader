// Book.swift
// NoorReader
//
// SwiftData model for PDF books in the library

import SwiftData
import Foundation

@Model
final class Book {
    // MARK: - Properties

    @Attribute(.unique) var id: UUID
    var title: String
    var author: String
    var fileURL: URL
    @Attribute(.externalStorage) var coverImageData: Data?
    var dateAdded: Date
    var lastRead: Date?
    var currentPage: Int
    var totalPages: Int
    var isFavorite: Bool

    // MARK: - Relationships

    @Relationship(deleteRule: .cascade, inverse: \Highlight.book)
    var highlights: [Highlight] = []

    @Relationship(deleteRule: .cascade, inverse: \Bookmark.book)
    var bookmarks: [Bookmark] = []

    @Relationship(deleteRule: .cascade, inverse: \Note.book)
    var notes: [Note] = []

    @Relationship(inverse: \Collection.books)
    var collections: [Collection] = []

    // Computed property for standalone notes (not attached to highlights)
    var standaloneNotes: [Note] {
        notes.filter { $0.isStandalone }
    }

    // MARK: - Computed Properties

    var progress: Double {
        guard totalPages > 0 else { return 0 }
        return Double(currentPage) / Double(totalPages)
    }

    var progressPercentage: Int {
        Int(progress * 100)
    }

    var isStarted: Bool {
        currentPage > 0
    }

    var isCompleted: Bool {
        currentPage >= totalPages && totalPages > 0
    }

    var displayTitle: String {
        title.isEmpty ? "Untitled" : title
    }

    var displayAuthor: String {
        author.isEmpty ? "Unknown Author" : author
    }

    // MARK: - Initialization

    init(
        title: String,
        author: String = "",
        fileURL: URL,
        totalPages: Int = 0
    ) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.fileURL = fileURL
        self.dateAdded = Date()
        self.currentPage = 0
        self.totalPages = totalPages
        self.isFavorite = false
    }
}
