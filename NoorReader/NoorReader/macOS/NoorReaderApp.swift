// NoorReaderApp.swift
// NoorReader
//
// App entry point for macOS

import SwiftUI
import SwiftData

@main
struct NoorReaderApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Book.self,
            Highlight.self,
            Bookmark.self,
            Collection.self,
            Note.self,
            Flashcard.self,
            ReviewLog.self,
            StudySession.self,
            StudyStreak.self,
            BookCategory.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MacContentView()
                .onAppear {
                    // Configure services with model context
                    let context = sharedModelContainer.mainContext
                    FlashcardService.shared.configure(modelContext: context)
                    StudySessionService.shared.configure(modelContext: context)
                    LibraryScannerService.shared.configure(modelContext: context)

                    // Auto-import library if configured and library is empty
                    Task {
                        await autoImportLibraryIfNeeded(context: context)
                    }
                }
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            MacMenuCommands()
        }

        Settings {
            SettingsView()
        }
    }

    /// Auto-import library on first launch if path is configured
    @MainActor
    private func autoImportLibraryIfNeeded(context: ModelContext) async {
        // Check if library is empty
        let descriptor = FetchDescriptor<Book>()
        guard let books = try? context.fetch(descriptor), books.isEmpty else {
            return // Library already has books
        }

        // Check if library path is configured
        guard let libraryPath = LibraryScannerService.shared.savedLibraryPath else {
            return // No library configured
        }

        // Import the library
        print("Auto-importing library from: \(libraryPath.path)")
        do {
            let result = try await LibraryScannerService.shared.scanFolder(at: libraryPath) { progress in
                print("Importing: \(progress.current)/\(progress.total) - \(progress.currentFile)")
            }
            print("Import complete: \(result.summary)")
        } catch {
            print("Auto-import failed: \(error.localizedDescription)")
        }
    }
}
