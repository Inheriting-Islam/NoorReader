// PDFService.swift
// NoorReader
//
// PDF operations service

import Foundation
import PDFKit

@MainActor
final class PDFService {

    /// Open a PDF document from a URL
    static func openDocument(at url: URL) -> PDFDocument? {
        // Try to access security-scoped resource
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }

        return PDFDocument(url: url)
    }

    /// Extract table of contents from a PDF
    static func extractTableOfContents(from document: PDFDocument) -> [TOCItem] {
        guard let outline = document.outlineRoot else {
            return []
        }

        return extractOutlineItems(from: outline, document: document, level: 0)
    }

    private static func extractOutlineItems(from outline: PDFOutline, document: PDFDocument, level: Int) -> [TOCItem] {
        var items: [TOCItem] = []

        for i in 0..<outline.numberOfChildren {
            guard let child = outline.child(at: i) else { continue }

            let title = child.label ?? "Untitled"
            var pageNumber = 0

            if let destination = child.destination,
               let page = destination.page {
                pageNumber = document.index(for: page)
            }

            let children = extractOutlineItems(from: child, document: document, level: level + 1)

            items.append(TOCItem(
                title: title,
                pageNumber: pageNumber,
                level: level,
                children: children
            ))
        }

        return items
    }

    /// Search for text in a PDF document
    static func search(text: String, in document: PDFDocument) -> [PDFSelection] {
        document.findString(text, withOptions: .caseInsensitive)
    }
}

// MARK: - TOC Item

struct TOCItem: Identifiable {
    let id = UUID()
    let title: String
    let pageNumber: Int
    let level: Int
    var children: [TOCItem]

    var hasChildren: Bool {
        !children.isEmpty
    }
}
