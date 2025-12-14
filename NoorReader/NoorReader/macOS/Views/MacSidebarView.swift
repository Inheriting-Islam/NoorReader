// MacSidebarView.swift
// NoorReader
//
// Left sidebar with library navigation and TOC

import SwiftUI
import SwiftData

struct MacSidebarView: View {
    @Binding var selectedCollection: LibraryCollection
    @Binding var selectedBook: Book?
    @Query private var collections: [Collection]

    var body: some View {
        List(selection: $selectedCollection) {
            // Library Section
            Section("Library") {
                Label("All Books", systemImage: "books.vertical")
                    .tag(LibraryCollection.all)

                Label("Reading Now", systemImage: "book")
                    .tag(LibraryCollection.readingNow)

                Label("Favorites", systemImage: "star")
                    .tag(LibraryCollection.favorites)

                Label("Recently Added", systemImage: "clock")
                    .tag(LibraryCollection.recentlyAdded)
            }

            // Custom Collections
            if !collections.isEmpty {
                Section("Collections") {
                    ForEach(collections) { collection in
                        Label(collection.name, systemImage: collection.icon)
                            .tag(LibraryCollection.custom(collection))
                    }
                }
            }

            // Table of Contents (when book is open)
            if let book = selectedBook {
                Section("Contents") {
                    TableOfContentsView(book: book)
                }

                Section("Bookmarks") {
                    if book.bookmarks.isEmpty {
                        Text("No bookmarks yet")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    } else {
                        ForEach(book.bookmarks.sorted(by: { $0.pageNumber < $1.pageNumber })) { bookmark in
                            Button(action: {
                                NotificationCenter.default.post(
                                    name: .goToPage,
                                    object: bookmark.pageNumber
                                )
                            }) {
                                Label(bookmark.title, systemImage: "bookmark")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        // Background handled by SidebarPanel container
        .toolbar {
            ToolbarItem {
                Button(action: { /* Add collection */ }) {
                    Image(systemName: "folder.badge.plus")
                }
                .help("New Collection")
            }
        }
    }
}

// MARK: - Table of Contents View

struct TableOfContentsView: View {
    let book: Book
    @State private var tocItems: [TOCItem] = []
    @State private var isLoaded = false

    var body: some View {
        Group {
            if tocItems.isEmpty {
                if isLoaded {
                    Text("No table of contents")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            } else {
                ForEach(tocItems) { item in
                    TOCItemRow(item: item)
                }
            }
        }
        .task {
            await loadTOC()
        }
    }

    private func loadTOC() async {
        guard let document = PDFService.openDocument(at: book.fileURL) else {
            isLoaded = true
            return
        }

        tocItems = PDFService.extractTableOfContents(from: document)
        isLoaded = true
    }
}

struct TOCItemRow: View {
    let item: TOCItem

    var body: some View {
        DisclosureGroup {
            ForEach(item.children) { child in
                TOCItemRow(item: child)
            }
        } label: {
            Button(action: {
                NotificationCenter.default.post(
                    name: .goToPage,
                    object: item.pageNumber
                )
            }) {
                HStack {
                    Text(item.title)
                        .lineLimit(2)
                    Spacer()
                    Text("\(item.pageNumber + 1)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, CGFloat(item.level) * 12)
    }
}

// MARK: - Visual Effect View

/// NSVisualEffectView wrapper for full-bleed sidebar background
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .followsWindowActiveState
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

#Preview {
    MacSidebarView(
        selectedCollection: .constant(.all),
        selectedBook: .constant(nil)
    )
    .modelContainer(for: Collection.self, inMemory: true)
}
