// SelectionPopover.swift
// NoorReader
//
// Enhanced text selection actions popover with full color palette and note support

import SwiftUI
import PDFKit
import AppKit

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
                Text(selectedText.prefix(100) + (selectedText.count > 100 ? "..." : ""))
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
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

// MARK: - Legacy SelectionPopover for backward compatibility

struct LegacySelectionPopover: View {
    let selection: PDFSelection
    let onHighlight: (HighlightColor) -> Void
    let onCopy: () -> Void
    let onDismiss: () -> Void

    @State private var showColorPicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Selected text preview
            if let text = selection.string, !text.isEmpty {
                Text(text.prefix(100) + (text.count > 100 ? "..." : ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .controlBackgroundColor))
            }

            Divider()

            // Action buttons
            HStack(spacing: 16) {
                Button(action: { showColorPicker.toggle() }) {
                    VStack(spacing: 4) {
                        Image(systemName: "highlighter")
                            .font(.title3)
                        Text("Highlight")
                            .font(.caption2)
                    }
                }
                .buttonStyle(.plain)

                Button(action: onCopy) {
                    VStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.title3)
                        Text("Copy")
                            .font(.caption2)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(12)

            // Color picker
            if showColorPicker {
                Divider()

                HStack(spacing: 8) {
                    ForEach(HighlightColor.allCases) { color in
                        Button(action: { onHighlight(color) }) {
                            Circle()
                                .fill(color.color)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .help("\(color.displayName) (\(color.shortcut))")
                    }
                }
                .padding(12)
            }
        }
        .frame(width: 280)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Action Button

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

// MARK: - Color Button

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

#Preview {
    SelectionPopover(
        selectedText: "This is some sample selected text that the user has highlighted in the PDF document.",
        onHighlight: { _ in },
        onAddNote: {},
        onCopy: {},
        onDismiss: {}
    )
    .padding()
}
