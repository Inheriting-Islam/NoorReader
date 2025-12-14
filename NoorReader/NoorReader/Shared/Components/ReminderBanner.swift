// ReminderBanner.swift
// NoorReader
//
// Islamic reminder display components with support for different reminder types

import SwiftUI

// MARK: - Launch Dua Banner

struct LaunchDuaBanner: View {
    @Binding var isPresented: Bool

    private let dua = IslamicReminder.launchDua

    var body: some View {
        VStack(spacing: 0) {
            banner
            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.easeOut(duration: 0.5), value: isPresented)
    }

    private var banner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                // Arabic text
                Text(dua.arabic)
                    .font(.system(size: 24, weight: .medium, design: .serif))
                    .foregroundStyle(Color.noorGold)

                // Transliteration
                Text(dua.transliteration)
                    .font(.subheadline)
                    .italic()
                    .foregroundStyle(.white.opacity(0.8))

                // English translation
                Text("\"\(dua.english)\"")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))

                // Source
                Text("— \(dua.source)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            // Dismiss button
            Button(action: {
                withAnimation {
                    isPresented = false
                }
            }) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(8)
                    .background(Circle().fill(.white.opacity(0.1)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            LinearGradient(
                colors: [Color.noorTeal, Color.noorTeal.opacity(0.9)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

// MARK: - Enhanced Reminder Banner

struct ReminderBanner: View {
    let reminder: IslamicReminder
    let onDismiss: () -> Void
    let onSave: (() -> Void)?

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Main content
            VStack(spacing: 12) {
                // Type indicator
                HStack {
                    Image(systemName: reminder.type.icon)
                        .foregroundStyle(reminder.type.color)

                    Text(reminder.type.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                // Arabic text
                Text(reminder.arabic)
                    .font(.title2)
                    .fontDesign(.serif)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                // Transliteration (collapsible)
                if isExpanded && !reminder.transliteration.isEmpty {
                    Text(reminder.transliteration)
                        .font(.subheadline)
                        .italic()
                        .foregroundStyle(.secondary)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // English translation
                Text(reminder.english)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                // Source
                if !reminder.source.isEmpty {
                    Text("— \(reminder.source)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(20)

            // Action bar
            HStack {
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Label(
                        isExpanded ? "Less" : "More",
                        systemImage: isExpanded ? "chevron.up" : "chevron.down"
                    )
                    .font(.caption)
                }
                .buttonStyle(.plain)

                Spacer()

                if let onSave {
                    Button {
                        onSave()
                    } label: {
                        Label("Save", systemImage: "bookmark")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: 500)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - ReminderType Extensions

extension IslamicReminder.ReminderType {
    var icon: String {
        switch self {
        case .dua: return "hands.sparkles"
        case .hadith: return "quote.opening"
        case .ayah: return "book.closed"
        case .reminder: return "bell"
        }
    }

    var color: Color {
        switch self {
        case .dua: return .noorTeal
        case .hadith: return .noorGold
        case .ayah: return .green
        case .reminder: return .orange
        }
    }

    var displayName: String {
        switch self {
        case .dua: return "Dua"
        case .hadith: return "Hadith"
        case .ayah: return "Quran"
        case .reminder: return "Reminder"
        }
    }
}

// MARK: - Daily Reminder Widget (for sidebar)

struct DailyReminderWidget: View {
    @State private var reminder: IslamicReminder = .sampleHadith
    @State private var isFavorite = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "book.closed")
                    .foregroundStyle(Color.noorGold)
                Text("Daily Reminder")
                    .font(.headline)
                Spacer()
            }

            Divider()

            // Arabic (if available and not too long)
            if !reminder.arabic.isEmpty && reminder.arabic.count < 100 {
                Text(reminder.arabic)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // English translation
            Text(reminder.english)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Source
            HStack {
                Text("— \(reminder.source)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer()

                // Favorite button
                Button(action: { isFavorite.toggle() }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? .red : .secondary)
                }
                .buttonStyle(.plain)

                // Share button
                Button(action: { shareReminder() }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func shareReminder() {
        let text = "\(reminder.arabic)\n\n\"\(reminder.english)\"\n\n— \(reminder.source)"
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

// MARK: - Floating Reminder Overlay

struct FloatingReminderOverlay: View {
    let reminder: IslamicReminder
    let onDismiss: () -> Void

    @State private var opacity: Double = 0
    @State private var offset: CGFloat = 50

    var body: some View {
        VStack {
            Spacer()

            ReminderBanner(
                reminder: reminder,
                onDismiss: onDismiss,
                onSave: nil
            )
            .padding()
            .opacity(opacity)
            .offset(y: offset)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                opacity = 1
                offset = 0
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        LaunchDuaBanner(isPresented: .constant(true))

        ReminderBanner(
            reminder: .sampleHadith,
            onDismiss: {},
            onSave: {}
        )
        .padding()

        DailyReminderWidget()
            .padding()
            .frame(width: 300)
    }
}
