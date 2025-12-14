// ReadingInsightsView.swift
// NoorReader
//
// Comprehensive reading analytics dashboard

import SwiftUI
import SwiftData
import Charts

struct ReadingInsightsView: View {
    @Bindable var viewModel: InsightsViewModel

    @State private var selectedTab: InsightsTab = .overview
    @State private var isRefreshing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                insightsHeader

                // Time range picker
                timeRangePicker

                // Tab picker
                tabPicker

                // Content based on selected tab
                switch selectedTab {
                case .overview:
                    overviewSection
                case .reading:
                    readingStatsSection
                case .learning:
                    learningStatsSection
                case .achievements:
                    achievementsSection
                }
            }
            .padding()
        }
        .background(Color(.windowBackgroundColor))
        .task {
            await viewModel.loadAnalytics()
        }
    }

    // MARK: - Header

    private var insightsHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Reading Insights")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Track your learning journey")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Refresh button
            Button {
                Task {
                    isRefreshing = true
                    await viewModel.refreshData()
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
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        Picker("Time Range", selection: $viewModel.selectedTimeRange) {
            ForEach(TimeRange.allCases) { range in
                Text(range.displayName).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(InsightsTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                        Text(tab.title)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                    .foregroundStyle(selectedTab == tab ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.controlBackgroundColor))
        }
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        VStack(spacing: 20) {
            // Key metrics
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MetricCard(
                    title: "Total Study Time",
                    value: viewModel.totalStudyHours,
                    icon: "clock.fill",
                    color: .blue
                )

                MetricCard(
                    title: "Reading Speed",
                    value: viewModel.readingSpeedDescription,
                    icon: "speedometer",
                    color: .green
                )

                MetricCard(
                    title: "Retention Rate",
                    value: "\(viewModel.retentionRatePercent)%",
                    icon: "brain.head.profile",
                    color: .purple
                )

                MetricCard(
                    title: "Completion",
                    value: "\(viewModel.completionRatePercent)%",
                    icon: "checkmark.circle.fill",
                    color: .orange
                )
            }

            // Weekly activity chart
            weeklyActivityChart

            // Activity heatmap
            if let heatmap = viewModel.heatmapData {
                activityHeatmap(heatmap)
            }

            // Insights and suggestions
            if let report = viewModel.weeklyReport {
                insightsCard(report)
            }
        }
    }

    // MARK: - Reading Stats Section

    private var readingStatsSection: some View {
        VStack(spacing: 20) {
            // Speed over time chart
            if !viewModel.velocityChartData.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Reading Speed Over Time")
                        .font(.headline)

                    Chart(viewModel.velocityChartData, id: \.date) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Pages/Hour", item.value)
                        )
                        .foregroundStyle(.blue)

                        AreaMark(
                            x: .value("Date", item.date),
                            y: .value("Pages/Hour", item.value)
                        )
                        .foregroundStyle(.blue.opacity(0.1))
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.month().day())
                        }
                    }
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.controlBackgroundColor))
                }
            }

            // Reading patterns
            HStack(spacing: 16) {
                PatternCard(
                    title: "Most Productive Time",
                    value: viewModel.mostProductiveHour,
                    icon: "clock.fill"
                )

                PatternCard(
                    title: "Most Productive Day",
                    value: viewModel.mostProductiveDay,
                    icon: "calendar"
                )
            }

            // Book completion estimates
            if !viewModel.bookCompletionEstimates.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Estimated Completion Dates")
                        .font(.headline)

                    ForEach(viewModel.bookCompletionEstimates, id: \.bookID) { estimate in
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundStyle(.secondary)

                            Text("Book")  // Would show actual book title
                                .font(.callout)

                            Spacer()

                            Text(estimate.estimatedDate, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.controlBackgroundColor))
                }
            }
        }
    }

    // MARK: - Learning Stats Section

    private var learningStatsSection: some View {
        VStack(spacing: 20) {
            // Flashcard stats
            if let analytics = viewModel.analytics {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    LearningMetricCard(
                        title: "Flashcards Created",
                        value: "\(analytics.flashcardsCreated)",
                        subtitle: "Total cards",
                        icon: "rectangle.stack.fill"
                    )

                    LearningMetricCard(
                        title: "Reviews Completed",
                        value: "\(analytics.flashcardsReviewed)",
                        subtitle: "All time",
                        icon: "checkmark.circle.fill"
                    )

                    LearningMetricCard(
                        title: "Retention Rate",
                        value: "\(viewModel.retentionRatePercent)%",
                        subtitle: "Success rate",
                        icon: "brain"
                    )

                    LearningMetricCard(
                        title: "Weekly Growth",
                        value: "+\(Int(analytics.knowledgeGrowthRate))",
                        subtitle: "Cards mastered",
                        icon: "arrow.up.right"
                    )
                }

                // Annotation stats
                VStack(alignment: .leading, spacing: 12) {
                    Text("Annotation Activity")
                        .font(.headline)

                    HStack(spacing: 20) {
                        VStack {
                            Text("\(analytics.totalHighlights)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Highlights")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Divider()
                            .frame(height: 40)

                        VStack {
                            Text("\(analytics.totalNotes)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Notes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Divider()
                            .frame(height: 40)

                        VStack {
                            Text(String(format: "%.1f", analytics.highlightsPerBook))
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Per Book")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.controlBackgroundColor))
                }
            }
        }
    }

    // MARK: - Achievements Section

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.headline)

            if viewModel.achievements.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "trophy")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)

                    Text("No achievements yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("Keep studying to earn achievements!")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.controlBackgroundColor))
                }
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(viewModel.achievements) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
            }
        }
    }

    // MARK: - Weekly Activity Chart

    private var weeklyActivityChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("This Week")
                    .font(.headline)

                Spacer()

                Text(viewModel.weeklyComparisonText)
                    .font(.caption)
                    .foregroundStyle(viewModel.weeklyComparisonIsPositive ? .green : .red)
            }

            if !viewModel.weeklyActivityData.isEmpty {
                Chart(viewModel.weeklyActivityData, id: \.day) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Minutes", item.minutes)
                    )
                    .foregroundStyle(Color.accentColor)
                    .cornerRadius(4)
                }
                .frame(height: 150)
            } else {
                Text("No data for this week")
                    .foregroundStyle(.secondary)
                    .frame(height: 150)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        }
    }

    // MARK: - Activity Heatmap

    private func activityHeatmap(_ data: ActivityHeatmapData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Heatmap")
                .font(.headline)

            HStack(alignment: .top, spacing: 2) {
                // Day labels
                VStack(alignment: .trailing, spacing: 2) {
                    ForEach(["", "Mon", "", "Wed", "", "Fri", ""], id: \.self) { day in
                        Text(day)
                            .font(.caption2)
                            .frame(height: 12)
                    }
                }
                .frame(width: 30)

                // Heatmap grid
                VStack(spacing: 2) {
                    // Hour labels
                    HStack(spacing: 2) {
                        ForEach([0, 6, 12, 18, 23], id: \.self) { hour in
                            Text("\(hour)")
                                .font(.caption2)
                                .frame(width: 12)
                            if hour < 23 {
                                Spacer()
                            }
                        }
                    }

                    ForEach(0..<7, id: \.self) { day in
                        HStack(spacing: 2) {
                            ForEach(0..<24, id: \.self) { hour in
                                Rectangle()
                                    .fill(heatmapColor(intensity: data.intensity(day: day, hour: hour)))
                                    .frame(width: 12, height: 12)
                                    .cornerRadius(2)
                            }
                        }
                    }
                }
            }

            // Legend
            HStack {
                Text("Less")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { intensity in
                    Rectangle()
                        .fill(heatmapColor(intensity: intensity))
                        .frame(width: 12, height: 12)
                        .cornerRadius(2)
                }

                Text("More")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        }
    }

    private func heatmapColor(intensity: Double) -> Color {
        if intensity == 0 {
            return Color.secondary.opacity(0.1)
        }
        return Color.green.opacity(0.2 + intensity * 0.8)
    }

    // MARK: - Insights Card

    private func insightsCard(_ report: WeeklyReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.headline)

            ForEach(report.insights, id: \.self) { insight in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text(insight)
                        .font(.callout)
                }
            }

            Divider()

            Text("Suggestions")
                .font(.subheadline)
                .fontWeight(.medium)

            ForEach(report.suggestions, id: \.self) { suggestion in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(.blue)
                    Text(suggestion)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        }
    }
}

// MARK: - Insights Tab

enum InsightsTab: String, CaseIterable, Identifiable {
    case overview
    case reading
    case learning
    case achievements

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .reading: return "Reading"
        case .learning: return "Learning"
        case .achievements: return "Achievements"
        }
    }

    var icon: String {
        switch self {
        case .overview: return "chart.pie.fill"
        case .reading: return "book.fill"
        case .learning: return "brain.head.profile"
        case .achievements: return "trophy.fill"
        }
    }
}

// MARK: - Supporting Views

private struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        }
    }
}

private struct PatternCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        }
    }
}

private struct LearningMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.purple)
                Spacer()
            }

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .fontWeight(.medium)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        }
    }
}

private struct AchievementCard: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.type.icon)
                .font(.title)
                .foregroundStyle(achievementColor)

            Text(achievement.title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)

            Text(achievement.description)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(achievementColor.opacity(0.1))
        }
    }

    private var achievementColor: Color {
        switch achievement.type {
        case .streak: return .orange
        case .pages: return .blue
        case .flashcards: return .purple
        case .books: return .green
        case .time: return .indigo
        case .consistency: return .teal
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = InsightsViewModel()

    return ReadingInsightsView(viewModel: viewModel)
        .frame(width: 800, height: 800)
}
