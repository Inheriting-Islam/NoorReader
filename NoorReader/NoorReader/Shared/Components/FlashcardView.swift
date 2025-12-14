// FlashcardView.swift
// NoorReader
//
// Displays a single flashcard with flip animation

import SwiftUI

/// Displays a single flashcard with flip animation
struct FlashcardView: View {
    let flashcard: Flashcard
    let isFlipped: Bool
    let onFlip: () -> Void

    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Back (Answer)
            cardFace(
                content: flashcard.back,
                label: "Answer",
                icon: "lightbulb.fill",
                color: .green
            )
            .rotation3DEffect(.degrees(rotation + 180), axis: (x: 0, y: 1, z: 0))
            .opacity(isFlipped ? 1 : 0)

            // Front (Question)
            cardFace(
                content: flashcard.front,
                label: "Question",
                icon: "questionmark.circle.fill",
                color: .blue
            )
            .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
            .opacity(isFlipped ? 0 : 1)
        }
        .onChange(of: isFlipped) { _, flipped in
            withAnimation(.easeInOut(duration: 0.4)) {
                rotation = flipped ? 180 : 0
            }
        }
        .onTapGesture {
            onFlip()
        }
    }

    @ViewBuilder
    private func cardFace(
        content: String,
        label: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()

                // State badge
                stateBadge
            }

            Divider()

            // Content
            ScrollView {
                Text(content)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            Spacer()

            // Source info
            if let page = flashcard.sourcePageNumber {
                HStack {
                    Image(systemName: "book.pages")
                        .font(.caption2)
                    Text("Page \(page)")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }

            // Flip hint
            if !isFlipped {
                Text("Tap or press Space to reveal answer")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }

    private var stateBadge: some View {
        let state = flashcard.state

        return HStack(spacing: 4) {
            Image(systemName: state.icon)
            Text(state.displayName)
        }
        .font(.caption2)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(stateColor(for: state).opacity(0.2))
        .clipShape(Capsule())
    }

    private func stateColor(for state: FlashcardState) -> Color {
        switch state {
        case .new: return .blue
        case .learning: return .orange
        case .review: return .green
        case .relearning: return .red
        }
    }
}

// MARK: - Compact Flashcard View

struct CompactFlashcardView: View {
    let flashcard: Flashcard
    let showAnswer: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Question
            Text(flashcard.front)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(3)

            if showAnswer {
                Divider()

                // Answer
                Text(flashcard.back)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            // Footer
            HStack {
                stateBadge
                Spacer()
                Text(flashcard.formattedDueDate)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var stateBadge: some View {
        let state = flashcard.state

        return HStack(spacing: 4) {
            Circle()
                .fill(stateColor(for: state))
                .frame(width: 6, height: 6)
            Text(state.displayName)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func stateColor(for state: FlashcardState) -> Color {
        switch state {
        case .new: return .blue
        case .learning: return .orange
        case .review: return .green
        case .relearning: return .red
        }
    }
}

#Preview("Flashcard View") {
    FlashcardView(
        flashcard: Flashcard(
            front: "What is the capital of France?",
            back: "Paris",
            sourcePageNumber: 42
        ),
        isFlipped: false,
        onFlip: {}
    )
    .frame(width: 400, height: 300)
    .padding()
}
