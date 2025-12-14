// ThemeService.swift
// NoorReader
//
// Theme management service for reading modes

import SwiftUI
import AppKit

// MARK: - Theme Enum

enum ReadingTheme: String, CaseIterable, Identifiable, Codable {
    case day
    case sepia
    case night
    case auto

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .day: return "Day"
        case .sepia: return "Sepia"
        case .night: return "Night"
        case .auto: return "Auto"
        }
    }

    var icon: String {
        switch self {
        case .day: return "sun.max"
        case .sepia: return "book"
        case .night: return "moon"
        case .auto: return "circle.lefthalf.filled"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .day: return .dayBackground
        case .sepia: return .sepiaBackground
        case .night: return .nightBackground
        case .auto:
            return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? .nightBackground
                : .dayBackground
        }
    }

    var textColor: Color {
        switch self {
        case .day: return .dayText
        case .sepia: return .sepiaText
        case .night: return .nightText
        case .auto:
            return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? .nightText
                : .dayText
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .day: return .daySecondary
        case .sepia: return .sepiaSecondary
        case .night: return .nightSecondary
        case .auto:
            return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? .nightSecondary
                : .daySecondary
        }
    }
}

// MARK: - Theme Service

@MainActor
@Observable
final class ThemeService {
    static let shared = ThemeService()

    private(set) var currentTheme: ReadingTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "readingTheme")
        }
    }

    private init() {
        if let savedTheme = UserDefaults.standard.string(forKey: "readingTheme"),
           let theme = ReadingTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .auto
        }
    }

    func setTheme(_ theme: ReadingTheme) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = theme
        }
    }

    func cycleTheme() {
        let themes = ReadingTheme.allCases
        guard let currentIndex = themes.firstIndex(of: currentTheme) else { return }
        let nextIndex = (currentIndex + 1) % themes.count
        setTheme(themes[nextIndex])
    }
}
