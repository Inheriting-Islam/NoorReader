// WeeklyActivityChart.swift
// NoorReader
//
// Charts showing weekly study activity

import SwiftUI
import Charts

/// Bar chart showing daily study time for the week
struct WeeklyActivityChart: View {
    let weeklyActivity: [DayActivity]
    let goalMinutes: Int

    var maxMinutes: Int {
        max(goalMinutes, weeklyActivity.map(\.minutes).max() ?? 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)

            Chart(weeklyActivity) { day in
                BarMark(
                    x: .value("Day", day.dayName),
                    y: .value("Minutes", day.minutes)
                )
                .foregroundStyle(barColor(for: day))
                .cornerRadius(4)

                // Goal line
                RuleMark(y: .value("Goal", goalMinutes))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    if let minutes = value.as(Int.self) {
                        AxisValueLabel {
                            Text("\(minutes)m")
                                .font(.caption2)
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                }
            }
            .frame(height: 150)

            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text("Goal met")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                    Text("In progress")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("Goal: \(goalMinutes)m")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func barColor(for day: DayActivity) -> Color {
        if day.minutes >= goalMinutes {
            return .green
        } else if day.minutes > 0 {
            return .blue
        } else {
            return .secondary.opacity(0.3)
        }
    }
}

/// Compact activity indicator using small blocks
struct CompactActivityIndicator: View {
    let weeklyActivity: [DayActivity]
    let goalMinutes: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(weeklyActivity) { day in
                VStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(activityColor(for: day))
                        .frame(width: 20, height: 20)

                    Text(day.shortDayName)
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func activityColor(for day: DayActivity) -> Color {
        let intensity = min(1.0, Double(day.minutes) / Double(max(1, goalMinutes)))

        if day.minutes >= goalMinutes {
            return .green
        } else if day.minutes > 0 {
            return .blue.opacity(0.3 + intensity * 0.7)
        } else {
            return .secondary.opacity(0.15)
        }
    }
}

/// Activity heatmap calendar (for longer periods)
struct ActivityHeatmap: View {
    let activityData: [Date: Int]  // Date to minutes mapping
    let weeks: Int = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(12), spacing: 2), count: 7), spacing: 2) {
                ForEach(getDates(), id: \.self) { date in
                    let minutes = activityData[Calendar.current.startOfDay(for: date)] ?? 0
                    Rectangle()
                        .fill(heatmapColor(for: minutes))
                        .frame(width: 12, height: 12)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                        .help("\(formattedDate(date)): \(minutes) min")
                }
            }

            // Legend
            HStack(spacing: 4) {
                Text("Less")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                ForEach([0, 15, 30, 45, 60], id: \.self) { level in
                    Rectangle()
                        .fill(heatmapColor(for: level))
                        .frame(width: 10, height: 10)
                        .clipShape(RoundedRectangle(cornerRadius: 1))
                }

                Text("More")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func getDates() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        var dates: [Date] = []

        for offset in (0..<(weeks * 7)).reversed() {
            if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
                dates.append(date)
            }
        }

        return dates
    }

    private func heatmapColor(for minutes: Int) -> Color {
        switch minutes {
        case 0:
            return Color.secondary.opacity(0.15)
        case 1..<15:
            return Color.green.opacity(0.25)
        case 15..<30:
            return Color.green.opacity(0.45)
        case 30..<45:
            return Color.green.opacity(0.65)
        case 45..<60:
            return Color.green.opacity(0.85)
        default:
            return Color.green
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview("Weekly Activity") {
    VStack(spacing: 20) {
        WeeklyActivityChart(
            weeklyActivity: [
                DayActivity(date: Date().addingTimeInterval(-6 * 86400), minutes: 25, flashcardsReviewed: 10, pagesRead: 5),
                DayActivity(date: Date().addingTimeInterval(-5 * 86400), minutes: 45, flashcardsReviewed: 15, pagesRead: 8),
                DayActivity(date: Date().addingTimeInterval(-4 * 86400), minutes: 30, flashcardsReviewed: 12, pagesRead: 6),
                DayActivity(date: Date().addingTimeInterval(-3 * 86400), minutes: 0, flashcardsReviewed: 0, pagesRead: 0),
                DayActivity(date: Date().addingTimeInterval(-2 * 86400), minutes: 50, flashcardsReviewed: 20, pagesRead: 10),
                DayActivity(date: Date().addingTimeInterval(-1 * 86400), minutes: 35, flashcardsReviewed: 14, pagesRead: 7),
                DayActivity(date: Date(), minutes: 20, flashcardsReviewed: 8, pagesRead: 4)
            ],
            goalMinutes: 30
        )

        CompactActivityIndicator(
            weeklyActivity: [
                DayActivity(date: Date().addingTimeInterval(-6 * 86400), minutes: 25, flashcardsReviewed: 0, pagesRead: 0),
                DayActivity(date: Date().addingTimeInterval(-5 * 86400), minutes: 45, flashcardsReviewed: 0, pagesRead: 0),
                DayActivity(date: Date().addingTimeInterval(-4 * 86400), minutes: 30, flashcardsReviewed: 0, pagesRead: 0),
                DayActivity(date: Date().addingTimeInterval(-3 * 86400), minutes: 0, flashcardsReviewed: 0, pagesRead: 0),
                DayActivity(date: Date().addingTimeInterval(-2 * 86400), minutes: 50, flashcardsReviewed: 0, pagesRead: 0),
                DayActivity(date: Date().addingTimeInterval(-1 * 86400), minutes: 35, flashcardsReviewed: 0, pagesRead: 0),
                DayActivity(date: Date(), minutes: 20, flashcardsReviewed: 0, pagesRead: 0)
            ],
            goalMinutes: 30
        )
    }
    .padding()
    .frame(width: 400)
}
