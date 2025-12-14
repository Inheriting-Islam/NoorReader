// LibraryViewModel.swift
// NoorReader
//
// Library view state management

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@MainActor
@Observable
final class LibraryViewModel {
    // MARK: - State

    var searchText = ""
    var sortOrder: SortOrder = .dateAdded
    var isImporting = false
    var importError: LibraryError?
    var showingError = false

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Filtering

    func filterBooks(_ books: [Book], for collection: LibraryCollection) -> [Book] {
        var filtered = books

        // Filter by collection
        switch collection {
        case .all:
            break
        case .readingNow:
            filtered = filtered.filter { $0.isStarted && !$0.isCompleted }
        case .favorites:
            filtered = filtered.filter { $0.isFavorite }
        case .recentlyAdded:
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            filtered = filtered.filter { $0.dateAdded >= thirtyDaysAgo }
        case .custom(let collection):
            filtered = filtered.filter { $0.collections.contains(collection) }
        case .category(let category):
            filtered = filtered.filter { $0.category?.id == category.id }
        }

        // Filter by search
        if !searchText.isEmpty {
            filtered = filtered.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.author.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Sort
        switch sortOrder {
        case .title:
            filtered.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .author:
            filtered.sort { $0.author.localizedCompare($1.author) == .orderedAscending }
        case .dateAdded:
            filtered.sort { $0.dateAdded > $1.dateAdded }
        case .lastRead:
            filtered.sort { ($0.lastRead ?? .distantPast) > ($1.lastRead ?? .distantPast) }
        case .progress:
            filtered.sort { $0.progress > $1.progress }
        }

        return filtered
    }

    // MARK: - Import

    func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            Task {
                let service = LibraryService(modelContext: modelContext)
                for url in urls {
                    do {
                        _ = try await service.importPDF(from: url)
                    } catch let error as LibraryError {
                        importError = error
                        showingError = true
                    } catch {
                        importError = .saveFailed
                        showingError = true
                    }
                }
            }
        case .failure:
            importError = .accessDenied
            showingError = true
        }
    }

    func handleDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.pdf.identifier, options: nil) { [weak self] item, _ in
                guard let url = item as? URL else { return }

                Task { @MainActor in
                    guard let self else { return }
                    let service = LibraryService(modelContext: self.modelContext)
                    do {
                        _ = try await service.importPDF(from: url)
                    } catch let error as LibraryError {
                        self.importError = error
                        self.showingError = true
                    } catch {
                        self.importError = .saveFailed
                        self.showingError = true
                    }
                }
            }
        }
    }
}

// MARK: - Sort Order

enum SortOrder: String, CaseIterable, Identifiable {
    case title
    case author
    case dateAdded
    case lastRead
    case progress

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .title: return "Title"
        case .author: return "Author"
        case .dateAdded: return "Date Added"
        case .lastRead: return "Last Read"
        case .progress: return "Progress"
        }
    }
}
