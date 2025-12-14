// LibraryScannerService.swift
// NoorReader
//
// Service for scanning external library folders and importing/categorizing books

import Foundation
import PDFKit
import SwiftData

@MainActor
final class LibraryScannerService {
    static let shared = LibraryScannerService()

    private var modelContext: ModelContext?

    private init() {}

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Library Path Management

    /// Key for storing the library folder path in UserDefaults
    private let libraryPathKey = "externalLibraryPath"

    /// Get the saved library folder path
    var savedLibraryPath: URL? {
        get {
            guard let path = UserDefaults.standard.string(forKey: libraryPathKey) else { return nil }
            return URL(fileURLWithPath: path)
        }
        set {
            UserDefaults.standard.set(newValue?.path, forKey: libraryPathKey)
        }
    }

    // MARK: - Category Management

    /// Ensure all Islamic categories exist in the database
    func ensureCategoriesExist() throws {
        guard let context = modelContext else {
            throw LibraryScannerError.notConfigured
        }

        // Check existing categories
        let descriptor = FetchDescriptor<BookCategory>()
        let existingCategories = try context.fetch(descriptor)
        let existingNames = Set(existingCategories.map { $0.name })

        // Create missing categories
        for category in IslamicCategory.allCases {
            if !existingNames.contains(category.rawValue) {
                let newCategory = category.toModel()
                context.insert(newCategory)
            }
        }

        try context.save()
    }

    /// Get or create a category by name
    func getCategory(for islamicCategory: IslamicCategory) throws -> BookCategory {
        guard let context = modelContext else {
            throw LibraryScannerError.notConfigured
        }

        let name = islamicCategory.rawValue
        var descriptor = FetchDescriptor<BookCategory>(
            predicate: #Predicate { $0.name == name }
        )
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            return existing
        }

