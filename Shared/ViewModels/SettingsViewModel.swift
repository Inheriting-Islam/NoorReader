// SettingsViewModel.swift
// NoorReader
//
// User preferences state management

import SwiftUI

@MainActor
@Observable
final class SettingsViewModel {
    // MARK: - Appearance

    var readingTheme: ReadingTheme {
        get { ThemeService.shared.currentTheme }
        set { ThemeService.shared.setTheme(newValue) }
    }

    // MARK: - Islamic Features

    var showLaunchDua: Bool {
        didSet {
            UserDefaults.standard.set(showLaunchDua, forKey: "showLaunchDua")
        }
    }

    var showPrayerTimes: Bool {
        didSet {
            UserDefaults.standard.set(showPrayerTimes, forKey: "showPrayerTimes")
        }
    }

    var prayerCalculationMethod: Int {
        didSet {
            UserDefaults.standard.set(prayerCalculationMethod, forKey: "prayerCalculationMethod")
        }
    }

    // MARK: - Reader Settings

    var defaultDisplayMode: PDFDisplayModeOption {
        didSet {
            UserDefaults.standard.set(defaultDisplayMode.rawValue, forKey: "defaultDisplayMode")
        }
    }

    var rememberLastPage: Bool {
        didSet {
            UserDefaults.standard.set(rememberLastPage, forKey: "rememberLastPage")
        }
    }

    // MARK: - Book Style Effects

    var bookStyleEffectsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(bookStyleEffectsEnabled, forKey: "bookStyleEffectsEnabled")
        }
    }

    var pageTurnAnimationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(pageTurnAnimationsEnabled, forKey: "pageTurnAnimationsEnabled")
        }
    }

    var paperTextureEnabled: Bool {
        didSet {
            UserDefaults.standard.set(paperTextureEnabled, forKey: "paperTextureEnabled")
        }
    }

    // MARK: - Initialization

    init() {
        self.showLaunchDua = UserDefaults.standard.object(forKey: "showLaunchDua") as? Bool ?? true
        self.showPrayerTimes = UserDefaults.standard.object(forKey: "showPrayerTimes") as? Bool ?? true
        self.prayerCalculationMethod = UserDefaults.standard.integer(forKey: "prayerCalculationMethod")
        if prayerCalculationMethod == 0 { prayerCalculationMethod = 2 } // Default to ISNA

        let displayModeRaw = UserDefaults.standard.integer(forKey: "defaultDisplayMode")
        self.defaultDisplayMode = PDFDisplayModeOption(rawValue: displayModeRaw) ?? .continuous

        self.rememberLastPage = UserDefaults.standard.object(forKey: "rememberLastPage") as? Bool ?? true

        // Book style effects - default to enabled
        self.bookStyleEffectsEnabled = UserDefaults.standard.object(forKey: "bookStyleEffectsEnabled") as? Bool ?? true
        self.pageTurnAnimationsEnabled = UserDefaults.standard.object(forKey: "pageTurnAnimationsEnabled") as? Bool ?? true
        self.paperTextureEnabled = UserDefaults.standard.object(forKey: "paperTextureEnabled") as? Bool ?? true
    }
}

// MARK: - PDF Display Mode Option

enum PDFDisplayModeOption: Int, CaseIterable, Identifiable {
    case singlePage = 0
    case continuous = 1
    case twoUp = 2
    case twoUpContinuous = 3

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .singlePage: return "Single Page"
        case .continuous: return "Continuous"
        case .twoUp: return "Two Pages"
        case .twoUpContinuous: return "Two Pages Continuous"
        }
    }
}

// MARK: - Prayer Calculation Methods

struct PrayerMethod: Identifiable {
    let id: Int
    let name: String
}

let prayerCalculationMethods: [PrayerMethod] = [
    PrayerMethod(id: 1, name: "University of Islamic Sciences, Karachi"),
    PrayerMethod(id: 2, name: "Islamic Society of North America (ISNA)"),
    PrayerMethod(id: 3, name: "Muslim World League"),
    PrayerMethod(id: 4, name: "Umm Al-Qura University, Makkah"),
    PrayerMethod(id: 5, name: "Egyptian General Authority of Survey"),
    PrayerMethod(id: 7, name: "Institute of Geophysics, University of Tehran"),
    PrayerMethod(id: 8, name: "Gulf Region"),
    PrayerMethod(id: 9, name: "Kuwait"),
    PrayerMethod(id: 10, name: "Qatar"),
    PrayerMethod(id: 11, name: "Majlis Ugama Islam Singapura"),
    PrayerMethod(id: 12, name: "Union Organization Islamic de France"),
    PrayerMethod(id: 13, name: "Diyanet Isleri Baskanligi, Turkey"),
    PrayerMethod(id: 14, name: "Spiritual Administration of Muslims of Russia")
]
