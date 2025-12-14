// EnhancedExportService.swift
// NoorReader
//
// Extended export functionality with Anki, CSV, and sharing features

import Foundation
import UniformTypeIdentifiers
import AppKit
import SwiftData

// MARK: - Enhanced Export Formats

enum EnhancedExportFormat: String, CaseIterable, Identifiable, Sendable {
    case markdown = "markdown"
    case plainText = "plain_text"
    case json = "json"
    case csv = "csv"
    case anki = "anki"
    case pdf = "pdf"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .markdown: return "Markdown"
        case .plainText: return "Plain Text"
        case .json: return "JSON"
        case .csv: return "CSV (Spreadsheet)"
        case .anki: return "Anki Deck"
        case .pdf: return "PDF Document"
        }
    }

    var fileExtension: String {
        switch self {
        case .markdown: return "md"
        case .plainText: return "txt"
        case .json: return "json"
        case .csv: return "csv"
        case .anki: return "apkg"
        case .pdf: return "pdf"
        }
    }

    var icon: String {
        switch self {
        case .markdown: return "doc.text"
        case .plainText: return "doc.plaintext"
        case .json: return "curlybraces"
        case .csv: return "tablecells"
        case .anki: return "rectangle.on.rectangle"
        case .pdf: return "doc.richtext"
        }
    }

    var utType: UTType {
        switch self {
        case .markdown: return .plainText
        case .plainText: return .plainText
        case .json: return .json
        case .csv: return .commaSeparatedText
        case .anki: return .data
        case .pdf: return .pdf
        }
    }
}

// MARK: - Enhanced Export Options

struct EnhancedExportOptions: Sendable {
    var format: EnhancedExportFormat = .markdown
    var includeHighlights: Bool = true
    var includeNotes: Bool = true
    var includeFlashcards: Bool = true
    var includeStudyStats: Bool = false
    var dateRange: DateInterval?
    var books: [UUID]?  // nil = all books

    // Format-specific options
    var includeBismillah: Bool = true
    var groupByBook: Bool = true
    var includePageNumbers: Bool = true
    var includeTimestamps: Bool = false
    var includeColors: Bool = true

    // Anki-specific
    var ankiDeckName: String = "NoorReader Export"
    var ankiNoteType: String = "Basic"

    static var `default`: EnhancedExportOptions {
        EnhancedExportOptions()
    }

    static var flashcardsOnly: EnhancedExportOptions {
        var options = EnhancedExportOptions()
        options.includeHighlights = false
        options.includeNotes = false
        options.includeFlashcards = true
        return options
    }

    static var highlightsOnly: EnhancedExportOptions {
        var options = EnhancedExportOptions()
        options.includeHighlights = true
        options.includeNotes = true
        options.includeFlashcards = false
        return options
    }
}

// MARK: - Export Job

struct ExportJob: Identifiable {
    let id: UUID
    let options: EnhancedExportOptions
    let startTime: Date
    var progress: Double = 0
    var status: ExportJobStatus = .pending
    var outputURL: URL?
    var error: Error?
}

enum ExportJobStatus: String, Sendable {
    case pending
    case inProgress
    case completed
    case failed
    case cancelled
}

// MARK: - Enhanced Export Service

@MainActor
@Observable
final class EnhancedExportService {

    // MARK: - Properties

    private var modelContext: ModelContext?

    var isExporting = false
    var currentJob: ExportJob?
    var exportProgress: Double = 0
    var error: Error?

    // MARK: - Singleton

    static let shared = EnhancedExportService()

    private init() {}

    // MARK: - Configuration

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Export Operations

    /// Export data with given options
    func export(options: EnhancedExportOptions) async throws -> URL {
        guard let modelContext else {
            throw EnhancedExportError.notConfigured
        }

        isExporting = true
        exportProgress = 0

        defer { isExporting = false }

        // Fetch data to export
        let books = try fetchBooks(options: options)
        let highlights = try fetchHighlights(options: options, books: books)
        let flashcards = try fetchFlashcards(options: options, books: books)
        let notes = try fetchNotes(options: options, books: books)

        exportProgress = 0.2

        // Generate export content
        let content: Any
        switch options.format {
        case .markdown:
            content = generateMarkdown(
                books: books,
                highlights: highlights,
                flashcards: flashcards,
                notes: notes,
                options: options
            )
        case .plainText:
            content = generatePlainText(
                books: books,
                highlights: highlights,
                flashcards: flashcards,
                notes: notes,
                options: options
            )
        case .json:
            content = generateJSON(
                books: books,
                highlights: highlights,
                flashcards: flashcards,
                notes: notes,
                options: options
            )
        case .csv:
            content = generateCSV(
                highlights: highlights,
                flashcards: flashcards,
                options: options
            )
        case .anki:
            content = try generateAnkiExport(
                flashcards: flashcards,
                options: options
            )
        case .pdf:
            // PDF requires different handling
            content = generateMarkdown(
                books: books,
                highlights: highlights,
                flashcards: flashcards,
                notes: notes,
                options: options
            )
        }

        exportProgress = 0.8

        // Save to file
        let url = try await saveExport(content: content, format: options.format, options: options)

        exportProgress = 1.0

        return url
    }

