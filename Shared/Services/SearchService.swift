// SearchService.swift
// NoorReader
//
// In-document search functionality

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
        guard let pageText = page.string,
              let matchString = selection.string else {
            return ("", "")
        }

        guard let matchRange = pageText.range(of: matchString) else {
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

// MARK: - Search Options

extension SearchService {
    enum SearchOption: String, CaseIterable {
        case caseInsensitive = "Case Insensitive"
        case caseSensitive = "Case Sensitive"
        case wholeWord = "Whole Word"

        var compareOptions: NSString.CompareOptions {
            switch self {
            case .caseInsensitive:
                return .caseInsensitive
            case .caseSensitive:
                return []
            case .wholeWord:
                return .caseInsensitive
            }
        }
    }
}
