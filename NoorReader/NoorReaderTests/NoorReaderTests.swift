//
//  NoorReaderTests.swift
//  NoorReaderTests
//
//  Created by Hamza Abdul-Tawwaab on 12/13/25.
//

import XCTest
import SwiftData
@testable import NoorReader

final class NoorReaderTests: XCTestCase {

    // MARK: - Book Model Tests

    func testBookInitialization() throws {
        let url = URL(filePath: "/test/path/book.pdf")
        let book = Book(title: "Test Book", author: "Test Author", fileURL: url, totalPages: 100)

        XCTAssertEqual(book.title, "Test Book")
        XCTAssertEqual(book.author, "Test Author")
        XCTAssertEqual(book.totalPages, 100)
        XCTAssertEqual(book.currentPage, 0)
        XCTAssertFalse(book.isFavorite)
        XCTAssertFalse(book.isStarted)
        XCTAssertFalse(book.isCompleted)
    }

    func testBookProgress() throws {
        let url = URL(filePath: "/test/path/book.pdf")
        let book = Book(title: "Test", fileURL: url, totalPages: 100)

        // No progress yet
        XCTAssertEqual(book.progress, 0.0)
        XCTAssertEqual(book.progressPercentage, 0)

        // 50% progress
        book.currentPage = 50
        XCTAssertEqual(book.progress, 0.5)
        XCTAssertEqual(book.progressPercentage, 50)
        XCTAssertTrue(book.isStarted)
        XCTAssertFalse(book.isCompleted)

        // 100% progress
        book.currentPage = 100
        XCTAssertEqual(book.progress, 1.0)
        XCTAssertEqual(book.progressPercentage, 100)
        XCTAssertTrue(book.isCompleted)
    }

    func testBookDisplayProperties() throws {
        let url = URL(filePath: "/test/path/book.pdf")

        // With title and author
        let book1 = Book(title: "My Book", author: "John Doe", fileURL: url)
        XCTAssertEqual(book1.displayTitle, "My Book")
        XCTAssertEqual(book1.displayAuthor, "John Doe")

        // Without title and author
        let book2 = Book(title: "", author: "", fileURL: url)
        XCTAssertEqual(book2.displayTitle, "Untitled")
        XCTAssertEqual(book2.displayAuthor, "Unknown Author")
    }

    // MARK: - Bookmark Model Tests

    func testBookmarkInitialization() throws {
        let bookmark = Bookmark(pageNumber: 42, title: "Important Section")

        XCTAssertEqual(bookmark.pageNumber, 42)
        XCTAssertEqual(bookmark.title, "Important Section")
    }

    func testBookmarkDefaultTitle() throws {
        let bookmark = Bookmark(pageNumber: 10)

        XCTAssertEqual(bookmark.pageNumber, 10)
        XCTAssertEqual(bookmark.title, "Page 11") // 0-indexed, so page 10 displays as 11
    }

    // MARK: - Highlight Model Tests

    func testHighlightInitialization() throws {
        let highlight = Highlight(text: "Important text", pageNumber: 5, color: .green)

        XCTAssertEqual(highlight.text, "Important text")
        XCTAssertEqual(highlight.pageNumber, 5)
        XCTAssertEqual(highlight.color, .green)
    }

    func testHighlightColorProperties() throws {
        XCTAssertEqual(HighlightColor.yellow.displayName, "General")
        XCTAssertEqual(HighlightColor.green.displayName, "Key Concept")
        XCTAssertEqual(HighlightColor.blue.displayName, "Definition")
        XCTAssertEqual(HighlightColor.pink.displayName, "Question")

        XCTAssertEqual(HighlightColor.yellow.shortcut, "1")
        XCTAssertEqual(HighlightColor.green.shortcut, "2")
        XCTAssertEqual(HighlightColor.blue.shortcut, "3")
    }

    // MARK: - Collection Model Tests

    func testCollectionInitialization() throws {
        let collection = Collection(name: "Islamic Books", icon: "book.closed")

        XCTAssertEqual(collection.name, "Islamic Books")
        XCTAssertEqual(collection.icon, "book.closed")
    }

    // MARK: - Islamic Reminder Tests

    func testLaunchDua() throws {
        let dua = IslamicReminder.launchDua

        XCTAssertEqual(dua.type, .dua)
        XCTAssertEqual(dua.arabic, "رَبِّ زِدْنِي عِلْمًا")
        XCTAssertEqual(dua.transliteration, "Rabbi zidni ilma")
        XCTAssertEqual(dua.english, "My Lord, increase me in knowledge.")
        XCTAssertEqual(dua.source, "Quran 20:114")
    }

