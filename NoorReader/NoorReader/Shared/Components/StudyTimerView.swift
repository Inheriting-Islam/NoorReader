// StudyTimerView.swift
// NoorReader
//
// Pomodoro timer for study sessions

import SwiftUI

/// Pomodoro timer states
enum PomodoroState: String, CaseIterable {
    case idle = "idle"
    case working = "working"
    case shortBreak = "shortBreak"
    case longBreak = "longBreak"

    var displayName: String {
        switch self {
        case .idle: return "Ready"
        case .working: return "Focus Time"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }

    var color: Color {
        switch self {
        case .idle: return .secondary
        case .working: return .blue
        case .shortBreak: return .green
        case .longBreak: return .orange
        }
    }
}

/// Observable Pomodoro timer
@MainActor
@Observable
final class PomodoroTimer {
    // MARK: - Settings

    var workDurationMinutes: Int = 25
    var shortBreakMinutes: Int = 5
    var longBreakMinutes: Int = 15
    var pomodorosUntilLongBreak: Int = 4

    // MARK: - State

    var state: PomodoroState = .idle
    var remainingSeconds: Int = 0
    var completedPomodoros: Int = 0
    var isRunning: Bool = false

    private var timer: Timer?

    // MARK: - Computed Properties

    var currentDurationSeconds: Int {
        switch state {
        case .idle: return workDurationMinutes * 60
        case .working: return workDurationMinutes * 60
        case .shortBreak: return shortBreakMinutes * 60
        case .longBreak: return longBreakMinutes * 60
        }
    }

    var progress: Double {
        guard currentDurationSeconds > 0 else { return 0 }
        return 1.0 - (Double(remainingSeconds) / Double(currentDurationSeconds))
    }

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var canStart: Bool {
        state == .idle || !isRunning
    }

    // MARK: - Actions

    func start() {
        if state == .idle {
            state = .working
            remainingSeconds = workDurationMinutes * 60
        }

        isRunning = true
        startTimer()
    }

    func pause() {
        isRunning = false
        stopTimer()
    }

    func reset() {
        stopTimer()
        state = .idle
        remainingSeconds = workDurationMinutes * 60
        isRunning = false
    }

    func skip() {
        stopTimer()
        handlePhaseComplete()
    }

    // MARK: - Timer Logic

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard remainingSeconds > 0 else {
            handlePhaseComplete()
            return
        }

        remainingSeconds -= 1

        if remainingSeconds == 0 {
            handlePhaseComplete()
        }
    }

    private func handlePhaseComplete() {
        stopTimer()
        isRunning = false

        switch state {
        case .working:
            completedPomodoros += 1

            if completedPomodoros % pomodorosUntilLongBreak == 0 {
                state = .longBreak
                remainingSeconds = longBreakMinutes * 60
            } else {
                state = .shortBreak
                remainingSeconds = shortBreakMinutes * 60
            }

        case .shortBreak, .longBreak:
            state = .working
            remainingSeconds = workDurationMinutes * 60

        case .idle:
            break
        }

        // Play notification sound
        NSSound.beep()
    }

    // MARK: - Settings

    func loadSettings() {
        workDurationMinutes = UserDefaults.standard.integer(forKey: "pomodoroWorkMinutes")
        if workDurationMinutes == 0 { workDurationMinutes = 25 }

        shortBreakMinutes = UserDefaults.standard.integer(forKey: "pomodoroShortBreakMinutes")
        if shortBreakMinutes == 0 { shortBreakMinutes = 5 }

        longBreakMinutes = UserDefaults.standard.integer(forKey: "pomodoroLongBreakMinutes")
        if longBreakMinutes == 0 { longBreakMinutes = 15 }

        pomodorosUntilLongBreak = UserDefaults.standard.integer(forKey: "pomodorosUntilLongBreak")
        if pomodorosUntilLongBreak == 0 { pomodorosUntilLongBreak = 4 }

        remainingSeconds = workDurationMinutes * 60
    }

    func saveSettings() {
        UserDefaults.standard.set(workDurationMinutes, forKey: "pomodoroWorkMinutes")
        UserDefaults.standard.set(shortBreakMinutes, forKey: "pomodoroShortBreakMinutes")
        UserDefaults.standard.set(longBreakMinutes, forKey: "pomodoroLongBreakMinutes")
        UserDefaults.standard.set(pomodorosUntilLongBreak, forKey: "pomodorosUntilLongBreak")
    }
}

