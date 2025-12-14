// SemanticSearchViewModel.swift
// NoorReader
//
// ViewModel for semantic search UI

import Foundation
import SwiftData
import PDFKit

/// ViewModel for managing semantic search state and operations
@MainActor
@Observable
final class SemanticSearchViewModel {

    // MARK: - Properties

    private let searchService: SemanticSearchService
    private var modelContext: ModelContext?

    // Search state
    var query: String = ""
    var results: [HybridSearchResult] = []
    var isSearching = false
    var hasSearched = false

    // Search options
    var searchScope: SemanticSearchScope = .currentBook
    var includeSemanticSearch = true
    var includeKeywordSearch = true
    var minimumRelevance: Double = 0.3

    // Indexing state
    var isIndexing = false
    var indexingProgress: IndexingProgress?
    var indexStatus: SemanticIndexStatus?

    // Current context
    var currentBook: Book?
    var currentBookID: UUID?
    var availableBooks: [Book] = []

    // Error handling
    var error: Error?
    var showError = false

    // Recent searches
    var recentSearches: [String] = []
    private let maxRecentSearches = 10

    // MARK: - Computed Properties

    var canSearch: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isSearching &&
        !isIndexing
    }

    var hasResults: Bool {
        !results.isEmpty
    }

    var searchModeDescription: String {
        if includeSemanticSearch && includeKeywordSearch {
            return "Hybrid (Semantic + Keyword)"
        } else if includeSemanticSearch {
            return "Semantic Only"
        } else {
            return "Keyword Only"
        }
    }

    var scopeDescription: String {
        switch searchScope {
        case .currentBook:
            return currentBook?.title ?? "Current Book"
        case .collection:
            return "Selected Collection"
        case .library:
            return "Entire Library"
        }
    }

    var indexStatusText: String {
        guard let status = indexStatus else {
            return "Not indexed"
        }

        switch status.status {
        case .notStarted:
            return "Not indexed"
        case .inProgress:
            return "Indexing... \(status.progress.formatted(.percent))"
        case .completed:
            return "Indexed (\(status.chunksCreated) chunks)"
        case .failed:
            return "Indexing failed"
        }
    }

    var canIndexCurrentBook: Bool {
        currentBook != nil && !isIndexing
    }

    // MARK: - Initialization

    init() {
        self.searchService = SemanticSearchService.shared
        loadRecentSearches()
    }

    // MARK: - Configuration

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        searchService.configure(modelContext: modelContext)
    }

    func setCurrentBook(_ book: Book?, document: PDFDocument? = nil) {
        self.currentBook = book
        self.currentBookID = book?.id

        if let book {
            searchService.cacheBookTitle(book.title, for: book.id)

            // Load index status
            Task {
                await loadIndexStatus(for: book.id)
            }
        }
    }

    func setAvailableBooks(_ books: [Book]) {
        self.availableBooks = books
        searchService.loadBookTitles(from: books)
    }

    // MARK: - Search Operations

    func search() async {
        guard canSearch else { return }

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }

        isSearching = true
        hasSearched = true
        error = nil
        results = []

        // Save to recent searches
        addToRecentSearches(trimmedQuery)

        do {
            let options = SearchOptions(
                scope: searchScope,
                includeSemanticSearch: includeSemanticSearch,
                includeKeywordSearch: includeKeywordSearch,
                minimumRelevance: minimumRelevance,
                maxResults: 50,
                bookIDs: searchScope == .library ? availableBooks.map(\.id) : nil
            )

            results = try await searchService.search(
                query: trimmedQuery,
                options: options,
                currentBookID: currentBookID
            )
        } catch {
            self.error = error
            showError = true
        }

        isSearching = false
    }

    func quickSearch(in bookID: UUID) async -> [SemanticSearchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        do {
            return try await searchService.quickSearch(
                query: trimmedQuery,
                in: bookID,
                limit: 10
            )
        } catch {
            self.error = error
            return []
        }
    }

    func clearSearch() {
        query = ""
        results = []
        hasSearched = false
        error = nil
    }

    // MARK: - Indexing Operations

    func indexCurrentBook(document: PDFDocument) async {
        guard let book = currentBook else { return }

        isIndexing = true
        error = nil

        do {
            try await searchService.indexBook(book, document: document)
            await loadIndexStatus(for: book.id)
        } catch {
            self.error = error
            showError = true
        }

        isIndexing = false
        indexingProgress = nil
    }

    func ensureIndexLoaded() async {
        guard let book = currentBook else { return }

        do {
            try await searchService.ensureIndexLoaded(for: book)
        } catch {
            // Index not available, user may need to build it
            self.error = error
        }
    }

    func loadIndexStatus(for bookID: UUID) async {
        do {
            indexStatus = try await searchService.getIndexStatus(for: bookID)
        } catch {
            indexStatus = nil
        }
    }

    func checkNeedsReindex() async -> Bool {
        guard let bookID = currentBookID else { return true }
        do {
            return try await searchService.needsReindex(for: bookID)
        } catch {
            return true
        }
    }

    // MARK: - Recent Searches

    private func addToRecentSearches(_ search: String) {
        // Remove if already exists
        recentSearches.removeAll { $0.lowercased() == search.lowercased() }

        // Add to beginning
        recentSearches.insert(search, at: 0)

        // Trim to max
        if recentSearches.count > maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(maxRecentSearches))
        }

        saveRecentSearches()
    }

    func useRecentSearch(_ search: String) {
        query = search
        Task {
            await self.search()
        }
    }

    func clearRecentSearches() {
        recentSearches = []
        saveRecentSearches()
    }

    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: "SemanticRecentSearches") ?? []
    }

    private func saveRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: "SemanticRecentSearches")
    }

    // MARK: - Result Actions

    func navigateToResult(_ result: HybridSearchResult) -> (bookID: UUID, pageNumber: Int) {
        return (result.bookID, result.pageNumber)
    }

    func groupResultsByBook() -> [(bookTitle: String, bookID: UUID, results: [HybridSearchResult])] {
        let grouped = Dictionary(grouping: results, by: \.bookID)

        return grouped.map { bookID, bookResults in
            let title = bookResults.first?.bookTitle ?? "Unknown"
            return (title, bookID, bookResults.sorted { $0.relevanceScore > $1.relevanceScore })
        }.sorted { $0.bookTitle < $1.bookTitle }
    }

    // MARK: - Filters

    func filterByMatchType(_ matchType: SearchMatchType?) {
        // This would filter results in place if needed
        // For now, we keep all results and let the UI filter
    }

    func setSearchScope(_ scope: SemanticSearchScope) {
        searchScope = scope
        // Clear results when scope changes
        if hasSearched {
            results = []
            hasSearched = false
        }
    }

    func toggleSemanticSearch() {
        includeSemanticSearch.toggle()
        // Ensure at least one mode is enabled
        if !includeSemanticSearch && !includeKeywordSearch {
            includeKeywordSearch = true
        }
    }

    func toggleKeywordSearch() {
        includeKeywordSearch.toggle()
        // Ensure at least one mode is enabled
        if !includeSemanticSearch && !includeKeywordSearch {
            includeSemanticSearch = true
        }
    }
}

// MARK: - Result Statistics

extension SemanticSearchViewModel {

    var resultStats: SearchResultStats {
        let semanticCount = results.filter { $0.matchType == .semantic }.count
        let keywordCount = results.filter { $0.matchType == .keyword }.count
        let hybridCount = results.filter { $0.matchType == .hybrid }.count
        let bookCount = Set(results.map(\.bookID)).count
        let avgRelevance = results.isEmpty ? 0 : results.reduce(0) { $0 + $1.relevanceScore } / Double(results.count)

        return SearchResultStats(
            totalResults: results.count,
            semanticMatches: semanticCount,
            keywordMatches: keywordCount,
            hybridMatches: hybridCount,
            booksSearched: bookCount,
            averageRelevance: avgRelevance
        )
    }
}

/// Statistics about search results
struct SearchResultStats {
    let totalResults: Int
    let semanticMatches: Int
    let keywordMatches: Int
    let hybridMatches: Int
    let booksSearched: Int
    let averageRelevance: Double

    var formattedAverageRelevance: String {
        "\(Int(averageRelevance * 100))%"
    }
}
