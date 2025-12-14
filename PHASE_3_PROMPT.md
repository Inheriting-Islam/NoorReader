# Phase 3: AI Integration - Development Prompt

بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ

**In the name of Allah, the Most Gracious, the Most Merciful.**

---

> "Whoever is given wisdom has certainly been given much good. And none will remember except those of understanding."
> — Quran 2:269

Phase 3 brings the power of artificial intelligence to NoorReader, enabling users to engage more deeply with their texts through summarization, flashcard generation, and semantic search — all while respecting their privacy by running locally on-device by default.

---

## Table of Contents

1. [Phase 3 Overview](#phase-3-overview)
2. [Prerequisites](#prerequisites)
3. [Architecture Overview](#architecture-overview)
4. [Implementation Tasks](#implementation-tasks)
   - [Task 1: MLX Framework Integration](#task-1-mlx-framework-integration)
   - [Task 2: Local Summarization](#task-2-local-summarization)
   - [Task 3: Auto Flashcard Generation](#task-3-auto-flashcard-generation)
   - [Task 4: Explain Selection Feature](#task-4-explain-selection-feature)
   - [Task 5: Semantic Search with Embeddings](#task-5-semantic-search-with-embeddings)
   - [Task 6: Claude API Integration (Optional)](#task-6-claude-api-integration-optional)
   - [Task 7: AI Settings & Privacy Controls](#task-7-ai-settings--privacy-controls)
5. [Data Models](#data-models)
6. [Quality Standards](#quality-standards)
7. [Testing Requirements](#testing-requirements)
8. [Phase 3 Completion Criteria](#phase-3-completion-criteria)

---

## Phase 3 Overview

**Objective:** Integrate AI capabilities that enhance the study experience while maintaining user privacy. Local-first AI using Apple's MLX framework ensures data never leaves the device by default, with optional cloud AI for users who want enhanced capabilities.

**Building Upon:** Phase 1 (PDF viewing, library, themes) and Phase 2 (annotations, notes, search, export)

**Deliverable:** Enhanced NoorReader with:
- On-device AI summarization using MLX
- Automatic flashcard generation from highlights
- "Explain this" feature for selected text
- Semantic/similarity search across documents
- Optional Claude API integration for advanced features
- Privacy-respecting AI settings

---

## Prerequisites

Before starting Phase 3, ensure Phases 1 and 2 are complete:

- [ ] PDF import and library management working
- [ ] PDF viewing with smooth rendering
- [ ] Full highlight system with 8 colors
- [ ] Notes attached to highlights functional
- [ ] Annotations sidebar working
- [ ] In-document search functional
- [ ] Markdown export working
- [ ] Islamic reminders functional
- [ ] All Phase 1 & 2 tests passing
- [ ] Zero compiler warnings

---

## Architecture Overview

### AI Privacy Model

```
┌─────────────────────────────────────────────────────────────┐
│                        AI FEATURES                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   LOCAL (Default)              CLOUD (Opt-In)               │
│   ─────────────────            ─────────────────            │
│   ✓ Summarization              ○ Study Chat                 │
│   ✓ Flashcard Generation       ○ Advanced Analysis          │
│   ✓ Explain Selection          ○ Cross-Book Insights        │
│   ✓ Semantic Search                                         │
│                                Requires:                    │
│   100% on-device               • User consent               │
│   No data leaves Mac           • API key                    │
│   Apple Silicon optimized      • Per-request approval       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### New Files to Create

```
NoorReader/
├── Shared/
│   ├── Models/
│   │   ├── Flashcard.swift              # NEW: Flashcard model
│   │   ├── AIResponse.swift             # NEW: AI response wrapper
│   │   └── SemanticIndex.swift          # NEW: Vector embeddings index
│   │
│   ├── Services/
│   │   ├── AIService.swift              # NEW: Local AI coordinator
│   │   ├── MLXService.swift             # NEW: MLX model management
│   │   ├── EmbeddingService.swift       # NEW: Text embeddings
│   │   ├── CloudAIService.swift         # NEW: Claude API client
│   │   └── FlashcardService.swift       # NEW: Flashcard management
│   │
│   ├── ViewModels/
│   │   ├── AIViewModel.swift            # NEW: AI feature state
│   │   └── FlashcardViewModel.swift     # NEW: Flashcard study state
│   │
│   └── Components/
│       ├── AISummarySheet.swift         # NEW: Summary display
│       ├── AIExplainPopover.swift       # NEW: Explanation display
│       ├── FlashcardGeneratorSheet.swift # NEW: Flashcard creation UI
│       ├── SemanticSearchBar.swift      # NEW: AI-powered search
│       └── AILoadingIndicator.swift     # NEW: AI processing state
│
└── macOS/
    └── Views/
        ├── AISettingsView.swift         # NEW: AI configuration
        └── FlashcardReviewView.swift    # NEW: Flashcard study UI
```

### Files to Modify

```
Shared/
├── Components/
│   └── SelectionPopover.swift           # MODIFY: Add AI actions
│
├── ViewModels/
│   ├── ReaderViewModel.swift            # MODIFY: AI integration
│   └── SettingsViewModel.swift          # MODIFY: AI preferences
│
└── Services/
    └── SearchService.swift              # MODIFY: Add semantic search

macOS/
├── MacReaderView.swift                  # MODIFY: AI UI integration
├── SettingsView.swift                   # MODIFY: AI settings tab
└── MacMenuCommands.swift                # MODIFY: AI menu items
```

---

## Implementation Tasks

### Task 1: MLX Framework Integration

**Objective:** Set up Apple's MLX framework for running LLMs locally on Apple Silicon.

#### 1.1 Add MLX Dependencies

Add MLX Swift to your project. In Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/ml-explore/mlx-swift`
3. Add `MLX`, `MLXRandom`, and `MLXNN` products

#### 1.2 Create MLX Service

```swift
// Shared/Services/MLXService.swift
// NEW FILE

import Foundation
import MLX
import MLXNN

/// Manages local LLM inference using MLX framework
actor MLXService {

    enum ModelType: String, CaseIterable {
        case small = "mlx-community/Qwen2.5-0.5B-Instruct-4bit"
        case medium = "mlx-community/Qwen2.5-1.5B-Instruct-4bit"
        case large = "mlx-community/Qwen2.5-3B-Instruct-4bit"

        var displayName: String {
            switch self {
            case .small: return "Fast (0.5B)"
            case .medium: return "Balanced (1.5B)"
            case .large: return "Quality (3B)"
            }
        }

        var contextLength: Int {
            switch self {
            case .small: return 4096
            case .medium: return 8192
            case .large: return 8192
            }
        }
    }

    enum MLXError: LocalizedError {
        case modelNotLoaded
        case downloadFailed(String)
        case inferenceFailed(String)
        case insufficientMemory

        var errorDescription: String? {
            switch self {
            case .modelNotLoaded:
                return "AI model is not loaded. Please wait for download to complete."
            case .downloadFailed(let reason):
                return "Failed to download AI model: \(reason)"
            case .inferenceFailed(let reason):
                return "AI processing failed: \(reason)"
            case .insufficientMemory:
                return "Not enough memory to run AI model. Try a smaller model."
            }
        }
    }

    // MARK: - Properties

    private var currentModel: ModelType?
    private var isModelLoaded = false
    private var downloadProgress: Double = 0

    // Model cache directory
    private var modelCacheURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("NoorReader/MLXModels", isDirectory: true)
    }

    // MARK: - Initialization

    init() {
        createCacheDirectoryIfNeeded()
    }

    private func createCacheDirectoryIfNeeded() {
        try? FileManager.default.createDirectory(
            at: modelCacheURL,
            withIntermediateDirectories: true
        )
    }

    // MARK: - Model Management

    func loadModel(_ type: ModelType) async throws {
        // Check if model is cached
        let modelPath = modelCacheURL.appendingPathComponent(type.rawValue)

        if !FileManager.default.fileExists(atPath: modelPath.path) {
            try await downloadModel(type)
        }

        // Load model into memory
        // Note: Actual MLX model loading code will depend on MLX-Swift API
        // This is a placeholder for the loading logic

        currentModel = type
        isModelLoaded = true
    }

    private func downloadModel(_ type: ModelType) async throws {
        // Download from Hugging Face hub
        // MLX-Swift provides utilities for this

        downloadProgress = 0

        // Placeholder for actual download logic
        // The MLX-Swift library provides model downloading utilities

        downloadProgress = 1.0
    }

    func unloadModel() {
        currentModel = nil
        isModelLoaded = false
    }

    // MARK: - Inference

    func generate(
        prompt: String,
        systemPrompt: String? = nil,
        maxTokens: Int = 512,
        temperature: Float = 0.7
    ) async throws -> String {
        guard isModelLoaded else {
            throw MLXError.modelNotLoaded
        }

        // Build the full prompt with system instructions
        var fullPrompt = ""
        if let system = systemPrompt {
            fullPrompt = "<|system|>\n\(system)<|end|>\n"
        }
        fullPrompt += "<|user|>\n\(prompt)<|end|>\n<|assistant|>\n"

        // Placeholder for actual MLX inference
        // The actual implementation will use MLX-Swift's generation API

        return "AI response placeholder"
    }

    func generateStream(
        prompt: String,
        systemPrompt: String? = nil,
        maxTokens: Int = 512,
        temperature: Float = 0.7
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard isModelLoaded else {
                        throw MLXError.modelNotLoaded
                    }

                    // Placeholder for streaming generation
                    // MLX-Swift supports token-by-token streaming

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Status

    func getDownloadProgress() -> Double {
        downloadProgress
    }

    func isReady() -> Bool {
        isModelLoaded
    }

    func getCurrentModel() -> ModelType? {
        currentModel
    }
}
```

#### 1.3 Create AI Service Coordinator

```swift
// Shared/Services/AIService.swift
// NEW FILE

import Foundation

/// Coordinates AI features between local (MLX) and cloud (Claude) services
@MainActor
@Observable
final class AIService {

    enum AIProvider {
        case local
        case cloud
    }

    enum AIFeature {
        case summarize
        case explain
        case flashcards
        case semanticSearch
        case chat
    }

    // MARK: - Properties

    private let mlxService = MLXService()
    private let cloudService = CloudAIService()
    private let embeddingService = EmbeddingService()

    var isProcessing = false
    var currentTask: String?
    var progress: Double = 0
    var error: Error?

    // User preferences
    var preferredProvider: AIProvider = .local
    var localModelType: MLXService.ModelType = .medium
    var cloudAPIKey: String?

    // MARK: - Initialization

    func initialize() async {
        do {
            try await mlxService.loadModel(localModelType)
        } catch {
            self.error = error
        }
    }

    // MARK: - Feature Availability

    func isFeatureAvailable(_ feature: AIFeature) -> Bool {
        switch feature {
        case .summarize, .explain, .flashcards:
            return preferredProvider == .local ? mlxService.isReady() : cloudAPIKey != nil
        case .semanticSearch:
            return embeddingService.isReady()
        case .chat:
            return cloudAPIKey != nil // Chat only available with cloud
        }
    }

    // MARK: - Summarization

    func summarize(
        text: String,
        style: SummarizationStyle = .concise
    ) async throws -> String {
        isProcessing = true
        currentTask = "Summarizing..."
        defer {
            isProcessing = false
            currentTask = nil
        }

        let systemPrompt = """
        You are a helpful study assistant. Summarize the following text \(style.instruction).
        Focus on key points and main arguments. Be clear and concise.
        """

        if preferredProvider == .local {
            return try await mlxService.generate(
                prompt: text,
                systemPrompt: systemPrompt,
                maxTokens: style.maxTokens
            )
        } else {
            return try await cloudService.summarize(text: text, style: style)
        }
    }

    // MARK: - Explanation

    func explain(text: String, context: String? = nil) async throws -> String {
        isProcessing = true
        currentTask = "Explaining..."
        defer {
            isProcessing = false
            currentTask = nil
        }

        var systemPrompt = """
        You are a patient teacher. Explain the following text in simple, clear language.
        Break down complex concepts. Use analogies where helpful.
        """

        if let ctx = context {
            systemPrompt += "\n\nContext from the document: \(ctx)"
        }

        if preferredProvider == .local {
            return try await mlxService.generate(
                prompt: "Please explain this: \(text)",
                systemPrompt: systemPrompt,
                maxTokens: 512
            )
        } else {
            return try await cloudService.explain(text: text, context: context)
        }
    }

    // MARK: - Flashcard Generation

    func generateFlashcards(
        from highlights: [Highlight],
        count: Int = 5
    ) async throws -> [FlashcardSuggestion] {
        isProcessing = true
        currentTask = "Generating flashcards..."
        defer {
            isProcessing = false
            currentTask = nil
        }

        let highlightText = highlights.map { "- \($0.text)" }.joined(separator: "\n")

        let systemPrompt = """
        You are a study assistant creating flashcards for spaced repetition learning.
        Generate exactly \(count) flashcards from the highlighted text.
        Each flashcard should have a clear question and concise answer.
        Focus on key concepts, definitions, and important facts.

        Format your response as JSON:
        [
          {"question": "...", "answer": "..."},
          {"question": "...", "answer": "..."}
        ]
        """

        let response: String
        if preferredProvider == .local {
            response = try await mlxService.generate(
                prompt: highlightText,
                systemPrompt: systemPrompt,
                maxTokens: 1024
            )
        } else {
            response = try await cloudService.generateFlashcardsRaw(
                from: highlightText,
                count: count
            )
        }

        return try parseFlashcardResponse(response)
    }

    private func parseFlashcardResponse(_ response: String) throws -> [FlashcardSuggestion] {
        // Extract JSON from response
        guard let jsonStart = response.firstIndex(of: "["),
              let jsonEnd = response.lastIndex(of: "]") else {
            throw AIError.parseError("Could not find JSON in response")
        }

        let jsonString = String(response[jsonStart...jsonEnd])
        let data = Data(jsonString.utf8)

        struct FlashcardJSON: Codable {
            let question: String
            let answer: String
        }

        let decoded = try JSONDecoder().decode([FlashcardJSON].self, from: data)
        return decoded.map { FlashcardSuggestion(question: $0.question, answer: $0.answer) }
    }

    // MARK: - Semantic Search

    func semanticSearch(
        query: String,
        in book: Book,
        limit: Int = 10
    ) async throws -> [SemanticSearchResult] {
        isProcessing = true
        currentTask = "Searching..."
        defer {
            isProcessing = false
            currentTask = nil
        }

        return try await embeddingService.search(
            query: query,
            in: book,
            limit: limit
        )
    }

    // MARK: - Model Management

    func switchModel(to type: MLXService.ModelType) async throws {
        await mlxService.unloadModel()
        try await mlxService.loadModel(type)
        localModelType = type
    }

    func getModelDownloadProgress() async -> Double {
        await mlxService.getDownloadProgress()
    }
}

// MARK: - Supporting Types

enum SummarizationStyle {
    case concise
    case detailed
    case bulletPoints

    var instruction: String {
        switch self {
        case .concise: return "in 2-3 sentences"
        case .detailed: return "in detail, covering all main points"
        case .bulletPoints: return "as bullet points highlighting key takeaways"
        }
    }

    var maxTokens: Int {
        switch self {
        case .concise: return 256
        case .detailed: return 1024
        case .bulletPoints: return 512
        }
    }
}

struct FlashcardSuggestion: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
    var isSelected: Bool = true
}

struct SemanticSearchResult: Identifiable {
    let id = UUID()
    let text: String
    let pageNumber: Int
    let relevanceScore: Double
}

enum AIError: LocalizedError {
    case parseError(String)
    case networkError(String)
    case quotaExceeded
    case invalidAPIKey

    var errorDescription: String? {
        switch self {
        case .parseError(let msg): return "Failed to parse AI response: \(msg)"
        case .networkError(let msg): return "Network error: \(msg)"
        case .quotaExceeded: return "API quota exceeded. Please try again later."
        case .invalidAPIKey: return "Invalid API key. Please check your settings."
        }
    }
}
```

---

### Task 2: Local Summarization

**Objective:** Enable users to select text or chapters and get AI-generated summaries.

#### 2.1 Create Summary Sheet Component

```swift
// Shared/Components/AISummarySheet.swift
// NEW FILE

import SwiftUI

struct AISummarySheet: View {
    let selectedText: String
    let pageRange: ClosedRange<Int>?
    @Environment(\.dismiss) private var dismiss

    @State private var aiService = AIService()
    @State private var summary: String?
    @State private var isLoading = false
    @State private var error: Error?
    @State private var style: SummarizationStyle = .concise

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Source text preview
                    sourcePreview

                    // Style selector
                    stylePicker

                    Divider()

                    // Summary output
                    if isLoading {
                        loadingView
                    } else if let error {
                        errorView(error)
                    } else if let summary {
                        summaryView(summary)
                    } else {
                        promptView
                    }
                }
                .padding()
            }

            Divider()

            // Footer
            footer
        }
        .frame(width: 500, height: 600)
        .background(.background)
    }

    private var header: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundStyle(.purple)

            Text("AI Summary")
                .font(.headline)

            Spacer()

            // Privacy indicator
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.caption)
                Text("On-device")
                    .font(.caption)
            }
            .foregroundStyle(.green)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.green.opacity(0.1))
            .clipShape(Capsule())

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    private var sourcePreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Source Text")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let range = pageRange {
                    Text("Pages \(range.lowerBound + 1)-\(range.upperBound + 1)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Text(selectedText)
                .font(.callout)
                .lineLimit(6)
                .padding()
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var stylePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary Style")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("Style", selection: $style) {
                Text("Concise").tag(SummarizationStyle.concise)
                Text("Detailed").tag(SummarizationStyle.detailed)
                Text("Bullet Points").tag(SummarizationStyle.bulletPoints)
            }
            .pickerStyle(.segmented)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Generating summary...")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("This runs entirely on your device")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)

            Text("Something went wrong")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                generateSummary()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func summaryView(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundStyle(.purple)

                Text("Summary")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(summary)
                .font(.body)
                .textSelection(.enabled)
                .padding()
                .background(Color.purple.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var promptView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(.purple.opacity(0.5))

            Text("Ready to summarize")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Click 'Generate' to create an AI summary of the selected text.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var footer: some View {
        HStack {
            if summary != nil {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(summary!, forType: .string)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }

                Button {
                    // Save to notes
                } label: {
                    Label("Save to Notes", systemImage: "square.and.pencil")
                }
            }

            Spacer()

            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.escape, modifiers: [])

            Button("Generate") {
                generateSummary()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding()
    }

    private func generateSummary() {
        isLoading = true
        error = nil

        Task {
            do {
                summary = try await aiService.summarize(text: selectedText, style: style)
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
}
```

#### 2.2 Update Selection Popover

```swift
// Shared/Components/SelectionPopover.swift
// MODIFY - Add AI actions

// Add to the action buttons section:

ActionButton(icon: "sparkles", label: "AI", shortcut: "A") {
    onAIAction()
}

// Add AI submenu when expanded:
Menu {
    Button {
        onSummarize()
    } label: {
        Label("Summarize", systemImage: "text.alignleft")
    }

    Button {
        onExplain()
    } label: {
        Label("Explain", systemImage: "questionmark.circle")
    }

    Button {
        onCreateFlashcard()
    } label: {
        Label("Create Flashcard", systemImage: "rectangle.on.rectangle")
    }
} label: {
    Label("AI Actions", systemImage: "sparkles")
}
```

---

### Task 3: Auto Flashcard Generation

**Objective:** Generate flashcards from highlights for spaced repetition learning.

#### 3.1 Create Flashcard Model

```swift
// Shared/Models/Flashcard.swift
// NEW FILE

import SwiftData
import Foundation

@Model
final class Flashcard {
    var id: UUID
    var front: String  // Question
    var back: String   // Answer
    var dateCreated: Date
    var dateLastReviewed: Date?
    var nextReviewDate: Date

    // Spaced repetition fields (SM-2 algorithm)
    var easeFactor: Double  // Default 2.5
    var interval: Int       // Days until next review
    var repetitions: Int    // Number of successful reviews

    // Source tracking
    var sourcePageNumber: Int?
    var sourceHighlightID: UUID?

    // Relationships
    var book: Book?

    // Review quality ratings
    enum ReviewQuality: Int {
        case again = 0      // Complete failure
        case hard = 1       // Correct with difficulty
        case good = 2       // Correct with some hesitation
        case easy = 3       // Perfect recall
    }

    var isDue: Bool {
        nextReviewDate <= Date()
    }

    init(
        front: String,
        back: String,
        sourcePageNumber: Int? = nil,
        sourceHighlightID: UUID? = nil
    ) {
        self.id = UUID()
        self.front = front
        self.back = back
        self.dateCreated = Date()
        self.nextReviewDate = Date()  // Due immediately
        self.easeFactor = 2.5
        self.interval = 0
        self.repetitions = 0
        self.sourcePageNumber = sourcePageNumber
        self.sourceHighlightID = sourceHighlightID
    }

    /// Process a review using SM-2 algorithm
    func processReview(quality: ReviewQuality) {
        dateLastReviewed = Date()

        if quality.rawValue < 2 {
            // Failed review - reset
            repetitions = 0
            interval = 1
        } else {
            // Successful review
            repetitions += 1

            if repetitions == 1 {
                interval = 1
            } else if repetitions == 2 {
                interval = 6
            } else {
                interval = Int(Double(interval) * easeFactor)
            }
        }

        // Update ease factor
        let q = Double(quality.rawValue)
        easeFactor = max(1.3, easeFactor + (0.1 - (3 - q) * (0.08 + (3 - q) * 0.02)))

        // Calculate next review date
        nextReviewDate = Calendar.current.date(
            byAdding: .day,
            value: interval,
            to: Date()
        ) ?? Date()
    }
}

// Add relationship to Book model
extension Book {
    @Relationship(deleteRule: .cascade)
    var flashcards: [Flashcard] { get set }

    var dueFlashcards: [Flashcard] {
        flashcards.filter { $0.isDue }
    }
}
```

#### 3.2 Create Flashcard Generator Sheet

```swift
// Shared/Components/FlashcardGeneratorSheet.swift
// NEW FILE

import SwiftUI

struct FlashcardGeneratorSheet: View {
    let highlights: [Highlight]
    let book: Book
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var aiService = AIService()
    @State private var suggestions: [FlashcardSuggestion] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var flashcardCount = 5

    var selectedCount: Int {
        suggestions.filter { $0.isSelected }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            if isLoading {
                loadingView
            } else if let error {
                errorView(error)
            } else if suggestions.isEmpty {
                configurationView
            } else {
                suggestionsView
            }

            Divider()

            footer
        }
        .frame(width: 550, height: 650)
        .background(.background)
    }

    private var header: some View {
        HStack {
            Image(systemName: "rectangle.on.rectangle")
                .foregroundStyle(.blue)

            Text("Generate Flashcards")
                .font(.headline)

            Spacer()

            Text("\(highlights.count) highlights selected")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("AI is analyzing your highlights...")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Generating \(flashcardCount) flashcards")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)

            Text("Generation Failed")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                generateFlashcards()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var configurationView: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(.blue.opacity(0.6))

            Text("Create Flashcards from Highlights")
                .font(.title2)

            Text("AI will analyze your \(highlights.count) highlights and generate study flashcards.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            VStack(alignment: .leading, spacing: 8) {
                Text("Number of flashcards")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Picker("Count", selection: $flashcardCount) {
                    Text("3 cards").tag(3)
                    Text("5 cards").tag(5)
                    Text("10 cards").tag(10)
                }
                .pickerStyle(.segmented)
                .frame(width: 250)
            }

            Button {
                generateFlashcards()
            } label: {
                Label("Generate Flashcards", systemImage: "sparkles")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var suggestionsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach($suggestions) { $suggestion in
                    FlashcardSuggestionRow(
                        suggestion: $suggestion
                    )
                }
            }
            .padding()
        }
    }

    private var footer: some View {
        HStack {
            if !suggestions.isEmpty {
                Button("Select All") {
                    for i in suggestions.indices {
                        suggestions[i].isSelected = true
                    }
                }

                Button("Deselect All") {
                    for i in suggestions.indices {
                        suggestions[i].isSelected = false
                    }
                }
            }

            Spacer()

            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.escape, modifiers: [])

            if !suggestions.isEmpty {
                Button("Create \(selectedCount) Flashcards") {
                    createSelectedFlashcards()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedCount == 0)
            }
        }
        .padding()
    }

    private func generateFlashcards() {
        isLoading = true
        error = nil

        Task {
            do {
                suggestions = try await aiService.generateFlashcards(
                    from: highlights,
                    count: flashcardCount
                )
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }

    private func createSelectedFlashcards() {
        let selected = suggestions.filter { $0.isSelected }

        for suggestion in selected {
            let flashcard = Flashcard(
                front: suggestion.question,
                back: suggestion.answer
            )
            flashcard.book = book
            modelContext.insert(flashcard)
        }

        dismiss()
    }
}

struct FlashcardSuggestionRow: View {
    @Binding var suggestion: FlashcardSuggestion

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Toggle("", isOn: $suggestion.isSelected)
                .labelsHidden()

            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Question")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(suggestion.question)
                        .font(.callout)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Answer")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(suggestion.answer)
                        .font(.callout)
                        .foregroundStyle(.primary.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(suggestion.isSelected ? Color.blue.opacity(0.05) : Color.secondary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(suggestion.isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}
```

---

### Task 4: Explain Selection Feature

**Objective:** Allow users to select confusing text and get a clear explanation.

#### 4.1 Create Explain Popover

```swift
// Shared/Components/AIExplainPopover.swift
// NEW FILE

import SwiftUI

struct AIExplainPopover: View {
    let selectedText: String
    let context: String?
    @State private var aiService = AIService()
    @State private var explanation: String?
    @State private var isLoading = false
    @State private var error: Error?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundStyle(.orange)

                Text("Explain")
                    .font(.headline)

                Spacer()

                // Privacy badge
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                    Text("Local AI")
                        .font(.caption2)
                }
                .foregroundStyle(.green)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.1))
                .clipShape(Capsule())
            }

            // Selected text
            Text(selectedText)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .padding(10)
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Divider()

            // Explanation
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Thinking...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if let error {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)

                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Retry") {
                        explain()
                    }
                    .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            } else if let explanation {
                Text(explanation)
                    .font(.body)
                    .textSelection(.enabled)
            }

            // Actions
            if explanation != nil {
                Divider()

                HStack {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(explanation!, forType: .string)
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        explain()
                    } label: {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .frame(width: 350)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        .onAppear {
            explain()
        }
    }

    private func explain() {
        isLoading = true
        error = nil

        Task {
            do {
                explanation = try await aiService.explain(
                    text: selectedText,
                    context: context
                )
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
}
```

---

### Task 5: Semantic Search with Embeddings

**Objective:** Enable "search by meaning" using vector embeddings.

#### 5.1 Create Embedding Service

```swift
// Shared/Services/EmbeddingService.swift
// NEW FILE

import Foundation
import NaturalLanguage

/// Generates and manages text embeddings for semantic search
actor EmbeddingService {

    private var embeddings: [UUID: SemanticIndex] = [:]
    private let embeddingModel: NLEmbedding?

    init() {
        // Use Apple's built-in sentence embedding
        self.embeddingModel = NLEmbedding.sentenceEmbedding(for: .english)
    }

    func isReady() -> Bool {
        embeddingModel != nil
    }

    // MARK: - Index Building

    func buildIndex(for book: Book, document: PDFDocument) async throws {
        var chunks: [TextChunk] = []

        // Extract text chunks from each page
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex),
                  let pageText = page.string else { continue }

            // Split into paragraphs
            let paragraphs = pageText.components(separatedBy: "\n\n")

            for (paragraphIndex, text) in paragraphs.enumerated() {
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmed.count > 50 else { continue }  // Skip short chunks

                if let embedding = getEmbedding(for: trimmed) {
                    chunks.append(TextChunk(
                        text: trimmed,
                        pageNumber: pageIndex,
                        chunkIndex: paragraphIndex,
                        embedding: embedding
                    ))
                }
            }
        }

        embeddings[book.id] = SemanticIndex(
            bookID: book.id,
            chunks: chunks,
            dateBuilt: Date()
        )
    }

    // MARK: - Search

    func search(
        query: String,
        in book: Book,
        limit: Int = 10
    ) async throws -> [SemanticSearchResult] {
        guard let index = embeddings[book.id] else {
            throw EmbeddingError.indexNotBuilt
        }

        guard let queryEmbedding = getEmbedding(for: query) else {
            throw EmbeddingError.embeddingFailed
        }

        // Calculate cosine similarity for all chunks
        var results: [(chunk: TextChunk, score: Double)] = []

        for chunk in index.chunks {
            let similarity = cosineSimilarity(queryEmbedding, chunk.embedding)
            results.append((chunk, similarity))
        }

        // Sort by similarity and take top results
        results.sort { $0.score > $1.score }

        return results.prefix(limit).map { result in
            SemanticSearchResult(
                text: result.chunk.text,
                pageNumber: result.chunk.pageNumber,
                relevanceScore: result.score
            )
        }
    }

    // MARK: - Embedding Helpers

    private func getEmbedding(for text: String) -> [Double]? {
        guard let model = embeddingModel else { return nil }

        // NLEmbedding returns an optional vector
        guard let vector = model.vector(for: text) else { return nil }

        return vector
    }

    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count else { return 0 }

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

    // MARK: - Index Management

    func hasIndex(for book: Book) -> Bool {
        embeddings[book.id] != nil
    }

    func removeIndex(for book: Book) {
        embeddings.removeValue(forKey: book.id)
    }
}

// MARK: - Supporting Types

struct TextChunk {
    let text: String
    let pageNumber: Int
    let chunkIndex: Int
    let embedding: [Double]
}

struct SemanticIndex {
    let bookID: UUID
    let chunks: [TextChunk]
    let dateBuilt: Date
}

enum EmbeddingError: LocalizedError {
    case indexNotBuilt
    case embeddingFailed

    var errorDescription: String? {
        switch self {
        case .indexNotBuilt:
            return "Semantic index not built for this book. Please wait for indexing to complete."
        case .embeddingFailed:
            return "Failed to generate text embeddings."
        }
    }
}
```

#### 5.2 Create Semantic Search Bar

```swift
// Shared/Components/SemanticSearchBar.swift
// NEW FILE

import SwiftUI

struct SemanticSearchBar: View {
    @Binding var query: String
    @Binding var results: [SemanticSearchResult]
    @Binding var selectedIndex: Int
    let book: Book
    let onNavigate: (Int) -> Void
    let onClose: () -> Void

    @State private var aiService = AIService()
    @State private var isSearching = false
    @State private var searchMode: SearchMode = .keyword

    enum SearchMode {
        case keyword
        case semantic
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search input
            HStack(spacing: 12) {
                // Mode toggle
                Picker("", selection: $searchMode) {
                    Image(systemName: "textformat")
                        .tag(SearchMode.keyword)
                    Image(systemName: "sparkles")
                        .tag(SearchMode.semantic)
                }
                .pickerStyle(.segmented)
                .frame(width: 80)
                .help(searchMode == .keyword ? "Keyword Search" : "AI Semantic Search")

                // Search field
                HStack(spacing: 8) {
                    Image(systemName: searchMode == .semantic ? "sparkles" : "magnifyingglass")
                        .foregroundStyle(searchMode == .semantic ? .purple : .secondary)

                    TextField(
                        searchMode == .semantic ? "Ask a question about the content..." : "Search...",
                        text: $query
                    )
                    .textFieldStyle(.plain)
                    .onSubmit {
                        performSearch()
                    }

                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.7)
                    }

                    if !query.isEmpty {
                        Button {
                            query = ""
                            results = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Close
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            // Semantic search hint
            if searchMode == .semantic && query.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb")
                        .font(.caption)
                    Text("Try: \"Where does the author discuss motivation?\" or \"Examples of leadership\"")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }

            // Results
            if !results.isEmpty {
                Divider()

                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                            SemanticSearchResultRow(
                                result: result,
                                isSelected: index == selectedIndex,
                                showRelevance: searchMode == .semantic
                            ) {
                                onNavigate(result.pageNumber)
                            }
                        }
                    }
                    .padding(8)
                }
                .frame(maxHeight: 300)
            }
        }
        .background(.bar)
    }

    private func performSearch() {
        guard !query.isEmpty else { return }

        if searchMode == .semantic {
            performSemanticSearch()
        } else {
            // Regular keyword search handled elsewhere
        }
    }

    private func performSemanticSearch() {
        isSearching = true

        Task {
            do {
                results = try await aiService.semanticSearch(
                    query: query,
                    in: book,
                    limit: 10
                )
            } catch {
                print("Semantic search error: \(error)")
            }
            isSearching = false
        }
    }
}

struct SemanticSearchResultRow: View {
    let result: SemanticSearchResult
    let isSelected: Bool
    let showRelevance: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Page number
                Text("\(result.pageNumber + 1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 30)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.text)
                        .font(.callout)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    if showRelevance {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                            Text("\(Int(result.relevanceScore * 100))% relevant")
                                .font(.caption2)
                        }
                        .foregroundStyle(.purple)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}
```

---

### Task 6: Claude API Integration (Optional)

**Objective:** Provide optional cloud AI for users who want enhanced capabilities.

#### 6.1 Create Cloud AI Service

```swift
// Shared/Services/CloudAIService.swift
// NEW FILE

import Foundation

/// Client for Claude API (optional cloud AI features)
actor CloudAIService {

    private var apiKey: String?
    private let baseURL = "https://api.anthropic.com/v1"
    private let modelID = "claude-3-haiku-20240307"  // Fast, cost-effective

    // MARK: - Configuration

    func configure(apiKey: String) {
        self.apiKey = apiKey
    }

    func isConfigured() -> Bool {
        apiKey != nil && !apiKey!.isEmpty
    }

    // MARK: - API Methods

    func summarize(text: String, style: SummarizationStyle) async throws -> String {
        let systemPrompt = """
        You are a helpful study assistant. Summarize the following text \(style.instruction).
        Focus on key points and main arguments. Be clear and concise.
        """

        return try await sendMessage(
            userMessage: text,
            systemPrompt: systemPrompt,
            maxTokens: style.maxTokens
        )
    }

    func explain(text: String, context: String?) async throws -> String {
        var systemPrompt = """
        You are a patient teacher. Explain the following text in simple, clear language.
        Break down complex concepts. Use analogies where helpful.
        """

        if let ctx = context {
            systemPrompt += "\n\nDocument context: \(ctx)"
        }

        return try await sendMessage(
            userMessage: "Please explain this:\n\n\(text)",
            systemPrompt: systemPrompt,
            maxTokens: 512
        )
    }

    func generateFlashcardsRaw(from highlightText: String, count: Int) async throws -> String {
        let systemPrompt = """
        You are a study assistant creating flashcards for spaced repetition learning.
        Generate exactly \(count) flashcards from the highlighted text.
        Each flashcard should have a clear question and concise answer.
        Focus on key concepts, definitions, and important facts.

        Format your response as JSON array:
        [{"question": "...", "answer": "..."}, ...]
        """

        return try await sendMessage(
            userMessage: highlightText,
            systemPrompt: systemPrompt,
            maxTokens: 1024
        )
    }

    func chat(
        messages: [(role: String, content: String)],
        bookContext: String?
    ) async throws -> String {
        guard isConfigured() else {
            throw CloudAIError.notConfigured
        }

        var systemPrompt = """
        You are a knowledgeable study assistant helping the user understand their reading material.
        Be helpful, accurate, and concise. If you're unsure about something, say so.
        """

        if let context = bookContext {
            systemPrompt += "\n\nThe user is reading a document. Here's some context:\n\(context)"
        }

        return try await sendChatMessages(
            messages: messages,
            systemPrompt: systemPrompt
        )
    }

    // MARK: - API Communication

    private func sendMessage(
        userMessage: String,
        systemPrompt: String,
        maxTokens: Int
    ) async throws -> String {
        guard let apiKey else {
            throw CloudAIError.notConfigured
        }

        let url = URL(string: "\(baseURL)/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": modelID,
            "max_tokens": maxTokens,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userMessage]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudAIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw CloudAIError.invalidAPIKey
        }

        if httpResponse.statusCode == 429 {
            throw CloudAIError.rateLimited
        }

        guard httpResponse.statusCode == 200 else {
            throw CloudAIError.apiError(httpResponse.statusCode)
        }

        return try parseResponse(data)
    }

    private func sendChatMessages(
        messages: [(role: String, content: String)],
        systemPrompt: String
    ) async throws -> String {
        guard let apiKey else {
            throw CloudAIError.notConfigured
        }

        let url = URL(string: "\(baseURL)/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let formattedMessages = messages.map { ["role": $0.role, "content": $0.content] }

        let body: [String: Any] = [
            "model": modelID,
            "max_tokens": 1024,
            "system": systemPrompt,
            "messages": formattedMessages
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw CloudAIError.invalidResponse
        }

        return try parseResponse(data)
    }

    private func parseResponse(_ data: Data) throws -> String {
        struct Response: Codable {
            struct Content: Codable {
                let text: String
            }
            let content: [Content]
        }

        let response = try JSONDecoder().decode(Response.self, from: data)
        return response.content.first?.text ?? ""
    }
}

enum CloudAIError: LocalizedError {
    case notConfigured
    case invalidAPIKey
    case rateLimited
    case invalidResponse
    case apiError(Int)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Cloud AI not configured. Please add your API key in Settings."
        case .invalidAPIKey:
            return "Invalid API key. Please check your key in Settings."
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .invalidResponse:
            return "Invalid response from AI service."
        case .apiError(let code):
            return "API error (code \(code)). Please try again."
        }
    }
}
```

---

### Task 7: AI Settings & Privacy Controls

**Objective:** Give users full control over AI features and their privacy.

#### 7.1 Create AI Settings View

```swift
// macOS/Views/AISettingsView.swift
// NEW FILE

import SwiftUI

struct AISettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var aiService = AIService()
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0

    var body: some View {
        Form {
            // AI Enable/Disable
            Section {
                Toggle("Enable AI Features", isOn: $viewModel.aiEnabled)
                    .help("Enable or disable all AI features")
            } header: {
                Text("AI Features")
            }

            if viewModel.aiEnabled {
                // Provider Selection
                Section {
                    Picker("AI Provider", selection: $viewModel.aiProvider) {
                        Text("Local (On-Device)").tag(AIProvider.local)
                        Text("Cloud (Claude API)").tag(AIProvider.cloud)
                    }

                    if viewModel.aiProvider == .local {
                        localAISettings
                    } else {
                        cloudAISettings
                    }
                } header: {
                    Text("Provider")
                } footer: {
                    if viewModel.aiProvider == .local {
                        Text("Local AI runs entirely on your Mac. Your data never leaves your device.")
                    } else {
                        Text("Cloud AI sends text to Anthropic's servers. Only use for non-sensitive content.")
                    }
                }

                // Feature Toggles
                Section {
                    Toggle("Summarization", isOn: $viewModel.aiSummarizationEnabled)
                    Toggle("Explain Selection", isOn: $viewModel.aiExplainEnabled)
                    Toggle("Flashcard Generation", isOn: $viewModel.aiFlashcardsEnabled)
                    Toggle("Semantic Search", isOn: $viewModel.aiSemanticSearchEnabled)
                } header: {
                    Text("Features")
                }

                // Privacy
                Section {
                    privacyInfo
                } header: {
                    Text("Privacy")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var localAISettings: some View {
        Group {
            Picker("Model Size", selection: $viewModel.localModelType) {
                ForEach(MLXService.ModelType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .onChange(of: viewModel.localModelType) { _, newType in
                switchModel(to: newType)
            }

            if isDownloading {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: downloadProgress)
                    Text("Downloading model... \(Int(downloadProgress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Model Status")
                        .font(.subheadline)
                    Text(aiService.isProcessing ? "Processing..." : "Ready")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Circle()
                    .fill(aiService.isProcessing ? .orange : .green)
                    .frame(width: 8, height: 8)
            }
        }
    }

    private var cloudAISettings: some View {
        Group {
            SecureField("Claude API Key", text: $viewModel.claudeAPIKey)
                .textFieldStyle(.roundedBorder)

            if !viewModel.claudeAPIKey.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("API key configured")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Link("Get an API key from Anthropic",
                 destination: URL(string: "https://console.anthropic.com/")!)
                .font(.caption)
        }
    }

    private var privacyInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: viewModel.aiProvider == .local ? "lock.shield.fill" : "network")
                    .font(.title2)
                    .foregroundStyle(viewModel.aiProvider == .local ? .green : .orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.aiProvider == .local ? "Maximum Privacy" : "Cloud Processing")
                        .font(.headline)

                    if viewModel.aiProvider == .local {
                        Text("All AI processing happens on your Mac using Apple's MLX framework. No data is sent to any external server.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Text is sent to Anthropic's Claude API for processing. Use only for non-sensitive content. Anthropic does not train on API data.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if viewModel.aiProvider == .local {
                HStack(spacing: 8) {
                    Label("On-device", systemImage: "desktopcomputer")
                    Label("No internet required", systemImage: "wifi.slash")
                    Label("Fully private", systemImage: "hand.raised.fill")
                }
                .font(.caption)
                .foregroundStyle(.green)
            }
        }
    }

    private func switchModel(to type: MLXService.ModelType) {
        isDownloading = true

        Task {
            // Monitor download progress
            while isDownloading {
                downloadProgress = await aiService.getModelDownloadProgress()
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            }
        }

        Task {
            do {
                try await aiService.switchModel(to: type)
            } catch {
                print("Model switch error: \(error)")
            }
            isDownloading = false
        }
    }
}
```

#### 7.2 Update SettingsViewModel

```swift
// Shared/ViewModels/SettingsViewModel.swift
// MODIFY - Add AI settings

// Add these properties to SettingsViewModel:

// MARK: - AI Settings

var aiEnabled: Bool = true {
    didSet {
        UserDefaults.standard.set(aiEnabled, forKey: "aiEnabled")
    }
}

var aiProvider: AIProvider = .local {
    didSet {
        UserDefaults.standard.set(aiProvider == .local ? "local" : "cloud", forKey: "aiProvider")
    }
}

var localModelType: MLXService.ModelType = .medium {
    didSet {
        UserDefaults.standard.set(localModelType.rawValue, forKey: "localModelType")
    }
}

var claudeAPIKey: String = "" {
    didSet {
        // Store securely in Keychain in production
        UserDefaults.standard.set(claudeAPIKey, forKey: "claudeAPIKey")
    }
}

var aiSummarizationEnabled: Bool = true {
    didSet {
        UserDefaults.standard.set(aiSummarizationEnabled, forKey: "aiSummarizationEnabled")
    }
}

var aiExplainEnabled: Bool = true {
    didSet {
        UserDefaults.standard.set(aiExplainEnabled, forKey: "aiExplainEnabled")
    }
}

var aiFlashcardsEnabled: Bool = true {
    didSet {
        UserDefaults.standard.set(aiFlashcardsEnabled, forKey: "aiFlashcardsEnabled")
    }
}

var aiSemanticSearchEnabled: Bool = true {
    didSet {
        UserDefaults.standard.set(aiSemanticSearchEnabled, forKey: "aiSemanticSearchEnabled")
    }
}

// Add to init():
aiEnabled = UserDefaults.standard.object(forKey: "aiEnabled") as? Bool ?? true
let providerString = UserDefaults.standard.string(forKey: "aiProvider") ?? "local"
aiProvider = providerString == "cloud" ? .cloud : .local
if let modelRaw = UserDefaults.standard.string(forKey: "localModelType") {
    localModelType = MLXService.ModelType(rawValue: modelRaw) ?? .medium
}
claudeAPIKey = UserDefaults.standard.string(forKey: "claudeAPIKey") ?? ""
aiSummarizationEnabled = UserDefaults.standard.object(forKey: "aiSummarizationEnabled") as? Bool ?? true
aiExplainEnabled = UserDefaults.standard.object(forKey: "aiExplainEnabled") as? Bool ?? true
aiFlashcardsEnabled = UserDefaults.standard.object(forKey: "aiFlashcardsEnabled") as? Bool ?? true
aiSemanticSearchEnabled = UserDefaults.standard.object(forKey: "aiSemanticSearchEnabled") as? Bool ?? true
```

---

## Data Models

### New Models Summary

```swift
// All new SwiftData models for Phase 3

@Model final class Flashcard {
    var id: UUID
    var front: String
    var back: String
    var dateCreated: Date
    var dateLastReviewed: Date?
    var nextReviewDate: Date
    var easeFactor: Double
    var interval: Int
    var repetitions: Int
    var sourcePageNumber: Int?
    var sourceHighlightID: UUID?
    var book: Book?
}

// Update Book model to include:
@Relationship(deleteRule: .cascade)
var flashcards: [Flashcard] = []
```

---

## Quality Standards

### Code Quality

- Swift 6 strict concurrency — all AI services are actors
- Comprehensive error handling with user-friendly messages
- Privacy-first design — local by default
- Clean separation between local and cloud AI
- Proper memory management for large models

### Performance Targets

| Metric | Target |
|--------|--------|
| Model load time | < 10 seconds |
| Summarization (local) | < 5 seconds for 1 page |
| Flashcard generation | < 8 seconds for 5 cards |
| Semantic search | < 1 second |
| Memory usage | < 2GB with model loaded |

### Privacy Standards

- Local AI is the default
- No data leaves device unless user explicitly enables cloud
- Cloud API key stored securely (Keychain in production)
- Clear indicators when AI is processing
- User can disable all AI features

---

## Testing Requirements

### Unit Tests

```swift
// Tests/SharedTests/AITests.swift

final class AIServiceTests: XCTestCase {

    func testLocalSummarization() async throws {
        let service = AIService()
        await service.initialize()

        let text = "This is a test paragraph about machine learning..."
        let summary = try await service.summarize(text: text)

        XCTAssertFalse(summary.isEmpty)
        XCTAssert(summary.count < text.count)
    }

    func testFlashcardGeneration() async throws {
        let service = AIService()
        await service.initialize()

        let highlights = [
            Highlight(text: "Machine learning is a subset of AI", pageNumber: 1)
        ]

        let flashcards = try await service.generateFlashcards(from: highlights, count: 3)

        XCTAssertEqual(flashcards.count, 3)
        XCTAssert(flashcards.allSatisfy { !$0.question.isEmpty && !$0.answer.isEmpty })
    }

    func testSemanticSearch() async throws {
        // Test embedding generation and similarity search
    }
}

final class FlashcardTests: XCTestCase {

    func testSM2Algorithm() {
        let card = Flashcard(front: "Q", back: "A")

        // First review - good
        card.processReview(quality: .good)
        XCTAssertEqual(card.interval, 1)
        XCTAssertEqual(card.repetitions, 1)

        // Second review - good
        card.processReview(quality: .good)
        XCTAssertEqual(card.interval, 6)
        XCTAssertEqual(card.repetitions, 2)

        // Third review - hard
        card.processReview(quality: .hard)
        XCTAssertEqual(card.repetitions, 3)
        XCTAssert(card.easeFactor < 2.5)
    }

    func testReviewReset() {
        let card = Flashcard(front: "Q", back: "A")
        card.processReview(quality: .good)
        card.processReview(quality: .good)

        // Failed review
        card.processReview(quality: .again)
        XCTAssertEqual(card.repetitions, 0)
        XCTAssertEqual(card.interval, 1)
    }
}
```

### Manual Testing Checklist

- [ ] AI model downloads successfully
- [ ] Model switching works (small/medium/large)
- [ ] Summarization produces coherent output
- [ ] Different summary styles work (concise/detailed/bullets)
- [ ] Explain selection provides clear explanations
- [ ] Flashcard generation creates valid Q&A pairs
- [ ] Flashcard selection/deselection works
- [ ] Created flashcards save to database
- [ ] Semantic search returns relevant results
- [ ] Semantic search scores make sense
- [ ] Claude API integration works (with valid key)
- [ ] Invalid API key shows appropriate error
- [ ] AI settings persist across app restarts
- [ ] Privacy indicators are accurate
- [ ] AI features can be disabled individually
- [ ] Memory usage is acceptable with model loaded
- [ ] AI works offline (local mode)

---

## Phase 3 Completion Criteria

Phase 3 is complete when ALL of the following are true:

### Functionality

- [ ] MLX framework integrated and models download
- [ ] Local summarization works for selected text
- [ ] Three summarization styles available (concise/detailed/bullets)
- [ ] Explain selection provides clear explanations
- [ ] Flashcard generation creates valid Q&A from highlights
- [ ] Flashcards use SM-2 spaced repetition algorithm
- [ ] Semantic search returns relevant results
- [ ] Claude API integration works (optional)
- [ ] All AI features can be individually enabled/disabled
- [ ] Model size can be changed (small/medium/large)
- [ ] Privacy indicators show current AI mode

### Quality

- [ ] Zero compiler warnings
- [ ] All unit tests pass
- [ ] Manual testing checklist complete
- [ ] Performance targets met
- [ ] Memory usage acceptable

### Privacy

- [ ] Local AI is default
- [ ] No network requests in local mode
- [ ] Clear indication when cloud AI is used
- [ ] API key stored securely

### Integration

- [ ] AI actions available in selection popover
- [ ] AI settings integrated in Settings view
- [ ] AI features respect user preferences
- [ ] Keyboard shortcuts for AI actions

---

## Dua for Knowledge

رَبِّ زِدْنِي عِلْمًا

*Rabbi zidni 'ilma.*

**My Lord, increase me in knowledge.**
— Quran 20:114

---

اللَّهُمَّ انْفَعْنَا بِمَا عَلَّمْتَنَا وَعَلِّمْنَا مَا يَنْفَعُنَا وَزِدْنَا عِلْمًا

*Allahumma infa'na bima 'allamtana wa 'allimna ma yanfa'una wa zidna 'ilma.*

**O Allah, benefit us with what You have taught us, teach us what will benefit us, and increase us in knowledge.**

---

بِسْمِ اللَّهِ، تَوَكَّلْتُ عَلَى اللَّهِ

**In the name of Allah, I place my trust in Allah.**

Continue with excellence and intention.
