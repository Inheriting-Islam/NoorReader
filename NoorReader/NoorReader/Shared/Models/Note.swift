// Note.swift
// NoorReader
//
// SwiftData model for notes attached to highlights or standalone

import SwiftData
import Foundation

@Model
final class Note {
    var id: UUID
    var content: String
    var dateCreated: Date
    var dateModified: Date
    var pageNumber: Int?

    // Relationships
    var highlight: Highlight?
    var book: Book?

    var isStandalone: Bool {
        highlight == nil
    }

    var displayTitle: String {
        // Return first line or truncated content
        let firstLine = content.split(separator: "\n").first.map(String.init) ?? content
        if firstLine.count > 50 {
            return String(firstLine.prefix(47)) + "..."
        }
        return firstLine.isEmpty ? "Untitled Note" : firstLine
    }

    var preview: String {
        if content.count > 100 {
            return String(content.prefix(97)) + "..."
        }
        return content
    }

    init(
        content: String = "",
        pageNumber: Int? = nil,
        highlight: Highlight? = nil
    ) {
        self.id = UUID()
        self.content = content
        self.dateCreated = Date()
        self.dateModified = Date()
        self.pageNumber = pageNumber
        self.highlight = highlight
    }

    func updateContent(_ newContent: String) {
        content = newContent
        dateModified = Date()
    }
}
