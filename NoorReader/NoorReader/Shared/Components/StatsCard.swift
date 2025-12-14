// StatsCard.swift
// NoorReader
//
// Stat display cards for the study dashboard

import SwiftUI

/// A card displaying a single statistic
struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .blue
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// A larger stat card with more emphasis
struct LargeStatsCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .blue
    var trend: Trend? = nil

    enum Trend {
        case up(String)
        case down(String)
        case neutral(String)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Spacer()

                if let trend {
                    trendBadge(trend)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func trendBadge(_ trend: Trend) -> some View {
        let (icon, text, color): (String, String, Color) = {
            switch trend {
            case .up(let value):
                return ("arrow.up", value, .green)
            case .down(let value):
                return ("arrow.down", value, .red)
            case .neutral(let value):
                return ("minus", value, .secondary)
            }
        }()

        HStack(spacing: 2) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption2)
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

/// A row of mini stats
struct MiniStatsRow: View {
    let stats: [(String, String, String)]  // (icon, value, label)

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(stats.enumerated()), id: \.offset) { index, stat in
                if index > 0 {
                    Divider()
                        .frame(height: 30)
                }

                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: stat.0)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(stat.1)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    Text(stat.2)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Card count badges for flashcard states
struct CardCountBadges: View {
    let newCount: Int
    let learningCount: Int
    let dueCount: Int

    var body: some View {
        HStack(spacing: 12) {
            countBadge(count: newCount, label: "New", color: .blue)
            countBadge(count: learningCount, label: "Learning", color: .orange)
            countBadge(count: dueCount, label: "Due", color: .green)
        }
    }

    private func countBadge(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview("Stats Cards") {
    VStack(spacing: 16) {
        HStack(spacing: 16) {
            StatsCard(
                title: "Total Time",
                value: "12h 30m",
                icon: "clock",
                color: .blue
            )

            StatsCard(
                title: "Cards Reviewed",
                value: "156",
                icon: "rectangle.on.rectangle",
                color: .green
            )
        }

        LargeStatsCard(
            title: "Current Streak",
            value: "7 days",
            icon: "flame.fill",
            color: .orange,
            trend: .up("+2")
        )

        MiniStatsRow(stats: [
            ("book", "42", "Pages"),
            ("highlighter", "18", "Highlights"),
            ("rectangle.on.rectangle", "25", "Cards")
        ])

        CardCountBadges(
            newCount: 10,
            learningCount: 5,
            dueCount: 15
        )
    }
    .padding()
    .frame(width: 400)
}
