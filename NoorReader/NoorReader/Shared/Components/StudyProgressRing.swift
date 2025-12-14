// StudyProgressRing.swift
// NoorReader
//
// Circular progress indicator for study goals

import SwiftUI

/// Circular progress ring for displaying goal progress
struct StudyProgressRing: View {
    let progress: Double
    let goal: Int
    let current: Int
    let label: String
    var color: Color = .blue
    var lineWidth: CGFloat = 12
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            // Center content
            VStack(spacing: 4) {
                Text("\(current)")
                    .font(.system(size: size / 3, weight: .bold, design: .rounded))

                Text("/ \(goal) \(label)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}

/// Compact progress ring for smaller displays
struct CompactProgressRing: View {
    let progress: Double
    var color: Color = .blue
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 4)

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)

            // Percentage
            Text("\(Int(progress * 100))%")
                .font(.system(size: size / 4, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
    }
}

/// Daily goal progress with time display
struct DailyGoalProgressView: View {
    let currentMinutes: Int
    let goalMinutes: Int

    var progress: Double {
        guard goalMinutes > 0 else { return 0 }
        return Double(currentMinutes) / Double(goalMinutes)
    }

    var isComplete: Bool {
        currentMinutes >= goalMinutes
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Progress ring
                StudyProgressRing(
                    progress: progress,
                    goal: goalMinutes,
                    current: currentMinutes,
                    label: "min",
                    color: isComplete ? .green : .blue,
                    size: 140
                )

                // Completion checkmark
                if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(.green)
                        .offset(x: 50, y: -50)
                }
            }

            // Status text
            if isComplete {
                Text("Goal Complete!")
                    .font(.headline)
                    .foregroundStyle(.green)
            } else {
                let remaining = goalMinutes - currentMinutes
                Text("\(remaining) min remaining")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview("Progress Rings") {
    VStack(spacing: 40) {
        StudyProgressRing(
            progress: 0.75,
            goal: 30,
            current: 22,
            label: "min"
        )

        DailyGoalProgressView(
            currentMinutes: 25,
            goalMinutes: 30
        )

        HStack(spacing: 20) {
            CompactProgressRing(progress: 0.33, color: .orange)
            CompactProgressRing(progress: 0.66, color: .blue)
            CompactProgressRing(progress: 1.0, color: .green)
        }
    }
    .padding()
}
