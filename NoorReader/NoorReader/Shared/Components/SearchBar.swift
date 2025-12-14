// SearchBar.swift
// NoorReader
//
// In-document search bar with navigation controls

import SwiftUI

struct SearchBar: View {
    @Binding var query: String
    @Binding var currentIndex: Int
    let totalResults: Int
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onClose: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Find in document...", text: $query)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onSubmit {
                        onNext()
                    }

                if !query.isEmpty {
                    Button {
                        query = ""
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
            .frame(width: 250)

            // Results indicator
            if !query.isEmpty {
                if totalResults > 0 {
                    Text("\(currentIndex + 1) of \(totalResults)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 70)
                } else {
                    Text("No results")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 70)
                }
            }

            // Navigation buttons
            HStack(spacing: 4) {
                Button {
                    onPrevious()
                } label: {
                    Image(systemName: "chevron.up")
                }
                .buttonStyle(.borderless)
                .disabled(totalResults == 0)
                .keyboardShortcut("g", modifiers: [.command, .shift])
                .help("Previous Match (⌘⇧G)")

                Button {
                    onNext()
                } label: {
                    Image(systemName: "chevron.down")
                }
                .buttonStyle(.borderless)
                .disabled(totalResults == 0)
                .keyboardShortcut("g", modifiers: .command)
                .help("Next Match (⌘G)")
            }

            Divider()
                .frame(height: 20)

            // Close button
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut(.escape, modifiers: [])
            .help("Close (Esc)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
        .onAppear {
            isFocused = true
        }
    }
}

// MARK: - Compact Search Bar (for toolbar)

struct CompactSearchBar: View {
    @Binding var query: String
    let isSearching: Bool
    let onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search...", text: $query)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit {
                    onSubmit()
                }

            if isSearching {
                ProgressView()
                    .scaleEffect(0.7)
            } else if !query.isEmpty {
                Button {
                    query = ""
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
        .frame(width: 200)
    }
}

#Preview {
    VStack(spacing: 20) {
        SearchBar(
            query: .constant("search term"),
            currentIndex: .constant(2),
            totalResults: 15,
            onNext: {},
            onPrevious: {},
            onClose: {}
        )

        SearchBar(
            query: .constant(""),
            currentIndex: .constant(0),
            totalResults: 0,
            onNext: {},
            onPrevious: {},
            onClose: {}
        )

        CompactSearchBar(
            query: .constant("test"),
            isSearching: false,
            onSubmit: {}
        )
    }
    .padding()
}
