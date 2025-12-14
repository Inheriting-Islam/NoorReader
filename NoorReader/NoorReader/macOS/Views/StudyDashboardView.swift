// StudyDashboardView.swift
// NoorReader
//
// Main statistics dashboard view

import SwiftUI
import Charts

/// Main statistics dashboard view
struct StudyDashboardView: View {
    @Bindable var viewModel: StatsViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showGoalSettings = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Top row: Streak and Daily Goal
                HStack(spacing: 20) {
                    streakCard
                    dailyGoalCard
                }

                // Weekly Activity Chart
                if !viewModel.weeklyActivity.isEmpty {
                    WeeklyActivityChart(
                        weeklyActivity: viewModel.weeklyActivity,
                        goalMinutes: viewModel.streak?.dailyGoalMinutes ?? 30
                    )
                }

                // Flashcard Stats
                flashcardStatsSection

                // Stats Grid
                statsGrid

                // Recent Sessions
                recentSessionsSection
            }
            .padding()
        }
        .navigationTitle("Study Dashboard")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showGoalSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showGoalSettings) {
            GoalSettingsSheet(viewModel: viewModel)
        }
        .task {
            viewModel.configure(modelContext: modelContext)
            await viewModel.loadStats()
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("Current Streak")
                    .font(.headline)
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(viewModel.streak?.currentStreak ?? 0)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                Text("days")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            if let streak = viewModel.streak, streak.longestStreak > 0 {
                Text("Longest: \(streak.longestStreak) days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Daily Goal Card

    private var dailyGoalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .foregroundStyle(.green)
                Text("Daily Goal")
                    .font(.headline)

                Spacer()

                if let streak = viewModel.streak, streak.hasMetDailyGoal {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            if let streak = viewModel.streak {
                DailyGoalProgressView(
                    currentMinutes: streak.todayMinutes,
                    goalMinutes: streak.dailyGoalMinutes
                )
            } else {
                Text("No data")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Flashcard Stats

    private var flashcardStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Flashcards")
                .font(.headline)

            HStack(spacing: 16) {
                CardCountBadges(
                    newCount: viewModel.newCards,
                    learningCount: viewModel.learningCards,
                    dueCount: viewModel.dueCards
                )
            }

            HStack(spacing: 12) {
                StatsCard(
                    title: "Total Cards",
                    value: "\(viewModel.totalCards)",
                    icon: "rectangle.stack",
                    color: .blue
                )

                StatsCard(
                    title: "Mastered",
                    value: "\(viewModel.masteredCards)",
                    icon: "checkmark.seal.fill",
                    color: .green
                )

                StatsCard(
                    title: "Reviewed This Week",
                    value: "\(viewModel.cardsReviewedThisWeek)",
                    icon: "arrow.clockwise",
                    color: .purple
                )
            }
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Study Time")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatsCard(
                    title: "Today",
                    value: viewModel.todayStudyTime,
                    icon: "clock",
                    color: .blue
                )

                StatsCard(
                    title: "This Week",
                    value: viewModel.thisWeekStudyTime,
                    icon: "calendar",
                    color: .orange
                )

                StatsCard(
                    title: "Total",
                    value: viewModel.totalStudyTime,
                    icon: "hourglass",
                    color: .purple
                )

                StatsCard(
                    title: "Avg Session",
                    value: viewModel.averageSessionLength,
                    icon: "timer",
                    color: .green
                )

                StatsCard(
                    title: "Pages This Week",
                    value: "\(viewModel.pagesReadThisWeek)",
                    icon: "book.pages",
                    color: .cyan
                )

                StatsCard(
                    title: "Total Pages",
                    value: "\(viewModel.streak?.totalPagesRead ?? 0)",
                    icon: "books.vertical",
                    color: .indigo
                )
            }
        }
    }

    // MARK: - Recent Sessions

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.headline)

            if viewModel.recentSessions.isEmpty {
                Text("No sessions yet. Start studying to see your history!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.recentSessions.prefix(5), id: \.id) { session in
                        SessionRow(session: session)
                    }
                }
            }
        }
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: StudySession

    var body: some View {
        HStack {
            Image(systemName: session.type.icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.bookTitle ?? session.type.displayName)
                    .font(.subheadline)

                Text(session.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(session.formattedDuration)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    if session.flashcardsReviewed > 0 {
                        Label("\(session.flashcardsReviewed)", systemImage: "rectangle.on.rectangle")
                    }
                    if session.pagesRead > 0 {
                        Label("\(session.pagesRead)", systemImage: "book")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Goal Settings Sheet

struct GoalSettingsSheet: View {
    @Bindable var viewModel: StatsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var dailyGoalMinutes: Double = 30
    @State private var weeklyGoalDays: Double = 5

    var body: some View {
        VStack(spacing: 24) {
            Text("Study Goals")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                Text("Daily Goal")
                    .font(.headline)

                HStack {
                    Slider(value: $dailyGoalMinutes, in: 5...120, step: 5)

                    Text("\(Int(dailyGoalMinutes)) min")
                        .font(.subheadline)
                        .frame(width: 60)
                }

                Text("Study for at least \(Int(dailyGoalMinutes)) minutes each day")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Weekly Goal")
                    .font(.headline)

                HStack {
                    Slider(value: $weeklyGoalDays, in: 1...7, step: 1)

                    Text("\(Int(weeklyGoalDays)) days")
                        .font(.subheadline)
                        .frame(width: 60)
                }

                Text("Study on at least \(Int(weeklyGoalDays)) days per week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack {
                Button("Cancel") {
                    dismiss()
                }

                Spacer()

                Button("Save") {
                    viewModel.updateDailyGoal(minutes: Int(dailyGoalMinutes))
                    viewModel.updateWeeklyGoal(days: Int(weeklyGoalDays))
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 350)
        .onAppear {
            if let streak = viewModel.streak {
                dailyGoalMinutes = Double(streak.dailyGoalMinutes)
                weeklyGoalDays = Double(streak.weeklyGoalDays)
            }
        }
    }
}

#Preview {
    StudyDashboardView(viewModel: StatsViewModel())
}
