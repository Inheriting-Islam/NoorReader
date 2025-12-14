// EmbeddingService.swift
// NoorReader
//
// Text embeddings for semantic search using Apple's NaturalLanguage framework
// Enhanced with persistent SwiftData storage and incremental indexing

import Foundation
import NaturalLanguage
import PDFKit
import SwiftData

/// Progress reporting for indexing operations
struct IndexingProgress: Sendable {
    let bookID: UUID
    let currentPage: Int
    let totalPages: Int
    let chunksProcessed: Int
    let status: IndexingStatus

    var progress: Double {
        guard totalPages > 0 else { return 0 }
        return Double(currentPage) / Double(totalPages)
    }

    var progressPercentage: Int {
        Int(progress * 100)
    }
}

/// Generates and manages text embeddings for semantic search
actor EmbeddingService {

    // MARK: - Properties

    /// In-memory cache of indices for fast access
    private var indexCache: [UUID: [TextChunkData]] = [:]

    /// Language-specific embedding models (loaded on demand)
    private var embeddingModels: [NLLanguage: NLEmbedding] = [:]
    private let supportedLanguages: [NLLanguage] = [.english, .arabic]

    // Configuration
    private let minimumChunkLength = 50
    private let maximumChunkLength = 1024
    private let optimalChunkLength = 512

    /// Progress callback for UI updates
    private var progressCallback: ((IndexingProgress) -> Void)?

    // MARK: - Initialization

    init() {
        // Pre-load common embedding models
        // Arabic and English are both supported for NoorReader's Islamic texts
        for language in supportedLanguages {
            if let model = NLEmbedding.sentenceEmbedding(for: language) {
                embeddingModels[language] = model
            }
        }
    }

    // MARK: - Status

    func isReady() -> Bool {
        !embeddingModels.isEmpty
    }

    func supportedLanguageNames() -> [String] {
        embeddingModels.keys.compactMap { language in
            switch language {
            case .english: return "English"
            case .arabic: return "Arabic"
            default: return nil
            }
        }
    }

    func hasIndex(for bookID: UUID) -> Bool {
        indexCache[bookID] != nil
    }

    func getIndexStats(for bookID: UUID) -> (chunkCount: Int, dateBuilt: Date)? {
        guard let chunks = indexCache[bookID], !chunks.isEmpty else { return nil }
        return (chunks.count, chunks.first?.createdAt ?? Date())
    }

    func setProgressCallback(_ callback: @escaping (IndexingProgress) -> Void) {
        self.progressCallback = callback
    }

    // MARK: - Persistent Index Building

    /// Build semantic index for a book with SwiftData persistence
    func buildPersistentIndex(
        for book: Book,
        document: PDFDocument,
        modelContext: ModelContext
    ) async throws {
        guard isReady() else {
            throw AIError.embeddingFailed
        }

        let bookID = book.id
        let totalPages = document.pageCount

        // Check/create index status
        let status = try getOrCreateIndexStatus(for: bookID, totalPages: totalPages, modelContext: modelContext)
        status.startIndexing()
        try modelContext.save()

        // Report initial progress
        progressCallback?(IndexingProgress(
            bookID: bookID,
            currentPage: 0,
            totalPages: totalPages,
            chunksProcessed: 0,
            status: .inProgress
        ))

        // Delete existing chunks for this book (full reindex)
        try deleteChunks(for: bookID, modelContext: modelContext)

        var chunksCreated = 0
        var inMemoryChunks: [TextChunkData] = []

        // Extract and index each page
        for pageIndex in 0..<totalPages {
            guard let page = document.page(at: pageIndex),
                  let pageText = page.string,
                  !pageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                continue
            }

            // Split into meaningful chunks
            let textChunks = splitIntoChunks(text: pageText, pageNumber: pageIndex)

            for (chunkIndex, chunkText) in textChunks.enumerated() {
                if let embedding = getEmbedding(for: chunkText) {
                    // Create persistent model
                    let chunk = PersistedTextChunk(
                        bookID: bookID,
                        pageNumber: pageIndex,
                        chunkIndex: chunkIndex,
                        text: chunkText,
                        embedding: embedding
                    )
                    modelContext.insert(chunk)

                    // Also store in memory for immediate use
                    inMemoryChunks.append(TextChunkData(
                        id: chunk.id,
                        text: chunkText,
                        pageNumber: pageIndex,
                        chunkIndex: chunkIndex,
                        embedding: embedding,
                        createdAt: chunk.createdAt
                    ))

                    chunksCreated += 1
                }
            }

            // Update status periodically
            if pageIndex % 5 == 0 || pageIndex == totalPages - 1 {
                status.updateProgress(pagesIndexed: pageIndex + 1, chunksCreated: chunksCreated)
                try modelContext.save()

                progressCallback?(IndexingProgress(
                    bookID: bookID,
                    currentPage: pageIndex + 1,
                    totalPages: totalPages,
                    chunksProcessed: chunksCreated,
                    status: .inProgress
                ))
            }

            // Yield to prevent blocking UI
            if pageIndex % 10 == 0 {
                await Task.yield()
            }
        }

        // Complete indexing
        status.completeIndexing()
        try modelContext.save()

        // Update cache
        indexCache[bookID] = inMemoryChunks

        progressCallback?(IndexingProgress(
            bookID: bookID,
            currentPage: totalPages,
            totalPages: totalPages,
            chunksProcessed: chunksCreated,
            status: .completed
        ))
    }

    /// Incremental index - only index new or changed pages
    func incrementalIndex(
        for book: Book,
        document: PDFDocument,
        modelContext: ModelContext
    ) async throws {
        guard isReady() else {
            throw AIError.embeddingFailed
        }

        let bookID = book.id
        let totalPages = document.pageCount

        // Get existing chunks
        let existingChunks = try fetchChunks(for: bookID, modelContext: modelContext)
        let existingPageChunks = Dictionary(grouping: existingChunks, by: \.pageNumber)

        var chunksCreated = 0
        var chunksUpdated = 0
        var inMemoryChunks: [TextChunkData] = []

        for pageIndex in 0..<totalPages {
            guard let page = document.page(at: pageIndex),
                  let pageText = page.string,
                  !pageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                continue
            }

            let newChunks = splitIntoChunks(text: pageText, pageNumber: pageIndex)

            // Check if page content has changed
            let existingPageContent = existingPageChunks[pageIndex]
            let needsReindex = shouldReindexPage(
                existingChunks: existingPageContent,
                newTexts: newChunks
            )

            if needsReindex {
                // Delete old chunks for this page
                for chunk in existingPageContent ?? [] {
                    modelContext.delete(chunk)
                }

                // Create new chunks
                for (chunkIndex, chunkText) in newChunks.enumerated() {
                    if let embedding = getEmbedding(for: chunkText) {
                        let chunk = PersistedTextChunk(
                            bookID: bookID,
                            pageNumber: pageIndex,
                            chunkIndex: chunkIndex,
                            text: chunkText,
                            embedding: embedding
                        )
                        modelContext.insert(chunk)

                        inMemoryChunks.append(TextChunkData(
                            id: chunk.id,
                            text: chunkText,
                            pageNumber: pageIndex,
                            chunkIndex: chunkIndex,
                            embedding: embedding,
                            createdAt: chunk.createdAt
                        ))

                        chunksCreated += 1
                    }
                }
                chunksUpdated += 1
            } else {
                // Keep existing chunks in memory cache
                for chunk in existingPageContent ?? [] {
                    if let embedding = chunk.embedding {
                        inMemoryChunks.append(TextChunkData(
                            id: chunk.id,
                            text: chunk.text,
                            pageNumber: chunk.pageNumber,
                            chunkIndex: chunk.chunkIndex,
                            embedding: embedding,
                            createdAt: chunk.createdAt
                        ))
                    }
                }
            }

            if pageIndex % 10 == 0 {
                await Task.yield()
            }
        }

        try modelContext.save()
        indexCache[bookID] = inMemoryChunks
    }

    /// Load existing index from SwiftData into memory cache
    func loadIndex(for bookID: UUID, modelContext: ModelContext) async throws {
        let chunks = try fetchChunks(for: bookID, modelContext: modelContext)

        var inMemoryChunks: [TextChunkData] = []
        for chunk in chunks {
            if let embedding = chunk.embedding {
                inMemoryChunks.append(TextChunkData(
                    id: chunk.id,
                    text: chunk.text,
                    pageNumber: chunk.pageNumber,
                    chunkIndex: chunk.chunkIndex,
                    embedding: embedding,
                    createdAt: chunk.createdAt
                ))
            }
        }

        indexCache[bookID] = inMemoryChunks
    }

    // MARK: - Legacy In-Memory Index Building (kept for compatibility)

    /// Build semantic index for a book from its PDF document (in-memory only)
    func buildIndex(for book: Book, document: PDFDocument) async throws {
        guard isReady() else {
            throw AIError.embeddingFailed
        }

        var chunks: [TextChunkData] = []

        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex),
                  let pageText = page.string else { continue }

            let pageChunks = splitIntoChunks(text: pageText, pageNumber: pageIndex)

            for (chunkIndex, chunkText) in pageChunks.enumerated() {
                if let embedding = getEmbedding(for: chunkText) {
                    chunks.append(TextChunkData(
                        id: UUID(),
                        text: chunkText,
                        pageNumber: pageIndex,
                        chunkIndex: chunkIndex,
                        embedding: embedding,
                        createdAt: Date()
                    ))
                }
            }

            if pageIndex % 10 == 0 {
                await Task.yield()
            }
        }

        indexCache[book.id] = chunks
    }

    /// Build index from text content directly
    func buildIndex(for bookID: UUID, fromText text: String) async throws {
        guard isReady() else {
            throw AIError.embeddingFailed
        }

        var chunks: [TextChunkData] = []
        let paragraphs = text.components(separatedBy: "\n\n")

        for (index, paragraph) in paragraphs.enumerated() {
            let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count >= minimumChunkLength else { continue }

            if let embedding = getEmbedding(for: trimmed) {
                chunks.append(TextChunkData(
                    id: UUID(),
                    text: trimmed,
                    pageNumber: 0,
                    chunkIndex: index,
                    embedding: embedding,
                    createdAt: Date()
                ))
            }
        }

        indexCache[bookID] = chunks
    }

    // MARK: - Search

    /// Search for semantically similar text chunks
    func search(
        query: String,
        in bookID: UUID,
        limit: Int = 10,
        minimumScore: Double = 0.3
    ) async throws -> [SemanticSearchResult] {
        guard let chunks = indexCache[bookID] else {
            throw AIError.indexNotBuilt
        }

        guard let queryEmbedding = getEmbedding(for: query) else {
            throw AIError.embeddingFailed
        }

        var results: [(chunk: TextChunkData, score: Double)] = []

        for chunk in chunks {
            let similarity = cosineSimilarity(queryEmbedding, chunk.embedding)
            if similarity >= minimumScore {
                results.append((chunk, similarity))
            }
        }

        results.sort { $0.score > $1.score }

        return results.prefix(limit).map { result in
            SemanticSearchResult(
                text: result.chunk.text,
                pageNumber: result.chunk.pageNumber,
                relevanceScore: result.score,
                chunkIndex: result.chunk.chunkIndex
            )
        }
    }

    /// Search across multiple books
    func searchLibrary(
        query: String,
        bookIDs: [UUID],
        limit: Int = 20,
        minimumScore: Double = 0.3
    ) async throws -> [LibrarySearchResult] {
        guard let queryEmbedding = getEmbedding(for: query) else {
            throw AIError.embeddingFailed
        }

        var allResults: [(bookID: UUID, chunk: TextChunkData, score: Double)] = []

        for bookID in bookIDs {
            guard let chunks = indexCache[bookID] else { continue }

            for chunk in chunks {
                let similarity = cosineSimilarity(queryEmbedding, chunk.embedding)
                if similarity >= minimumScore {
                    allResults.append((bookID, chunk, similarity))
                }
            }
        }

        allResults.sort { $0.score > $1.score }

        return allResults.prefix(limit).map { result in
            LibrarySearchResult(
                bookID: result.bookID,
                text: result.chunk.text,
                pageNumber: result.chunk.pageNumber,
                relevanceScore: result.score,
                chunkIndex: result.chunk.chunkIndex
            )
        }
    }

    /// Find similar passages to a given text
    func findSimilar(
        to text: String,
        in bookID: UUID,
        limit: Int = 5
    ) async throws -> [SemanticSearchResult] {
        return try await search(query: text, in: bookID, limit: limit)
    }

    // MARK: - Index Management

    func removeIndex(for bookID: UUID) {
        indexCache.removeValue(forKey: bookID)
    }

    func clearAllIndices() {
        indexCache.removeAll()
    }

    func getIndexedBookIDs() -> [UUID] {
        Array(indexCache.keys)
    }

    // MARK: - SwiftData Helpers

    private func fetchChunks(for bookID: UUID, modelContext: ModelContext) throws -> [PersistedTextChunk] {
        let descriptor = FetchDescriptor<PersistedTextChunk>(
            predicate: #Predicate<PersistedTextChunk> { $0.bookID == bookID },
            sortBy: [
                SortDescriptor(\PersistedTextChunk.pageNumber),
                SortDescriptor(\PersistedTextChunk.chunkIndex)
            ]
        )
        return try modelContext.fetch(descriptor)
    }

    private func deleteChunks(for bookID: UUID, modelContext: ModelContext) throws {
        let chunks = try fetchChunks(for: bookID, modelContext: modelContext)
        for chunk in chunks {
            modelContext.delete(chunk)
        }
    }

    private func getOrCreateIndexStatus(
        for bookID: UUID,
        totalPages: Int,
        modelContext: ModelContext
    ) throws -> SemanticIndexStatus {
        let descriptor = FetchDescriptor<SemanticIndexStatus>(
            predicate: #Predicate { $0.bookID == bookID }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.totalPages = totalPages
            return existing
        }

        let status = SemanticIndexStatus(bookID: bookID, totalPages: totalPages)
        modelContext.insert(status)
        return status
    }

    func getIndexStatus(for bookID: UUID, modelContext: ModelContext) throws -> SemanticIndexStatus? {
        let descriptor = FetchDescriptor<SemanticIndexStatus>(
            predicate: #Predicate { $0.bookID == bookID }
        )
        return try modelContext.fetch(descriptor).first
    }

    private func shouldReindexPage(existingChunks: [PersistedTextChunk]?, newTexts: [String]) -> Bool {
        guard let existing = existingChunks, !existing.isEmpty else {
            return true
        }

        // Check if chunk count matches
        if existing.count != newTexts.count {
            return true
        }

        // Check if any text has changed
        for (chunk, newText) in zip(existing, newTexts) {
            if chunk.hasTextChanged(newText: newText) {
                return true
            }
        }

        return false
    }

    // MARK: - Text Processing

    private func splitIntoChunks(text: String, pageNumber: Int) -> [String] {
        var chunks: [String] = []

        // First, split by double newlines (paragraphs)
        let paragraphs = text.components(separatedBy: "\n\n")

        for paragraph in paragraphs {
            let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)

            guard trimmed.count >= minimumChunkLength else { continue }

            if trimmed.count > maximumChunkLength {
                // Split long paragraphs into optimal-sized chunks
                let sentences = splitIntoSentences(trimmed)
                var currentChunk = ""

                for sentence in sentences {
                    if currentChunk.count + sentence.count > optimalChunkLength {
                        if currentChunk.count >= minimumChunkLength {
                            chunks.append(currentChunk.trimmingCharacters(in: .whitespaces))
                        }
                        currentChunk = sentence
                    } else {
                        currentChunk += (currentChunk.isEmpty ? "" : " ") + sentence
                    }
                }

                if currentChunk.count >= minimumChunkLength {
                    chunks.append(currentChunk.trimmingCharacters(in: .whitespaces))
                }
            } else {
                chunks.append(trimmed)
            }
        }

        return chunks
    }

    private func splitIntoSentences(_ text: String) -> [String] {
        var sentences: [String] = []

        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text

        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = String(text[range]).trimmingCharacters(in: .whitespaces)
            if !sentence.isEmpty {
                sentences.append(sentence)
            }
            return true
        }

        return sentences
    }

    // MARK: - Embedding Generation

    private func getEmbedding(for text: String) -> [Double]? {
        let language = detectLanguage(for: text)

        guard let model = embeddingModels[language] ?? embeddingModels[.english] else {
            return nil
        }

        guard let vector = model.vector(for: text) else { return nil }
        return vector
    }

    /// Generate embedding for a query (public for use by search service)
    func generateQueryEmbedding(for text: String) -> [Double]? {
        getEmbedding(for: text)
    }

    private func detectLanguage(for text: String) -> NLLanguage {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        guard let dominantLanguage = recognizer.dominantLanguage else {
            return .english
        }

        if embeddingModels[dominantLanguage] != nil {
            return dominantLanguage
        }

        return .english
    }

    // MARK: - Similarity Calculation

    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }

        var dotProduct: Double = 0
        var normA: Double = 0
        var normB: Double = 0

        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }

        let denominator = sqrt(normA) * sqrt(normB)
        guard denominator > 0 else { return 0 }

        return dotProduct / denominator
    }
}

// MARK: - Supporting Types

/// In-memory representation of a text chunk for fast search
struct TextChunkData: Sendable {
    let id: UUID
    let text: String
    let pageNumber: Int
    let chunkIndex: Int
    let embedding: [Double]
    let createdAt: Date
}

/// Search result from library-wide search
struct LibrarySearchResult: Identifiable, Sendable {
    let id: UUID
    let bookID: UUID
    let text: String
    let pageNumber: Int
    let relevanceScore: Double
    let chunkIndex: Int?

    init(
        bookID: UUID,
        text: String,
        pageNumber: Int,
        relevanceScore: Double,
        chunkIndex: Int? = nil
    ) {
        self.id = UUID()
        self.bookID = bookID
        self.text = text
        self.pageNumber = pageNumber
        self.relevanceScore = relevanceScore
        self.chunkIndex = chunkIndex
    }

    var relevancePercentage: Int {
        Int(relevanceScore * 100)
    }
}
