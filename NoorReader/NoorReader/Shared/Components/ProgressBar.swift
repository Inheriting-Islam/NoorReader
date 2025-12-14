// ProgressBar.swift
// NoorReader
//
// Reading progress indicator

import SwiftUI

struct ReadingProgressBar: View {
    let progress: Double
    var height: CGFloat = 4
    var showPercentage: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: height)

                    // Progress fill
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color.noorTeal)
                        .frame(width: geometry.size.width * CGFloat(progress), height: height)
                }
            }
            .frame(height: height)

            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// Interactive progress scrubber for reader
struct ProgressScrubber: View {
    @Binding var currentPage: Int
    let totalPages: Int
    var onPageChange: ((Int) -> Void)?

    @State private var isDragging = false
    @State private var dragProgress: Double = 0

    private var progress: Double {
        guard totalPages > 0 else { return 0 }
        return Double(currentPage) / Double(totalPages - 1)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)

                // Progress fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.noorTeal)
                    .frame(width: geometry.size.width * CGFloat(isDragging ? dragProgress : progress), height: 4)

                // Thumb
                Circle()
                    .fill(Color.noorTeal)
                    .frame(width: 12, height: 12)
                    .offset(x: geometry.size.width * CGFloat(isDragging ? dragProgress : progress) - 6)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let newProgress = max(0, min(1, value.location.x / geometry.size.width))
                        dragProgress = newProgress
                    }
                    .onEnded { value in
                        isDragging = false
                        let newProgress = max(0, min(1, value.location.x / geometry.size.width))
                        let newPage = Int(round(newProgress * Double(totalPages - 1)))
                        currentPage = newPage
                        onPageChange?(newPage)
                    }
            )
        }
        .frame(height: 12)
    }
}

#Preview {
    VStack(spacing: 32) {
        ReadingProgressBar(progress: 0.45)
        ReadingProgressBar(progress: 0.75, showPercentage: true)
        ProgressScrubber(currentPage: .constant(45), totalPages: 100)
    }
    .padding()
    .frame(width: 300)
}
