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
    @Query(sort: \BookCategory.sortOrder) private var categories: [BookCategory]

    @State private var showFlashcardReview = false
    @State private var showStudyDashboard = false
    @State private var showQuickReview = false
    @State private var showLibraryImport = false
    @State private var expandedCategories: Set<UUID> = []

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

            // Categories Section (Islamic Book Categories)
            if !categories.isEmpty {
                Section("Categories") {
                    ForEach(categoriesWithBooks) { category in
                        CategoryRow(
                            category: category,
                            isExpanded: expandedCategories.contains(category.id),
                            selectedCollection: $selectedCollection
                        ) {
                            toggleCategory(category)
                        }
                    }
                }
            }

            // Study Section
            Section("Study") {
                Button {
                    showStudyDashboard = true
                } label: {
                    Label("Dashboard", systemImage: "chart.bar")
                }
                .buttonStyle(.plain)

                Button {
                    showFlashcardReview = true
                } label: {
                    HStack {
                        Label("Flashcards", systemImage: "rectangle.on.rectangle")
                        Spacer()
                        if let book = selectedBook, book.dueFlashcardCount > 0 {
                            Text("\(book.dueFlashcardCount)")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
                .buttonStyle(.plain)

                if selectedBook != nil {
                    Button {
                        showQuickReview = true
                    } label: {
                        Label("Quick Review", systemImage: "highlighter")
                    }
                    .buttonStyle(.plain)
                }
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

                // Flashcards for current book
                if !book.flashcards.isEmpty {
                    Section("Flashcards") {
                        HStack {
                            Text("\(book.flashcardCount) cards")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            if book.dueFlashcardCount > 0 {
                                Text("\(book.dueFlashcardCount) due")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }

                        Button {
                            showFlashcardReview = true
                        } label: {
                            Label("Study Now", systemImage: "play.circle")
                        }
                        .buttonStyle(.plain)
                        .disabled(book.dueFlashcardCount == 0)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        // Background handled by SidebarPanel container
        .toolbar {
            ToolbarItem {
                Menu {
                    Button(action: { /* Add collection */ }) {
                        Label("New Collection", systemImage: "folder.badge.plus")
                    }
                    Button(action: { showLibraryImport = true }) {
                        Label("Import Library Folder...", systemImage: "folder.badge.gearshape")
                    }
                    Divider()
                    Button {
                        Task {
                            try? await LibraryScannerService.shared.refreshAllBooks()
                        }
                    } label: {
                        Label("Refresh Library (Clean Titles & Re-categorize)", systemImage: "arrow.triangle.2.circlepath")
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add")
            }
        }
        .sheet(isPresented: $showLibraryImport) {
            LibraryImportView()
        }
        .sheet(isPresented: $showFlashcardReview) {
            FlashcardReviewSheet(book: selectedBook)
        }
        .sheet(isPresented: $showStudyDashboard) {
            NavigationStack {
                StudyDashboardView(viewModel: StatsViewModel())
            }
            .frame(minWidth: 700, minHeight: 600)
        }
        .sheet(isPresented: $showQuickReview) {
            if let book = selectedBook {
                QuickReviewView(book: book)
            }
        }
    }

    // MARK: - Computed Properties

    /// Categories that have at least one book
    private var categoriesWithBooks: [BookCategory] {
        categories.filter { !$0.books.isEmpty }
    }

    // MARK: - Actions

    private func toggleCategory(_ category: BookCategory) {
        if expandedCategories.contains(category.id) {
            expandedCategories.remove(category.id)
        } else {
            expandedCategories.insert(category.id)
        }
    }
}

// MARK: - Category Row View

struct CategoryRow: View {
    let category: BookCategory
    let isExpanded: Bool
    @Binding var selectedCollection: LibraryCollection
    let onToggle: () -> Void

    var body: some View {
        DisclosureGroup(isExpanded: Binding(
            get: { isExpanded },
            set: { _ in onToggle() }
        )) {
            ForEach(category.books.sorted(by: { $0.title < $1.title })) { book in
                BookRow(book: book)
            }
        } label: {
            HStack {
                Label(category.name, systemImage: category.icon)
                    .foregroundStyle(category.color)
                Spacer()
                Text("\(category.books.count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .clipShape(Capsule())
            }
            .tag(LibraryCollection.category(category))
        }
    }
}

// MARK: - Book Row View (for category expansion)

struct BookRow: View {
    let book: Book

    var body: some View {
        HStack(spacing: 8) {
            // Cover thumbnail
            if let imageData = book.coverImageData,
               let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 24, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            } else {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 24, height: 32)
                    .overlay {
                        Image(systemName: "book.closed")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.caption)
                    .lineLimit(1)

                if !book.author.isEmpty {
                    Text(book.author)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Progress indicator
            if book.progress > 0 && book.progress < 1 {
                Text("\(book.progressPercentage)%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if book.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Library Import View

struct LibraryImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = LibraryCatalogViewModel()

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Import Library")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Select a folder containing your Islamic books")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding()

            Divider()

            if viewModel.isScanning {
                // Progress view
                VStack(spacing: 16) {
                    ProgressView(value: viewModel.scanProgress?.percentage ?? 0)
                        .progressViewStyle(.linear)

                    if let progress = viewModel.scanProgress {
                        Text("Scanning: \(progress.currentFile)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text("\(progress.current) of \(progress.total) files")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding()
            } else if let result = viewModel.scanResult {
                // Results view
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)

                    Text("Import Complete")
                        .font(.headline)

                    VStack(spacing: 8) {
                        StatRow(label: "Books found", value: "\(result.totalFound)")
                        StatRow(label: "Imported", value: "\(result.imported)")
                        if result.skipped > 0 {
                            StatRow(label: "Already in library", value: "\(result.skipped)")
                        }
                        if result.failed > 0 {
                            StatRow(label: "Failed", value: "\(result.failed)")
                                .foregroundStyle(.red)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    Spacer()

                    Button("Import Another Folder") {
                        viewModel.scanResult = nil
                        Task {
                            await viewModel.selectAndScanFolder()
                        }
                    }
                }
                .padding()
            } else {
                // Initial state
                VStack(spacing: 24) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)

                    VStack(spacing: 8) {
                        Text("Select Your Library Folder")
                            .font(.headline)
                        Text("NoorReader will scan for PDF files and automatically categorize them into Islamic topics.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    if viewModel.hasLibraryFolder {
                        VStack(spacing: 4) {
                            Text("Current library:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(viewModel.libraryFolderName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        if viewModel.hasLibraryFolder {
                            Button("Rescan Library") {
                                Task {
                                    await viewModel.rescanLibrary()
                                }
                            }
                            .buttonStyle(.bordered)
                        }

                        Button("Select Folder...") {
                            Task {
                                await viewModel.selectAndScanFolder()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }

            if let error = viewModel.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
            }
        }
        .frame(width: 400, height: 400)
        .onAppear {
            viewModel.configure(modelContext: modelContext)
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.caption)
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
