// NoteEditor.swift
// NoorReader
//
// Rich note editor for highlights and standalone notes

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
        .background(Color(nsColor: .windowBackgroundColor))
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

// MARK: - Compact Note Editor (for inline editing)

struct CompactNoteEditor: View {
    @Binding var content: String
    let placeholder: String
    let onSave: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextEditor(text: $content)
                .font(.body)
                .scrollContentBackground(.hidden)
                .focused($isFocused)
                .frame(minHeight: 60, maxHeight: 120)
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )

            HStack {
                Spacer()

                Button("Save") {
                    onSave()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(content.isEmpty)
            }
        }
        .onAppear {
            isFocused = true
        }
    }
}

// MARK: - Note Preview Card

struct NotePreviewCard: View {
    let note: Note
    let onTap: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(note.displayTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                // Preview
                if note.content.count > note.displayTitle.count {
                    Text(note.preview)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                // Metadata
                HStack {
                    if let page = note.pageNumber {
                        Label("Page \(page + 1)", systemImage: "doc")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    Text(note.dateModified.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isHovering ? Color.secondary.opacity(0.05) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

#Preview {
    let note = Note(content: "This is a sample note with some content.", pageNumber: 5)

    return NoteEditor(
        note: note,
        highlight: nil,
        onSave: {},
        onDelete: {},
        onCancel: {}
    )
    .padding()
}
