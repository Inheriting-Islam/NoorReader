// FocusModeView.swift
// NoorReader
//
// Distraction-free reading mode

import SwiftUI
import PDFKit

/// Focus mode wrapper for distraction-free reading
struct FocusModeView: View {
    let book: Book
    @Bindable var readerViewModel: ReaderViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showControls = true
    @State private var controlsTimer: Timer?
    @State private var pomodoroTimer = PomodoroTimer()
    @State private var showTimer = false

    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea()

            // PDF content (centered)
            VStack {
                if let document = readerViewModel.document {
                    FocusPDFView(
                        document: document,
                        currentPage: $readerViewModel.currentPage
                    )
                    .frame(maxWidth: 800)
                    .padding(.vertical, 40)
                }
            }

            // Controls overlay
            if showControls {
                focusControlsOverlay
                    .transition(.opacity)
            }

            // Timer overlay (top right)
            if showTimer {
                VStack {
                    HStack {
                        Spacer()
                        CompactTimerView(timer: pomodoroTimer)
                            .padding()
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            pomodoroTimer.loadSettings()
            scheduleHideControls()
        }
        .onDisappear {
            controlsTimer?.invalidate()
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showControls.toggle()
            }
            if showControls {
                scheduleHideControls()
            }
        }
        .onHover { hovering in
            if hovering {
                withAnimation {
                    showControls = true
                }
                scheduleHideControls()
            }
        }
    }

    // MARK: - Controls Overlay

    private var focusControlsOverlay: some View {
        VStack {
            // Top bar
            HStack {
                // Exit button
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])

                Spacer()

                // Title
                Text(book.title)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)

                Spacer()

                // Timer toggle
                Button {
                    withAnimation {
                        showTimer.toggle()
                        if showTimer && !pomodoroTimer.isRunning {
                            pomodoroTimer.start()
                        }
                    }
                } label: {
                    Image(systemName: showTimer ? "timer.circle.fill" : "timer.circle")
                        .font(.title)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [.black.opacity(0.8), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            Spacer()

            // Bottom bar
            HStack {
                // Page info
                Text("Page \(readerViewModel.currentPage + 1) of \(book.totalPages)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))

                Spacer()

                // Navigation
                HStack(spacing: 20) {
                    Button {
                        readerViewModel.previousPage()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.leftArrow, modifiers: [])
                    .disabled(readerViewModel.currentPage <= 0)

                    Button {
                        readerViewModel.nextPage()
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.rightArrow, modifiers: [])
                    .disabled(readerViewModel.currentPage >= book.totalPages - 1)
                }

                Spacer()

                // Progress
                Text("\(book.progressPercentage)%")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private func scheduleHideControls() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls = false
            }
        }
    }
}

/// Simplified PDF view for focus mode
struct FocusPDFView: NSViewRepresentable {
    let document: PDFDocument
    @Binding var currentPage: Int

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.displayMode = .singlePage
        pdfView.autoScales = true
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .black

        // Navigate to current page
        if let page = document.page(at: currentPage) {
            pdfView.go(to: page)
        }

        // Add page change observer
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )

        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        // Update page if changed externally
        if let page = document.page(at: currentPage),
           pdfView.currentPage != page {
            pdfView.go(to: page)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: FocusPDFView

        init(_ parent: FocusPDFView) {
            self.parent = parent
        }

        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let currentPage = pdfView.currentPage,
                  let pageIndex = pdfView.document?.index(for: currentPage) else {
                return
            }

            DispatchQueue.main.async {
                self.parent.currentPage = pageIndex
            }
        }
    }
}

/// Focus mode launch button
struct FocusModeButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Focus Mode", systemImage: "eye")
        }
        .help("Enter distraction-free reading mode")
    }
}

/// Break reminder overlay
struct BreakReminderOverlay: View {
    let onTakeBreak: () -> Void
    let onDismiss: () -> Void

    @State private var breakDua = IslamicReminder.breakReminders.randomElement() ?? IslamicReminder.breakReminders[0]

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Time for a Break")
                .font(.title)
                .fontWeight(.bold)

            Text("You've been studying for a while. Take a moment to rest your eyes and stretch.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Islamic reminder
            VStack(spacing: 8) {
                Text(breakDua.arabic)
                    .font(.title3)

                Text(breakDua.english)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 16) {
                Button("Skip") {
                    onDismiss()
                }

                Button("Take Break") {
                    onTakeBreak()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(40)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 20)
    }
}

/// Islamic reminders for breaks
extension IslamicReminder {
    static let breakReminders = [
        IslamicReminder(
            id: UUID(),
            type: .dua,
            arabic: "رَبِّ زِدْنِي عِلْمًا",
            transliteration: "Rabbi zidni ilma",
            english: "My Lord, increase me in knowledge",
            source: "Quran 20:114",
            category: "break_reminder"
        ),
        IslamicReminder(
            id: UUID(),
            type: .dua,
            arabic: "اللَّهُمَّ انْفَعْنِي بِمَا عَلَّمْتَنِي",
            transliteration: "Allahumma infa'ni bima 'allamtani",
            english: "O Allah, benefit me with what You have taught me",
            source: "Hadith",
            category: "break_reminder"
        ),
        IslamicReminder(
            id: UUID(),
            type: .reminder,
            arabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
            transliteration: "Subhan Allahi wa bihamdihi",
            english: "Glory be to Allah and His is the praise",
            source: "Dhikr",
            category: "break_reminder"
        )
    ]
}

// Note: FocusModeView preview requires a fully configured ReaderViewModel

#Preview("Break Reminder") {
    BreakReminderOverlay(
        onTakeBreak: {},
        onDismiss: {}
    )
    .frame(width: 500, height: 400)
}
