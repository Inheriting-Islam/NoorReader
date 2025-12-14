// BookCategory.swift
// NoorReader
//
// SwiftData model for book categories with Islamic categorization

import SwiftData
import Foundation

@Model
final class BookCategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var sortOrder: Int
    var dateCreated: Date

    @Relationship(inverse: \Book.category)
    var books: [Book] = []

    init(name: String, icon: String, colorHex: String = "007AFF", sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.dateCreated = Date()
    }
}

// MARK: - Islamic Categories Definition

enum IslamicCategory: String, CaseIterable {
    case aqeedah = "Aqeedah"
    case quranTafsir = "Quran & Tafsir"
    case hadith = "Hadith Sciences"
    case fiqh = "Fiqh"
    case salahWorship = "Salah & Worship"
    case duaAdhkar = "Dua & Adhkar"
    case seerah = "Seerah"
    case companionsSalaf = "Companions & Salaf"
    case tazkiyah = "Tazkiyah"
    case akhirah = "Akhirah"
    case akhlaq = "Akhlaq & Manners"
    case familyMarriage = "Family & Marriage"
    case knowledge = "Knowledge & Seeking"
    case dawahNewMuslims = "Dawah & New Muslims"
    case history = "History & Civilization"
    case contemporary = "Contemporary Issues"
    case ruqyahProtection = "Ruqyah & Protection"
    case ramadanFasting = "Ramadan & Fasting"
    case hajjUmrah = "Hajj & Umrah"
    case arabicLanguage = "Arabic Language"
    case healthMedicine = "Health & Medicine"
    case uncategorized = "Uncategorized"

    var icon: String {
        switch self {
        case .aqeedah: return "star.circle"
        case .quranTafsir: return "book.closed"
        case .hadith: return "text.book.closed"
        case .fiqh: return "scale.3d"
        case .salahWorship: return "person.and.background.dotted"
        case .duaAdhkar: return "hands.clap"
        case .seerah: return "person.text.rectangle"
        case .companionsSalaf: return "person.3"
        case .tazkiyah: return "heart.circle"
        case .akhirah: return "moon.stars"
        case .akhlaq: return "hand.raised"
        case .familyMarriage: return "house"
        case .knowledge: return "graduationcap"
        case .dawahNewMuslims: return "lightbulb"
        case .history: return "clock.arrow.circlepath"
        case .contemporary: return "globe"
        case .ruqyahProtection: return "shield"
        case .ramadanFasting: return "moon"
        case .hajjUmrah: return "building.columns"
        case .arabicLanguage: return "character.book.closed.ar"
        case .healthMedicine: return "cross.case"
        case .uncategorized: return "folder"
        }
    }

    var colorHex: String {
        switch self {
        case .aqeedah: return "FFD700"           // Gold
        case .quranTafsir: return "228B22"       // Forest Green
        case .hadith: return "8B4513"            // Saddle Brown
        case .fiqh: return "4169E1"              // Royal Blue
        case .salahWorship: return "9370DB"      // Medium Purple
        case .duaAdhkar: return "20B2AA"         // Light Sea Green
        case .seerah: return "CD853F"            // Peru
        case .companionsSalaf: return "708090"   // Slate Gray
        case .tazkiyah: return "FF69B4"          // Hot Pink
        case .akhirah: return "483D8B"           // Dark Slate Blue
        case .akhlaq: return "32CD32"            // Lime Green
        case .familyMarriage: return "FF6347"    // Tomato
        case .knowledge: return "1E90FF"         // Dodger Blue
        case .dawahNewMuslims: return "FFA500"   // Orange
        case .history: return "A0522D"           // Sienna
        case .contemporary: return "6A5ACD"      // Slate Blue
        case .ruqyahProtection: return "8B0000"  // Dark Red
        case .ramadanFasting: return "9932CC"    // Dark Orchid
        case .hajjUmrah: return "2F4F4F"         // Dark Slate Gray
        case .arabicLanguage: return "006400"    // Dark Green
        case .healthMedicine: return "DC143C"    // Crimson
        case .uncategorized: return "808080"     // Gray
        }
    }

