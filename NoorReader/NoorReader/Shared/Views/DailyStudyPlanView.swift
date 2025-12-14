// DailyStudyPlanView.swift
// NoorReader
//
// Daily study plan overview with AI recommendations

import SwiftUI
import SwiftData

struct DailyStudyPlanView: View {
    @Bindable var viewModel: RecommendationsViewModel
    let onStartReview: ([UUID]) -> Void
    let onNavigateToBook: (UUID, Int) -> Void

    @State private var selectedSection: PlanSection = .flashcards
    @State private var isRefreshing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Motivational header
                motivationalHeader

                // Prayer time suggestion (if available)
                if let prayer = viewModel.prayerSuggestion {
                    prayerTimeBanner(prayer)
                }

                // Plan summary
                planSummaryCard

                // Section picker
                sectionPicker

                // Content based on selection
                switch selectedSection {
                case .flashcards:
                    flashcardsSection
                case .reading:
                    readingSection
                case .weakAreas:
                    weakAreasSection
                }
            }
            .padding()
        }
        .background(Color(.windowBackgroundColor))
        .task {
            if !viewModel.hasPlan {
                await viewModel.loadPlan()
            }
        }
    }

    // MARK: - Motivational Header

    private var motivationalHeader: some View {
        VStack(spacing: 12) {
            // Date and greeting
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Date(), style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Your Study Plan")
                        .font(.title)
                        .fontWeight(.bold)
                }

                Spacer()

                // Refresh button
                Button {
                    Task {
                        isRefreshing = true
                        await viewModel.refreshPlan()
                        isRefreshing = false
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                }
                .buttonStyle(.borderless)
                .disabled(isRefreshing || viewModel.isLoading)
            }

            // Motivational message
            Text(viewModel.motivationalMessage)
                .font(.callout)
                .italic()
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.accentColor.opacity(0.1))
                }
        }
    }

    // MARK: - Prayer Time Banner

    private func prayerTimeBanner(_ suggestion: PrayerTimeStudySuggestion) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "moon.stars")
                .font(.title2)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.suggestedActivity.displayName)
                    .font(.headline)

                Text(suggestion.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(suggestion.nextPrayer)
                    .font(.caption)
                    .fontWeight(.medium)

                Text("in \(Int(suggestion.timeUntilPrayer / 60)) min")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        }
    }

    // MARK: - Plan Summary

    private var planSummaryCard: some View {
        HStack(spacing: 20) {
            // Estimated time
            SummaryItem(
                icon: "clock",
                value: viewModel.estimatedStudyTime,
                label: "Est. Time",
                color: .blue
            )

            Divider()
                .frame(height: 40)

            // Cards to review
            SummaryItem(
                icon: "rectangle.on.rectangle",
                value: "\(viewModel.totalRecommendedCards)",
                label: "Cards",
                color: viewModel.criticalCount > 0 ? .red : .green
            )

            Divider()
                .frame(height: 40)

            // Reading suggestions
            SummaryItem(
                icon: "book",
                value: "\(viewModel.readingSuggestions.count)",
                label: "Reading",
                color: .purple
            )

            Divider()
                .frame(height: 40)

            // Focus areas
            SummaryItem(
                icon: "target",
                value: "\(viewModel.focusAreas.count)",
                label: "Focus Areas",
                color: .orange
            )
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        }
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {
        Picker("Section", selection: $selectedSection) {
            ForEach(PlanSection.allCases) { section in
                Label(section.title, systemImage: section.icon)
                    .tag(section)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Flashcards Section

    private var flashcardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Priority filter
            HStack {
                Text("Flashcards to Review")
                    .font(.headline)

                Spacer()

                // Quick action buttons
                if viewModel.criticalCount > 0 {
                    Button {
                        let ids = viewModel.getFlashcardIDs(for: .critical)
                        onStartReview(ids)
                    } label: {
                        Label("Review Critical", systemImage: "exclamationmark.circle.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }

                Button {
                    let ids = viewModel.getFlashcardIDs()
                    onStartReview(ids)
                } label: {
                    Label("Start Review", systemImage: "play.fill")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
            }

            // Priority badges
            HStack(spacing: 8) {
                PriorityBadge(
                    priority: .critical,
                    count: viewModel.criticalCount,
                    isSelected: viewModel.selectedPriority == .critical
                ) {
                    viewModel.filterByPriority(viewModel.selectedPriority == .critical ? nil : .critical)
                }

                PriorityBadge(
                    priority: .high,
                    count: viewModel.highPriorityCount,
                    isSelected: viewModel.selectedPriority == .high
                ) {
                    viewModel.filterByPriority(viewModel.selectedPriority == .high ? nil : .high)
                }

                PriorityBadge(
                    priority: .normal,
                    count: viewModel.normalCount,
                    isSelected: viewModel.selectedPriority == .normal
                ) {
                    viewModel.filterByPriority(viewModel.selectedPriority == .normal ? nil : .normal)
                }

                Spacer()

                if viewModel.selectedPriority != nil {
                    Button("Clear Filter") {
                        viewModel.clearFilters()
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }

            // Flashcard list
            if viewModel.flashcardRecommendations.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "All Caught Up!",
                    message: "No urgent flashcards to review right now."
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.flashcardRecommendations) { recommendation in
                        FlashcardRecommendationCard(recommendation: recommendation) {
                            onStartReview([recommendation.flashcardID])
                        }
                    }
                }

                if viewModel.totalRecommendedCards > 10 && !viewModel.showAllFlashcards {
                    Button {
                        viewModel.toggleShowAllFlashcards()
                    } label: {
                        Text("Show all \(viewModel.totalRecommendedCards) cards")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                }
            }
        }
    }

    // MARK: - Reading Section

    private var readingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Suggested Reading")
                .font(.headline)

            if viewModel.readingSuggestions.isEmpty {
                EmptyStateView(
                    icon: "book.closed",
                    title: "No Reading Suggestions",
                    message: "Keep studying to get personalized reading recommendations."
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.readingSuggestions) { suggestion in
                        ReadingSuggestionCard(suggestion: suggestion) {
                            onNavigateToBook(suggestion.bookID, suggestion.pageRange.lowerBound)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Weak Areas Section

    private var weakAreasSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Areas Needing Attention")
                .font(.headline)

            if viewModel.weakAreas.isEmpty {
                EmptyStateView(
                    icon: "star.fill",
                    title: "Great Performance!",
                    message: "No significant weak areas detected. Keep up the excellent work!"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.weakAreas) { area in
                        WeakAreaCard(weakArea: area)
                    }
                }
            }

            // Focus areas from plan
            if !viewModel.focusAreas.isEmpty {
                Text("Recommended Focus")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.top, 8)

                LazyVStack(spacing: 8) {
                    ForEach(viewModel.focusAreas) { area in
                        FocusAreaRow(focusArea: area)
                    }
                }
            }
        }
    }
}

// MARK: - Plan Section

enum PlanSection: String, CaseIterable, Identifiable {
    case flashcards
    case reading
    case weakAreas

    var id: String { rawValue }

    var title: String {
        switch self {
        case .flashcards: return "Flashcards"
        case .reading: return "Reading"
        case .weakAreas: return "Focus Areas"
        }
    }

    var icon: String {
        switch self {
        case .flashcards: return "rectangle.on.rectangle"
        case .reading: return "book"
        case .weakAreas: return "target"
        }
    }
}

// MARK: - Supporting Views

private struct SummaryItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct PriorityBadge: View {
    let priority: FlashcardRecommendation.ReviewPriority
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(priority.displayName)
                Text("(\(count))")
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                Capsule()
                    .fill(badgeColor.opacity(isSelected ? 0.3 : 0.1))
            }
            .overlay {
                Capsule()
                    .stroke(isSelected ? badgeColor : .clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(count == 0)
        .opacity(count == 0 ? 0.5 : 1)
    }

    private var badgeColor: Color {
        switch priority {
        case .critical: return .red
        case .high: return .orange
        case .normal: return .blue
        case .optional: return .gray
        }
    }
}

private struct FlashcardRecommendationCard: View {
    let recommendation: FlashcardRecommendation
    let onReview: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Priority indicator
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.front)
                    .font(.callout)
                    .lineLimit(2)

                HStack {
                    if let book = recommendation.bookTitle {
                        Text(book)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(recommendation.reason)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Button {
                onReview()
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.controlBackgroundColor))
        }
    }

    private var priorityColor: Color {
        switch recommendation.priority {
        case .critical: return .red
        case .high: return .orange
        case .normal: return .blue
        case .optional: return .gray
        }
    }
}

private struct ReadingSuggestionCard: View {
    let suggestion: ReadingSuggestion
    let onNavigate: () -> Void

    var body: some View {
        Button(action: onNavigate) {
            HStack(spacing: 12) {
                Image(systemName: "book.fill")
                    .font(.title2)
                    .foregroundStyle(.purple)
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.bookTitle)
                        .font(.headline)

                    Text(suggestion.pageRangeDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(suggestion.reason)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("~\(suggestion.estimatedMinutes)m")
                        .font(.caption)
                        .fontWeight(.medium)

                    Image(systemName: "chevron.right")
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
        .buttonStyle(.plain)
    }
}

private struct WeakAreaCard: View {
    let weakArea: WeakArea

    var body: some View {
        HStack(spacing: 12) {
            // Severity indicator
            Circle()
                .fill(severityColor)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(weakArea.topic)
                    .font(.headline)

                HStack {
                    Text("Failure rate: \(Int(weakArea.failureRate * 100))%")
                    Text("•")
                    Text("\(weakArea.flashcardCount) cards")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Retention gauge
            CircularProgressView(progress: 1.0 - weakArea.failureRate)
                .frame(width: 40, height: 40)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.controlBackgroundColor))
        }
    }

    private var severityColor: Color {
        switch weakArea.severity {
        case .high: return .red
        case .medium: return .orange
        case .low: return .yellow
        }
    }
}

private struct FocusAreaRow: View {
    let focusArea: FocusArea

    var body: some View {
        HStack {
            Image(systemName: "target")
                .foregroundStyle(.orange)

            Text(focusArea.topic)
                .font(.callout)

            Spacer()

            Text("\(focusArea.reviewsNeeded) reviews needed")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.orange.opacity(0.1))
        }
    }
}

private struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 4)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(progressColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .fontWeight(.medium)
        }
    }

    private var progressColor: Color {
        if progress >= 0.7 { return .green }
        if progress >= 0.5 { return .orange }
        return .red
    }
}

private struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(.green)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = RecommendationsViewModel()

    return DailyStudyPlanView(
        viewModel: viewModel,
        onStartReview: { _ in },
        onNavigateToBook: { _, _ in }
    )
    .frame(width: 600, height: 700)
}
