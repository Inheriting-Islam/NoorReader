// ReaderViewModel.swift
// NoorReader
//
// PDF reader state management

import Foundation
import PDFKit
import SwiftData
import Combine

@MainActor
@Observable
final class ReaderViewModel {
    // MARK: - Properties

    let book: Book
    private(set) var document: PDFDocument?
    private(set) var isLoading = true
    private(set) var error: Error?
    private(set) var tableOfContents: [TOCItem] = []

    var currentPage: Int {
        didSet {
            saveProgress()
        }
    }
    var scaleFactor: CGFloat = 1.0
    var displayMode: PDFDisplayMode = .singlePageContinuous
    var currentSelection: PDFSelection?

    // Page turn animation
    var pageTurnState: PageTurnState = .idle
    var pageTurnAnimationsEnabled: Bool = true

    // Search
    var searchText = ""
    var searchResults: [PDFSelection] = []
    var currentSearchIndex = 0
    var isSearching = false

    private let modelContext: ModelContext
    private var saveTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var totalPages: Int {
        document?.pageCount ?? 0
    }

    var progress: Double {
        guard totalPages > 0 else { return 0 }
        return Double(currentPage + 1) / Double(totalPages)
    }

    var pageLabel: String {
        "Page \(currentPage + 1) of \(totalPages)"
    }

    var currentSearchResult: PDFSelection? {
        guard !searchResults.isEmpty, currentSearchIndex < searchResults.count else { return nil }
        return searchResults[currentSearchIndex]
    }

    var searchResultsLabel: String {
        guard !searchResults.isEmpty else { return "No results" }
        return "\(currentSearchIndex + 1) of \(searchResults.count)"
    }

    // MARK: - Initialization

    init(book: Book, modelContext: ModelContext) {
        self.book = book
        self.modelContext = modelContext
        self.currentPage = book.currentPage

        Task {
            await loadDocument()
        }
    }

    // MARK: - Document Loading

