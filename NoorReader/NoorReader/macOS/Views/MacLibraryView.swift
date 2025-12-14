// MacLibraryView.swift
// NoorReader
//
// Library grid view with import and organization

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct MacLibraryView: View {
    let collection: LibraryCollection
    @Binding var selectedBook: Book?

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.dateAdded, order: .reverse) private var allBooks: [Book]

    @State private var viewModel: LibraryViewModel?
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .dateAdded
    @State private var isImporting = false
    @State private var importError: LibraryError?
    @State private var showingError = false

    private var filteredBooks: [Book] {
        viewModel?.filterBooks(allBooks, for: collection) ?? allBooks
    }

    var body: some View {
        Group {
            if filteredBooks.isEmpty {
                emptyState
            } else {
                bookGrid
            }
        }
        .searchable(text: $searchText, prompt: "Search library...")
        .onChange(of: searchText) { _, newValue in
            viewModel?.searchText = newValue
        }
        .toolbar {
            ToolbarItemGroup {
                // Prayer time indicator
                if UserDefaults.standard.object(forKey: "showPrayerTimes") as? Bool ?? true {
                    PrayerTimeIndicator()
                }

                Divider()

                sortMenu

                Button(action: { isImporting = true }) {
                    Image(systemName: "plus")
                }
                .help("Import PDF")
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [UTType.pdf],
            allowsMultipleSelection: true
        ) { result in
            viewModel?.handleImport(result)
        }
        .alert("Import Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importError?.localizedDescription ?? "Unknown error")
        }
        .onDrop(of: [UTType.pdf], isTargeted: nil) { providers in
            viewModel?.handleDrop(providers)
            return true
        }
        .onAppear {
            if viewModel == nil {
                viewModel = LibraryViewModel(modelContext: modelContext)
            }
        }
        .onChange(of: viewModel?.showingError ?? false) { _, newValue in
            showingError = newValue
        }
        .onChange(of: viewModel?.importError) { _, newValue in
            importError = newValue
        }
        .navigationTitle(collection.displayName)
    }

    // MARK: - Views

    private var bookGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 160, maximum: 200))],
                spacing: 24
            ) {
                ForEach(filteredBooks) { book in
                    BookCard(book: book) {
                        selectedBook = book
                    }
                }
            }
            .padding(24)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Books Yet")
                .font(.title2)
                .fontWeight(.medium)

            Text("Drag and drop PDF files here, or click + to import.")
                .foregroundStyle(.secondary)

            Button("Import PDF") {
                isImporting = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.noorTeal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort By", selection: $sortOrder) {
                ForEach(SortOrder.allCases) { order in
                    Text(order.displayName).tag(order)
                }
            }
            .onChange(of: sortOrder) { _, newValue in
                viewModel?.sortOrder = newValue
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .help("Sort Order")
    }
}

#Preview {
    MacLibraryView(
        collection: .all,
        selectedBook: .constant(nil)
    )
    .modelContainer(for: Book.self, inMemory: true)
}
