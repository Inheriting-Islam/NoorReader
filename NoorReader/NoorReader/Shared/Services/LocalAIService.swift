// LocalAIService.swift
// NoorReader
//
// On-device AI using Core ML for offline functionality

import Foundation
import NaturalLanguage
import CoreML

// MARK: - Model Types

enum LocalModelType: String, CaseIterable, Identifiable, Sendable {
    case embedding = "embedding"
    case summarization = "summarization"
    case classification = "classification"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .embedding: return "Text Embeddings"
        case .summarization: return "Summarization"
        case .classification: return "Classification"
        }
    }

    var description: String {
        switch self {
        case .embedding: return "Generate semantic embeddings for search"
        case .summarization: return "Generate text summaries"
        case .classification: return "Classify text into categories"
        }
    }

    var estimatedSize: String {
        switch self {
        case .embedding: return "~50 MB"
        case .summarization: return "~200 MB"
        case .classification: return "~30 MB"
        }
    }

    var icon: String {
        switch self {
        case .embedding: return "brain.head.profile"
        case .summarization: return "text.alignleft"
        case .classification: return "tag"
        }
    }
}

// MARK: - Model Status

struct LocalModelStatus: Sendable {
    let type: LocalModelType
    let isAvailable: Bool
    let isDownloading: Bool
    let downloadProgress: Double
    let sizeOnDisk: Int64?
    let lastUsed: Date?
}

// MARK: - Local Model Manager

/// Manages downloading and storage of local AI models
actor LocalModelManager {

    // MARK: - Properties

    private var downloadedModels: Set<LocalModelType> = []
    private var downloadingModels: Set<LocalModelType> = []
    private var downloadProgress: [LocalModelType: Double] = [:]

    // Model storage location
    private let modelsDirectory: URL

    // MARK: - Initialization

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.modelsDirectory = appSupport.appendingPathComponent("NoorReader/Models", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)

        // Check for existing models
        checkExistingModels()
    }

    // MARK: - Status

    func isModelAvailable(_ type: LocalModelType) -> Bool {
        downloadedModels.contains(type)
    }

    func isModelDownloading(_ type: LocalModelType) -> Bool {
        downloadingModels.contains(type)
    }

    func getDownloadProgress(_ type: LocalModelType) -> Double {
        downloadProgress[type] ?? 0
    }

    func getModelStatus(_ type: LocalModelType) -> LocalModelStatus {
        LocalModelStatus(
            type: type,
            isAvailable: isModelAvailable(type),
            isDownloading: isModelDownloading(type),
            downloadProgress: getDownloadProgress(type),
            sizeOnDisk: getModelSize(type),
            lastUsed: getLastUsed(type)
        )
    }

    func getAllModelStatuses() -> [LocalModelStatus] {
        LocalModelType.allCases.map { getModelStatus($0) }
    }

    var downloadedModelsSize: Int64 {
        var totalSize: Int64 = 0
        for type in downloadedModels {
            if let size = getModelSize(type) {
                totalSize += size
            }
        }
        return totalSize
    }

    var formattedDownloadedSize: String {
        ByteCountFormatter.string(fromByteCount: downloadedModelsSize, countStyle: .file)
    }

    // MARK: - Model Management

    func downloadModel(_ type: LocalModelType) async throws {
        guard !downloadedModels.contains(type) else { return }
        guard !downloadingModels.contains(type) else { return }

        downloadingModels.insert(type)
        downloadProgress[type] = 0

        defer {
            downloadingModels.remove(type)
        }

        // Simulate download progress
        // In production, this would download actual models from a server
        for i in 1...10 {
            try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 second
            downloadProgress[type] = Double(i) / 10.0
        }

        // Mark as downloaded
        downloadedModels.insert(type)
        saveModelMetadata(type)

        downloadProgress[type] = 1.0
    }

    func deleteModel(_ type: LocalModelType) throws {
        guard downloadedModels.contains(type) else { return }

        let modelPath = modelsDirectory.appendingPathComponent(type.rawValue)
        try? FileManager.default.removeItem(at: modelPath)

        downloadedModels.remove(type)
        removeModelMetadata(type)
    }

    func deleteAllModels() throws {
        for type in downloadedModels {
            try deleteModel(type)
        }
    }

    // MARK: - Private Helpers

    private func checkExistingModels() {
        for type in LocalModelType.allCases {
            let modelPath = modelsDirectory.appendingPathComponent(type.rawValue)
            if FileManager.default.fileExists(atPath: modelPath.path) {
                downloadedModels.insert(type)
            }
        }

        // Also check UserDefaults for downloaded models (for built-in Apple models)
        if let savedModels = UserDefaults.standard.stringArray(forKey: "DownloadedLocalModels") {
            for modelName in savedModels {
                if let type = LocalModelType(rawValue: modelName) {
                    downloadedModels.insert(type)
                }
            }
        }

        // Embedding model is always available (uses Apple's NaturalLanguage)
        downloadedModels.insert(.embedding)
    }

    private func saveModelMetadata(_ type: LocalModelType) {
        var savedModels = UserDefaults.standard.stringArray(forKey: "DownloadedLocalModels") ?? []
        if !savedModels.contains(type.rawValue) {
            savedModels.append(type.rawValue)
            UserDefaults.standard.set(savedModels, forKey: "DownloadedLocalModels")
        }
        UserDefaults.standard.set(Date(), forKey: "ModelLastUsed_\(type.rawValue)")
    }

    private func removeModelMetadata(_ type: LocalModelType) {
        var savedModels = UserDefaults.standard.stringArray(forKey: "DownloadedLocalModels") ?? []
        savedModels.removeAll { $0 == type.rawValue }
        UserDefaults.standard.set(savedModels, forKey: "DownloadedLocalModels")
        UserDefaults.standard.removeObject(forKey: "ModelLastUsed_\(type.rawValue)")
    }

    private func getModelSize(_ type: LocalModelType) -> Int64? {
        let modelPath = modelsDirectory.appendingPathComponent(type.rawValue)
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: modelPath.path),
              let size = attributes[.size] as? Int64 else {
            return nil
        }
        return size
    }

    private func getLastUsed(_ type: LocalModelType) -> Date? {
        UserDefaults.standard.object(forKey: "ModelLastUsed_\(type.rawValue)") as? Date
    }

    func markModelUsed(_ type: LocalModelType) {
        UserDefaults.standard.set(Date(), forKey: "ModelLastUsed_\(type.rawValue)")
    }
}