    private func loadDocument() async {
        isLoading = true
        error = nil

        do {
            // Try to access security-scoped resource (for files from open dialog)
            // This returns false for files in app's own container, which is fine
            let accessGranted = book.fileURL.startAccessingSecurityScopedResource()
            defer {
                if accessGranted {
                    book.fileURL.stopAccessingSecurityScopedResource()
                }
            }

            // Check if file exists
            guard FileManager.default.fileExists(atPath: book.fileURL.path) else {
                throw ReaderError.accessDenied
            }

            guard let doc = PDFDocument(url: book.fileURL) else {
                throw ReaderError.cannotOpenDocument
            }

            self.document = doc
            self.tableOfContents = PDFService.extractTableOfContents(from: doc)

            // Update total pages if needed
            if book.totalPages != doc.pageCount {
                book.totalPages = doc.pageCount
                try? modelContext.save()
            }

            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    // MARK: - Navigation

    func goToPage(_ page: Int) {
        guard page >= 0, page < totalPages else { return }
        currentPage = page
    }

    func nextPage() {
        if pageTurnAnimationsEnabled && isTwoPageMode {
            animatePageTurn(direction: .forward) {
                self.goToPage(self.currentPage + 1)
            }
        } else {
            goToPage(currentPage + 1)
        }
    }

    func previousPage() {
        if pageTurnAnimationsEnabled && isTwoPageMode {
            animatePageTurn(direction: .backward) {
                self.goToPage(self.currentPage - 1)
            }
        } else {
            goToPage(currentPage - 1)
        }
    }

    private var isTwoPageMode: Bool {
        displayMode == .twoUp || displayMode == .twoUpContinuous
    }

    private func animatePageTurn(direction: PageTurnDirection, completion: @escaping () -> Void) {
        guard pageTurnState == .idle else { return }

        pageTurnState = .animating(direction: direction, progress: 0)

        // The animation will call completion when done
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            self?.pageTurnState = .idle
            completion()
        }
    }

    func completePageTurn() {
        pageTurnState = .idle
    }

    func goToFirstPage() {
        goToPage(0)
    }

    func goToLastPage() {
        goToPage(totalPages - 1)
    }

    // MARK: - Zoom

    func zoomIn() {
        scaleFactor = min(scaleFactor * 1.25, 5.0)
    }

    func zoomOut() {
        scaleFactor = max(scaleFactor / 1.25, 0.25)
    }

    func resetZoom() {
        scaleFactor = 1.0
    }

    func fitToWidth() {
        // Will be calculated by PDFView
        scaleFactor = 1.0
    }

    // MARK: - Search

    func search() {
        guard !searchText.isEmpty, let document else {
            searchResults = []
            return
        }

        isSearching = true
        searchResults = []
        currentSearchIndex = 0

        Task {
            let results = document.findString(searchText, withOptions: .caseInsensitive)

            await MainActor.run {
                self.searchResults = results
                self.isSearching = false
            }
        }
    }

    func nextSearchResult() {
        guard !searchResults.isEmpty else { return }
        currentSearchIndex = (currentSearchIndex + 1) % searchResults.count
        navigateToCurrentSearchResult()
    }

    func previousSearchResult() {
        guard !searchResults.isEmpty else { return }
        currentSearchIndex = (currentSearchIndex - 1 + searchResults.count) % searchResults.count
        navigateToCurrentSearchResult()
    }

    private func navigateToCurrentSearchResult() {
        guard let selection = currentSearchResult,
              let page = selection.pages.first,
              let pageIndex = document?.index(for: page) else { return }

        currentPage = pageIndex
    }

    func clearSearch() {
        searchText = ""
        searchResults = []
        currentSearchIndex = 0
    }

    // MARK: - Bookmarks

    func addBookmark(title: String = "") {
        let bookmark = Bookmark(pageNumber: currentPage, title: title)
        book.bookmarks.append(bookmark)
        try? modelContext.save()
    }

    func removeBookmark(at pageNumber: Int) {
        book.bookmarks.removeAll { $0.pageNumber == pageNumber }
        try? modelContext.save()
    }

    func isCurrentPageBookmarked() -> Bool {
        book.bookmarks.contains { $0.pageNumber == currentPage }
    }

    func toggleBookmark() {
        if isCurrentPageBookmarked() {
            removeBookmark(at: currentPage)
        } else {
            addBookmark()
        }
    }

    // MARK: - Highlights

    func addHighlight(text: String, bounds: [CGRect], color: HighlightColor = .yellow) {
        let highlight = Highlight(
            text: text,
            pageNumber: currentPage,
            bounds: bounds,
            color: color
        )
        book.highlights.append(highlight)
        try? modelContext.save()

        // Trigger reminder service
        ReminderService.shared.onHighlightCreated()
    }

    func addHighlight(from selection: PDFSelection, color: HighlightColor = .yellow) {
        guard let text = selection.string else { return }

        var bounds: [CGRect] = []
        for page in selection.pages {
            bounds.append(selection.bounds(for: page))
        }

        addHighlight(text: text, bounds: bounds, color: color)
    }

    func removeHighlight(_ highlight: Highlight) {
        // Also remove associated note
        if let note = highlight.note {
            modelContext.delete(note)
        }
        book.highlights.removeAll { $0.id == highlight.id }
        try? modelContext.save()
    }

    func updateHighlightColor(_ highlight: Highlight, to color: HighlightColor) {
        highlight.color = color
        try? modelContext.save()
    }

    // MARK: - Notes

    func addNote(to highlight: Highlight, content: String = "") {
        let note = Note(content: content, pageNumber: highlight.pageNumber, highlight: highlight)
        highlight.note = note
        book.notes.append(note)
        try? modelContext.save()
    }

    func addStandaloneNote(content: String = "") {
        let note = Note(content: content, pageNumber: currentPage)
        book.notes.append(note)
        try? modelContext.save()
    }

    func deleteNote(_ note: Note) {
        modelContext.delete(note)
        try? modelContext.save()
    }

    // MARK: - Progress Saving

    private func saveProgress() {
        // Debounce saves
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            guard !Task.isCancelled else { return }

            book.currentPage = currentPage
            book.lastRead = Date()
            try? modelContext.save()
        }
    }
}

// MARK: - Errors

enum ReaderError: LocalizedError {
    case accessDenied
    case cannotOpenDocument

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Cannot access the document. Please re-import the file."
        case .cannotOpenDocument:
            return "Cannot open the document. The file may be corrupted."
        }
    }
}
