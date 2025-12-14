// FlashcardReviewView.swift
// NoorReader
//
// Main flashcard study view

import SwiftUI

/// Main flashcard study view
struct FlashcardReviewView: View {
    @Bindable var viewModel: FlashcardViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            if viewModel.isLoading {
                loadingView
            } else if viewModel.hasCardsRemaining {
                studyView
            } else {
                completionView
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color(.windowBackgroundColor))
        .onKeyPress { press in
            if viewModel.handleKeyPress(press.key) {
                return .handled
            }
            return .ignored
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            // Card counts
            HStack(spacing: 16) {
                countBadge(count: viewModel.newCount, label: "New", color: .blue)
                countBadge(count: viewModel.learningCount, label: "Learning", color: .orange)
                countBadge(count: viewModel.dueCount, label: "Due", color: .green)
            }

            Spacer()

            // Session info
            HStack(spacing: 8) {
                Image(systemName: "clock")
                Text(viewModel.formattedSessionDuration)
                    .monospacedDigit()

                Divider()
                    .frame(height: 16)

                Image(systemName: "checkmark.circle")
                Text("\(viewModel.cardsReviewedCount) reviewed")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()

            // Close button
            Button {
                viewModel.endSession()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding()
    }

    private func countBadge(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.headline)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 60)
    }

    // MARK: - Study View

    private var studyView: some View {
        VStack(spacing: 24) {
            // Progress
            ProgressView(value: Double(viewModel.currentCardIndex), total: Double(viewModel.studyQueue.count))
                .padding(.horizontal)

            Text("\(viewModel.remainingCards) cards remaining")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Current card
            if let card = viewModel.currentCard {
                FlashcardView(
                    flashcard: card,
                    isFlipped: viewModel.isFlipped,
                    onFlip: { viewModel.flipCard() }
                )
                .frame(maxWidth: 500, maxHeight: 350)
                .padding()

                // Rating buttons (only show when flipped)
                if viewModel.isFlipped {
                    ReviewRatingButtons(
                        intervalPreviews: viewModel.intervalPreviews
                    ) { quality in
                        Task {
                            await viewModel.rateCard(quality)
                        }
                    }
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            Spacer()
        }
        .animation(.easeInOut, value: viewModel.isFlipped)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading flashcards...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Session Complete!")
                .font(.title)

            VStack(spacing: 8) {
                Text("\(viewModel.cardsReviewedCount) cards reviewed")
                Text("Time: \(viewModel.formattedSessionDuration)")
                if viewModel.cardsReviewedCount > 0 {
                    Text("Average: \(String(format: "%.1f", viewModel.averageTimePerCard))s per card")
                }
            }
            .foregroundStyle(.secondary)

            // Islamic completion message
            VStack(spacing: 8) {
                Text("جَزَاكَ ٱللَّٰهُ خَيْرًا")
                    .font(.title2)
                Text("May Allah reward you for your effort")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top)

            HStack(spacing: 16) {
                Button("Study More") {
                    Task {
                        await viewModel.startStudySession(for: viewModel.currentBook)
                    }
                }

                Button("Done") {
                    viewModel.endSession()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Flashcard Review Sheet

struct FlashcardReviewSheet: View {
    let book: Book?
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = FlashcardViewModel()

    var body: some View {
        FlashcardReviewView(viewModel: viewModel)
            .task {
                await viewModel.startStudySession(for: book)
            }
    }
}

// MARK: - Empty State View

struct NoFlashcardsView: View {
    let book: Book?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.on.rectangle.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Flashcards Due")
                .font(.title2)

            if let book {
                Text("Create flashcards from highlights in \"\(book.title)\" to start studying.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else {
                Text("Create flashcards from your highlights to start studying.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(minWidth: 400, minHeight: 300)
        .padding()
    }
}

#Preview {
    FlashcardReviewView(viewModel: FlashcardViewModel())
}
