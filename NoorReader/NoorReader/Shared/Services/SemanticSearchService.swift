// SemanticSearchService.swift
// NoorReader
//
// Hybrid semantic + keyword search service for library-wide search

import Foundation
import SwiftData
import PDFKit

/// Combined search result from hybrid search
struct HybridSearchResult: Identifiable, Sendable {
    let id: UUID
    let bookID: UUID
    let bookTitle: String
    let text: String
    let pageNumber: Int
    let relevanceScore: Double
    let matchType: SearchMatchType
    let highlightRanges: [Range<String.Index>]?

    init(
        bookID: UUID,
        bookTitle: String,
        text: String,
        pageNumber: Int,
        relevanceScore: Double,
        matchType: SearchMatchType,
        highlightRanges: [Range<String.Index>]? = nil
    ) {
        self.id = UUID()
        self.bookID = bookID
        self.bookTitle = bookTitle
        self.text = text
        self.pageNumber = pageNumber
        self.relevanceScore = relevanceScore
        self.matchType = matchType
        self.highlightRanges = highlightRanges
    }

    var relevancePercentage: Int {
        Int(relevanceScore * 100)
    }

    var contextPreview: String {
        if text.count <= 200 {
            return text
        }
        return String(text.prefix(200)) + "..."
    }
}

/// Type of match found in search
enum SearchMatchType: String, Sendable {
    case semantic = "semantic"
    case keyword = "keyword"
    case hybrid = "hybrid"  // Both semantic and keyword match

    var displayName: String {
        switch self {
        case .semantic: return "Concept Match"
        case .keyword: return "Keyword Match"
        case .hybrid: return "Best Match"
        }
    }

    var icon: String {
        switch self {
        case .semantic: return "brain.head.profile"
        case .keyword: return "text.magnifyingglass"
        case .hybrid: return "sparkle.magnifyingglass"
        }
    }

    var color: String {
        switch self {
        case .semantic: return "purple"
        case .keyword: return "blue"
        case .hybrid: return "green"
        }
    }
}

/// Search options for customizing search behavior
struct SearchOptions {
    var scope: SemanticSearchScope = .currentBook
    var includeSemanticSearch: Bool = true
    var includeKeywordSearch: Bool = true
    var minimumRelevance: Double = 0.3
    var maxResults: Int = 20
    var bookIDs: [UUID]? = nil  // Specific books to search (for collection scope)

    static var `default`: SearchOptions {
        SearchOptions()
    }

    static var semanticOnly: SearchOptions {
        SearchOptions(includeKeywordSearch: false)
    }

    static var keywordOnly: SearchOptions {
        SearchOptions(includeSemanticSearch: false)
    }
}

/// Service for hybrid semantic + keyword search across library
@MainActor
@Observable
final class SemanticSearchService {

    // MARK: - Properties

    private let embeddingService: EmbeddingService
    private var modelContext: ModelContext?

    var isSearching = false
    var indexingProgress: IndexingProgress?
    var error: Error?

    // Cached book titles for search results
    private var bookTitles: [UUID: String] = [:]

    // MARK: - Singleton

    static let shared = SemanticSearchService()

    private init() {
        self.embeddingService = EmbeddingService()
    }

    // MARK: - Configuration

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Indexing

    /// Index a book for semantic search
    func indexBook(_ book: Book, document: PDFDocument) async throws {
        guard let modelContext else {
            throw SemanticSearchError.notConfigured
        }

        // Cache book title
        bookTitles[book.id] = book.title

        // Set up progress callback
        await embeddingService.setProgressCallback { [weak self] progress in
            Task { @MainActor in
                self?.indexingProgress = progress
            }
        }

        try await embeddingService.buildPersistentIndex(
            for: book,
            document: document,
            modelContext: modelContext
        )
    }

    /// Check if book is indexed and load if needed
    func ensureIndexLoaded(for book: Book) async throws {
        guard let modelContext else {
            throw SemanticSearchError.notConfigured
        }

        let hasIndex = await embeddingService.hasIndex(for: book.id)
        if !hasIndex {
            try await embeddingService.loadIndex(for: book.id, modelContext: modelContext)
        }

        // Cache book title
        bookTitles[book.id] = book.title
    }

