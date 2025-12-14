// SemanticSearchBar.swift
// NoorReader
//
// AI-powered semantic search component

import SwiftUI

struct SemanticSearchBar: View {
    @Binding var query: String
    @Binding var results: [SemanticSearchResult]
    @Binding var selectedIndex: Int

    let book: Book
    let onNavigate: (Int) -> Void
    let onClose: () -> Void

    @State private var aiService = AIService.shared
    @State private var isSearching = false
    @State private var searchMode: SearchMode = .keyword
    @State private var error: Error?

    enum SearchMode: String, CaseIterable {
        case keyword
        case semantic

        var displayName: String {
            switch self {
            case .keyword: return "Keyword"
            case .semantic: return "AI Semantic"
            }
        }

        var icon: String {
            switch self {
            case .keyword: return "textformat"
            case .semantic: return "sparkles"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchInputArea
            searchHint
            resultsArea
        }
        .background(.bar)
    }

    // MARK: - Search Input

    private var searchInputArea: some View {
        HStack(spacing: 12) {
            // Mode toggle
            Picker("", selection: $searchMode) {
                ForEach(SearchMode.allCases, id: \.self) { mode in
                    Image(systemName: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 80)
            .help(searchMode == .keyword ? "Keyword Search" : "AI Semantic Search")

            // Search field
            HStack(spacing: 8) {
                Image(systemName: searchMode == .semantic ? "sparkles" : "magnifyingglass")
                    .foregroundStyle(searchMode == .semantic ? .purple : .secondary)

                TextField(
                    searchMode == .semantic
                        ? "Ask about the content..."
                        : "Search...",
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
                        error = nil
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

            // Close button
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Search Hint

    @ViewBuilder
    private var searchHint: some View {
        if searchMode == .semantic && query.isEmpty {
            HStack(spacing: 4) {
                Image(systemName: "lightbulb")
                    .font(.caption)
                Text("Try: \"Where does the author discuss...\" or \"Examples of...\"")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }

        if let error {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.caption)
                Text(error.localizedDescription)
                    .font(.caption)
            }
            .foregroundStyle(.orange)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Results Area

    @ViewBuilder
    private var resultsArea: some View {
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

    // MARK: - Actions

    private func performSearch() {
        guard !query.isEmpty else { return }
        error = nil

        if searchMode == .semantic {
            performSemanticSearch()
        }
        // Keyword search is handled by the parent view
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
                selectedIndex = 0
            } catch {
                self.error = error
                results = []
            }
            isSearching = false
        }
    }
}

// MARK: - Search Result Row

struct SemanticSearchResultRow: View {
    let result: SemanticSearchResult
    let isSelected: Bool
    let showRelevance: Bool
    let onTap: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Page number
                Text("\(result.pageNumber + 1)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(width: 30)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.text)
                        .font(.callout)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)

                    if showRelevance {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.caption2)

                            Text("\(result.relevancePercentage)% relevant")
                                .font(.caption2)

                            // Relevance bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.purple.opacity(0.2))

                                    Rectangle()
                                        .fill(Color.purple)
                                        .frame(width: geo.size.width * result.relevanceScore)
                                }
                            }
                            .frame(width: 60, height: 4)
                            .clipShape(Capsule())
                        }
                        .foregroundStyle(.purple)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Navigation indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                isSelected ? Color.accentColor.opacity(0.1) :
                isHovering ? Color.secondary.opacity(0.05) :
                Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Standalone Semantic Search View

struct SemanticSearchView: View {
    let book: Book
    let onNavigate: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [SemanticSearchResult] = []
    @State private var selectedIndex = 0
    @State private var isSearching = false
    @State private var error: Error?
    @State private var aiService = AIService.shared
    @State private var hasIndex = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "sparkle.magnifyingglass")
                    .foregroundStyle(.purple)

                Text("Semantic Search")
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

            if !hasIndex {
                indexBuildingView
            } else {
                searchContent
            }
        }
        .frame(width: 500, height: 500)
        .background(.background)
        .task {
            hasIndex = await aiService.hasSemanticIndex(for: book)
        }
    }

    private var indexBuildingView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(.purple.opacity(0.5))

            Text("Building Search Index")
                .font(.headline)

            Text("Semantic search requires building an index of your document. This may take a moment.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            ProgressView()

            Text("Processing pages...")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var searchContent: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)

                TextField("Ask about the content...", text: $query)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        search()
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
            .padding()
            .background(Color.secondary.opacity(0.05))

            // Suggestions
            if query.isEmpty && results.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Try asking:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(["Where does the author discuss...", "What are the main arguments about...", "Examples of..."], id: \.self) { suggestion in
                        Button {
                            query = suggestion
                        } label: {
                            HStack {
                                Image(systemName: "text.bubble")
                                    .foregroundStyle(.purple)
                                Text(suggestion)
                                    .foregroundStyle(.primary)
                            }
                            .font(.callout)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            // Error
            if let error {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }

            // Results
            if !results.isEmpty {
                List(results) { result in
                    Button {
                        onNavigate(result.pageNumber)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Page \(result.pageNumber + 1)")
                                    .font(.caption)
                                    .fontWeight(.medium)

                                Spacer()

                                Text("\(result.relevancePercentage)%")
                                    .font(.caption)
                                    .foregroundStyle(.purple)
                            }

                            Text(result.text)
                                .font(.callout)
                                .lineLimit(3)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func search() {
        guard !query.isEmpty else { return }

        isSearching = true
        error = nil

        Task {
            do {
                results = try await aiService.semanticSearch(query: query, in: book, limit: 10)
            } catch {
                self.error = error
            }
            isSearching = false
        }
    }
}

#Preview {
    SemanticSearchBar(
        query: .constant(""),
        results: .constant([]),
        selectedIndex: .constant(0),
        book: Book(title: "Sample", fileURL: URL(fileURLWithPath: "/")),
        onNavigate: { _ in },
        onClose: {}
    )
}