    var sortOrder: Int {
        switch self {
        case .aqeedah: return 0
        case .quranTafsir: return 1
        case .hadith: return 2
        case .fiqh: return 3
        case .salahWorship: return 4
        case .duaAdhkar: return 5
        case .seerah: return 6
        case .companionsSalaf: return 7
        case .tazkiyah: return 8
        case .akhirah: return 9
        case .akhlaq: return 10
        case .familyMarriage: return 11
        case .knowledge: return 12
        case .dawahNewMuslims: return 13
        case .history: return 14
        case .contemporary: return 15
        case .ruqyahProtection: return 16
        case .ramadanFasting: return 17
        case .hajjUmrah: return 18
        case .arabicLanguage: return 19
        case .healthMedicine: return 20
        case .uncategorized: return 99
        }
    }

    /// Keywords used to match book titles/filenames to this category
    var keywords: [String] {
        switch self {
        case .aqeedah:
            return [
                "aqeedah", "aqidah", "creed", "tawheed", "tawhid", "shirk",
                "belief", "divine will", "predestination", "al wala", "wal bara",
                "kitab at-tawheed", "kitab al-tawheed", "knowing allah",
                "names of allah", "four principles", "nullifiers of islam",
                "hamawiyyah", "sound creed", "eemaan", "eeman", "iman", "faith",
                "kitab al-iman", "free will", "forced", "alliance and disavowal",
                "mumthahinah", "causes behind the increase", "ibn taymeeyah",
                "ibn taymiyyah", "three fundamental", "guidance to the uncertain"
            ]
        case .quranTafsir:
            return [
                "quran", "qur'an", "tafsir", "tafseer", "surah", "ayah", "ayat",
                "atlas of the quran", "etiquette with quran", "quranic",
                "paragons of the quran", "80 percent of quranic", "riyadh al-saliheen",
                "riyadh us saliheen", "riyad al-salihin"
            ]
        case .hadith:
            return [
                "hadith", "hadīth", "ahadith", "fabricated hadith", "sahih",
                "bukhari", "muslim", "nawawi", "forty hadith", "al-mufrad",
                "adab al-mufrad", "hadith rejecters", "sunnah"
            ]
        case .fiqh:
            return [
                "fiqh", "jurisprudence", "umdah", "rulings", "fatwa", "fatwas",
                "fiqh us sunnah", "fiqh made easy", "islamic verdicts",
                "pillars of islam", "financial", "trade", "transactions",
                "natural blood", "congregational", "madhab", "hanafi", "maliki",
                "shafi", "hanbali", "worship", "tobacco", "cigarettes", "forbidden",
                "lawful earnings", "rizq", "celebrating birthday", "celebrating middle",
                "valentine", "differences of opinion"
            ]
        case .salahWorship:
            return [
                "salah", "salat", "prayer", "wudhu", "wudu", "ablution",
                "description of the prophet", "humility in prayer",
                "inner dimensions", "taraweeh", "fiqh ul ibadah",
                "description of the wudhu"
            ]
        case .duaAdhkar:
            return [
                "dua", "du'a", "adhkar", "dhikr", "zikr", "supplication",
                "fortress of the muslim", "hisn al muslim", "morning and evening",
                "sunnan for day", "precious remembrance", "forgiveness"
            ]
        case .seerah:
            return [
                "seerah", "sirah", "prophet muhammad", "messenger of allah",
                "noble life", "saheeh seerah", "al-albaanee", "house of messenger",
                "day in the house of the messenger", "men and women around the messenger"
            ]
        case .companionsSalaf:
            return [
                "sahaba", "sahabah", "companions", "caliphs", "caliph",
                "abu bakr", "umar", "uthman", "ali ibn abi", "hayatus-sahaba",
                "ibn abbas", "abdullah ibn umar", "commanders", "rightly-guided",
                "salaf", "predecessors", "al-hasan ibn ali", "ali-ibn-abi-talib",
                "ibn rajab", "luqmaan", "luqman"
            ]
        case .tazkiyah:
            return [
                "tazkiyah", "purification", "soul", "heart", "diseases of the heart",
                "disciplining", "devils deception", "ibn al-jawzi", "patience",
                "gratitude", "heavens door", "essay on heart", "lust", "greed",
                "dont be sad", "enjoy your life", "al-fawaid", "wise sayings",
                "awaking from the sleep", "heedlessness", "seeds of admonishment",
                "admonishment and reform", "being true with allah", "bieng true",
                "hindrances on the path", "love of allah", "appeal to your sense",
                "sense of shame", "good friendship", "road to good"
            ]
        case .akhirah:
            return [
                "akhirah", "hereafter", "barzakh", "paradise", "jannah", "naar",
                "hell", "death", "end times", "book of the end", "doomsday",
                "resurrection", "last day", "dajjal", "messiah", "day of wrath"
            ]
        case .akhlaq:
            return [
                "akhlaq", "manners", "etiquette", "character", "tongue", "backbiting",
                "parents", "dutifulness", "kindness", "gentleness", "anger",
                "lying", "envying", "envy", "book of manners", "do not be envious",
                "do not become angry", "enjoining good", "forbidding evil",
                "major sins"
            ]
        case .familyMarriage:
            return [
                "marriage", "family", "wife", "husband", "intimacy", "children",
                "child education", "nurturing", "eeman in children", "polygamy",
                "garment", "happy marriage", "love and mercy", "wedding",
                "wives rather than mistresses", "islamic home", "establishing an islamic home",
                "my son", "o my son", "angels curse", "love notes"
            ]
        case .knowledge:
            return [
                "knowledge", "seeking knowledge", "seeker", "ilm", "beneficial",
                "adorning knowledge", "advice for", "excellence of knowledge",
                "collection of ilm", "muaadh ibn jabal", "islamic studies",
                "module", "men and the universe"
            ]
        case .dawahNewMuslims:
            return [
                "dawah", "da'wah", "new muslim", "convert", "revert",
                "guide for the new", "discover islam", "illustrated guide",
                "understanding islam", "training", "program of study",
                "new sister", "misunderstood religion", "islam a complete way",
                "complete way of life", "message to every youth"
            ]
        case .history:
            return [
                "history of islam", "history of palestine", "salah ad-deen",
                "salahuddin", "ayubi", "atlas of the islamic conquests",
                "early days", "stories of", "prophets", "civilization",
                "authentic interpretation of the dreams"
            ]
        case .contemporary:
            return [
                "democracy", "khilafa", "caliphate", "shariah", "shari'ah",
                "man made laws", "defense of muslim lands", "milestones",
                "extremism", "jihad", "crusade", "israel lobby", "hubris",
                "rogue state", "superpower", "capitalism", "allah governance",
                "governance on earth", "economic", "ibn taymiyyah economic",
                "khawarij", "takfir", "beware of takfir", "join the caravan",
                "call to migrate", "salafi manhaj", "tamyee"
            ]
        case .ruqyahProtection:
            return [
                "ruqyah", "jinn", "shaytaan", "shaytan", "magic", "envy",
                "evil eye", "protection", "exposing shaytan", "sihr"
            ]
        case .ramadanFasting:
            return [
                "ramadan", "fasting", "fast", "sawm", "siyam", "iftar",
                "itikaaf", "itikaf", "lessons for those who fast"
            ]
        case .hajjUmrah:
            return [
                "hajj", "umrah", "umra", "pilgrimage", "rituals", "makkah",
                "medina", "madinah", "kaaba", "tawaf", "sa'i"
            ]
        case .arabicLanguage:
            return [
                "arabic", "madinah book", "madina book", "arabic reader",
                "tajweed", "tajwid", "glossary", "arabic text", "learning arabic",
                "dr v. abdur rahim"
            ]
        case .healthMedicine:
            return [
                "medicine", "health", "healing", "prophetic medicine", "tibb",
                "herbalism", "psychology", "wellbeing", "body and soul", "vaccine"
            ]
        case .uncategorized:
            return []
        }
    }

    /// Create a BookCategory model from this enum case
    func toModel() -> BookCategory {
        BookCategory(
            name: self.rawValue,
            icon: self.icon,
            colorHex: self.colorHex,
            sortOrder: self.sortOrder
        )
    }

    /// Find the best matching category for a given filename
    static func categorize(filename: String) -> IslamicCategory {
        let lowercased = filename.lowercased()

        // Check each category's keywords
        var bestMatch: IslamicCategory = .uncategorized
        var bestScore = 0

        for category in IslamicCategory.allCases {
            guard category != .uncategorized else { continue }

            var score = 0
            for keyword in category.keywords {
                if lowercased.contains(keyword.lowercased()) {
                    // Longer keywords get higher scores (more specific matches)
                    score += keyword.count
                }
            }

            if score > bestScore {
                bestScore = score
                bestMatch = category
            }
        }

        return bestMatch
    }
}

// MARK: - Color Extension

import SwiftUI

extension BookCategory {
    var color: Color {
        Color(hex: colorHex)
    }
}
