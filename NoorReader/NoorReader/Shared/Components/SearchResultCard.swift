// SearchResultCard.swift
// NoorReader
//
// Card component for displaying semantic search results with context preview

import SwiftUI

struct SearchResultCard: View {
    let result: HybridSearchResult
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Header with book info and match type
                HStack(alignment: .top) {
                    // Book title and page
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.bookTitle)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text("Page \(result.pageNumber + 1)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    // Match type badge
                    MatchTypeBadge(matchType: result.matchType)

                    // Relevance indicator
                    RelevanceIndicator(score: result.relevanceScore)
                }

                // Text preview
                Text(result.contextPreview)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                // Action hint
                HStack {
                    Spacer()
                    Text("Click to navigate")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Image(systemName: "arrow.right.circle")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .opacity(isHovered ? 1 : 0)
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.controlBackgroundColor))
                    .shadow(color: .black.opacity(isHovered ? 0.1 : 0.05), radius: isHovered ? 4 : 2)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isHovered ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Match Type Badge

struct MatchTypeBadge: View {
    let matchType: SearchMatchType

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: matchType.icon)
            Text(matchType.displayName)
        }
        .font(.caption2)
        .fontWeight(.medium)
        .foregroundStyle(badgeColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background {
            Capsule()
                .fill(badgeColor.opacity(0.15))
        }
    }

    private var badgeColor: Color {
        switch matchType {
        case .semantic: return .purple
        case .keyword: return .blue
        case .hybrid: return .green
        }
    }
}

// MARK: - Relevance Indicator

struct RelevanceIndicator: View {
    let score: Double

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "chart.bar.fill")
                .font(.caption2)
            Text("\(Int(score * 100))%")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundStyle(relevanceColor)
    }

    private var relevanceColor: Color {
        if score >= 0.7 {
            return .green
        } else if score >= 0.5 {
            return .orange
        } else {
            return .secondary
        }
    }
}

// MARK: - Search Result Group Header

struct SearchResultGroupHeader: View {
    let bookTitle: String
    let resultCount: Int
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundStyle(.secondary)

                Text(bookTitle)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("(\(resultCount))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - No Results View

struct NoSearchResultsView: View {
    let hasSearched: Bool
    let query: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasSearched ? "magnifyingglass" : "sparkle.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            if hasSearched {
                Text("No results for \"\(query)\"")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("Try different keywords or expand your search scope")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Search Your Library")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("Enter a query to find conceptually related content across your books")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
    }
}

// MARK: - Search Stats Banner

struct SearchStatsBanner: View {
    let stats: SearchResultStats

    var body: some View {
        HStack(spacing: 16) {
            StatItem(
                icon: "doc.text.magnifyingglass",
                value: "\(stats.totalResults)",
                label: "Results"
            )

            Divider()
                .frame(height: 24)

            StatItem(
                icon: "books.vertical",
                value: "\(stats.booksSearched)",
                label: "Books"
            )

            Divider()
                .frame(height: 24)

            StatItem(
                icon: "chart.bar",
                value: stats.formattedAverageRelevance,
                label: "Avg. Match"
            )

            if stats.hybridMatches > 0 {
                Divider()
                    .frame(height: 24)

                StatItem(
                    icon: "sparkle.magnifyingglass",
                    value: "\(stats.hybridMatches)",
                    label: "Best"
                )
            }
        }
        .font(.caption)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.1))
        }
    }
}

private struct StatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .fontWeight(.semibold)
                Text(label)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Indexing Progress View

struct IndexingProgressView: View {
    let progress: IndexingProgress

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .foregroundStyle(.secondary)

                Text("Indexing for semantic search...")
                    .font(.subheadline)

                Spacer()

                Text("\(progress.progressPercentage)%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress.progress)
                .progressViewStyle(.linear)

            HStack {
                Text("Page \(progress.currentPage) of \(progress.totalPages)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer()

                Text("\(progress.chunksProcessed) chunks")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.controlBackgroundColor))
        }
    }
}

// MARK: - Index Status Badge

struct IndexStatusBadge: View {
    let status: IndexingStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
            Text(status.displayName)
        }
        .font(.caption)
        .foregroundStyle(statusColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .fill(statusColor.opacity(0.15))
        }
    }

    private var statusColor: Color {
        switch status {
        case .notStarted: return .secondary
        case .inProgress: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }
}

// MARK: - Previews

#Preview("Search Result Card") {
    VStack(spacing: 12) {
        SearchResultCard(
            result: HybridSearchResult(
                bookID: UUID(),
                bookTitle: "Introduction to Islamic Finance",
                text: "The concept of riba (usury) is strictly prohibited in Islamic law. This prohibition extends to all forms of interest-based transactions, including conventional banking practices.",
                pageNumber: 42,
                relevanceScore: 0.85,
                matchType: .hybrid
            ),
            onTap: {}
        )

        SearchResultCard(
            result: HybridSearchResult(
                bookID: UUID(),
                bookTitle: "Principles of Fiqh",
                text: "The five pillars of Islam form the foundation of Muslim life. These are: Shahada (declaration of faith), Salat (prayer), Zakat (almsgiving), Sawm (fasting), and Hajj (pilgrimage).",
                pageNumber: 15,
                relevanceScore: 0.62,
                matchType: .semantic
            ),
            onTap: {}
        )
    }
    .padding()
    .frame(width: 400)
}

#Preview("No Results") {
    NoSearchResultsView(hasSearched: true, query: "quantum physics")
        .frame(width: 400, height: 300)
}

#Preview("Stats Banner") {
    SearchStatsBanner(stats: SearchResultStats(
        totalResults: 24,
        semanticMatches: 12,
        keywordMatches: 8,
        hybridMatches: 4,
        booksSearched: 3,
        averageRelevance: 0.72
    ))
    .padding()
}
