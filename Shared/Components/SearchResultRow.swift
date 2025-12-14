// SearchResultRow.swift
// NoorReader
//
// Individual search result row with context highlighting

import SwiftUI

struct SearchResultRow: View {
    let result: SearchService.SearchResult
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Page number
                Text("\(result.pageNumber + 1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 30, alignment: .trailing)

                // Context with highlighted match
                Text(attributedContext)
                    .font(.callout)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    private var attributedContext: AttributedString {
        var result = AttributedString(self.result.contextBefore)
        result.foregroundColor = .secondary

        var match = AttributedString(self.result.matchText)
        match.backgroundColor = .yellow.opacity(0.3)
        match.font = .callout.bold()
        match.foregroundColor = .primary

        var after = AttributedString(self.result.contextAfter)
        after.foregroundColor = .secondary

        result.append(match)
        result.append(after)

        return result
    }
}

// MARK: - Search Results List

struct SearchResultsList: View {
    let results: [SearchService.SearchResult]
    let selectedIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                    SearchResultRow(
                        result: result,
                        isSelected: index == selectedIndex,
                        onTap: {
                            onSelect(index)
                        }
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Search Sheet

struct SearchSheet: View {
    @Binding var isPresented: Bool
    @Binding var searchQuery: String
    let results: [SearchService.SearchResult]
    @Binding var currentIndex: Int
    let isSearching: Bool
    let onSearch: () -> Void
    let onNavigateToResult: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Find in Document")
                    .font(.headline)

                Spacer()

                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // Search field
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            onSearch()
                        }

                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Button("Search") {
                    onSearch()
                }
                .buttonStyle(.borderedProminent)
                .disabled(searchQuery.isEmpty)
            }
            .padding()

            Divider()

            // Results
            if results.isEmpty {
                if !searchQuery.isEmpty && !isSearching {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 32))
                            .foregroundStyle(.tertiary)

                        Text("No results found")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 32))
                            .foregroundStyle(.tertiary)

                        Text("Enter a search term")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                VStack(spacing: 0) {
                    // Results count
                    HStack {
                        Text("\(results.count) results")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        // Navigation
                        HStack(spacing: 4) {
                            Button {
                                if currentIndex > 0 {
                                    currentIndex -= 1
                                    onNavigateToResult(currentIndex)
                                }
                            } label: {
                                Image(systemName: "chevron.up")
                            }
                            .buttonStyle(.borderless)
                            .disabled(currentIndex == 0)

                            Text("\(currentIndex + 1) / \(results.count)")
                                .font(.caption)
                                .frame(width: 60)

                            Button {
                                if currentIndex < results.count - 1 {
                                    currentIndex += 1
                                    onNavigateToResult(currentIndex)
                                }
                            } label: {
                                Image(systemName: "chevron.down")
                            }
                            .buttonStyle(.borderless)
                            .disabled(currentIndex >= results.count - 1)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    Divider()

                    // Results list
                    SearchResultsList(
                        results: results,
                        selectedIndex: currentIndex,
                        onSelect: { index in
                            currentIndex = index
                            onNavigateToResult(index)
                        }
                    )
                }
            }
        }
        .frame(width: 450, height: 400)
    }
}

#Preview {
    SearchSheet(
        isPresented: .constant(true),
        searchQuery: .constant("test"),
        results: [],
        currentIndex: .constant(0),
        isSearching: false,
        onSearch: {},
        onNavigateToResult: { _ in }
    )
}