// MARK: - Local AI Service

/// Service for on-device AI operations
@MainActor
@Observable
final class LocalAIService {

    // MARK: - Properties

    private let modelManager = LocalModelManager()

    var isProcessing = false
    var error: Error?
    var modelStatuses: [LocalModelStatus] = []

    // Natural Language models
    private var sentenceEmbedding: NLEmbedding?
    private let tagger = NLTagger(tagSchemes: [.nameType, .lemma, .lexicalClass])

    // MARK: - Singleton

    static let shared = LocalAIService()

    private init() {
        // Load Apple's built-in embedding model
        sentenceEmbedding = NLEmbedding.sentenceEmbedding(for: .english)

        Task {
            await refreshModelStatuses()
        }
    }

    // MARK: - Model Management

    func refreshModelStatuses() async {
        modelStatuses = await modelManager.getAllModelStatuses()
    }

    func downloadModel(_ type: LocalModelType) async throws {
        try await modelManager.downloadModel(type)
        await refreshModelStatuses()
    }

    func deleteModel(_ type: LocalModelType) async throws {
        try await modelManager.deleteModel(type)
        await refreshModelStatuses()
    }

    func isModelAvailable(_ type: LocalModelType) async -> Bool {
        await modelManager.isModelAvailable(type)
    }

    var totalDownloadedSize: String {
        get async {
            await modelManager.formattedDownloadedSize
        }
    }

    // MARK: - Embedding Generation (Always Available)

    func generateEmbedding(for text: String) -> [Double]? {
        guard let embedding = sentenceEmbedding else { return nil }
        return embedding.vector(for: text)
    }

    func findSimilarWords(to word: String, count: Int = 5) -> [(word: String, distance: Double)] {
        guard let embedding = sentenceEmbedding else { return [] }

        var results: [(String, Double)] = []

        embedding.enumerateNeighbors(for: word, maximumCount: count) { neighbor, distance in
            results.append((neighbor, distance))
            return true
        }

        return results
    }

    func calculateSimilarity(text1: String, text2: String) -> Double? {
        guard let embedding = sentenceEmbedding,
              let vector1 = embedding.vector(for: text1),
              let vector2 = embedding.vector(for: text2) else {
            return nil
        }

        return cosineSimilarity(vector1, vector2)
    }

    // MARK: - Text Classification

    func classifyText(_ text: String) -> [TextCategory] {
        // Use NLTagger for basic classification
        tagger.string = text

        var categories: [TextCategory] = []

        // Analyze entity types
        let entityCounts: [NLTag: Int] = [:]

        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .nameType
        ) { tag, _ in
            // Count named entities
            return true
        }

        // Basic topic classification based on keywords
        let lowercased = text.lowercased()

        if containsArabicKeywords(lowercased) {
            categories.append(.arabic)
        }
        if containsIslamicKeywords(lowercased) {
            categories.append(.islamic)
        }
        if containsFiqhKeywords(lowercased) {
            categories.append(.fiqh)
        }
        if containsAqidahKeywords(lowercased) {
            categories.append(.aqidah)
        }
        if containsHistoryKeywords(lowercased) {
            categories.append(.history)
        }

