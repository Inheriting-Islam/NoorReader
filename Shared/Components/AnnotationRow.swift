// AnnotationRow.swift
// NoorReader
//
// Sidebar list item for highlights and annotations

import SwiftUI
import AppKit

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
                        HStack {
                            Circle()
                                .fill(color.color)
                                .frame(width: 12, height: 12)
                            Text(color.displayName)
                            if highlight.color == color {
                                Image(systemName: "checkmark")
                            }
                        }
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

// MARK: - Standalone Note Row

struct StandaloneNoteRow: View {
    let note: Note
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "note.text")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Note")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if let page = note.pageNumber {
                    Text("Page \(page + 1)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            // Note content
            Text(note.displayTitle)
                .font(.callout)
                .fontWeight(.medium)
                .lineLimit(1)

            if note.content.count > note.displayTitle.count {
                Text(note.preview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Timestamp
            Text(note.dateModified.formatted(.relative(presentation: .named)))
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
                Label("Edit Note", systemImage: "pencil")
            }

            if let page = note.pageNumber {
                Button {
                    NotificationCenter.default.post(name: .navigateToPage, object: page)
                } label: {
                    Label("Go to Page", systemImage: "arrow.right.circle")
                }
            }

            Divider()

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(note.content, forType: .string)
            } label: {
                Label("Copy Note", systemImage: "doc.on.doc")
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

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToPage = Notification.Name("navigateToPage")
}

#Preview {
    let highlight = Highlight(
        text: "This is a sample highlighted text that demonstrates how the annotation row component displays highlights in the sidebar.",
        pageNumber: 5,
        bounds: [],
        color: .green
    )

    return VStack {
        AnnotationRow(
            highlight: highlight,
            onTap: {},
            onDelete: {},
            onEditNote: {}
        )
    }
    .frame(width: 280)
    .padding()
}
