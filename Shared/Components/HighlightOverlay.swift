// HighlightOverlay.swift
// NoorReader
//
// Renders highlight rectangles over PDF content

import SwiftUI
import PDFKit
import AppKit

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

// MARK: - NSView subclass for highlight overlay in PDFView

class HighlightOverlayView: NSView {
    var color: NSColor
    var hasNote: Bool
    var highlight: Highlight?
    var onTap: (() -> Void)?

    private var isHovering = false

    init(frame: CGRect, color: NSColor, hasNote: Bool) {
        self.color = color
        self.hasNote = hasNote
        super.init(frame: frame)
        self.wantsLayer = true
        setupTrackingArea()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupTrackingArea() {
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeInKeyWindow]
        let trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let opacity: CGFloat = isHovering ? 0.5 : 0.35
        color.withAlphaComponent(opacity).setFill()
        bounds.fill()

        // Draw note indicator if has note
        if hasNote {
            if let noteIcon = NSImage(systemSymbolName: "note.text", accessibilityDescription: "Has note") {
                noteIcon.draw(
                    in: NSRect(x: bounds.maxX - 12, y: bounds.maxY - 12, width: 10, height: 10),
                    from: .zero,
                    operation: .sourceOver,
                    fraction: 0.6
                )
            }
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
        isHovering = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovering = false
        needsDisplay = true
    }
}