    // MARK: - Data Fetching

    private func fetchBooks(options: EnhancedExportOptions) throws -> [Book] {
        guard let modelContext else { return [] }

        if let bookIDs = options.books {
            let descriptor = FetchDescriptor<Book>(
                predicate: #Predicate { bookIDs.contains($0.id) }
            )
            return try modelContext.fetch(descriptor)
        }

        return try modelContext.fetch(FetchDescriptor<Book>())
    }

    private func fetchHighlights(options: EnhancedExportOptions, books: [Book]) throws -> [Highlight] {
        guard options.includeHighlights else { return [] }

        var allHighlights: [Highlight] = []
        for book in books {
            var highlights = book.highlights

            // Filter by date range if specified
            if let dateRange = options.dateRange {
                highlights = highlights.filter { dateRange.contains($0.dateCreated) }
            }

            allHighlights.append(contentsOf: highlights)
        }

        return allHighlights.sorted { $0.dateCreated > $1.dateCreated }
    }

    private func fetchFlashcards(options: EnhancedExportOptions, books: [Book]) throws -> [Flashcard] {
        guard options.includeFlashcards else { return [] }

        var allFlashcards: [Flashcard] = []
        for book in books {
            var flashcards = book.flashcards

            if let dateRange = options.dateRange {
                flashcards = flashcards.filter { dateRange.contains($0.dateCreated) }
            }

            allFlashcards.append(contentsOf: flashcards)
        }

        return allFlashcards.sorted { $0.dateCreated > $1.dateCreated }
    }

    private func fetchNotes(options: EnhancedExportOptions, books: [Book]) throws -> [Note] {
        guard options.includeNotes else { return [] }

        var allNotes: [Note] = []
        for book in books {
            var notes = book.standaloneNotes

            if let dateRange = options.dateRange {
                notes = notes.filter { dateRange.contains($0.dateCreated) }
            }

            allNotes.append(contentsOf: notes)
        }

        return allNotes.sorted { $0.dateCreated > $1.dateCreated }
    }

    // MARK: - Format Generators

    private func generateMarkdown(
        books: [Book],
        highlights: [Highlight],
        flashcards: [Flashcard],
        notes: [Note],
        options: EnhancedExportOptions
    ) -> String {
        var output = ""

        // Bismillah header
        if options.includeBismillah {
            output += "بسم الله الرحمن الرحيم\n\n"
            output += "---\n\n"
        }

        output += "# NoorReader Export\n"
        output += "**Exported:** \(Date().formatted(date: .long, time: .shortened))\n\n"

        // Highlights section
        if !highlights.isEmpty {
            output += "## Highlights (\(highlights.count))\n\n"

            if options.groupByBook {
                let grouped = Dictionary(grouping: highlights) { $0.book?.title ?? "Unknown" }
                for (bookTitle, bookHighlights) in grouped.sorted(by: { $0.key < $1.key }) {
                    output += "### \(bookTitle)\n\n"
                    for highlight in bookHighlights {
                        output += formatHighlightMarkdown(highlight, options: options)
                    }
                }
            } else {
                for highlight in highlights {
                    output += formatHighlightMarkdown(highlight, options: options)
                }
            }
        }

        // Flashcards section
        if !flashcards.isEmpty {
            output += "## Flashcards (\(flashcards.count))\n\n"

            for flashcard in flashcards {
                output += "**Q:** \(flashcard.front)\n\n"
                output += "**A:** \(flashcard.back)\n\n"
                if let book = flashcard.book {
                    output += "*Source: \(book.title)*\n\n"
                }
                output += "---\n\n"
            }
        }

        // Notes section
        if !notes.isEmpty {
            output += "## Notes (\(notes.count))\n\n"

            for note in notes {
                if options.includePageNumbers, let page = note.pageNumber {
                    output += "*Page \(page + 1)*\n\n"
                }
                output += "\(note.content)\n\n"
                output += "---\n\n"
            }
        }

        return output
    }