        return categories.isEmpty ? [.general] : categories
    }

    // MARK: - Basic Summarization (Extractive)

    func extractiveSummary(of text: String, sentenceCount: Int = 3) -> String {
        // Simple extractive summarization using sentence scoring
        let sentences = splitIntoSentences(text)

        guard sentences.count > sentenceCount else {
            return text
        }

        // Score sentences based on:
        // 1. Position (first and last sentences often important)
        // 2. Length (not too short, not too long)
        // 3. Keyword presence

        var scoredSentences: [(sentence: String, score: Double, index: Int)] = []

        let keywords = extractKeywords(from: text)

        for (index, sentence) in sentences.enumerated() {
            var score = 0.0

            // Position score
            if index == 0 || index == sentences.count - 1 {
                score += 0.3
            }

            // Length score (prefer medium-length sentences)
            let wordCount = sentence.components(separatedBy: .whitespaces).count
            if wordCount >= 10 && wordCount <= 30 {
                score += 0.2
            }

            // Keyword score
            let lowercased = sentence.lowercased()
            for keyword in keywords {
                if lowercased.contains(keyword.lowercased()) {
                    score += 0.1
                }
            }

            scoredSentences.append((sentence, score, index))
        }

        // Select top sentences
        let topSentences = scoredSentences
            .sorted { $0.score > $1.score }
            .prefix(sentenceCount)
            .sorted { $0.index < $1.index }  // Maintain original order
            .map(\.sentence)

        return topSentences.joined(separator: " ")
    }

    // MARK: - Keyword Extraction

    func extractKeywords(from text: String, count: Int = 10) -> [String] {
        tagger.string = text

        var wordFrequency: [String: Int] = [:]
        var importantWords: [String] = []

        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lexicalClass
        ) { tag, range in
            let word = String(text[range]).lowercased()

            // Skip common stop words and short words
            guard word.count > 3,
                  !isStopWord(word),
                  let tag = tag else {
                return true
            }

            // Focus on nouns and verbs
            if tag == .noun || tag == .verb {
                wordFrequency[word, default: 0] += 1
                importantWords.append(word)
            }

            return true
        }

        // Return most frequent important words
        return wordFrequency
            .sorted { $0.value > $1.value }
            .prefix(count)
            .map(\.key)
    }

    // MARK: - Arabic Detection

    func detectLanguage(_ text: String) -> NLLanguage? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage
    }

    func containsArabic(_ text: String) -> Bool {
        let arabicRange = text.range(of: "[\u{0600}-\u{06FF}]", options: .regularExpression)
        return arabicRange != nil
    }

    // MARK: - Private Helpers

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

    private func splitIntoSentences(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text

        var sentences: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty {
                sentences.append(sentence)
            }
            return true
        }

        return sentences
    }

    private func isStopWord(_ word: String) -> Bool {
        let stopWords: Set<String> = [
            "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for",
            "of", "with", "by", "from", "as", "is", "was", "are", "were", "been",
            "be", "have", "has", "had", "do", "does", "did", "will", "would",
            "could", "should", "may", "might", "must", "shall", "can", "need",
            "this", "that", "these", "those", "it", "its", "which", "who", "whom",
            "whose", "where", "when", "why", "how", "what", "all", "each", "every",
            "both", "few", "more", "most", "other", "some", "such", "only", "own",
            "same", "than", "too", "very", "just", "also", "now", "here", "there"
        ]
        return stopWords.contains(word)
    }

    // Keyword detection for classification
    private func containsIslamicKeywords(_ text: String) -> Bool {
        let keywords = ["allah", "quran", "prophet", "muhammad", "islam", "muslim", "hadith", "sunnah", "salah", "prayer", "mosque"]
        return keywords.contains { text.contains($0) }
    }

    private func containsFiqhKeywords(_ text: String) -> Bool {
        let keywords = ["fiqh", "halal", "haram", "wajib", "sunnah", "makruh", "ruling", "fatwa", "shariah", "jurisprudence"]
        return keywords.contains { text.contains($0) }
    }

    private func containsAqidahKeywords(_ text: String) -> Bool {
        let keywords = ["aqidah", "tawhid", "belief", "iman", "faith", "creed", "theology", "kalam"]
        return keywords.contains { text.contains($0) }
    }

    private func containsArabicKeywords(_ text: String) -> Bool {
        return containsArabic(text)
    }

    private func containsHistoryKeywords(_ text: String) -> Bool {
        let keywords = ["history", "century", "era", "caliphate", "dynasty", "conquest", "empire", "sultan", "khalifah"]
        return keywords.contains { text.contains($0) }
    }
}

// MARK: - Text Categories

enum TextCategory: String, CaseIterable, Sendable {
    case general
    case islamic
    case fiqh
    case aqidah
    case arabic
    case history

    var displayName: String {
        switch self {
        case .general: return "General"
        case .islamic: return "Islamic"
        case .fiqh: return "Fiqh"
        case .aqidah: return "Aqidah"
        case .arabic: return "Arabic"
        case .history: return "History"
        }
    }

    var icon: String {
        switch self {
        case .general: return "doc.text"
        case .islamic: return "moon.stars"
        case .fiqh: return "books.vertical"
        case .aqidah: return "heart"
        case .arabic: return "character.book.closed.ar"
        case .history: return "clock"
        }
    }
}

// MARK: - Errors

enum LocalAIError: LocalizedError {
    case modelNotAvailable
    case processingFailed(String)
    case embeddingFailed

    var errorDescription: String? {
        switch self {
        case .modelNotAvailable:
            return "Required model is not available. Please download it first."
        case .processingFailed(let reason):
            return "Processing failed: \(reason)"
        case .embeddingFailed:
            return "Failed to generate embedding."
        }
    }
}