/// Pomodoro timer view
struct StudyTimerView: View {
    @Bindable var timer: PomodoroTimer
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 24) {
            // State indicator
            Text(timer.state.displayName)
                .font(.headline)
                .foregroundStyle(timer.state.color)

            // Timer ring
            ZStack {
                Circle()
                    .stroke(timer.state.color.opacity(0.2), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: timer.progress)
                    .stroke(
                        timer.state.color,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timer.progress)

                VStack(spacing: 8) {
                    Text(timer.formattedTime)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))

                    // Pomodoro count
                    HStack(spacing: 4) {
                        ForEach(0..<timer.pomodorosUntilLongBreak, id: \.self) { index in
                            Image(systemName: index < timer.completedPomodoros % timer.pomodorosUntilLongBreak || timer.completedPomodoros >= timer.pomodorosUntilLongBreak && timer.completedPomodoros > 0 && index < timer.completedPomodoros % timer.pomodorosUntilLongBreak + (timer.completedPomodoros / timer.pomodorosUntilLongBreak > 0 ? 0 : 0) ? "circle.fill" : "circle")
                                .font(.caption)
                                .foregroundStyle(index < (timer.completedPomodoros % timer.pomodorosUntilLongBreak == 0 && timer.completedPomodoros > 0 ? timer.pomodorosUntilLongBreak : timer.completedPomodoros % timer.pomodorosUntilLongBreak) ? .orange : .secondary)
                        }
                    }
                }
            }
            .frame(width: 200, height: 200)

            // Controls
            HStack(spacing: 20) {
                Button {
                    timer.reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .disabled(timer.state == .idle && !timer.isRunning)

                Button {
                    if timer.isRunning {
                        timer.pause()
                    } else {
                        timer.start()
                    }
                } label: {
                    Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                        .font(.largeTitle)
                        .foregroundStyle(timer.state.color)
                }
                .buttonStyle(.plain)

                Button {
                    timer.skip()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .disabled(timer.state == .idle)
            }

            // Session count
            Text("\(timer.completedPomodoros) pomodoros completed")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Settings button
            Button {
                showSettings = true
            } label: {
                Label("Settings", systemImage: "gearshape")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding()
        .sheet(isPresented: $showSettings) {
            PomodoroSettingsSheet(timer: timer)
        }
        .onAppear {
            timer.loadSettings()
        }
    }
}

/// Compact timer view for toolbar or sidebar
struct CompactTimerView: View {
    @Bindable var timer: PomodoroTimer

    var body: some View {
        HStack(spacing: 8) {
            // Mini progress ring
            ZStack {
                Circle()
                    .stroke(timer.state.color.opacity(0.2), lineWidth: 3)

                Circle()
                    .trim(from: 0, to: timer.progress)
                    .stroke(timer.state.color, lineWidth: 3)
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 24, height: 24)

            Text(timer.formattedTime)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)

            Button {
                if timer.isRunning {
                    timer.pause()
                } else {
                    timer.start()
                }
            } label: {
                Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(timer.state.color.opacity(0.1))
        .clipShape(Capsule())
    }
}

/// Settings sheet for Pomodoro timer
struct PomodoroSettingsSheet: View {
    @Bindable var timer: PomodoroTimer
    @Environment(\.dismiss) private var dismiss

    @State private var workMinutes: Double = 25
    @State private var shortBreakMinutes: Double = 5
    @State private var longBreakMinutes: Double = 15
    @State private var pomodorosCount: Double = 4

    var body: some View {
        VStack(spacing: 24) {
            Text("Pomodoro Settings")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 16) {
                settingRow(
                    title: "Focus Duration",
                    value: $workMinutes,
                    range: 10...60,
                    unit: "min"
                )

                settingRow(
                    title: "Short Break",
                    value: $shortBreakMinutes,
                    range: 1...15,
                    unit: "min"
                )

                settingRow(
                    title: "Long Break",
                    value: $longBreakMinutes,
                    range: 10...30,
                    unit: "min"
                )

                settingRow(
                    title: "Pomodoros until long break",
                    value: $pomodorosCount,
                    range: 2...8,
                    unit: ""
                )
            }

            Spacer()

            HStack {
                Button("Cancel") {
                    dismiss()
                }

                Spacer()

                Button("Save") {
                    timer.workDurationMinutes = Int(workMinutes)
                    timer.shortBreakMinutes = Int(shortBreakMinutes)
                    timer.longBreakMinutes = Int(longBreakMinutes)
                    timer.pomodorosUntilLongBreak = Int(pomodorosCount)
                    timer.saveSettings()
                    timer.reset()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 350, height: 400)
        .onAppear {
            workMinutes = Double(timer.workDurationMinutes)
            shortBreakMinutes = Double(timer.shortBreakMinutes)
            longBreakMinutes = Double(timer.longBreakMinutes)
            pomodorosCount = Double(timer.pomodorosUntilLongBreak)
        }
    }

    private func settingRow(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        unit: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(value.wrappedValue))\(unit.isEmpty ? "" : " \(unit)")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Slider(value: value, in: range, step: 1)
        }
    }
}

#Preview("Pomodoro Timer") {
    StudyTimerView(timer: PomodoroTimer())
        .frame(width: 300, height: 400)
}

#Preview("Compact Timer") {
    CompactTimerView(timer: PomodoroTimer())
        .padding()
}
