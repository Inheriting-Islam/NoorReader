// IslamicReminder.swift
// NoorReader
//
// Model for Islamic duas, hadith, and ayah content

import Foundation

struct IslamicReminder: Codable, Identifiable {
    let id: UUID
    let type: ReminderType
    let arabic: String
    let transliteration: String
    let english: String
    let source: String
    let category: String

    enum ReminderType: String, Codable {
        case dua
        case hadith
        case ayah
        case reminder
    }
}

// MARK: - Sample Content

extension IslamicReminder {
    static let launchDua = IslamicReminder(
        id: UUID(),
        type: .dua,
        arabic: "رَبِّ زِدْنِي عِلْمًا",
        transliteration: "Rabbi zidni ilma",
        english: "My Lord, increase me in knowledge.",
        source: "Quran 20:114",
        category: "seeking_knowledge"
    )

    static let sampleHadith = IslamicReminder(
        id: UUID(),
        type: .hadith,
        arabic: "مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الْجَنَّةِ",
        transliteration: "Man salaka tareeqan yaltamisu fihi ilman, sahhal Allahu lahu bihi tareeqan ilal jannah",
        english: "Whoever takes a path seeking knowledge, Allah will make easy for him the path to Paradise.",
        source: "Sahih Muslim 2699",
        category: "seeking_knowledge"
    )

    static let studyDuas: [IslamicReminder] = [
        launchDua,
        IslamicReminder(
            id: UUID(),
            type: .dua,
            arabic: "اللَّهُمَّ انْفَعْنِي بِمَا عَلَّمْتَنِي وَعَلِّمْنِي مَا يَنْفَعُنِي وَزِدْنِي عِلْمًا",
            transliteration: "Allahumma infa'ni bima 'allamtani, wa 'allimni ma yanfa'uni, wa zidni 'ilma",
            english: "O Allah, benefit me with what You have taught me, teach me what will benefit me, and increase me in knowledge.",
            source: "Sunan Ibn Majah 251",
            category: "seeking_knowledge"
        ),
        IslamicReminder(
            id: UUID(),
            type: .dua,
            arabic: "رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي وَاحْلُلْ عُقْدَةً مِنْ لِسَانِي يَفْقَهُوا قَوْلِي",
            transliteration: "Rabbi-shrah li sadri, wa yassir li amri, wahlul 'uqdatan min lisani, yafqahu qawli",
            english: "My Lord, expand for me my chest, ease for me my task, and untie the knot from my tongue that they may understand my speech.",
            source: "Quran 20:25-28",
            category: "ease_in_learning"
        )
    ]
}
