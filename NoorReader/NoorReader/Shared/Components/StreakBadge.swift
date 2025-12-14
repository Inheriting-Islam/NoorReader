// StreakBadge.swift
// NoorReader
//
// Streak display badges and indicators

import SwiftUI

/// Displays the current streak with fire icon
struct StreakBadge: View {
    let currentStreak: Int
    let longestStreak: Int
    var size: BadgeSize = .regular

    enum BadgeSize {
        case compact
        case regular
        case large

        var iconSize: CGFloat {
            switch self {
            case .compact: return 16
            case .regular: return 24
            case .large: return 40
            }
        }

        var numberFont: Font {
            switch self {
            case .compact: return .headline
            case .regular: return .title
            case .large: return .system(size: 48, weight: .bold, design: .rounded)
            }
        }

        var labelFont: Font {
            switch self {
            case .compact: return .caption2
            case .regular: return .caption
            case .large: return .subheadline
            }
        }
    }

    var body: some View {
        VStack(spacing: size == .large ? 8 : 4) {
            HStack(spacing: 4) {
                Image(systemName: currentStreak > 0 ? "flame.fill" : "flame")
                    .font(.system(size: size.iconSize))
                    .foregroundStyle(currentStreak > 0 ? .orange : .secondary)
                    .symbolEffect(.bounce, value: currentStreak)

                Text("\(currentStreak)")
                    .font(size.numberFont)
                    .fontWeight(.bold)
            }

            if size != .compact {
                Text(currentStreak == 1 ? "day streak" : "day streak")
                    .font(size.labelFont)
                    .foregroundStyle(.secondary)
            }

            if size == .large && longestStreak > currentStreak {
                Text("Best: \(longestStreak) days")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

/// Inline streak indicator
struct InlineStreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: streak > 0 ? "flame.fill" : "flame")
                .foregroundStyle(streak > 0 ? .orange : .secondary)

            Text("\(streak)")
                .fontWeight(.semibold)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(streak > 0 ? Color.orange.opacity(0.1) : Color.secondary.opacity(0.1))
        .clipShape(Capsule())
    }
}

/// Weekly streak indicator showing which days have been completed
struct WeeklyStreakView: View {
    let weeklyActivity: [DayActivity]
    let goalMinutes: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(weeklyActivity) { day in
                VStack(spacing: 4) {
                    Circle()
                        .fill(dayColor(for: day))
                        .frame(width: 24, height: 24)
                        .overlay {
                            if day.minutes >= goalMinutes {
                                Image(systemName: "checkmark")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                        }

                    Text(day.shortDayName)
                        .font(.caption2)
                        .foregroundStyle(day.isToday ? .primary : .secondary)
                }
            }
        }
    }

    private func dayColor(for day: DayActivity) -> Color {
        if day.minutes >= goalMinutes {
            return .green
        } else if day.minutes > 0 {
            return .orange.opacity(0.6)
        } else {
            return .secondary.opacity(0.2)
        }
    }
}

/// Achievement badge for streaks
struct StreakAchievementBadge: View {
    let milestone: Int
    let isAchieved: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isAchieved ? Color.orange : Color.secondary.opacity(0.2))
                    .frame(width: 50, height: 50)

                if isAchieved {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: "flame")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }

            Text("\(milestone)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(isAchieved ? .primary : .secondary)

            Text("days")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}

/// Row of streak milestone badges
struct StreakMilestonesView: View {
    let currentStreak: Int
    let milestones = [7, 14, 30, 60, 100]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Milestones")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                ForEach(milestones, id: \.self) { milestone in
                    StreakAchievementBadge(
                        milestone: milestone,
                        isAchieved: currentStreak >= milestone
                    )
                }
            }
        }
    }
}

#Preview("Streak Badges") {
    VStack(spacing: 30) {
        HStack(spacing: 20) {
            StreakBadge(currentStreak: 0, longestStreak: 5, size: .compact)
            StreakBadge(currentStreak: 7, longestStreak: 14, size: .compact)
        }

        StreakBadge(currentStreak: 7, longestStreak: 14, size: .regular)

        StreakBadge(currentStreak: 21, longestStreak: 30, size: .large)

        InlineStreakBadge(streak: 5)

        StreakMilestonesView(currentStreak: 21)
    }
    .padding()
}
