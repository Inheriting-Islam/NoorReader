// ReviewRatingButtons.swift
// NoorReader
//
// Rating buttons for flashcard review

import SwiftUI

/// Rating buttons for flashcard review
struct ReviewRatingButtons: View {
    let intervalPreviews: [ReviewQuality: String]
    let onRate: (ReviewQuality) -> Void

    var body: some View {
        HStack(spacing: 12) {
            ForEach(ReviewQuality.allCases) { quality in
                ratingButton(quality)
            }
        }
    }

    @ViewBuilder
    private func ratingButton(_ quality: ReviewQuality) -> some View {
        Button {
            onRate(quality)
        } label: {
            VStack(spacing: 4) {
                Text(intervalPreviews[quality] ?? "")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(quality.displayName)
                    .font(.headline)

                Text(quality.shortcut)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(qualityColor(quality).opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .keyboardShortcut(KeyEquivalent(Character(quality.shortcut)), modifiers: [])
    }

    private func qualityColor(_ quality: ReviewQuality) -> Color {
        switch quality {
        case .again: return .red
        case .hard: return .orange
        case .good: return .green
        case .easy: return .blue
        }
    }
}

// MARK: - Compact Rating Buttons

struct CompactRatingButtons: View {
    let onRate: (ReviewQuality) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ReviewQuality.allCases) { quality in
                Button {
                    onRate(quality)
                } label: {
                    Text(quality.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(qualityColor(quality).opacity(0.15))
                        .foregroundStyle(qualityColor(quality))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func qualityColor(_ quality: ReviewQuality) -> Color {
        switch quality {
        case .again: return .red
        case .hard: return .orange
        case .good: return .green
        case .easy: return .blue
        }
    }
}

// MARK: - Simple Rating Buttons (for quick review)

struct SimpleRatingButtons: View {
    let onKnew: () -> Void
    let onDidNotKnow: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button {
                onDidNotKnow()
            } label: {
                Label("Didn't Know", systemImage: "xmark.circle")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.15))
                    .foregroundStyle(.red)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .keyboardShortcut("1", modifiers: [])

            Button {
                onKnew()
            } label: {
                Label("Knew It", systemImage: "checkmark.circle")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.15))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .keyboardShortcut("3", modifiers: [])
        }
    }
}

#Preview("Rating Buttons") {
    VStack(spacing: 40) {
        ReviewRatingButtons(
            intervalPreviews: [
                .again: "<1m",
                .hard: "10m",
                .good: "1d",
                .easy: "4d"
            ],
            onRate: { _ in }
        )
        .padding()

        CompactRatingButtons(onRate: { _ in })
            .padding()

        SimpleRatingButtons(onKnew: {}, onDidNotKnow: {})
            .padding()
    }
    .frame(width: 500)
}
