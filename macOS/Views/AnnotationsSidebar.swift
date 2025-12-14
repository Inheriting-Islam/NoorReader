// AnnotationsSidebar.swift
// NoorReader
//
// Right sidebar displaying all highlights and notes for the current book

import SwiftUI
import SwiftData

struct AnnotationsSidebar: View {
    let book: Book
    let onNavigateToPage: (Int) -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var filterColor: HighlightColor?
    @State private var sortOrder: AnnotationSortOrder = .dateNewest
    @State private var searchQuery = ""
    @State private var selectedHighlight: Highlight?
    @State private var showNoteEditor = false
    @State private var editingNote: Note?

    enum AnnotationSortOrder: String, CaseIterable {
        case dateNewest = "Newest First"
        case dateOldest = "Oldest First"
        case pageOrder = "Page Order"
        case color = "By Color"
    }

    var filteredHighlights: [Highlight] {
        var highlights = book.highlights

        // Apply color filter
        if let filterColor {
            highlights = highlights.filter { $0.color == filterColor }
        }

        // Apply search filter
        if !searchQuery.isEmpty {
            highlights = highlights.filter {
                $0.text.localizedCaseInsensitiveContains(searchQuery) ||
                ($0.note?.content.localizedCaseInsensitiveContains(searchQuery) ?? false)
            }
        }

        // Apply sort
        switch sortOrder {
        case .dateNewest:
            highlights.sort { $0.dateCreated > $1.dateCreated }
        case .dateOldest:
            highlights.sort { $0.dateCreated < $1.dateCreated }
        case .pageOrder:
            highlights.sort { $0.pageNumber < $1.pageNumber }
        case .color:
            highlights.sort { $0.colorName < $1.colorName }
        }

        return highlights
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Filters
            filters

            Divider()

            // Annotations list
            if filteredHighlights.isEmpty && book.standaloneNotes.isEmpty {
                emptyState
            } else {
                annotationsList
            }
        }
        .frame(minWidth: 280, idealWidth: 300, maxWidth: 350)
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showNoteEditor) {
            if let note = editingNote {
                NoteEditor(
                    note: note,
                    highlight: selectedHighlight,
                    onSave: {
                        showNoteEditor = false
                        editingNote = nil
                        selectedHighlight = nil
                    },
                    onDelete: {
                        deleteNote(note)
                        showNoteEditor = false
                        editingNote = nil
                        selectedHighlight = nil
                    },
                    onCancel: {
                        // Revert changes if new note is empty
                        if editingNote?.content.isEmpty ?? false {
                            if let note = editingNote {
                                deleteNote(note)
                            }
                        }
                        showNoteEditor = false
                        editingNote = nil
                        selectedHighlight = nil
                    }
                )
            }
        }
    }

    private var header: some View {
        HStack {
            Label("Annotations", systemImage: "highlighter")
                .font(.headline)

            Spacer()

            Text("\(filteredHighlights.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding()
    }

    private var filters: some View {
        VStack(spacing: 8) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search annotations...", text: $searchQuery)
                    .textFieldStyle(.plain)

                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.secondary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Sort and filter controls
            HStack {
                // Sort picker
                Picker("Sort", selection: $sortOrder) {
                    ForEach(AnnotationSortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()

                Spacer()

                // Color filter
                Menu {
                    Button("All Colors") {
                        filterColor = nil
                    }

                    Divider()

                    ForEach(HighlightColor.allCases) { color in
                        Button {
                            filterColor = color
                        } label: {
                            HStack {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 12, height: 12)
                                Text(color.displayName)
                                if filterColor == color {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        if let filterColor {
                            Circle()
                                .fill(filterColor.color)
                                .frame(width: 10, height: 10)
                        }
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "highlighter")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            Text(searchQuery.isEmpty ? "No Highlights Yet" : "No Results")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(searchQuery.isEmpty ?
                 "Select text in the PDF and highlight it to see your annotations here." :
                 "Try adjusting your search or filters.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var annotationsList: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                // Highlights section
                ForEach(filteredHighlights) { highlight in
                    AnnotationRow(
                        highlight: highlight,
                        onTap: {
                            onNavigateToPage(highlight.pageNumber)
                        },
                        onDelete: {
                            deleteHighlight(highlight)
                        },
                        onEditNote: {
                            openNoteEditor(for: highlight)
                        }
                    )
                }

                // Standalone notes section (if not searching by color)
                if filterColor == nil && !book.standaloneNotes.isEmpty {
                    if !filteredHighlights.isEmpty {
                        Divider()
                            .padding(.vertical, 8)

                        HStack {
                            Text("Notes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                    }

                    ForEach(book.standaloneNotes.filter { note in
                        searchQuery.isEmpty || note.content.localizedCaseInsensitiveContains(searchQuery)
                    }) { note in
                        StandaloneNoteRow(
                            note: note,
                            onTap: {
                                editingNote = note
                                selectedHighlight = nil
                                showNoteEditor = true
                            },
                            onDelete: {
                                deleteNote(note)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }

    private func deleteHighlight(_ highlight: Highlight) {
        if let note = highlight.note {
            modelContext.delete(note)
        }
        modelContext.delete(highlight)
        try? modelContext.save()
    }

    private func deleteNote(_ note: Note) {
        modelContext.delete(note)
        try? modelContext.save()
    }

    private func openNoteEditor(for highlight: Highlight) {
        selectedHighlight = highlight

        if let existingNote = highlight.note {
            editingNote = existingNote
        } else {
            // Create new note
            let note = Note(pageNumber: highlight.pageNumber, highlight: highlight)
            highlight.note = note
            book.notes.append(note)
            editingNote = note
        }

        showNoteEditor = true
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Book.self, Highlight.self, Bookmark.self, Note.self, configurations: config)

    let book = Book(title: "Sample Book", author: "Author Name", fileURL: URL(fileURLWithPath: "/tmp/sample.pdf"), totalPages: 100)
    container.mainContext.insert(book)

    let highlight1 = Highlight(text: "This is a sample highlight", pageNumber: 5, color: .yellow)
    let highlight2 = Highlight(text: "Another important point to remember", pageNumber: 12, color: .green)
    let highlight3 = Highlight(text: "Critical information here", pageNumber: 20, color: .red)

    book.highlights.append(contentsOf: [highlight1, highlight2, highlight3])

    return AnnotationsSidebar(
        book: book,
        onNavigateToPage: { _ in }
    )
    .modelContainer(container)
}