    private func formatHighlightMarkdown(_ highlight: Highlight, options: EnhancedExportOptions) -> String {
        var output = ""

        var meta: [String] = []
        if options.includePageNumbers {
            meta.append("Page \(highlight.pageNumber + 1)")
        }
        if options.includeColors {
            meta.append(highlight.color.displayName)
        }
        if options.includeTimestamps {
            meta.append(highlight.dateCreated.formatted(date: .abbreviated, time: .shortened))
        }

        if !meta.isEmpty {
            output += "*\(meta.joined(separator: " · "))*\n\n"
        }

        output += "> \(highlight.text.replacingOccurrences(of: "\n", with: "\n> "))\n\n"

        if let note = highlight.note, !note.content.isEmpty {
            output += "📝 \(note.content)\n\n"
        }

        output += "---\n\n"
        return output
    }

    private func generatePlainText(
        books: [Book],
        highlights: [Highlight],
        flashcards: [Flashcard],
        notes: [Note],
        options: EnhancedExportOptions
    ) -> String {
        var output = ""

        if options.includeBismillah {
            output += "In the Name of Allah, the Most Gracious, the Most Merciful\n\n"
        }

        output += "NoorReader Export\n"
        output += "Exported: \(Date().formatted())\n"
        output += String(repeating: "=", count: 50) + "\n\n"

        if !highlights.isEmpty {
            output += "HIGHLIGHTS\n"
            output += String(repeating: "-", count: 50) + "\n\n"

            for highlight in highlights {
                if options.includePageNumbers {
                    output += "[Page \(highlight.pageNumber + 1)] "
                }
                output += highlight.text + "\n"
                if let note = highlight.note, !note.content.isEmpty {
                    output += "  Note: \(note.content)\n"
                }
                output += "\n"
            }
        }

        if !flashcards.isEmpty {
            output += "FLASHCARDS\n"
            output += String(repeating: "-", count: 50) + "\n\n"

            for flashcard in flashcards {
                output += "Q: \(flashcard.front)\n"
                output += "A: \(flashcard.back)\n\n"
            }
        }

        return output
    }

    private func generateJSON(
        books: [Book],
        highlights: [Highlight],
        flashcards: [Flashcard],
        notes: [Note],
        options: EnhancedExportOptions
    ) -> String {
        struct ExportData: Codable {
            let exportDate: Date
            let highlights: [ExportedHighlight]
            let flashcards: [ExportedFlashcard]
            let notes: [ExportedNote]
        }

        struct ExportedHighlight: Codable {
            let text: String
            let page: Int
            let color: String
            let dateCreated: Date
            let bookTitle: String?
            let note: String?
        }

        struct ExportedFlashcard: Codable {
            let front: String
            let back: String
            let dateCreated: Date
            let bookTitle: String?
            let repetitions: Int
            let interval: Int
        }

        struct ExportedNote: Codable {
            let content: String
            let page: Int?
            let dateCreated: Date
        }

        let exportedHighlights = highlights.map {
            ExportedHighlight(
                text: $0.text,
                page: $0.pageNumber + 1,
                color: $0.color.displayName,
                dateCreated: $0.dateCreated,
                bookTitle: $0.book?.title,
                note: $0.note?.content
            )
        }

        let exportedFlashcards = flashcards.map {
            ExportedFlashcard(
                front: $0.front,
                back: $0.back,
                dateCreated: $0.dateCreated,
                bookTitle: $0.book?.title,
                repetitions: $0.repetitions,
                interval: $0.interval
            )
        }

        let exportedNotes = notes.map {
            ExportedNote(
                content: $0.content,
                page: $0.pageNumber.map { $0 + 1 },
                dateCreated: $0.dateCreated
            )
        }

        let exportData = ExportData(
            exportDate: Date(),
            highlights: exportedHighlights,
            flashcards: exportedFlashcards,
            notes: exportedNotes
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(exportData),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "{}"
        }

        return jsonString
    }