    // MARK: - CodableRect Tests

    func testCodableRect() throws {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 50)
        let codableRect = CodableRect(rect: rect)

        XCTAssertEqual(codableRect.x, 10)
        XCTAssertEqual(codableRect.y, 20)
        XCTAssertEqual(codableRect.width, 100)
        XCTAssertEqual(codableRect.height, 50)

        let decodedRect = codableRect.rect
        XCTAssertEqual(decodedRect, rect)
    }

    func testCodableRectEncoding() throws {
        let rect = CGRect(x: 5, y: 10, width: 200, height: 300)
        let codableRect = CodableRect(rect: rect)

        let encoder = JSONEncoder()
        let data = try encoder.encode(codableRect)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CodableRect.self, from: data)

        XCTAssertEqual(decoded.rect, rect)
    }

    // MARK: - Theme Tests

    func testReadingThemeProperties() throws {
        XCTAssertEqual(ReadingTheme.day.displayName, "Day")
        XCTAssertEqual(ReadingTheme.sepia.displayName, "Sepia")
        XCTAssertEqual(ReadingTheme.night.displayName, "Night")
        XCTAssertEqual(ReadingTheme.auto.displayName, "Auto")

        XCTAssertEqual(ReadingTheme.day.icon, "sun.max")
        XCTAssertEqual(ReadingTheme.night.icon, "moon")
    }

    // MARK: - Sort Order Tests

    func testSortOrderDisplayNames() throws {
        XCTAssertEqual(SortOrder.title.displayName, "Title")
        XCTAssertEqual(SortOrder.author.displayName, "Author")
        XCTAssertEqual(SortOrder.dateAdded.displayName, "Date Added")
        XCTAssertEqual(SortOrder.lastRead.displayName, "Last Read")
        XCTAssertEqual(SortOrder.progress.displayName, "Progress")
    }

    // MARK: - Library Collection Tests

    func testLibraryCollectionDisplayNames() throws {
        XCTAssertEqual(LibraryCollection.all.displayName, "All Books")
        XCTAssertEqual(LibraryCollection.readingNow.displayName, "Reading Now")
        XCTAssertEqual(LibraryCollection.favorites.displayName, "Favorites")
        XCTAssertEqual(LibraryCollection.recentlyAdded.displayName, "Recently Added")
    }

    func testLibraryCollectionIcons() throws {
        XCTAssertEqual(LibraryCollection.all.icon, "books.vertical")
        XCTAssertEqual(LibraryCollection.readingNow.icon, "book")
        XCTAssertEqual(LibraryCollection.favorites.icon, "star")
        XCTAssertEqual(LibraryCollection.recentlyAdded.icon, "clock")
    }

    // MARK: - Prayer Tests

    func testPrayerProperties() throws {
        XCTAssertEqual(Prayer.fajr.rawValue, "Fajr")
        XCTAssertEqual(Prayer.dhuhr.rawValue, "Dhuhr")
        XCTAssertEqual(Prayer.asr.rawValue, "Asr")
        XCTAssertEqual(Prayer.maghrib.rawValue, "Maghrib")
        XCTAssertEqual(Prayer.isha.rawValue, "Isha")

        XCTAssertEqual(Prayer.fajr.icon, "sunrise")
        XCTAssertEqual(Prayer.isha.icon, "moon.stars")
    }

    // MARK: - Error Tests

    func testLibraryErrorDescriptions() throws {
        XCTAssertEqual(LibraryError.invalidFileType.errorDescription, "Please select a PDF file.")
        XCTAssertEqual(LibraryError.accessDenied.errorDescription, "Cannot access the selected file.")
        XCTAssertEqual(LibraryError.cannotOpenPDF.errorDescription, "Cannot open the PDF file.")
        XCTAssertEqual(LibraryError.saveFailed.errorDescription, "Failed to save to library.")
    }

    func testReaderErrorDescriptions() throws {
        XCTAssertEqual(ReaderError.accessDenied.errorDescription, "Cannot access the document. Please re-import the file.")
        XCTAssertEqual(ReaderError.cannotOpenDocument.errorDescription, "Cannot open the document. The file may be corrupted.")
    }

    func testPrayerTimeErrorDescriptions() throws {
        XCTAssertEqual(PrayerTimeError.invalidURL.errorDescription, "Invalid API URL")
        XCTAssertEqual(PrayerTimeError.serverError.errorDescription, "Could not fetch prayer times")
        XCTAssertEqual(PrayerTimeError.locationUnavailable.errorDescription, "Location not available")
    }
}
