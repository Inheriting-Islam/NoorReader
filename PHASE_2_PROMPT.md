# Phase 2: Annotations - Development Prompt

بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ

**In the name of Allah, the Most Gracious, the Most Merciful.**

---

> "Take advantage of five before five: your youth before your old age, your health before your illness, your wealth before your poverty, your free time before your busyness, and your life before your death."
> — Prophet Muhammad ﷺ (Narrated by Ibn Abbas, Sahih)

Phase 2 builds the annotation system that helps users capture and preserve their insights. Every highlight, every note is a seed of knowledge that can grow into lasting understanding, insha'Allah.

---

## Table of Contents

1. [Phase 2 Overview](#phase-2-overview)
2. [Prerequisites](#prerequisites)
3. [Architecture Overview](#architecture-overview)
4. [Implementation Tasks](#implementation-tasks)
   - [Task 1: Enhanced Highlight System](#task-1-enhanced-highlight-system)
   - [Task 2: Notes System](#task-2-notes-system)
   - [Task 3: Annotations Sidebar](#task-3-annotations-sidebar)
   - [Task 4: In-Document Search](#task-4-in-document-search)
   - [Task 5: Markdown Export](#task-5-markdown-export)
   - [Task 6: Enhanced Islamic Reminders](#task-6-enhanced-islamic-reminders)
5. [Data Models](#data-models)
6. [Quality Standards](#quality-standards)
7. [Testing Requirements](#testing-requirements)
8. [Phase 2 Completion Criteria](#phase-2-completion-criteria)

---

## Phase 2 Overview

**Objective:** Build a comprehensive annotation system that allows users to highlight text with semantic colors, attach notes, search within documents, and export their annotations in Markdown format.

**Building Upon:** Phase 1 foundation (PDF viewing, library, themes, basic highlights, Islamic reminders)

**Deliverable:** Enhanced NoorReader with:
- Full 8-color highlight system with visual rendering on PDF
- Rich notes attached to highlights or standalone
- Annotations sidebar showing all highlights and notes
- In-document search with match navigation
- Markdown export with page references
- Daily Islamic reminder improvements

---

## Prerequisites

Before starting Phase 2, ensure Phase 1 is complete:

- [ ] PDF import and library management working
- [ ] PDF viewing with smooth rendering
- [ ] Basic highlight creation functional
- [ ] Themes (Day/Sepia/Night/Auto) working
- [ ] Bookmarks functional
- [ ] Launch dua displaying
- [ ] Prayer time indicator showing
- [ ] All Phase 1 tests passing
- [ ] Zero compiler warnings

---

## Architecture Overview

### New Files to Create

```
NoorReader/
├── Shared/
│   ├── Models/
│   │   └── Note.swift                    # NEW: Note model
│   │
│   ├── Services/
│   │   ├── AnnotationService.swift       # NEW: Annotation management
│   │   ├── SearchService.swift           # NEW: In-document search
│   │   └── ExportService.swift           # NEW: Markdown export
│   │
│   ├── ViewModels/
│   │   └── AnnotationViewModel.swift     # NEW: Annotation state
│   │
│   └── Components/
│       ├── HighlightOverlay.swift        # NEW: PDF highlight rendering
│       ├── NoteEditor.swift              # NEW: Rich note editor
│       ├── AnnotationRow.swift           # NEW: Sidebar list item
│       ├── SearchBar.swift               # NEW: Search input
│       └── SearchResultRow.swift         # NEW: Search result item
│
└── macOS/
    └── Views/
        ├── AnnotationsSidebar.swift      # NEW: Right sidebar
        └── SearchSheet.swift             # NEW: Search modal
```

### Files to Modify

```
Shared/
├── Models/
│   ├── Highlight.swift                   # MODIFY: Add note relationship
│   └── Book.swift                        # MODIFY: Add notes relationship
│
├── Services/
│   └── ReminderService.swift             # MODIFY: Enhanced reminders
│
├── ViewModels/
│   └── ReaderViewModel.swift             # MODIFY: Search & annotation state
│
└── Components/
    ├── PDFViewRepresentable.swift        # MODIFY: Highlight overlay
    └── SelectionPopover.swift            # MODIFY: Enhanced actions

macOS/
├── MacContentView.swift                  # MODIFY: Add right sidebar
├── MacReaderView.swift                   # MODIFY: Search integration
└── MacMenuCommands.swift                 # MODIFY: New menu items
```

---

## Implementation Tasks

### Task 1: Enhanced Highlight System

**Objective:** Upgrade the highlight system to render highlights visually on the PDF and support all 8 semantic colors.

#### 1.1 Update Highlight Model

```swift
// Shared/Models/Highlight.swift
// MODIFY existing file

import SwiftData
import SwiftUI
import Foundation

@Model
final class Highlight {
    var id: UUID
    var text: String
    var pageNumber: Int
    var colorName: String
    var dateCreated: Date

    // Selection bounds for rendering (multiple rects for multi-line selections)
    var boundsData: Data?

    // NEW: Relationship to note
    @Relationship(deleteRule: .cascade)
    var note: Note?

    var book: Book?

    var color: HighlightColor {
        get { HighlightColor(rawValue: colorName) ?? .yellow }
        set { colorName = newValue.rawValue }
    }

    // Store multiple bounds for multi-line highlights
    var selectionBounds: [CGRect] {
        get {
            guard let data = boundsData else { return [] }
            return (try? JSONDecoder().decode([CodableRect].self, from: data))?.map(\.rect) ?? []
        }
        set {
            boundsData = try? JSONEncoder().encode(newValue.map { CodableRect(rect: $0) })
        }
    }

    // Single bounds for backward compatibility
    var bounds: CGRect? {
        get { selectionBounds.first }
        set {
            if let rect = newValue {
                selectionBounds = [rect]
            } else {
                selectionBounds = []
            }
        }
    }

    var hasNote: Bool {
        note != nil && !(note?.content.isEmpty ?? true)
    }

    init(
        text: String,
        pageNumber: Int,
        bounds: [CGRect] = [],
        color: HighlightColor = .yellow
    ) {
        self.id = UUID()
        self.text = text
        self.pageNumber = pageNumber
        self.colorName = color.rawValue
        self.dateCreated = Date()
        self.selectionBounds = bounds
    }
}
```

#### 1.2 Create Highlight Overlay Component

```swift
// Shared/Components/HighlightOverlay.swift
// NEW FILE

import SwiftUI
import PDFKit

/// Renders highlight rectangles over PDF content
struct HighlightOverlay: View {
    let highlights: [Highlight]
    let pageIndex: Int
    let pageRect: CGRect
    let scale: CGFloat
    let onTap: (Highlight) -> Void

    var pageHighlights: [Highlight] {
        highlights.filter { $0.pageNumber == pageIndex }
    }

    var body: some View {
        GeometryReader { geometry in
            ForEach(pageHighlights) { highlight in
                ForEach(Array(highlight.selectionBounds.enumerated()), id: \.offset) { _, rect in
                    HighlightRect(
                        rect: convertRect(rect, in: geometry.size),
                        color: highlight.color.color,
                        hasNote: highlight.hasNote
                    )
                    .onTapGesture {
                        onTap(highlight)
                    }
                }
            }
        }
    }

    private func convertRect(_ rect: CGRect, in size: CGSize) -> CGRect {
        // Convert PDF coordinates to view coordinates
        let scaleX = size.width / pageRect.width
        let scaleY = size.height / pageRect.height

        return CGRect(
            x: rect.origin.x * scaleX,
            y: size.height - (rect.origin.y + rect.height) * scaleY, // Flip Y axis
            width: rect.width * scaleX,
            height: rect.height * scaleY
        )
    }
}

struct HighlightRect: View {
    let rect: CGRect
    let color: Color
    let hasNote: Bool

    @State private var isHovering = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Rectangle()
                .fill(color.opacity(isHovering ? 0.5 : 0.35))
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)

            // Note indicator
            if hasNote {
                Image(systemName: "note.text")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .offset(x: rect.maxX - 8, y: rect.minY + 4)
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .help(hasNote ? "Click to view note" : "Click to edit highlight")
    }
}
```

#### 1.3 Enhanced Selection Popover

```swift
// Shared/Components/SelectionPopover.swift
// MODIFY existing file - replace content

import SwiftUI

struct SelectionPopover: View {
    let selectedText: String
    let onHighlight: (HighlightColor) -> Void
    let onAddNote: () -> Void
    let onCopy: () -> Void
    let onDismiss: () -> Void

    @State private var showAllColors = false

    // Primary colors (most used)
    private let primaryColors: [HighlightColor] = [.yellow, .green, .blue, .pink]

    var body: some View {
        VStack(spacing: 0) {
            // Selected text preview
            if !selectedText.isEmpty {
                Text(selectedText)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }

            Divider()

            // Action buttons
            HStack(spacing: 16) {
                ActionButton(icon: "highlighter", label: "Highlight", shortcut: "H") {
                    onHighlight(.yellow)
                }

                ActionButton(icon: "note.text", label: "Note", shortcut: "N") {
                    onAddNote()
                }

                ActionButton(icon: "doc.on.doc", label: "Copy", shortcut: "C") {
                    onCopy()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Color palette
            VStack(spacing: 8) {
                // Primary colors row
                HStack(spacing: 8) {
                    ForEach(primaryColors) { color in
                        ColorButton(color: color) {
                            onHighlight(color)
                        }
                    }

                    // Expand button
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAllColors.toggle()
                        }
                    } label: {
                        Image(systemName: showAllColors ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                }

                // Secondary colors row (expanded)
                if showAllColors {
                    HStack(spacing: 8) {
                        ForEach(HighlightColor.allCases.filter { !primaryColors.contains($0) }) { color in
                            ColorButton(color: color) {
                                onHighlight(color)
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 260)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let shortcut: String
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))

                Text(label)
                    .font(.caption2)
            }
            .frame(width: 56, height: 44)
            .background(isHovering ? Color.gray.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
        .help("\(label) (⌘\(shortcut))")
    }
}

struct ColorButton: View {
    let color: HighlightColor
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color.color)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                )
                .scaleEffect(isHovering ? 1.15 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .help("\(color.displayName) (\(color.shortcut))")
    }
}
```

#### 1.4 Update PDFViewRepresentable for Highlight Rendering

```swift
// Shared/Components/PDFViewRepresentable.swift
// MODIFY - Add highlight overlay support

import SwiftUI
import PDFKit

struct PDFViewRepresentable: NSViewRepresentable {
    let document: PDFDocument
    @Binding var currentPage: Int
    @Binding var selectedText: String?
    @Binding var selectionBounds: [CGRect]
    let highlights: [Highlight]
    let displayMode: PDFDisplayMode
    let theme: ReadingTheme
    let onSelection: (String, [CGRect], Int) -> Void
    let onHighlightTap: (Highlight) -> Void

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.displayMode = displayMode
        pdfView.autoScales = true
        pdfView.backgroundColor = theme.backgroundColor
        pdfView.delegate = context.coordinator

        // Enable text selection
        pdfView.acceptsFirstResponder()

        // Add notification observer for selection changes
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.selectionChanged(_:)),
            name: .PDFViewSelectionChanged,
            object: pdfView
        )

        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        // Update display mode
        if pdfView.displayMode != displayMode {
            pdfView.displayMode = displayMode
        }

        // Update theme
        pdfView.backgroundColor = theme.backgroundColor

        // Navigate to page if changed externally
        if let page = document.page(at: currentPage),
           pdfView.currentPage != page {
            pdfView.go(to: page)
        }

        // Update highlights overlay
        context.coordinator.updateHighlights(highlights, in: pdfView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PDFViewDelegate {
        var parent: PDFViewRepresentable
        private var highlightOverlays: [NSView] = []

        init(_ parent: PDFViewRepresentable) {
            self.parent = parent
        }

        @objc func selectionChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let selection = pdfView.currentSelection,
                  let selectedString = selection.string,
                  !selectedString.isEmpty else {
                return
            }

            // Get selection bounds
            var bounds: [CGRect] = []
            var pageIndex = 0

            if let pages = selection.pages as? [PDFPage] {
                for page in pages {
                    if let pageBounds = selection.bounds(for: page) {
                        bounds.append(pageBounds)
                    }
                    if let firstPage = pages.first,
                       let document = pdfView.document {
                        pageIndex = document.index(for: firstPage)
                    }
                }
            }

            DispatchQueue.main.async {
                self.parent.onSelection(selectedString, bounds, pageIndex)
            }
        }

        func updateHighlights(_ highlights: [Highlight], in pdfView: PDFView) {
            // Remove existing overlays
            highlightOverlays.forEach { $0.removeFromSuperview() }
            highlightOverlays.removeAll()

            // Add new overlays for visible pages
            guard let document = pdfView.document else { return }

            for highlight in highlights {
                guard highlight.pageNumber < document.pageCount,
                      let page = document.page(at: highlight.pageNumber) else { continue }

                for rect in highlight.selectionBounds {
                    // Convert PDF coordinates to view coordinates
                    let viewRect = pdfView.convert(rect, from: page)

                    let overlay = HighlightOverlayView(
                        frame: viewRect,
                        color: NSColor(highlight.color.color),
                        hasNote: highlight.hasNote
                    )
                    overlay.highlight = highlight
                    overlay.onTap = { [weak self] in
                        self?.parent.onHighlightTap(highlight)
                    }

                    pdfView.documentView?.addSubview(overlay)
                    highlightOverlays.append(overlay)
                }
            }
        }

        func pdfViewPageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let currentPage = pdfView.currentPage,
                  let document = pdfView.document else { return }

            let pageIndex = document.index(for: currentPage)
            DispatchQueue.main.async {
                self.parent.currentPage = pageIndex
            }
        }
    }
}

// NSView subclass for highlight overlay
class HighlightOverlayView: NSView {
    var color: NSColor
    var hasNote: Bool
    var highlight: Highlight?
    var onTap: (() -> Void)?

    init(frame: CGRect, color: NSColor, hasNote: Bool) {
        self.color = color
        self.hasNote = hasNote
        super.init(frame: frame)
        self.wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        color.withAlphaComponent(0.35).setFill()
        bounds.fill()

        // Draw note indicator if has note
        if hasNote {
            let noteIcon = NSImage(systemSymbolName: "note.text", accessibilityDescription: "Has note")
            noteIcon?.draw(
                in: NSRect(x: bounds.maxX - 12, y: bounds.maxY - 12, width: 10, height: 10),
                from: .zero,
                operation: .sourceOver,
                fraction: 0.6
            )
        }
    }

    override func mouseDown(with event: NSEvent) {
        onTap?()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        for area in trackingAreas {
            removeTrackingArea(area)
        }

        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeInKeyWindow]
        let trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea)
    }

    override func mouseEntered(with event: NSEvent) {
        layer?.backgroundColor = color.withAlphaComponent(0.5).cgColor
    }

    override func mouseExited(with event: NSEvent) {
        layer?.backgroundColor = color.withAlphaComponent(0.35).cgColor
    }
}
```

---

### Task 2: Notes System

**Objective:** Create a note system where notes can be attached to highlights or exist standalone.

#### 2.1 Create Note Model

```swift
// Shared/Models/Note.swift
// NEW FILE

import SwiftData
import Foundation

@Model
final class Note {
    var id: UUID
    var content: String
    var dateCreated: Date
    var dateModified: Date
    var pageNumber: Int?

    // Relationships
    var highlight: Highlight?
    var book: Book?

    var isStandalone: Bool {
        highlight == nil
    }

    var displayTitle: String {
        // Return first line or truncated content
        let firstLine = content.split(separator: "\n").first.map(String.init) ?? content
        if firstLine.count > 50 {
            return String(firstLine.prefix(47)) + "..."
        }
        return firstLine.isEmpty ? "Untitled Note" : firstLine
    }

    var preview: String {
        if content.count > 100 {
            return String(content.prefix(97)) + "..."
        }
        return content
    }

    init(
        content: String = "",
        pageNumber: Int? = nil,
        highlight: Highlight? = nil
    ) {
        self.id = UUID()
        self.content = content
        self.dateCreated = Date()
        self.dateModified = Date()
        self.pageNumber = pageNumber
        self.highlight = highlight
    }

    func updateContent(_ newContent: String) {
        content = newContent
        dateModified = Date()
    }
}
```

#### 2.2 Update Book Model

```swift
// Shared/Models/Book.swift
// MODIFY - Add notes relationship

// Add this relationship to the Book model:
@Relationship(deleteRule: .cascade)
var notes: [Note] = []

// Add computed property for standalone notes:
var standaloneNotes: [Note] {
    notes.filter { $0.isStandalone }
}
```

#### 2.3 Create Note Editor Component

```swift
// Shared/Components/NoteEditor.swift
// NEW FILE

import SwiftUI

struct NoteEditor: View {
    @Bindable var note: Note
    let highlight: Highlight?
    let onSave: () -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void

    @State private var editedContent: String = ""
    @FocusState private var isEditorFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            header

            Divider()

            // Highlighted text (if attached to highlight)
            if let highlight {
                highlightPreview(highlight)
                Divider()
            }

            // Note editor
            editor

            Divider()

            // Footer with actions
            footer
        }
        .frame(width: 400, height: 350)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
        .onAppear {
            editedContent = note.content
            isEditorFocused = true
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: highlight != nil ? "note.text" : "square.and.pencil")
                .foregroundStyle(.secondary)

            Text(highlight != nil ? "Note on Highlight" : "Standalone Note")
                .font(.headline)

            Spacer()

            // Page indicator
            if let page = note.pageNumber ?? highlight?.pageNumber {
                Text("Page \(page + 1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding()
    }

    @ViewBuilder
    private func highlightPreview(_ highlight: Highlight) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(highlight.color.color)
                .frame(width: 4)

            Text(highlight.text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(highlight.color.color.opacity(0.1))
    }

    private var editor: some View {
        TextEditor(text: $editedContent)
            .font(.body)
            .scrollContentBackground(.hidden)
            .padding(12)
            .focused($isEditorFocused)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack {
            // Delete button
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("Delete note")

            Spacer()

            // Timestamps
            VStack(alignment: .trailing, spacing: 2) {
                if note.dateCreated != note.dateModified {
                    Text("Modified \(note.dateModified.formatted(.relative(presentation: .named)))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Text("Created \(note.dateCreated.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Action buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.escape, modifiers: [])

                Button("Save") {
                    note.updateContent(editedContent)
                    onSave()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .buttonStyle(.borderedProminent)
                .disabled(editedContent == note.content)
            }
        }
        .padding()
    }
}
```

---

### Task 3: Annotations Sidebar

**Objective:** Create a right sidebar that displays all highlights and notes for the current book.

#### 3.1 Create Annotation Row Component

```swift
// Shared/Components/AnnotationRow.swift
// NEW FILE

import SwiftUI

struct AnnotationRow: View {
    let highlight: Highlight
    let onTap: () -> Void
    let onDelete: () -> Void
    let onEditNote: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Color indicator + page number
            HStack {
                Circle()
                    .fill(highlight.color.color)
                    .frame(width: 10, height: 10)

                Text(highlight.color.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Page \(highlight.pageNumber + 1)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            // Highlighted text
            Text(highlight.text)
                .font(.callout)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Note preview (if exists)
            if let note = highlight.note, !note.content.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(note.preview)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .padding(8)
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Timestamp
            Text(highlight.dateCreated.formatted(.relative(presentation: .named)))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(isHovering ? Color.gray.opacity(0.05) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            Button {
                onTap()
            } label: {
                Label("Go to Page", systemImage: "arrow.right.circle")
            }

            Button {
                onEditNote()
            } label: {
                Label(highlight.hasNote ? "Edit Note" : "Add Note", systemImage: "note.text")
            }

            Divider()

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(highlight.text, forType: .string)
            } label: {
                Label("Copy Text", systemImage: "doc.on.doc")
            }

            Divider()

            // Color submenu
            Menu {
                ForEach(HighlightColor.allCases) { color in
                    Button {
                        highlight.color = color
                    } label: {
                        Label(color.displayName, systemImage: highlight.color == color ? "checkmark" : "")
                    }
                }
            } label: {
                Label("Change Color", systemImage: "paintpalette")
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
```

#### 3.2 Create Annotations Sidebar View

```swift
// macOS/Views/AnnotationsSidebar.swift
// NEW FILE

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
            if filteredHighlights.isEmpty {
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
                    },
                    onDelete: {
                        if let note = editingNote {
                            modelContext.delete(note)
                        }
                        showNoteEditor = false
                        editingNote = nil
                    },
                    onCancel: {
                        // Revert changes if new note
                        if editingNote?.content.isEmpty ?? false {
                            if let note = editingNote {
                                modelContext.delete(note)
                            }
                        }
                        showNoteEditor = false
                        editingNote = nil
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
                            Label(color.displayName, systemImage: filterColor == color ? "checkmark" : "circle.fill")
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
```

#### 3.3 Update MacContentView

```swift
// macOS/MacContentView.swift
// MODIFY - Add right sidebar for annotations

import SwiftUI
import SwiftData

struct MacContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var books: [Book]

    @State private var selectedCollection: LibraryCollection = .all
    @State private var selectedBook: Book?
    @State private var showLaunchDua = true
    @State private var showAnnotationsSidebar = true
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        ZStack {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                // Left Sidebar
                MacSidebarView(
                    selectedCollection: $selectedCollection,
                    selectedBook: $selectedBook
                )
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
            } content: {
                // Center Content
                if let book = selectedBook {
                    MacReaderView(book: book)
                } else {
                    MacLibraryView(
                        collection: selectedCollection,
                        onOpenBook: { book in
                            selectedBook = book
                        }
                    )
                }
            } detail: {
                // Right Sidebar - Annotations
                if let book = selectedBook, showAnnotationsSidebar {
                    AnnotationsSidebar(
                        book: book,
                        onNavigateToPage: { page in
                            // Navigate to page in reader
                            NotificationCenter.default.post(
                                name: .navigateToPage,
                                object: page
                            )
                        }
                    )
                    .navigationSplitViewColumnWidth(min: 250, ideal: 280, max: 350)
                } else {
                    Text("Select a book to view annotations")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .navigationSplitViewColumnWidth(min: 250, ideal: 280, max: 350)
                }
            }
            .navigationSplitViewStyle(.balanced)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        withAnimation {
                            showAnnotationsSidebar.toggle()
                        }
                    } label: {
                        Image(systemName: "sidebar.right")
                    }
                    .help("Toggle Annotations Sidebar (⌘⇧R)")
                }
            }

            // Launch Dua Banner
            if showLaunchDua {
                LaunchDuaBanner(isPresented: $showLaunchDua)
            }
        }
        .frame(minWidth: 1000, minHeight: 600)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showLaunchDua = false
                }
            }
        }
    }
}

// Add notification name
extension Notification.Name {
    static let navigateToPage = Notification.Name("navigateToPage")
}
```

---

### Task 4: In-Document Search

**Objective:** Implement search within the current PDF document with match highlighting and navigation.

#### 4.1 Create Search Service

```swift
// Shared/Services/SearchService.swift
// NEW FILE

import Foundation
import PDFKit

@MainActor
final class SearchService {

    struct SearchResult: Identifiable {
        let id = UUID()
        let selection: PDFSelection
        let pageNumber: Int
        let contextBefore: String
        let matchText: String
        let contextAfter: String

        var fullContext: String {
            "\(contextBefore)\(matchText)\(contextAfter)"
        }
    }

    func search(
        query: String,
        in document: PDFDocument,
        options: NSString.CompareOptions = .caseInsensitive
    ) async -> [SearchResult] {
        guard !query.isEmpty else { return [] }

        let selections = document.findString(query, withOptions: options)

        var results: [SearchResult] = []

        for selection in selections {
            guard let page = selection.pages.first as? PDFPage,
                  let matchString = selection.string else { continue }

            let pageIndex = document.index(for: page)

            // Get surrounding context
            let (before, after) = extractContext(
                for: selection,
                on: page,
                contextLength: 30
            )

            results.append(SearchResult(
                selection: selection,
                pageNumber: pageIndex,
                contextBefore: before,
                matchText: matchString,
                contextAfter: after
            ))
        }

        return results
    }

    private func extractContext(
        for selection: PDFSelection,
        on page: PDFPage,
        contextLength: Int
    ) -> (before: String, after: String) {
        guard let pageText = page.string else {
            return ("", "")
        }

        guard let matchRange = pageText.range(of: selection.string ?? "") else {
            return ("", "")
        }

        // Get text before match
        let beforeStart = pageText.index(
            matchRange.lowerBound,
            offsetBy: -contextLength,
            limitedBy: pageText.startIndex
        ) ?? pageText.startIndex

        let beforeText = String(pageText[beforeStart..<matchRange.lowerBound])
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespaces)

        // Get text after match
        let afterEnd = pageText.index(
            matchRange.upperBound,
            offsetBy: contextLength,
            limitedBy: pageText.endIndex
        ) ?? pageText.endIndex

        let afterText = String(pageText[matchRange.upperBound..<afterEnd])
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespaces)

        return (
            beforeText.isEmpty ? "" : "...\(beforeText)",
            afterText.isEmpty ? "" : "\(afterText)..."
        )
    }
}
```

#### 4.2 Create Search Bar Component

```swift
// Shared/Components/SearchBar.swift
// NEW FILE

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
```

#### 4.3 Create Search Result Row

```swift
// Shared/Components/SearchResultRow.swift
// NEW FILE

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

        var match = AttributedString(self.result.matchText)
        match.backgroundColor = .yellow.opacity(0.3)
        match.font = .callout.bold()

        result.append(match)
        result.append(AttributedString(self.result.contextAfter))

        return result
    }
}
```

---

### Task 5: Markdown Export

**Objective:** Export annotations to Markdown format with proper formatting and page references.

#### 5.1 Create Export Service

```swift
// Shared/Services/ExportService.swift
// NEW FILE

import Foundation
import UniformTypeIdentifiers

@MainActor
final class ExportService {

    enum ExportFormat: String, CaseIterable {
        case markdown = "Markdown"
        case plainText = "Plain Text"
        case json = "JSON"

        var fileExtension: String {
            switch self {
            case .markdown: return "md"
            case .plainText: return "txt"
            case .json: return "json"
            }
        }

        var utType: UTType {
            switch self {
            case .markdown: return .plainText
            case .plainText: return .plainText
            case .json: return .json
            }
        }
    }

    enum GroupingOption: String, CaseIterable {
        case none = "No Grouping"
        case page = "By Page"
        case color = "By Color"
        case date = "By Date"
    }

    struct ExportOptions {
        var format: ExportFormat = .markdown
        var grouping: GroupingOption = .page
        var includeHighlightedText: Bool = true
        var includeNotes: Bool = true
        var includePageNumbers: Bool = true
        var includeTimestamps: Bool = false
        var includeColorLabels: Bool = true
    }

    func export(
        book: Book,
        options: ExportOptions = ExportOptions()
    ) -> String {
        switch options.format {
        case .markdown:
            return exportToMarkdown(book: book, options: options)
        case .plainText:
            return exportToPlainText(book: book, options: options)
        case .json:
            return exportToJSON(book: book, options: options)
        }
    }

    // MARK: - Markdown Export

    private func exportToMarkdown(book: Book, options: ExportOptions) -> String {
        var output = "# \(book.displayTitle)\n"
        output += "**Author:** \(book.displayAuthor)\n"
        output += "**Exported:** \(Date().formatted(date: .long, time: .shortened))\n\n"
        output += "---\n\n"

        let highlights = book.highlights.sorted { $0.pageNumber < $1.pageNumber }

        if highlights.isEmpty {
            output += "*No annotations to export.*\n"
            return output
        }

        output += "## Annotations (\(highlights.count))\n\n"

        switch options.grouping {
        case .none:
            for highlight in highlights {
                output += formatHighlightMarkdown(highlight, options: options)
            }

        case .page:
            let grouped = Dictionary(grouping: highlights) { $0.pageNumber }
            for pageNumber in grouped.keys.sorted() {
                output += "### Page \(pageNumber + 1)\n\n"
                for highlight in grouped[pageNumber] ?? [] {
                    output += formatHighlightMarkdown(highlight, options: options, includePage: false)
                }
            }

        case .color:
            let grouped = Dictionary(grouping: highlights) { $0.color }
            for color in HighlightColor.allCases {
                guard let colorHighlights = grouped[color], !colorHighlights.isEmpty else { continue }
                output += "### \(color.displayName) (\(colorHighlights.count))\n\n"
                for highlight in colorHighlights.sorted(by: { $0.pageNumber < $1.pageNumber }) {
                    output += formatHighlightMarkdown(highlight, options: options, includeColor: false)
                }
            }

        case .date:
            let calendar = Calendar.current
            let grouped = Dictionary(grouping: highlights) {
                calendar.startOfDay(for: $0.dateCreated)
            }
            for date in grouped.keys.sorted().reversed() {
                output += "### \(date.formatted(date: .long, time: .omitted))\n\n"
                for highlight in grouped[date] ?? [] {
                    output += formatHighlightMarkdown(highlight, options: options)
                }
            }
        }

        // Standalone notes
        let standaloneNotes = book.notes.filter { $0.isStandalone }
        if !standaloneNotes.isEmpty && options.includeNotes {
            output += "---\n\n"
            output += "## Notes (\(standaloneNotes.count))\n\n"
            for note in standaloneNotes.sorted(by: { ($0.pageNumber ?? 0) < ($1.pageNumber ?? 0) }) {
                output += formatNoteMarkdown(note, options: options)
            }
        }

        return output
    }

    private func formatHighlightMarkdown(
        _ highlight: Highlight,
        options: ExportOptions,
        includePage: Bool = true,
        includeColor: Bool = true
    ) -> String {
        var output = ""

        // Metadata line
        var meta: [String] = []
        if includePage && options.includePageNumbers {
            meta.append("p. \(highlight.pageNumber + 1)")
        }
        if includeColor && options.includeColorLabels {
            meta.append(highlight.color.displayName)
        }
        if options.includeTimestamps {
            meta.append(highlight.dateCreated.formatted(date: .abbreviated, time: .shortened))
        }

        if !meta.isEmpty {
            output += "*\(meta.joined(separator: " · "))*\n\n"
        }

        // Highlighted text as blockquote
        if options.includeHighlightedText {
            output += "> \(highlight.text.replacingOccurrences(of: "\n", with: "\n> "))\n\n"
        }

        // Note
        if options.includeNotes, let note = highlight.note, !note.content.isEmpty {
            output += "📝 \(note.content)\n\n"
        }

        output += "---\n\n"

        return output
    }

    private func formatNoteMarkdown(_ note: Note, options: ExportOptions) -> String {
        var output = ""

        var meta: [String] = []
        if let page = note.pageNumber, options.includePageNumbers {
            meta.append("p. \(page + 1)")
        }
        if options.includeTimestamps {
            meta.append(note.dateCreated.formatted(date: .abbreviated, time: .shortened))
        }

        if !meta.isEmpty {
            output += "*\(meta.joined(separator: " · "))*\n\n"
        }

        output += "\(note.content)\n\n"
        output += "---\n\n"

        return output
    }

    // MARK: - Plain Text Export

    private func exportToPlainText(book: Book, options: ExportOptions) -> String {
        var output = "\(book.displayTitle)\n"
        output += "Author: \(book.displayAuthor)\n"
        output += "Exported: \(Date().formatted(date: .long, time: .shortened))\n"
        output += String(repeating: "=", count: 50) + "\n\n"

        let highlights = book.highlights.sorted { $0.pageNumber < $1.pageNumber }

        for highlight in highlights {
            if options.includePageNumbers {
                output += "[Page \(highlight.pageNumber + 1)]"
            }
            if options.includeColorLabels {
                output += " [\(highlight.color.displayName)]"
            }
            output += "\n"

            if options.includeHighlightedText {
                output += highlight.text + "\n"
            }

            if options.includeNotes, let note = highlight.note, !note.content.isEmpty {
                output += "  Note: \(note.content)\n"
            }

            output += "\n"
        }

        return output
    }

    // MARK: - JSON Export

    private func exportToJSON(book: Book, options: ExportOptions) -> String {
        struct ExportedHighlight: Codable {
            let text: String
            let page: Int
            let color: String
            let dateCreated: Date
            let note: String?
        }

        struct ExportedBook: Codable {
            let title: String
            let author: String
            let exportDate: Date
            let highlights: [ExportedHighlight]
        }

        let exportedHighlights = book.highlights.map { highlight in
            ExportedHighlight(
                text: highlight.text,
                page: highlight.pageNumber + 1,
                color: highlight.color.displayName,
                dateCreated: highlight.dateCreated,
                note: highlight.note?.content
            )
        }

        let exportedBook = ExportedBook(
            title: book.displayTitle,
            author: book.displayAuthor,
            exportDate: Date(),
            highlights: exportedHighlights
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(exportedBook),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "{}"
        }

        return jsonString
    }

    // MARK: - Save to File

    func saveToFile(
        content: String,
        filename: String,
        format: ExportFormat
    ) async throws -> URL {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [format.utType]
        panel.nameFieldStringValue = "\(filename).\(format.fileExtension)"
        panel.canCreateDirectories = true

        let response = await panel.beginSheetModal(for: NSApp.keyWindow!)

        guard response == .OK, let url = panel.url else {
            throw ExportError.cancelled
        }

        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func copyToClipboard(_ content: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
    }
}

enum ExportError: LocalizedError {
    case cancelled
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Export was cancelled."
        case .writeFailed:
            return "Failed to write the file."
        }
    }
}
```

---

### Task 6: Enhanced Islamic Reminders

**Objective:** Improve the Islamic reminder system with more trigger points and varied content.

#### 6.1 Update Reminder Service

```swift
// Shared/Services/ReminderService.swift
// MODIFY - Add new reminder types and triggers

import Foundation

@MainActor
@Observable
final class ReminderService {

    enum ReminderTrigger {
        case appLaunch
        case sessionStart
        case studyBreak(minutes: Int)
        case bookCompletion
        case highlightCreated(count: Int)
        case dailyReminder
    }

    // Current reminder being displayed
    var currentReminder: IslamicReminder?
    var showReminder = false

    // Statistics for triggers
    private var highlightCount = 0
    private var sessionStartTime: Date?
    private var lastBreakReminder: Date?

    // MARK: - Trigger Handlers

    func onAppLaunch() {
        currentReminder = IslamicReminder.launchDua
        showReminder = true
    }

    func onSessionStart() {
        sessionStartTime = Date()
        currentReminder = getRandomReminder(for: .sessionStart)
        showReminder = true
    }

    func onHighlightCreated() {
        highlightCount += 1

        // Show encouragement every 5 highlights
        if highlightCount % 5 == 0 {
            currentReminder = getRandomReminder(for: .highlightCreated(count: highlightCount))
            showReminder = true
        }
    }

    func checkForBreakReminder() {
        guard let sessionStart = sessionStartTime else { return }

        let minutesElapsed = Int(Date().timeIntervalSince(sessionStart) / 60)

        // Remind every 45 minutes
        if minutesElapsed >= 45 {
            if lastBreakReminder == nil ||
               Date().timeIntervalSince(lastBreakReminder!) >= 45 * 60 {
                currentReminder = getRandomReminder(for: .studyBreak(minutes: minutesElapsed))
                showReminder = true
                lastBreakReminder = Date()
            }
        }
    }

    func onBookCompletion(book: Book) {
        currentReminder = IslamicReminder.bookCompletionDua(bookTitle: book.displayTitle)
        showReminder = true
    }

    func dismiss() {
        withAnimation {
            showReminder = false
        }

        // Clear after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.currentReminder = nil
        }
    }

    // MARK: - Content Selection

    private func getRandomReminder(for trigger: ReminderTrigger) -> IslamicReminder {
        switch trigger {
        case .appLaunch:
            return .launchDua

        case .sessionStart:
            return sessionStartReminders.randomElement() ?? .launchDua

        case .studyBreak(let minutes):
            return breakReminder(minutes: minutes)

        case .bookCompletion:
            return completionReminders.randomElement() ?? .launchDua

        case .highlightCreated(let count):
            return highlightEncouragement(count: count)

        case .dailyReminder:
            return dailyReminders.randomElement() ?? .launchDua
        }
    }

    // MARK: - Reminder Content

    private var sessionStartReminders: [IslamicReminder] {
        [
            IslamicReminder(
                type: .hadith,
                arabic: "مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الْجَنَّةِ",
                transliteration: "Man salaka tareeqan yaltamisu feehi 'ilman sahhala Allahu lahu bihi tareeqan ila al-jannah",
                english: "Whoever takes a path seeking knowledge, Allah will make easy for him a path to Paradise.",
                source: "Sahih Muslim"
            ),
            IslamicReminder(
                type: .hadith,
                arabic: "طَلَبُ الْعِلْمِ فَرِيضَةٌ عَلَى كُلِّ مُسْلِمٍ",
                transliteration: "Talab al-'ilm fareeda 'ala kulli muslim",
                english: "Seeking knowledge is an obligation upon every Muslim.",
                source: "Ibn Majah"
            ),
            IslamicReminder(
                type: .dua,
                arabic: "اللَّهُمَّ انْفَعْنِي بِمَا عَلَّمْتَنِي وَعَلِّمْنِي مَا يَنْفَعُنِي",
                transliteration: "Allahumma infa'ni bima 'allamtani wa 'allimni ma yanfa'uni",
                english: "O Allah, benefit me with what You have taught me, and teach me what will benefit me.",
                source: "Ibn Majah"
            )
        ]
    }

    private func breakReminder(minutes: Int) -> IslamicReminder {
        IslamicReminder(
            type: .reminder,
            arabic: "وَاسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ",
            transliteration: "Wasta'eenu bis-sabri was-salah",
            english: "You have been studying for \(minutes) minutes. Take a break, stretch, and if it's prayer time, don't delay your salah.",
            source: "Quran 2:45"
        )
    }

    private var completionReminders: [IslamicReminder] {
        [
            IslamicReminder(
                type: .dua,
                arabic: "الْحَمْدُ لِلَّهِ الَّذِي بِنِعْمَتِهِ تَتِمُّ الصَّالِحَاتُ",
                transliteration: "Alhamdulillahil-ladhi bi ni'matihi tatimmus-salihat",
                english: "All praise is due to Allah, by Whose grace good deeds are completed.",
                source: "Ibn Majah"
            )
        ]
    }

    private func highlightEncouragement(count: Int) -> IslamicReminder {
        IslamicReminder(
            type: .reminder,
            arabic: "مَا شَاءَ اللَّه",
            transliteration: "Ma sha Allah",
            english: "Masha'Allah! You've made \(count) highlights. May Allah bless your efforts in seeking knowledge.",
            source: ""
        )
    }

    private var dailyReminders: [IslamicReminder] {
        [
            IslamicReminder(
                type: .hadith,
                arabic: "الْكَلِمَةُ الْحِكْمَةُ ضَالَّةُ الْمُؤْمِنِ",
                transliteration: "Al-kalimatul-hikmah daalatul-mu'min",
                english: "Wisdom is the lost property of the believer. Wherever he finds it, he has the most right to it.",
                source: "Tirmidhi"
            ),
            IslamicReminder(
                type: .hadith,
                arabic: "اقْرَأْ وَارْتَقِ",
                transliteration: "Iqra' wa artaqi",
                english: "Read and ascend (in ranks).",
                source: "Abu Dawud, Tirmidhi"
            )
        ]
    }
}

// MARK: - Additional IslamicReminder initializers

extension IslamicReminder {
    static func bookCompletionDua(bookTitle: String) -> IslamicReminder {
        IslamicReminder(
            type: .dua,
            arabic: "الْحَمْدُ لِلَّهِ الَّذِي بِنِعْمَتِهِ تَتِمُّ الصَّالِحَاتُ",
            transliteration: "Alhamdulillahil-ladhi bi ni'matihi tatimmus-salihat",
            english: "You completed \"\(bookTitle)\"! All praise is due to Allah, by Whose grace good deeds are completed.",
            source: "Ibn Majah"
        )
    }
}
```

#### 6.2 Create Enhanced Reminder Banner

```swift
// Shared/Components/ReminderBanner.swift
// MODIFY - Support different reminder types

import SwiftUI

struct ReminderBanner: View {
    let reminder: IslamicReminder
    let onDismiss: () -> Void
    let onSave: (() -> Void)?

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Main content
            VStack(spacing: 12) {
                // Type indicator
                HStack {
                    Image(systemName: reminder.type.icon)
                        .foregroundStyle(reminder.type.color)

                    Text(reminder.type.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                // Arabic text
                Text(reminder.arabic)
                    .font(.title2)
                    .fontDesign(.serif)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                // Transliteration (collapsible)
                if isExpanded && !reminder.transliteration.isEmpty {
                    Text(reminder.transliteration)
                        .font(.subheadline)
                        .italic()
                        .foregroundStyle(.secondary)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // English translation
                Text(reminder.english)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                // Source
                if !reminder.source.isEmpty {
                    Text("— \(reminder.source)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(20)

            // Action bar
            HStack {
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Label(
                        isExpanded ? "Less" : "More",
                        systemImage: isExpanded ? "chevron.up" : "chevron.down"
                    )
                    .font(.caption)
                }
                .buttonStyle(.plain)

                Spacer()

                if let onSave {
                    Button {
                        onSave()
                    } label: {
                        Label("Save", systemImage: "bookmark")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: 500)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

extension IslamicReminder.ReminderType {
    var icon: String {
        switch self {
        case .dua: return "hands.sparkles"
        case .hadith: return "quote.opening"
        case .ayah: return "book.closed"
        case .reminder: return "bell"
        }
    }

    var color: Color {
        switch self {
        case .dua: return .noorTeal
        case .hadith: return .noorGold
        case .ayah: return .green
        case .reminder: return .orange
        }
    }

    var displayName: String {
        switch self {
        case .dua: return "Dua"
        case .hadith: return "Hadith"
        case .ayah: return "Quran"
        case .reminder: return "Reminder"
        }
    }
}
```

---

## Data Models

### Updated Model Schema

```swift
// All SwiftData models for Phase 2

@Model final class Book {
    var id: UUID
    var title: String
    var author: String
    var fileURL: URL
    var coverImageData: Data?
    var dateAdded: Date
    var lastRead: Date?
    var currentPage: Int
    var totalPages: Int
    var isFavorite: Bool

    @Relationship(deleteRule: .cascade)
    var highlights: [Highlight] = []

    @Relationship(deleteRule: .cascade)
    var bookmarks: [Bookmark] = []

    @Relationship(deleteRule: .cascade)
    var notes: [Note] = []                    // NEW
}

@Model final class Highlight {
    var id: UUID
    var text: String
    var pageNumber: Int
    var colorName: String
    var dateCreated: Date
    var boundsData: Data?

    @Relationship(deleteRule: .cascade)
    var note: Note?                            // NEW

    var book: Book?
}

@Model final class Note {                      // NEW
    var id: UUID
    var content: String
    var dateCreated: Date
    var dateModified: Date
    var pageNumber: Int?

    var highlight: Highlight?
    var book: Book?
}

@Model final class Bookmark {
    var id: UUID
    var pageNumber: Int
    var title: String
    var dateCreated: Date

    var book: Book?
}
```

---

## Quality Standards

### Code Quality

- Swift 6 strict concurrency — no data races
- All new code follows existing patterns and style
- Comprehensive error handling
- No force unwraps without explicit justification
- Meaningful commit messages

### UI/UX Quality

- Consistent with Phase 1 design language
- Smooth animations (60fps)
- Responsive to user actions
- Clear feedback for all operations
- Accessibility support (VoiceOver, keyboard navigation)

### Performance

| Metric | Target |
|--------|--------|
| Highlight rendering | < 16ms per frame |
| Search (1000 pages) | < 500ms |
| Export (100 highlights) | < 1s |
| Note save | Immediate |

---

## Testing Requirements

### Unit Tests

```swift
// Tests/SharedTests/AnnotationTests.swift

final class AnnotationTests: XCTestCase {

    func testHighlightWithMultipleBounds() {
        let bounds = [
            CGRect(x: 0, y: 0, width: 100, height: 20),
            CGRect(x: 0, y: 20, width: 80, height: 20)
        ]
        let highlight = Highlight(text: "Multi-line text", pageNumber: 0, bounds: bounds)

        XCTAssertEqual(highlight.selectionBounds.count, 2)
    }

    func testNoteAttachedToHighlight() {
        let highlight = Highlight(text: "Test", pageNumber: 0)
        let note = Note(content: "My note", highlight: highlight)
        highlight.note = note

        XCTAssertTrue(highlight.hasNote)
        XCTAssertEqual(highlight.note?.content, "My note")
    }

    func testStandaloneNote() {
        let note = Note(content: "Standalone", pageNumber: 5)

        XCTAssertTrue(note.isStandalone)
        XCTAssertNil(note.highlight)
    }
}

final class SearchServiceTests: XCTestCase {

    func testSearchReturnsResults() async {
        // Load test PDF
        // Search for known text
        // Verify results
    }

    func testSearchContextExtraction() async {
        // Verify context before and after match
    }
}

final class ExportServiceTests: XCTestCase {

    func testMarkdownExport() {
        // Create book with highlights
        // Export to markdown
        // Verify format
    }

    func testJSONExport() {
        // Create book with highlights
        // Export to JSON
        // Verify valid JSON and structure
    }
}
```

### Manual Testing Checklist

- [ ] Create highlight by selecting text
- [ ] All 8 highlight colors work
- [ ] Highlights render correctly on PDF
- [ ] Multi-line highlights work
- [ ] Add note to highlight
- [ ] Edit existing note
- [ ] Create standalone note
- [ ] Delete highlight (with note)
- [ ] Annotations sidebar shows all highlights
- [ ] Filter annotations by color
- [ ] Sort annotations by page/date/color
- [ ] Search annotations
- [ ] Search within document
- [ ] Navigate between search results
- [ ] Export to Markdown
- [ ] Export to Plain Text
- [ ] Export to JSON
- [ ] Copy annotations to clipboard
- [ ] Islamic reminders appear at correct triggers
- [ ] Keyboard shortcuts work (1-8 for colors, ⌘F for search)

---

## Phase 2 Completion Criteria

Phase 2 is complete when ALL of the following are true:

### Functionality
- [ ] Highlights render visually on PDF with correct colors
- [ ] All 8 highlight colors work with keyboard shortcuts (1-8)
- [ ] Multi-line text selection creates proper highlights
- [ ] Notes can be attached to highlights
- [ ] Standalone notes can be created
- [ ] Annotations sidebar displays all highlights and notes
- [ ] Sidebar supports filtering by color
- [ ] Sidebar supports sorting (page, date, color)
- [ ] In-document search works with ⌘F
- [ ] Search results can be navigated with ⌘G / ⌘⇧G
- [ ] Markdown export includes all annotations with page references
- [ ] JSON and Plain Text export work
- [ ] Export can be grouped by page/color/date
- [ ] Islamic reminders trigger on session start
- [ ] Islamic reminders trigger on highlight milestones
- [ ] Break reminders appear after 45 minutes

### Quality
- [ ] Zero compiler warnings
- [ ] All unit tests pass
- [ ] Manual testing checklist complete
- [ ] Performance targets met

### Polish
- [ ] Highlight hover states work
- [ ] Note editor has smooth animations
- [ ] Search bar has proper focus handling
- [ ] Export dialog is intuitive
- [ ] All new UI matches Phase 1 design

---

## Dua for Success

اللَّهُمَّ عَلِّمْنَا مَا يَنْفَعُنَا وَانْفَعْنَا بِمَا عَلَّمْتَنَا وَزِدْنَا عِلْمًا

*Allahumma 'allimna ma yanfa'una wanfa'na bima 'allamtana wa zidna 'ilma.*

**O Allah, teach us what benefits us, benefit us from what You have taught us, and increase us in knowledge.**

---

بِسْمِ اللَّهِ، تَوَكَّلْتُ عَلَى اللَّهِ

**In the name of Allah, I place my trust in Allah.**

Continue with excellence.
