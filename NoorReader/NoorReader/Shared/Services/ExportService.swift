// ExportService.swift
// NoorReader
//
// Export annotations to Markdown, JSON, and Plain Text formats

import Foundation
import UniformTypeIdentifiers
import AppKit

enum ExportFormat: String, CaseIterable, Sendable {
    case markdown = "Markdown"
    case plainText = "Plain Text"
    case json = "JSON"

    var fileExtension: String {
        switch self {
        case .markdown: return "md"
        case .plainText: return "txt"
        case .json: return "json"
        }
    }

    var utType: UTType {
        switch self {
        case .markdown: return .plainText
        case .plainText: return .plainText
        case .json: return .json
        }
    }
}

enum ExportGroupingOption: String, CaseIterable, Sendable {
    case none = "No Grouping"
    case page = "By Page"
    case color = "By Color"
    case date = "By Date"
}

struct ExportOptions: Sendable {
    var format: ExportFormat = .markdown
    var grouping: ExportGroupingOption = .page
    var includeHighlightedText: Bool = true
    var includeNotes: Bool = true
    var includePageNumbers: Bool = true
    var includeTimestamps: Bool = false
    var includeColorLabels: Bool = true
}

@MainActor
final class ExportService {

    func export(book: Book, options: ExportOptions) -> String {
        switch options.format {
        case .markdown:
            return exportToMarkdown(book: book, options: options)
        case .plainText:
            return exportToPlainText(book: book, options: options)
        case .json:
            return exportToJSON(book: book, options: options)
        }
    }

    // MARK: - Markdown Export

    private func exportToMarkdown(book: Book, options: ExportOptions) -> String {
        var output = "# \(book.displayTitle)\n"
        output += "**Author:** \(book.displayAuthor)\n"
        output += "**Exported:** \(Date().formatted(date: .long, time: .shortened))\n\n"
        output += "---\n\n"

        let highlights = book.highlights.sorted { $0.pageNumber < $1.pageNumber }

        if highlights.isEmpty {
            output += "*No annotations to export.*\n"
            return output
        }

        output += "## Annotations (\(highlights.count))\n\n"

        switch options.grouping {
        case .none:
            for highlight in highlights {
                output += formatHighlightMarkdown(highlight, options: options)
            }

        case .page:
            let grouped = Dictionary(grouping: highlights) { $0.pageNumber }
            for pageNumber in grouped.keys.sorted() {
                output += "### Page \(pageNumber + 1)\n\n"
                for highlight in grouped[pageNumber] ?? [] {
                    output += formatHighlightMarkdown(highlight, options: options, includePage: false)
                }
            }

        case .color:
            let grouped = Dictionary(grouping: highlights) { $0.color }
            for color in HighlightColor.allCases {
                guard let colorHighlights = grouped[color], !colorHighlights.isEmpty else { continue }
                output += "### \(color.displayName) (\(colorHighlights.count))\n\n"
                for highlight in colorHighlights.sorted(by: { $0.pageNumber < $1.pageNumber }) {
                    output += formatHighlightMarkdown(highlight, options: options, includeColor: false)
                }
            }

        case .date:
            let calendar = Calendar.current
            let grouped = Dictionary(grouping: highlights) {
                calendar.startOfDay(for: $0.dateCreated)
            }
            for date in grouped.keys.sorted().reversed() {
                output += "### \(date.formatted(date: .long, time: .omitted))\n\n"
                for highlight in grouped[date] ?? [] {
                    output += formatHighlightMarkdown(highlight, options: options)
                }
            }
        }

        // Standalone notes
        let standaloneNotes = book.notes.filter { $0.isStandalone }
        if !standaloneNotes.isEmpty && options.includeNotes {
            output += "---\n\n"
            output += "## Notes (\(standaloneNotes.count))\n\n"
            for note in standaloneNotes.sorted(by: { ($0.pageNumber ?? 0) < ($1.pageNumber ?? 0) }) {
                output += formatNoteMarkdown(note, options: options)
            }
        }

        return output
    }

