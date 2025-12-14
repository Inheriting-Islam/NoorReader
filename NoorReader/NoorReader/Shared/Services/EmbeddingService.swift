// EmbeddingService.swift
// NoorReader
//
// Text embeddings for semantic search using Apple's NaturalLanguage framework

import Foundation
import NaturalLanguage
import PDFKit

/// Generates and manages text embeddings for semantic search
actor EmbeddingService {

    // MARK: - Properties

    private var indices: [UUID: SemanticIndex] = [:]
    private let embeddingModel: NLEmbedding?

    // Configuration
    private let minimumChunkLength = 50
    private let maximumChunkLength = 1000

    // MARK: - Initialization

    init() {
        // Use Apple's built-in sentence embedding for English
        // This runs entirely on-device
        self.embeddingModel = NLEmbedding.sentenceEmbedding(for: .english)
    }

    // MARK: - Status

    func isReady() -> Bool {
        embeddingModel != nil
    }

    func hasIndex(for bookID: UUID) -> Bool {
        indices[bookID] != nil
    }

    func getIndexStats(for bookID: UUID) -> (chunkCount: Int, dateBuilt: Date)? {
        guard let index = indices[bookID] else { return nil }
        return (index.chunkCount, index.dateBuilt)
    }

    // MARK: - Index Building

    /// Build semantic index for a book from its PDF document
    func buildIndex(for book: Book, document: PDFDocument) async throws {
        guard isReady() else {
            throw AIError.embeddingFailed
        }

        var chunks: [TextChunk] = []

        // Extract text chunks from each page
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex),
                  let pageText = page.string else { continue }

            // Split into meaningful chunks (paragraphs or sentences)
            let pageChunks = splitIntoChunks(text: pageText, pageNumber: pageIndex)

            for (chunkIndex, chunkText) in pageChunks.enumerated() {
                if let embedding = getEmbedding(for: chunkText) {
                    chunks.append(TextChunk(
                        text: chunkText,
                        pageNumber: pageIndex,
                        chunkIndex: chunkIndex,
                        embedding: embedding
                    ))
                }
            }

            // Yield to prevent blocking
            if pageIndex % 10 == 0 {
                await Task.yield()
            }
        }

        indices[book.id] = SemanticIndex(
            bookID: book.id,
            chunks: chunks,
            dateBuilt: Date()
        )
    }

    /// Build index from text content directly
    func buildIndex(for bookID: UUID, fromText text: String) async throws {
        guard isReady() else {
            throw AIError.embeddingFailed
        }

        var chunks: [TextChunk] = []

        // Split into paragraphs
        let paragraphs = text.components(separatedBy: "\n\n")

        for (index, paragraph) in paragraphs.enumerated() {
            let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count >= minimumChunkLength else { continue }

            if let embedding = getEmbedding(for: trimmed) {
                chunks.append(TextChunk(
                    text: trimmed,
                    pageNumber: 0,  // No page info for raw text
                    chunkIndex: index,
                    embedding: embedding
                ))
            }
        }

        indices[bookID] = SemanticIndex(
            bookID: bookID,
            chunks: chunks,
            dateBuilt: Date()
        )
    }

    // MARK: - Search

    /// Search for semantically similar text chunks
    func search(
        query: String,
        in bookID: UUID,
        limit: Int = 10,
        minimumScore: Double = 0.3
    ) async throws -> [SemanticSearchResult] {
        guard let index = indices[bookID] else {
            throw AIError.indexNotBuilt
        }

        guard let queryEmbedding = getEmbedding(for: query) else {
            throw AIError.embeddingFailed
        }

        // Calculate cosine similarity for all chunks
        var results: [(chunk: TextChunk, score: Double)] = []

        for chunk in index.chunks {
            let similarity = cosineSimilarity(queryEmbedding, chunk.embedding)
            if similarity >= minimumScore {
                results.append((chunk, similarity))
            }
        }

        // Sort by similarity (highest first) and take top results
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

    /// Find similar passages to a given text
    func findSimilar(
        to text: String,
        in bookID: UUID,
        limit: Int = 5
    ) async throws -> [SemanticSearchResult] {
        // Use the text directly as the query
        return try await search(query: text, in: bookID, limit: limit)
    }

    // MARK: - Index Management

    func removeIndex(for bookID: UUID) {
        indices.removeValue(forKey: bookID)
    }

    func clearAllIndices() {
        indices.removeAll()
    }

    // MARK: - Private Helpers

    private func splitIntoChunks(text: String, pageNumber: Int) -> [String] {
        var chunks: [String] = []

        // First, split by double newlines (paragraphs)
        let paragraphs = text.components(separatedBy: "\n\n")

        for paragraph in paragraphs {
            let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)

            // Skip very short chunks
            guard trimmed.count >= minimumChunkLength else { continue }

            // If paragraph is too long, split by sentences
            if trimmed.count > maximumChunkLength {
                let sentences = splitIntoSentences(trimmed)
                var currentChunk = ""

                for sentence in sentences {
                    if currentChunk.count + sentence.count > maximumChunkLength {
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

    private func getEmbedding(for text: String) -> [Double]? {
        guard let model = embeddingModel else { return nil }

        // NLEmbedding.vector returns an optional array
        guard let vector = model.vector(for: text) else { return nil }

        return vector
    }

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
