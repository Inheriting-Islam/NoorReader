// Highlight.swift
// NoorReader
//
// SwiftData model for text highlights in PDFs

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

    // Store selection bounds for rendering (supports multiple rects for multi-line selections)
    var boundsData: Data?

    // Relationship to note
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

    // Convenience initializer for single bounds (backward compatibility)
    convenience init(
        text: String,
        pageNumber: Int,
        bounds: CGRect?,
        color: HighlightColor = .yellow
    ) {
        self.init(
            text: text,
            pageNumber: pageNumber,
            bounds: bounds.map { [$0] } ?? [],
            color: color
        )
    }
}

// MARK: - Highlight Color

enum HighlightColor: String, Codable, CaseIterable, Identifiable {
    case yellow
    case green
    case blue
    case pink
    case orange
    case purple
    case red
    case gray

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .yellow: return .highlightYellow
        case .green: return .highlightGreen
        case .blue: return .highlightBlue
        case .pink: return .highlightPink
        case .orange: return .highlightOrange
        case .purple: return .highlightPurple
        case .red: return .highlightRed
        case .gray: return .highlightGray
        }
    }

    var displayName: String {
        switch self {
        case .yellow: return "General"
        case .green: return "Key Concept"
        case .blue: return "Definition"
        case .pink: return "Question"
        case .orange: return "Example"
        case .purple: return "Connection"
        case .red: return "Critical"
        case .gray: return "Reference"
        }
    }

    var shortcut: String {
        switch self {
        case .yellow: return "1"
        case .green: return "2"
        case .blue: return "3"
        case .pink: return "4"
        case .orange: return "5"
        case .purple: return "6"
        case .red: return "7"
        case .gray: return "8"
        }
    }
}

// MARK: - Codable CGRect wrapper

struct CodableRect: Codable {
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat

    var rect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }

    init(rect: CGRect) {
        self.x = rect.origin.x
        self.y = rect.origin.y
        self.width = rect.size.width
        self.height = rect.size.height
    }
}
