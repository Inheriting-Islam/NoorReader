// Bookmark.swift
// NoorReader
//
// SwiftData model for page bookmarks

import SwiftData
import Foundation

@Model
final class Bookmark {
    var id: UUID
    var pageNumber: Int
    var title: String
    var dateCreated: Date

    var book: Book?

    init(pageNumber: Int, title: String = "") {
        self.id = UUID()
        self.pageNumber = pageNumber
        self.title = title.isEmpty ? "Page \(pageNumber + 1)" : title
        self.dateCreated = Date()
    }
}