        // Create new category
        let newCategory = islamicCategory.toModel()
        context.insert(newCategory)
        try context.save()
        return newCategory
    }

    // MARK: - Scanning

    /// Scan a folder for PDF files and import them
    func scanFolder(at url: URL, progressHandler: ((ScanProgress) -> Void)? = nil) async throws -> ScanResult {
        guard let context = modelContext else {
            throw LibraryScannerError.notConfigured
        }

        // Save the library path
        savedLibraryPath = url

        // Ensure categories exist
        try ensureCategoriesExist()

        // Find all PDF files
        let fileManager = FileManager.default
        let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .nameKey]

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles]
        ) else {
            throw LibraryScannerError.cannotAccessFolder
        }

        var pdfFiles: [URL] = []
        while let fileURL = enumerator.nextObject() as? URL {
            if fileURL.pathExtension.lowercased() == "pdf" {
                pdfFiles.append(fileURL)
            }
        }

        let totalFiles = pdfFiles.count
        var imported = 0
        var skipped = 0
        var failed = 0
        var errors: [String] = []

        for (index, pdfURL) in pdfFiles.enumerated() {
            progressHandler?(ScanProgress(
                current: index + 1,
                total: totalFiles,
                currentFile: pdfURL.lastPathComponent,
                status: .scanning
            ))

            do {
                // Check if already imported (by file path)
                let pdfPath = pdfURL.path
                let existingDescriptor = FetchDescriptor<Book>(
                    predicate: #Predicate<Book> { book in
                        book.sourceFolder == pdfPath
                    }
                )
                let existingBooks = try context.fetch(existingDescriptor)

                if !existingBooks.isEmpty {
                    skipped += 1
                    continue
                }

                // Import the book
                _ = try await importBook(from: pdfURL, baseFolder: url)
                imported += 1

            } catch {
                failed += 1
                errors.append("\(pdfURL.lastPathComponent): \(error.localizedDescription)")
            }
        }

        try context.save()

        return ScanResult(
            totalFound: totalFiles,
            imported: imported,
            skipped: skipped,
            failed: failed,
            errors: errors
        )
    }

    /// Import a single book from an external location (without copying)
    private func importBook(from url: URL, baseFolder: URL) async throws -> Book {
        guard let context = modelContext else {
            throw LibraryScannerError.notConfigured
        }

        guard let document = PDFDocument(url: url) else {
            throw LibraryScannerError.cannotOpenPDF
        }

        // Extract metadata
        let filename = url.deletingPathExtension().lastPathComponent
        var title = document.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String

        // Clean up title from PDF metadata or use filename
        if let pdfTitle = title, !pdfTitle.isEmpty, pdfTitle.count >= 3 {
            title = cleanupFilename(pdfTitle)
        } else {
            title = cleanupFilename(filename)
        }

        // If title is still empty or just junk, use cleaned filename
        if title == nil || title!.isEmpty || title!.count < 3 {
            title = cleanupFilename(filename)
        }

        // Get author from PDF or detect from filename/title
        var author = document.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String ?? ""
        if author.isEmpty {
            author = detectAuthor(from: filename) ?? detectAuthor(from: title ?? "") ?? ""
        }

        let pageCount = document.pageCount

        // Get subfolder name for additional context
        let relativePath = url.path.replacingOccurrences(of: baseFolder.path, with: "")
        let components = relativePath.components(separatedBy: "/").filter { !$0.isEmpty }
        let subfolderHint = components.first

        // Determine category using multiple sources for better accuracy
        var islamicCategory = IslamicCategory.categorize(filename: filename)

        // Try title if filename didn't match
        if islamicCategory == .uncategorized, let titleStr = title {
            islamicCategory = IslamicCategory.categorize(filename: titleStr)
        }

        // Try subfolder name if still uncategorized
        if islamicCategory == .uncategorized, let hint = subfolderHint {
            islamicCategory = IslamicCategory.categorize(filename: hint)
        }

        // Try full path as last resort
        if islamicCategory == .uncategorized {
            islamicCategory = IslamicCategory.categorize(filename: url.path)
        }

        let finalCategory = try getCategory(for: islamicCategory)

        // Extract cover image
        let coverImageData = extractCoverImage(from: document)

        // Create book (referencing original location, not copying)
        let book = Book(
            title: title ?? "Untitled",
            author: author,
            fileURL: url,
            totalPages: pageCount
        )
        book.coverImageData = coverImageData
        book.category = finalCategory
        book.sourceFolder = url.path

        context.insert(book)

        return book
    }

    /// Clean up a filename for display as title
    private func cleanupFilename(_ filename: String) -> String {
        var cleaned = filename

        // Direct string replacements (more reliable than regex)
        let directReplacements = [
            " | Kalamullah.Com": "",
            "| Kalamullah.Com": "",
            "Kalamullah.Com | ": "",
            "Kalamullah.Com |": "",
            "::Kalamullah.Com::": "",
            "Kalamullah.Com": "",
            "Microsoft Word - ": "",
            "Microsoft Word -": "",
            ".docx": "",
            ".doc": "",
            ".pdf": "",
            "Full page fax print": "",
            "LAG: Ebook: ": "",
            "LAG: ": "",
        ]

        for (search, replacement) in directReplacements {
            cleaned = cleaned.replacingOccurrences(of: search, with: replacement, options: .caseInsensitive)
        }

        // Remove hex-encoded titles like <4D6963...>
        if cleaned.hasPrefix("<") && cleaned.hasSuffix(">") && cleaned.count > 20 {
            // This is likely a hex-encoded title, use filename instead
            return cleanupFilename(filename.replacingOccurrences(of: cleaned, with: ""))
        }

        // Remove PDF temp files
        if cleaned.uppercased().hasPrefix("PDF") && cleaned.uppercased().hasSuffix(".TMP") {
            return ""
        }

        // Remove common patterns
        let patterns = [
            #"\s*\(\d{4}\)"#,           // (2011)
            #"_text$"#,                  // _text suffix
            #"^\d+\s+"#,                 // Leading numbers like "01 "
            #"^AA\s+READ\s+ME.*"#,       // README files
            #"\s*-\s*$"#,                // Trailing dash
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                cleaned = regex.stringByReplacingMatches(
                    in: cleaned,
                    options: [],
                    range: NSRange(cleaned.startIndex..., in: cleaned),
                    withTemplate: ""
                )
            }
        }

        // Replace underscores with spaces
        cleaned = cleaned.replacingOccurrences(of: "_", with: " ")

        // Trim whitespace and punctuation
        cleaned = cleaned.trimmingCharacters(in: .whitespaces)
        cleaned = cleaned.trimmingCharacters(in: CharacterSet(charactersIn: "|-:"))
        cleaned = cleaned.trimmingCharacters(in: .whitespaces)

        // Title case if all caps or all lowercase
        if cleaned == cleaned.uppercased() || cleaned == cleaned.lowercased() {
            cleaned = cleaned.capitalized
        }

        return cleaned.isEmpty ? filename : cleaned
    }

    /// Known Islamic authors and scholars for author detection
    private static let knownAuthors: [String: String] = [
        // Classical scholars
        "ibn taymiyyah": "Ibn Taymiyyah",
        "ibn taymeeyah": "Ibn Taymiyyah",
        "ibn al-jawzi": "Ibn al-Jawzi",
        "ibn al jawzi": "Ibn al-Jawzi",
        "ibn qayyim": "Ibn Qayyim al-Jawziyyah",
        "ibn rajab": "Ibn Rajab al-Hanbali",
        "imam nawawi": "Imam an-Nawawi",
        "al-nawawi": "Imam an-Nawawi",
        "riyadh al-saliheen": "Imam an-Nawawi",
        "riyadh us saliheen": "Imam an-Nawawi",
        "imam bukhari": "Imam al-Bukhari",
        "imam muslim": "Imam Muslim",
        "ibn kathir": "Ibn Kathir",
        "ibn katheer": "Ibn Kathir",
        "al-ghazali": "Imam al-Ghazali",
        "imam ghazali": "Imam al-Ghazali",

        // Contemporary scholars
        "ibn baz": "Shaykh Ibn Baz",
        "ibn baaz": "Shaykh Ibn Baz",
        "al-albaanee": "Shaykh al-Albani",
        "al-albani": "Shaykh al-Albani",
        "ibn uthaymeen": "Shaykh Ibn Uthaymeen",
        "ibn uthaimeen": "Shaykh Ibn Uthaymeen",
        "al-fawzan": "Shaykh Salih al-Fawzan",
        "salih al-fawzan": "Shaykh Salih al-Fawzan",
        "muhammad ibn abdul wahhab": "Muhammad ibn Abdul Wahhab",
        "abdul wahhab": "Muhammad ibn Abdul Wahhab",

        // Other notable authors
        "sayyid qutb": "Sayyid Qutb",
        "abdullah azzam": "Abdullah Azzam",
        "ahmad musa jibril": "Ahmad Musa Jibril",
        "megan wyatt": "Megan Wyatt",

        // Madinah Arabic / Language authors
        "dr v. abdur rahim": "Dr. V. Abdur Rahim",
        "dr. v. abdur rahim": "Dr. V. Abdur Rahim",
        "abdur rahim": "Dr. V. Abdur Rahim",
        "madinah book": "Dr. V. Abdur Rahim",
        "madina book": "Dr. V. Abdur Rahim",
        "madinah arabic": "Dr. V. Abdur Rahim",
        "madina arabic": "Dr. V. Abdur Rahim",

        // Book-specific author mappings
        "fortress of the muslim": "Sa'id bin Wahf al-Qahtani",
        "hisn al muslim": "Sa'id bin Wahf al-Qahtani",
        "dont be sad": "Dr. A'id al-Qarni",
        "don't be sad": "Dr. A'id al-Qarni",
        "enjoy your life": "Dr. Muhammad al-Arifi",
        "fiqh us sunnah": "Sayyid Sabiq",
        "fiqh us-sunnah": "Sayyid Sabiq",
        "hayatus sahaba": "Muhammad Yusuf Kandhlawi",
        "hayatus-sahaba": "Muhammad Yusuf Kandhlawi",
        "lives of the sahaba": "Muhammad Yusuf Kandhlawi",
        "kitab at-tawheed": "Muhammad ibn Abdul Wahhab",
        "kitab al-tawheed": "Muhammad ibn Abdul Wahhab",
        "three fundamental": "Muhammad ibn Abdul Wahhab",
        "usool ath-thalaatha": "Muhammad ibn Abdul Wahhab",
        "milestones": "Sayyid Qutb",
        "in the shade of the quran": "Sayyid Qutb",
        "al-fawaid": "Ibn Qayyim al-Jawziyyah",
        "the legacy of the prophet": "Ibn Rajab al-Hanbali",
        "adab al-mufrad": "Imam al-Bukhari",
        "al-adab al-mufrad": "Imam al-Bukhari",
    ]

    /// Try to detect author from filename/title
    private func detectAuthor(from text: String) -> String? {
        let lowercased = text.lowercased()

        for (pattern, author) in Self.knownAuthors {
            if lowercased.contains(pattern) {
                return author
            }
        }

        return nil
    }

    /// Extract cover image from PDF document
    private func extractCoverImage(from document: PDFDocument) -> Data? {
        guard let firstPage = document.page(at: 0) else { return nil }

        let pageRect = firstPage.bounds(for: .mediaBox)
        let scale: CGFloat = 300 / max(pageRect.width, pageRect.height)
        let scaledSize = CGSize(
            width: pageRect.width * scale,
            height: pageRect.height * scale
        )

        let image = firstPage.thumbnail(of: scaledSize, for: .mediaBox)
        return image.tiffRepresentation
    }

    // MARK: - Rescan & Update

    /// Rescan the library folder for new books
    func rescan(progressHandler: ((ScanProgress) -> Void)? = nil) async throws -> ScanResult {
        guard let path = savedLibraryPath else {
            throw LibraryScannerError.noLibraryConfigured
        }
        return try await scanFolder(at: path, progressHandler: progressHandler)
    }

    /// Re-categorize all books based on current rules
    func recategorizeAllBooks() async throws {
        guard let context = modelContext else {
            throw LibraryScannerError.notConfigured
        }

        let descriptor = FetchDescriptor<Book>()
        let allBooks = try context.fetch(descriptor)

        for book in allBooks {
            // Combine multiple sources for better categorization
            let filename = book.fileURL.deletingPathExtension().lastPathComponent
            let title = book.title
            let sourcePath = book.sourceFolder ?? ""

            // Try filename first, then title, then full path
            var islamicCategory = IslamicCategory.categorize(filename: filename)
            if islamicCategory == .uncategorized {
                islamicCategory = IslamicCategory.categorize(filename: title)
            }
            if islamicCategory == .uncategorized {
                islamicCategory = IslamicCategory.categorize(filename: sourcePath)
            }

            let category = try getCategory(for: islamicCategory)
            book.category = category
        }

        try context.save()
    }

    /// Clean up all book titles and detect authors for existing books
    func cleanupAllBooks() async throws {
        guard let context = modelContext else {
            throw LibraryScannerError.notConfigured
        }

        let descriptor = FetchDescriptor<Book>()
        let allBooks = try context.fetch(descriptor)

        for book in allBooks {
            let filename = book.fileURL.deletingPathExtension().lastPathComponent

            // Clean up title
            let cleanedTitle = cleanupFilename(book.title)
            if cleanedTitle != book.title && !cleanedTitle.isEmpty {
                book.title = cleanedTitle
            }

            // If title is still junk (too short or just punctuation), use filename
            if book.title.count < 3 || book.title.trimmingCharacters(in: .alphanumerics).count == book.title.count {
                book.title = cleanupFilename(filename)
            }

            // Detect author if empty
            if book.author.isEmpty {
                if let detectedAuthor = detectAuthor(from: filename) ?? detectAuthor(from: book.title) {
                    book.author = detectedAuthor
                }
            }
        }

        try context.save()
    }

    /// Full refresh: clean titles, detect authors, and recategorize
    func refreshAllBooks() async throws {
        try await cleanupAllBooks()
        try await recategorizeAllBooks()
    }

    // MARK: - Statistics

    /// Get category statistics
    func getCategoryStats() throws -> [CategoryStat] {
        guard let context = modelContext else {
            throw LibraryScannerError.notConfigured
        }

        let categoryDescriptor = FetchDescriptor<BookCategory>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let categories = try context.fetch(categoryDescriptor)

        return categories.map { category in
            CategoryStat(
                category: category,
                bookCount: category.books.count
            )
        }.filter { $0.bookCount > 0 }
    }
}

// MARK: - Supporting Types

struct ScanProgress {
    let current: Int
    let total: Int
    let currentFile: String
    let status: ScanStatus

    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }

    enum ScanStatus {
        case scanning
        case importing
        case categorizing
        case complete
    }
}

struct ScanResult {
    let totalFound: Int
    let imported: Int
    let skipped: Int
    let failed: Int
    let errors: [String]

    var summary: String {
        var parts: [String] = []
        if imported > 0 { parts.append("\(imported) imported") }
        if skipped > 0 { parts.append("\(skipped) already in library") }
        if failed > 0 { parts.append("\(failed) failed") }
        return parts.joined(separator: ", ")
    }
}

struct CategoryStat {
    let category: BookCategory
    let bookCount: Int
}

enum LibraryScannerError: LocalizedError {
    case notConfigured
    case cannotAccessFolder
    case cannotOpenPDF
    case noLibraryConfigured

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Library scanner not configured. Please restart the app."
        case .cannotAccessFolder:
            return "Cannot access the selected folder."
        case .cannotOpenPDF:
            return "Cannot open PDF file."
        case .noLibraryConfigured:
            return "No library folder configured. Please select a folder first."
        }
    }
}
