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

    var showLaunchDua: Bool = true {
        didSet {
            UserDefaults.standard.set(showLaunchDua, forKey: "showLaunchDua")
        }
    }

    var showPrayerTimes: Bool = true {
        didSet {
            UserDefaults.standard.set(showPrayerTimes, forKey: "showPrayerTimes")
        }
    }

    var prayerCalculationMethod: Int = 2 {
        didSet {
            UserDefaults.standard.set(prayerCalculationMethod, forKey: "prayerCalculationMethod")
        }
    }

    // MARK: - Reader Settings

    var defaultDisplayMode: PDFDisplayModeOption = .continuous {
        didSet {
            UserDefaults.standard.set(defaultDisplayMode.rawValue, forKey: "defaultDisplayMode")
        }
    }

    var rememberLastPage: Bool = true {
        didSet {
            UserDefaults.standard.set(rememberLastPage, forKey: "rememberLastPage")
        }
    }

    // MARK: - Book Style Effects

    var bookStyleEffectsEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(bookStyleEffectsEnabled, forKey: "bookStyleEffectsEnabled")
        }
    }

    var pageTurnAnimationsEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(pageTurnAnimationsEnabled, forKey: "pageTurnAnimationsEnabled")
        }
    }

    var paperTextureEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(paperTextureEnabled, forKey: "paperTextureEnabled")
        }
    }

    // MARK: - AI Settings

    var aiEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(aiEnabled, forKey: "aiEnabled")
        }
    }

    var aiProvider: AIProvider = .cloud {
        didSet {
            UserDefaults.standard.set(aiProvider.rawValue, forKey: "aiProvider")
        }
    }

    var claudeAPIKey: String = "" {
        didSet {
            // In production, use Keychain instead of UserDefaults
            if !claudeAPIKey.isEmpty {
                UserDefaults.standard.set(claudeAPIKey, forKey: "claudeAPIKey")
            } else {
                UserDefaults.standard.removeObject(forKey: "claudeAPIKey")
            }
        }
    }

    var aiSummarizationEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(aiSummarizationEnabled, forKey: "aiSummarizationEnabled")
        }
    }

    var aiExplainEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(aiExplainEnabled, forKey: "aiExplainEnabled")
        }
    }

    var aiFlashcardsEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(aiFlashcardsEnabled, forKey: "aiFlashcardsEnabled")
        }
    }

    var aiSemanticSearchEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(aiSemanticSearchEnabled, forKey: "aiSemanticSearchEnabled")
        }
    }

    // MARK: - Initialization

    init() {
        // Load persisted values from UserDefaults
        showLaunchDua = UserDefaults.standard.object(forKey: "showLaunchDua") as? Bool ?? true
        showPrayerTimes = UserDefaults.standard.object(forKey: "showPrayerTimes") as? Bool ?? true

        let storedMethod = UserDefaults.standard.integer(forKey: "prayerCalculationMethod")
        prayerCalculationMethod = storedMethod == 0 ? 2 : storedMethod // Default to ISNA

        let displayModeRaw = UserDefaults.standard.integer(forKey: "defaultDisplayMode")
        defaultDisplayMode = PDFDisplayModeOption(rawValue: displayModeRaw) ?? .continuous

        rememberLastPage = UserDefaults.standard.object(forKey: "rememberLastPage") as? Bool ?? true

        // Book style effects - default to enabled
        bookStyleEffectsEnabled = UserDefaults.standard.object(forKey: "bookStyleEffectsEnabled") as? Bool ?? true
        pageTurnAnimationsEnabled = UserDefaults.standard.object(forKey: "pageTurnAnimationsEnabled") as? Bool ?? true
        paperTextureEnabled = UserDefaults.standard.object(forKey: "paperTextureEnabled") as? Bool ?? true

        // AI settings
        aiEnabled = UserDefaults.standard.object(forKey: "aiEnabled") as? Bool ?? true
        let providerString = UserDefaults.standard.string(forKey: "aiProvider") ?? "cloud"
        aiProvider = AIProvider(rawValue: providerString) ?? .cloud
        claudeAPIKey = UserDefaults.standard.string(forKey: "claudeAPIKey") ?? ""
        aiSummarizationEnabled = UserDefaults.standard.object(forKey: "aiSummarizationEnabled") as? Bool ?? true
        aiExplainEnabled = UserDefaults.standard.object(forKey: "aiExplainEnabled") as? Bool ?? true
        aiFlashcardsEnabled = UserDefaults.standard.object(forKey: "aiFlashcardsEnabled") as? Bool ?? true
        aiSemanticSearchEnabled = UserDefaults.standard.object(forKey: "aiSemanticSearchEnabled") as? Bool ?? true
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