    /// Get indexing status for a book
    func getIndexStatus(for bookID: UUID) async throws -> SemanticIndexStatus? {
        guard let modelContext else { return nil }
        return try await embeddingService.getIndexStatus(for: bookID, modelContext: modelContext)
    }

    /// Check if book needs reindexing
    func needsReindex(for bookID: UUID) async throws -> Bool {
        guard let modelContext else { return true }
        guard let status = try await embeddingService.getIndexStatus(for: bookID, modelContext: modelContext) else {
            return true
        }
        return status.needsReindex
    }

    // MARK: - Hybrid Search

    /// Perform hybrid search combining semantic and keyword matching
    func search(
        query: String,
        options: SearchOptions = .default,
        currentBookID: UUID? = nil
    ) async throws -> [HybridSearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        isSearching = true
        error = nil

        defer { isSearching = false }

        var allResults: [HybridSearchResult] = []

        // Determine which books to search
        let bookIDsToSearch = determineSearchScope(
            options: options,
            currentBookID: currentBookID
        )

        // Perform semantic search if enabled
        var semanticResults: [UUID: [SemanticSearchResult]] = [:]
        if options.includeSemanticSearch {
            semanticResults = try await performSemanticSearch(
                query: query,
                bookIDs: bookIDsToSearch,
                minimumScore: options.minimumRelevance
            )
        }

        // Perform keyword search if enabled
        var keywordResults: [UUID: [KeywordSearchResult]] = [:]
        if options.includeKeywordSearch {
            keywordResults = try await performKeywordSearch(
                query: query,
                bookIDs: bookIDsToSearch
            )
        }

        // Merge and rank results
        allResults = mergeResults(
            semanticResults: semanticResults,
            keywordResults: keywordResults,
            maxResults: options.maxResults
        )

        return allResults
    }

    /// Quick semantic search in current book only
    func quickSearch(
        query: String,
        in bookID: UUID,
        limit: Int = 10
    ) async throws -> [SemanticSearchResult] {
        return try await embeddingService.search(
            query: query,
            in: bookID,
            limit: limit
        )
    }

    // MARK: - Private Helpers

    private func determineSearchScope(
        options: SearchOptions,
        currentBookID: UUID?
    ) -> [UUID] {
        switch options.scope {
        case .currentBook:
            if let bookID = currentBookID {
                return [bookID]
            }
            return []

        case .collection:
            return options.bookIDs ?? []

        case .library:
            return Array(bookTitles.keys)
        }
    }

    private func performSemanticSearch(
        query: String,
        bookIDs: [UUID],
        minimumScore: Double
    ) async throws -> [UUID: [SemanticSearchResult]] {
        var results: [UUID: [SemanticSearchResult]] = [:]

        for bookID in bookIDs {
            do {
                let bookResults = try await embeddingService.search(
                    query: query,
                    in: bookID,
                    limit: 20,
                    minimumScore: minimumScore
                )
                if !bookResults.isEmpty {
                    results[bookID] = bookResults
                }
            } catch AIError.indexNotBuilt {
                // Skip books without index
                continue
            }
        }

        return results
    }

    private func performKeywordSearch(
        query: String,
        bookIDs: [UUID]
    ) async throws -> [UUID: [KeywordSearchResult]] {
        guard let modelContext else { return [:] }

        var results: [UUID: [KeywordSearchResult]] = [:]
        let searchTerms = query.lowercased().components(separatedBy: .whitespaces).filter { !$0.isEmpty }

        for bookID in bookIDs {
            // Search in PersistedTextChunks for this book
            let descriptor = FetchDescriptor<PersistedTextChunk>(
                predicate: #Predicate<PersistedTextChunk> { $0.bookID == bookID }
            )

            guard let chunks = try? modelContext.fetch(descriptor) else { continue }

            var bookResults: [KeywordSearchResult] = []

            for chunk in chunks {
                let lowerText = chunk.text.lowercased()
                var matchCount = 0
                var highlightRanges: [Range<String.Index>] = []

                for term in searchTerms {
                    if lowerText.contains(term) {
                        matchCount += 1

                        // Find all ranges of this term
                        var searchStart = chunk.text.startIndex
                        while let range = chunk.text.range(of: term, options: .caseInsensitive, range: searchStart..<chunk.text.endIndex) {
                            highlightRanges.append(range)
                            searchStart = range.upperBound
                        }
                    }
                }

                if matchCount > 0 {
                    let relevance = Double(matchCount) / Double(searchTerms.count)
                    bookResults.append(KeywordSearchResult(
                        text: chunk.text,
                        pageNumber: chunk.pageNumber,
                        relevanceScore: relevance,
                        matchCount: matchCount,
                        highlightRanges: highlightRanges
                    ))
                }
            }

            if !bookResults.isEmpty {
                // Sort by relevance and take top results
                bookResults.sort { $0.relevanceScore > $1.relevanceScore }
                results[bookID] = Array(bookResults.prefix(20))
            }
        }

        return results
    }

