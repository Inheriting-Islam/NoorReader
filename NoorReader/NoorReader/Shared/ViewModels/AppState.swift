// AppState.swift
// NoorReader
//
// Global app state management

import SwiftUI
import SwiftData

@MainActor
@Observable
final class AppState {
    static let shared = AppState()

    // MARK: - Navigation State

    var selectedCollection: LibraryCollection = .all
    var selectedBook: Book?
    var columnVisibility: NavigationSplitViewVisibility = .all

    // MARK: - UI State

    var showLaunchDua: Bool = true
    var showSettings: Bool = false

    // MARK: - Private

    private init() {
        // Check if launch dua should be shown
        showLaunchDua = UserDefaults.standard.object(forKey: "showLaunchDua") as? Bool ?? true
    }

    // MARK: - Actions

    func openBook(_ book: Book) {
        selectedBook = book
    }

    func closeBook() {
        selectedBook = nil
    }

    func dismissLaunchDua() {
        withAnimation(.easeOut(duration: 0.5)) {
            showLaunchDua = false
        }
    }
}

// MARK: - Library Collection Types

enum LibraryCollection: Hashable {
    case all
    case readingNow
    case favorites
    case recentlyAdded
    case custom(Collection)

    var displayName: String {
        switch self {
        case .all: return "All Books"
        case .readingNow: return "Reading Now"
        case .favorites: return "Favorites"
        case .recentlyAdded: return "Recently Added"
        case .custom(let collection): return collection.name
        }
    }

    var icon: String {
        switch self {
        case .all: return "books.vertical"
        case .readingNow: return "book"
        case .favorites: return "star"
        case .recentlyAdded: return "clock"
        case .custom: return "folder"
        }
    }
}
