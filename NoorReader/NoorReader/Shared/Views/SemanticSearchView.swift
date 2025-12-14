// SemanticSearchView.swift
// NoorReader
//
// Full semantic search interface with filters and results display

import SwiftUI
import SwiftData
import PDFKit

struct SemanticSearchView: View {
    @Bindable var viewModel: SemanticSearchViewModel
    let onNavigateToResult: (UUID, Int) -> Void
    let onDismiss: () -> Void

    @State private var expandedBooks: Set<UUID> = []
    @State private var showFilters = false
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            searchHeader

            Divider()

            // Search bar and options
            searchBar

            // Filters (collapsible)
            if showFilters {
                filterSection
            }

            Divider()

            // Results area
            resultsArea
        }
        .frame(minWidth: 500, minHeight: 400)
        .background(Color(.windowBackgroundColor))
        .onAppear {
            isSearchFieldFocused = true
        }
    }

    // MARK: - Header

    private var searchHeader: some View {
        HStack {
            Image(systemName: "sparkle.magnifyingglass")
                .font(.title2)
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("Semantic Search")
                    .font(.headline)

                Text("Find conceptually related content across your library")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Index status
            if let status = viewModel.indexStatus {
                IndexStatusBadge(status: status.status)
            }

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Search field
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search for concepts, ideas, or topics...", text: $viewModel.query)
                        .textFieldStyle(.plain)
                        .focused($isSearchFieldFocused)
                        .onSubmit {
                            Task {
                                await viewModel.search()
                            }
                        }

                    if viewModel.isSearching {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else if !viewModel.query.isEmpty {
                        Button {
                            viewModel.clearSearch()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Search button
                Button {
                    Task {
                        await viewModel.search()
                    }
                } label: {
                    Text("Search")
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canSearch)

                // Filter toggle
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showFilters.toggle()
                    }
                } label: {
                    Image(systemName: showFilters ? "slider.horizontal.3" : "slider.horizontal.3")
                        .foregroundStyle(showFilters ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.borderless)
                .help("Search options")
            }
            .padding(.horizontal)
            .padding(.top, 12)

            // Scope selector
            HStack {
                Text("Search in:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("", selection: $viewModel.searchScope) {
                    ForEach(SemanticSearchScope.allCases) { scope in
                        Label(scope.displayName, systemImage: scope.icon)
                            .tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 400)

                Spacer()

                // Search mode indicator
                Text(viewModel.searchModeDescription)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Filters

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            HStack(spacing: 24) {
                // Search mode toggles
                VStack(alignment: .leading, spacing: 8) {
                    Text("Search Mode")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        Toggle(isOn: $viewModel.includeSemanticSearch) {
                            Label("Semantic", systemImage: "brain.head.profile")
                        }
                        .toggleStyle(.checkbox)

                        Toggle(isOn: $viewModel.includeKeywordSearch) {
                            Label("Keyword", systemImage: "text.magnifyingglass")
                        }
                        .toggleStyle(.checkbox)
                    }
                }

                Divider()
                    .frame(height: 40)

                // Relevance threshold
                VStack(alignment: .leading, spacing: 8) {
                    Text("Minimum Relevance")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    HStack {
                        Slider(value: $viewModel.minimumRelevance, in: 0.1...0.8, step: 0.1)
                            .frame(width: 150)

                        Text("\(Int(viewModel.minimumRelevance * 100))%")
                            .font(.caption)
                            .frame(width: 35)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Results Area

    @ViewBuilder
    private var resultsArea: some View {
        if viewModel.isIndexing, let progress = viewModel.indexingProgress {
            // Indexing in progress
            VStack {
                Spacer()
                IndexingProgressView(progress: progress)
                    .frame(maxWidth: 400)
                Spacer()
            }
        } else if viewModel.hasResults {
            // Show results
            VStack(spacing: 0) {
                // Stats banner
                SearchStatsBanner(stats: viewModel.resultStats)
                    .padding()

                Divider()

                // Results list
                resultsListView
            }
        } else if viewModel.isSearching {
            // Searching
            VStack {
                Spacer()
                ProgressView("Searching...")
                    .progressViewStyle(.circular)
                Spacer()
            }
        } else {
            // No results or initial state
            VStack {
                Spacer()

                NoSearchResultsView(
                    hasSearched: viewModel.hasSearched,
                    query: viewModel.query
                )

                // Recent searches
                if !viewModel.recentSearches.isEmpty && !viewModel.hasSearched {
                    recentSearchesView
                }

                Spacer()
            }
        }
    }

    // MARK: - Results List

    private var resultsListView: some View {
        ScrollView {
            LazyVStack(spacing: 8, pinnedViews: [.sectionHeaders]) {
                let groupedResults = viewModel.groupResultsByBook()

                ForEach(groupedResults, id: \.bookID) { group in
                    Section {
                        if expandedBooks.contains(group.bookID) || groupedResults.count == 1 {
                            ForEach(group.results) { result in
                                SearchResultCard(result: result) {
                                    let navigation = viewModel.navigateToResult(result)
                                    onNavigateToResult(navigation.bookID, navigation.pageNumber)
                                }
                            }
                        }
                    } header: {
                        if groupedResults.count > 1 {
                            SearchResultGroupHeader(
                                bookTitle: group.bookTitle,
                                resultCount: group.results.count,
                                isExpanded: expandedBooks.contains(group.bookID)
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if expandedBooks.contains(group.bookID) {
                                        expandedBooks.remove(group.bookID)
                                    } else {
                                        expandedBooks.insert(group.bookID)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .background(Color(.windowBackgroundColor).opacity(0.95))
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Recent Searches

    private var recentSearchesView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent Searches")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Clear") {
                    viewModel.clearRecentSearches()
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            FlowLayout(spacing: 8) {
                ForEach(viewModel.recentSearches, id: \.self) { search in
                    Button {
                        viewModel.useRecentSearch(search)
                    } label: {
                        Text(search)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: 400)
        .padding()
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, spacing: spacing, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, spacing: spacing, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = SemanticSearchViewModel()

    return SemanticSearchView(
        viewModel: viewModel,
        onNavigateToResult: { _, _ in },
        onDismiss: {}
    )
    .frame(width: 600, height: 500)
}