    private func formatHighlightMarkdown(
        _ highlight: Highlight,
        options: ExportOptions,
        includePage: Bool = true,
        includeColor: Bool = true
    ) -> String {
        var output = ""

        // Metadata line
        var meta: [String] = []
        if includePage && options.includePageNumbers {
            meta.append("p. \(highlight.pageNumber + 1)")
        }
        if includeColor && options.includeColorLabels {
            meta.append(highlight.color.displayName)
        }
        if options.includeTimestamps {
            meta.append(highlight.dateCreated.formatted(date: .abbreviated, time: .shortened))
        }

        if !meta.isEmpty {
            output += "*\(meta.joined(separator: " · "))*\n\n"
        }

        // Highlighted text as blockquote
        if options.includeHighlightedText {
            output += "> \(highlight.text.replacingOccurrences(of: "\n", with: "\n> "))\n\n"
        }

        // Note
        if options.includeNotes, let note = highlight.note, !note.content.isEmpty {
            output += "📝 \(note.content)\n\n"
        }

        output += "---\n\n"

        return output
    }

    private func formatNoteMarkdown(_ note: Note, options: ExportOptions) -> String {
        var output = ""

        var meta: [String] = []
        if let page = note.pageNumber, options.includePageNumbers {
            meta.append("p. \(page + 1)")
        }
        if options.includeTimestamps {
            meta.append(note.dateCreated.formatted(date: .abbreviated, time: .shortened))
        }

        if !meta.isEmpty {
            output += "*\(meta.joined(separator: " · "))*\n\n"
        }

        output += "\(note.content)\n\n"
        output += "---\n\n"

        return output
    }

    // MARK: - Plain Text Export

    private func exportToPlainText(book: Book, options: ExportOptions) -> String {
        var output = "\(book.displayTitle)\n"
        output += "Author: \(book.displayAuthor)\n"
        output += "Exported: \(Date().formatted(date: .long, time: .shortened))\n"
        output += String(repeating: "=", count: 50) + "\n\n"

        let highlights = book.highlights.sorted { $0.pageNumber < $1.pageNumber }

        for highlight in highlights {
            if options.includePageNumbers {
                output += "[Page \(highlight.pageNumber + 1)]"
            }
            if options.includeColorLabels {
                output += " [\(highlight.color.displayName)]"
            }
            output += "\n"

            if options.includeHighlightedText {
                output += highlight.text + "\n"
            }

            if options.includeNotes, let note = highlight.note, !note.content.isEmpty {
                output += "  Note: \(note.content)\n"
            }

            output += "\n"
        }

        return output
    }

    // MARK: - JSON Export

    private func exportToJSON(book: Book, options: ExportOptions) -> String {
        struct ExportedHighlight: Codable {
            let text: String
            let page: Int
            let color: String
            let dateCreated: Date
            let note: String?
        }

        struct ExportedNote: Codable {
            let content: String
            let page: Int?
            let dateCreated: Date
        }

        struct ExportedBook: Codable {
            let title: String
            let author: String
            let exportDate: Date
            let highlights: [ExportedHighlight]
            let standaloneNotes: [ExportedNote]
        }

        let exportedHighlights = book.highlights.map { highlight in
            ExportedHighlight(
                text: highlight.text,
                page: highlight.pageNumber + 1,
                color: highlight.color.displayName,
                dateCreated: highlight.dateCreated,
                note: highlight.note?.content
            )
        }

        let exportedNotes = book.standaloneNotes.map { note in
            ExportedNote(
                content: note.content,
                page: note.pageNumber.map { $0 + 1 },
                dateCreated: note.dateCreated
            )
        }

        let exportedBook = ExportedBook(
            title: book.displayTitle,
            author: book.displayAuthor,
            exportDate: Date(),
            highlights: exportedHighlights,
            standaloneNotes: exportedNotes
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(exportedBook),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "{}"
        }

        return jsonString
    }

    // MARK: - Save to File

    func saveToFile(
        content: String,
        filename: String,
        format: ExportFormat
    ) async throws -> URL {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [format.utType]
        panel.nameFieldStringValue = "\(filename).\(format.fileExtension)"
        panel.canCreateDirectories = true

        guard let window = NSApp.keyWindow else {
            throw ExportError.noWindow
        }

        let response = await panel.beginSheetModal(for: window)

        guard response == .OK, let url = panel.url else {
            throw ExportError.cancelled
        }

        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func copyToClipboard(_ content: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
    }
}

enum ExportError: LocalizedError {
    case cancelled
    case writeFailed
    case noWindow

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Export was cancelled."
        case .writeFailed:
            return "Failed to write the file."
        case .noWindow:
            return "No active window found."
        }
    }
}