    private func mergeResults(
        semanticResults: [UUID: [SemanticSearchResult]],
        keywordResults: [UUID: [KeywordSearchResult]],
        maxResults: Int
    ) -> [HybridSearchResult] {
        var mergedResults: [HybridSearchResult] = []
        var seenTexts: Set<String> = []

        // Collect all book IDs
        let allBookIDs = Set(semanticResults.keys).union(keywordResults.keys)

        for bookID in allBookIDs {
            let bookTitle = bookTitles[bookID] ?? "Unknown Book"
            let semanticForBook = semanticResults[bookID] ?? []
            let keywordForBook = keywordResults[bookID] ?? []

            // Create lookup for keyword results by text prefix (for deduplication)
            let keywordLookup = Dictionary(
                keywordForBook.map { (String($0.text.prefix(100)), $0) },
                uniquingKeysWith: { first, _ in first }
            )

            // Process semantic results
            for semantic in semanticForBook {
                let textKey = String(semantic.text.prefix(100))

                if seenTexts.contains(textKey) { continue }
                seenTexts.insert(textKey)

                // Check if there's also a keyword match
                let matchType: SearchMatchType
                var finalScore = semantic.relevanceScore
                var highlightRanges: [Range<String.Index>]? = nil

                if let keyword = keywordLookup[textKey] {
                    matchType = .hybrid
                    // Boost score for hybrid matches
                    finalScore = min(1.0, semantic.relevanceScore * 1.2 + keyword.relevanceScore * 0.3)
                    highlightRanges = keyword.highlightRanges
                } else {
                    matchType = .semantic
                }

                mergedResults.append(HybridSearchResult(
                    bookID: bookID,
                    bookTitle: bookTitle,
                    text: semantic.text,
                    pageNumber: semantic.pageNumber,
                    relevanceScore: finalScore,
                    matchType: matchType,
                    highlightRanges: highlightRanges
                ))
            }

            // Add keyword-only results that weren't in semantic results
            for keyword in keywordForBook {
                let textKey = String(keyword.text.prefix(100))

                if seenTexts.contains(textKey) { continue }
                seenTexts.insert(textKey)

                mergedResults.append(HybridSearchResult(
                    bookID: bookID,
                    bookTitle: bookTitle,
                    text: keyword.text,
                    pageNumber: keyword.pageNumber,
                    relevanceScore: keyword.relevanceScore * 0.8,  // Slightly lower weight for keyword-only
                    matchType: .keyword,
                    highlightRanges: keyword.highlightRanges
                ))
            }
        }

        // Sort by relevance and limit results
        mergedResults.sort { $0.relevanceScore > $1.relevanceScore }
        return Array(mergedResults.prefix(maxResults))
    }

    // MARK: - Book Title Caching

    func cacheBookTitle(_ title: String, for bookID: UUID) {
        bookTitles[bookID] = title
    }

    func loadBookTitles(from books: [Book]) {
        for book in books {
            bookTitles[book.id] = book.title
        }
    }
}

// MARK: - Supporting Types

/// Internal type for keyword search results
private struct KeywordSearchResult {
    let text: String
    let pageNumber: Int
    let relevanceScore: Double
    let matchCount: Int
    let highlightRanges: [Range<String.Index>]
}

// MARK: - Errors

enum SemanticSearchError: LocalizedError {
    case notConfigured
    case indexingFailed(String)
    case searchFailed(String)
    case noResults

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Semantic search service not configured"
        case .indexingFailed(let reason):
            return "Indexing failed: \(reason)"
        case .searchFailed(let reason):
            return "Search failed: \(reason)"
        case .noResults:
            return "No results found"
        }
    }
}
