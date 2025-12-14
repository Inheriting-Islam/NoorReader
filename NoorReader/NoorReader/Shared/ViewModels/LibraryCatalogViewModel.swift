// LibraryCatalogViewModel.swift
// NoorReader
//
// ViewModel for managing the categorized library view

import SwiftUI
import SwiftData
import Combine

@MainActor
@Observable
final class LibraryCatalogViewModel {
    // MARK: - Published State

    var isScanning = false
    var scanProgress: ScanProgress?
    var scanResult: ScanResult?
    var error: String?

    var selectedCategory: BookCategory?
    var searchText = ""
    var expandedCategories: Set<UUID> = []

    // MARK: - Dependencies

    private var modelContext: ModelContext?
    private let scannerService = LibraryScannerService.shared

    // MARK: - Initialization

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        scannerService.configure(modelContext: modelContext)
    }

    // MARK: - Library Folder Selection

    var hasLibraryFolder: Bool {
        scannerService.savedLibraryPath != nil
    }

    var libraryFolderName: String {
        scannerService.savedLibraryPath?.lastPathComponent ?? "Not configured"
    }

    /// Open folder picker and scan selected folder
    func selectAndScanFolder() async {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select your Islamic library folder"
        panel.prompt = "Select Folder"

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        await scanFolder(at: url)
    }

    /// Scan a specific folder
    func scanFolder(at url: URL) async {
        isScanning = true
        scanProgress = nil
        scanResult = nil
        error = nil

        do {
            let result = try await scannerService.scanFolder(at: url) { [weak self] progress in
                Task { @MainActor in
                    self?.scanProgress = progress
                }
            }
            scanResult = result
        } catch {
            self.error = error.localizedDescription
        }

        isScanning = false
    }

    /// Rescan the existing library folder
    func rescanLibrary() async {
        guard hasLibraryFolder else {
            error = "No library folder configured"
            return
        }

        isScanning = true
        scanProgress = nil
        scanResult = nil
        error = nil

        do {
            let result = try await scannerService.rescan { [weak self] progress in
                Task { @MainActor in
                    self?.scanProgress = progress
                }
            }
            scanResult = result
        } catch {
            self.error = error.localizedDescription
        }

        isScanning = false
    }

    // MARK: - Category Management

    func toggleCategoryExpanded(_ category: BookCategory) {
        if expandedCategories.contains(category.id) {
            expandedCategories.remove(category.id)
        } else {
            expandedCategories.insert(category.id)
        }
    }

    func isCategoryExpanded(_ category: BookCategory) -> Bool {
        expandedCategories.contains(category.id)
    }

    func expandAllCategories(_ categories: [BookCategory]) {
        expandedCategories = Set(categories.map { $0.id })
    }

    func collapseAllCategories() {
        expandedCategories.removeAll()
    }

    // MARK: - Filtering

    func filterBooks(_ books: [Book]) -> [Book] {
        guard !searchText.isEmpty else { return books }

        let query = searchText.lowercased()
        return books.filter { book in
            book.title.lowercased().contains(query) ||
            book.author.lowercased().contains(query)
        }
    }

    func booksForCategory(_ category: BookCategory) -> [Book] {
        filterBooks(category.books).sorted { $0.title < $1.title }
    }

    // MARK: - Recategorization

    func recategorizeAllBooks() async {
        isScanning = true
        error = nil

        do {
            try await scannerService.recategorizeAllBooks()
        } catch {
            self.error = error.localizedDescription
        }

        isScanning = false
    }

    // MARK: - Statistics

    func getCategoryStats() -> [CategoryStat] {
        do {
            return try scannerService.getCategoryStats()
        } catch {
            self.error = error.localizedDescription
            return []
        }
    }
}