    private func generateCSV(
        highlights: [Highlight],
        flashcards: [Flashcard],
        options: EnhancedExportOptions
    ) -> String {
        var output = ""

        if options.includeHighlights && !highlights.isEmpty {
            // Highlights CSV
            output += "Type,Book,Page,Color,Text,Note,Date\n"

            for highlight in highlights {
                let text = escapeCSV(highlight.text)
                let note = escapeCSV(highlight.note?.content ?? "")
                let book = escapeCSV(highlight.book?.title ?? "")

                output += "Highlight,\(book),\(highlight.pageNumber + 1),\(highlight.color.displayName),\(text),\(note),\(highlight.dateCreated.ISO8601Format())\n"
            }

            output += "\n"
        }

        if options.includeFlashcards && !flashcards.isEmpty {
            // Flashcards CSV (Anki-compatible format)
            output += "Front,Back,Tags\n"

            for flashcard in flashcards {
                let front = escapeCSV(flashcard.front)
                let back = escapeCSV(flashcard.back)
                let tags = flashcard.book?.title ?? "NoorReader"

                output += "\(front),\(back),\(escapeCSV(tags))\n"
            }
        }

        return output
    }

    private func escapeCSV(_ string: String) -> String {
        let escaped = string
            .replacingOccurrences(of: "\"", with: "\"\"")
            .replacingOccurrences(of: "\n", with: " ")
        return "\"\(escaped)\""
    }

    private func generateAnkiExport(
        flashcards: [Flashcard],
        options: EnhancedExportOptions
    ) throws -> Data {
        // Generate Anki-compatible text format
        // Note: Full .apkg generation requires SQLite database creation
        // This generates a tab-separated file that can be imported to Anki

        var output = ""

        for flashcard in flashcards {
            let front = flashcard.front
                .replacingOccurrences(of: "\t", with: " ")
                .replacingOccurrences(of: "\n", with: "<br>")
            let back = flashcard.back
                .replacingOccurrences(of: "\t", with: " ")
                .replacingOccurrences(of: "\n", with: "<br>")
            let tags = (flashcard.book?.title ?? "NoorReader")
                .replacingOccurrences(of: " ", with: "_")

            output += "\(front)\t\(back)\t\(tags)\n"
        }

        guard let data = output.data(using: .utf8) else {
            throw EnhancedExportError.encodingFailed
        }

        return data
    }

    // MARK: - File Operations

    private func saveExport(
        content: Any,
        format: EnhancedExportFormat,
        options: EnhancedExportOptions
    ) async throws -> URL {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [format.utType]

        let filename = "NoorReader_Export_\(Date().formatted(.dateTime.year().month().day()))"
        panel.nameFieldStringValue = "\(filename).\(format.fileExtension)"
        panel.canCreateDirectories = true

        guard let window = NSApp.keyWindow else {
            throw EnhancedExportError.noWindow
        }

        let response = await panel.beginSheetModal(for: window)

        guard response == .OK, let url = panel.url else {
            throw EnhancedExportError.cancelled
        }

        switch content {
        case let string as String:
            try string.write(to: url, atomically: true, encoding: .utf8)
        case let data as Data:
            try data.write(to: url)
        default:
            throw EnhancedExportError.invalidContent
        }

        return url
    }

    // MARK: - Sharing

    func shareHighlight(_ highlight: Highlight) -> NSImage? {
        // Generate shareable highlight card image
        // This would create a nicely formatted image for sharing
        return nil  // Full implementation would use Core Graphics
    }

    func copyHighlightWithCitation(_ highlight: Highlight) -> String {
        var output = "\"\(highlight.text)\"\n\n"

        if let book = highlight.book {
            output += "— \(book.displayTitle)"
            if !book.displayAuthor.isEmpty && book.displayAuthor != "Unknown Author" {
                output += ", \(book.displayAuthor)"
            }
            output += ", p. \(highlight.pageNumber + 1)"
        }

        return output
    }

    func copyToClipboard(_ content: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
    }
}

// MARK: - Errors

enum EnhancedExportError: LocalizedError {
    case notConfigured
    case cancelled
    case noWindow
    case encodingFailed
    case invalidContent
    case exportFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Export service not configured"
        case .cancelled:
            return "Export was cancelled"
        case .noWindow:
            return "No active window found"
        case .encodingFailed:
            return "Failed to encode export data"
        case .invalidContent:
            return "Invalid content type for export"
        case .exportFailed(let reason):
            return "Export failed: \(reason)"
        }
    }
}
