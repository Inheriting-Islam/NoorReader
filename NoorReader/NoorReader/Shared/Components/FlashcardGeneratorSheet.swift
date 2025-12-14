// FlashcardGeneratorSheet.swift
// NoorReader
//
// AI-powered flashcard generation from highlights

import SwiftUI
import SwiftData

struct FlashcardGeneratorSheet: View {
    let highlights: [Highlight]
    let book: Book

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var aiService = AIService.shared
    @State private var suggestions: [FlashcardSuggestion] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var flashcardCount = 5
    @State private var showSuccessMessage = false

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
        .overlay {
            if showSuccessMessage {
                successOverlay
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "rectangle.on.rectangle")
                .foregroundStyle(.blue)

            Text("Generate Flashcards")
                .font(.headline)

            Spacer()

            Text("\(highlights.count) highlight\(highlights.count == 1 ? "" : "s") selected")
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

    // MARK: - Loading View

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

    // MARK: - Error View

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
                .padding(.horizontal)

            Button("Try Again") {
                generateFlashcards()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Configuration View

    private var configurationView: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(.blue.opacity(0.6))

            Text("Create Flashcards from Highlights")
                .font(.title2)

            Text("AI will analyze your \(highlights.count) highlight\(highlights.count == 1 ? "" : "s") and generate study flashcards.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Highlight preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Highlights to analyze:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(highlights.prefix(5), id: \.id) { highlight in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(highlight.color.color)
                                    .frame(width: 8, height: 8)
                                    .padding(.top, 4)

                                Text(highlight.text)
                                    .font(.caption)
                                    .lineLimit(2)
                                    .foregroundStyle(.primary)
                            }
                        }

                        if highlights.count > 5 {
                            Text("+ \(highlights.count - 5) more...")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .frame(maxHeight: 120)
                .padding()
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(maxWidth: 400)

            // Count picker
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

    // MARK: - Suggestions View

    private var suggestionsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, _ in
                    FlashcardSuggestionRow(suggestion: $suggestions[index])
                }
            }
            .padding()
        }
    }

    // MARK: - Footer

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
                Button("Create \(selectedCount) Flashcard\(selectedCount == 1 ? "" : "s")") {
                    createSelectedFlashcards()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedCount == 0)
            }
        }
        .padding()
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text("Flashcards Created!")
                .font(.title2)
                .fontWeight(.semibold)

            Text("\(selectedCount) flashcard\(selectedCount == 1 ? "" : "s") added to your study deck")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 20)
    }

    // MARK: - Actions

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

        // Show success message
        withAnimation {
            showSuccessMessage = true
        }

        // Dismiss after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

// MARK: - Flashcard Suggestion Row

struct FlashcardSuggestionRow: View {
    @Binding var suggestion: FlashcardSuggestion

    @State private var isEditing = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Toggle("", isOn: $suggestion.isSelected)
                .labelsHidden()

            VStack(alignment: .leading, spacing: 8) {
                // Question
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Question")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button {
                            isEditing.toggle()
                        } label: {
                            Image(systemName: "pencil")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }

                    Text(suggestion.question)
                        .font(.callout)
                        .fontWeight(.medium)
                }

                // Answer
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

// MARK: - Single Text Flashcard Generator

struct FlashcardFromTextSheet: View {
    let text: String
    let book: Book

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var aiService = AIService.shared
    @State private var suggestions: [FlashcardSuggestion] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var flashcardCount = 3

    var selectedCount: Int {
        suggestions.filter { $0.isSelected }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "rectangle.on.rectangle")
                    .foregroundStyle(.blue)

                Text("Create Flashcards")
                    .font(.headline)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Generating flashcards...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)

                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("Retry") {
                        generate()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if suggestions.isEmpty {
                VStack(spacing: 16) {
                    Text("Selected Text")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(text)
                        .font(.callout)
                        .lineLimit(4)
                        .padding()
                        .background(Color.secondary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Picker("Cards", selection: $flashcardCount) {
                        Text("1").tag(1)
                        Text("3").tag(3)
                        Text("5").tag(5)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)

                    Button("Generate") {
                        generate()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, _ in
                            FlashcardSuggestionRow(suggestion: $suggestions[index])
                        }
                    }
                    .padding()
                }
            }

            Divider()

            // Footer
            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }

                if !suggestions.isEmpty {
                    Button("Create \(selectedCount)") {
                        createFlashcards()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedCount == 0)
                }
            }
            .padding()
        }
        .frame(width: 450, height: 500)
    }

    private func generate() {
        isLoading = true
        error = nil

        Task {
            do {
                suggestions = try await aiService.generateFlashcards(
                    fromText: text,
                    count: flashcardCount
                )
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }

    private func createFlashcards() {
        for suggestion in suggestions where suggestion.isSelected {
            let flashcard = Flashcard(front: suggestion.question, back: suggestion.answer)
            flashcard.book = book
            modelContext.insert(flashcard)
        }
        dismiss()
    }
}

#Preview {
    FlashcardGeneratorSheet(
        highlights: [],
        book: Book(title: "Sample Book", fileURL: URL(fileURLWithPath: "/"))
    )
}
