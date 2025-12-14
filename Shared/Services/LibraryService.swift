// LibraryService.swift
// NoorReader
//
// Library management service for PDF import and organization

import Foundation
import PDFKit
import SwiftData
import UniformTypeIdentifiers

@MainActor
final class LibraryService: ObservableObject {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Import

    /// Import a PDF file into the library
    func importPDF(from url: URL) async throws -> Book {
        // Verify it's a PDF
        guard url.pathExtension.lowercased() == "pdf" else {
            throw LibraryError.invalidFileType
        }

        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            throw LibraryError.accessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }

        // Copy to app's documents directory
        let documentsURL = try getDocumentsDirectory()
        let destinationURL = documentsURL.appendingPathComponent(url.lastPathComponent)

        // If file already exists, generate unique name
        let finalURL = try getUniqueURL(for: destinationURL)

        try FileManager.default.copyItem(at: url, to: finalURL)

        // Extract metadata
        let metadata = try await extractMetadata(from: finalURL)

        // Create book model
        let book = Book(
            title: metadata.title,
            author: metadata.author,
            fileURL: finalURL,
            totalPages: metadata.pageCount
        )
        book.coverImageData = metadata.coverImage

        // Save to database
        modelContext.insert(book)
        try modelContext.save()

        return book
    }

    /// Extract metadata from PDF
    private func extractMetadata(from url: URL) async throws -> PDFMetadata {
        guard let document = PDFDocument(url: url) else {
            throw LibraryError.cannotOpenPDF
        }

        // Extract title
        var title = document.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String
        if title == nil || title!.isEmpty {
            title = url.deletingPathExtension().lastPathComponent
        }

        // Extract author
        let author = document.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String ?? ""

        // Extract page count
        let pageCount = document.pageCount

        // Extract cover image (first page)
        var coverImage: Data?
        if let firstPage = document.page(at: 0) {
            let pageRect = firstPage.bounds(for: .mediaBox)
            let scale: CGFloat = 200 / max(pageRect.width, pageRect.height)
            let scaledSize = CGSize(
                width: pageRect.width * scale,
                height: pageRect.height * scale
            )

            let image = firstPage.thumbnail(of: scaledSize, for: .mediaBox)
            coverImage = image.tiffRepresentation
        }

        return PDFMetadata(
            title: title ?? "Untitled",
            author: author,
            pageCount: pageCount,
            coverImage: coverImage
        )
    }

    // MARK: - File Management

    private func getDocumentsDirectory() throws -> URL {
        let fileManager = FileManager.default
        let documentsURL = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let libraryURL = documentsURL.appendingPathComponent("NoorReader Library", isDirectory: true)

        if !fileManager.fileExists(atPath: libraryURL.path) {
            try fileManager.createDirectory(at: libraryURL, withIntermediateDirectories: true)
        }

        return libraryURL
    }

    private func getUniqueURL(for url: URL) throws -> URL {
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: url.path) {
            return url
        }

        let directory = url.deletingLastPathComponent()
        let filename = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension

        var counter = 1
        var newURL = url

        while fileManager.fileExists(atPath: newURL.path) {
            counter += 1
            newURL = directory.appendingPathComponent("\(filename) \(counter).\(ext)")
        }

        return newURL
    }

    // MARK: - Library Operations

    /// Delete a book from the library
    func deleteBook(_ book: Book, deleteFile: Bool = false) throws {
        if deleteFile {
            try? FileManager.default.removeItem(at: book.fileURL)
        }

        modelContext.delete(book)
        try modelContext.save()
    }

    /// Toggle favorite status
    func toggleFavorite(_ book: Book) throws {
        book.isFavorite.toggle()
        try modelContext.save()
    }

    /// Update reading progress
    func updateProgress(_ book: Book, currentPage: Int) throws {
        book.currentPage = currentPage
        book.lastRead = Date()
        try modelContext.save()
    }
}

// MARK: - Supporting Types

struct PDFMetadata {
    let title: String
    let author: String
    let pageCount: Int
    let coverImage: Data?
}

enum LibraryError: LocalizedError {
    case invalidFileType
    case accessDenied
    case cannotOpenPDF
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .invalidFileType:
            return "Please select a PDF file."
        case .accessDenied:
            return "Cannot access the selected file."
        case .cannotOpenPDF:
            return "Cannot open the PDF file."
        case .saveFailed:
            return "Failed to save to library."
        }
    }
}
