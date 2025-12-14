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
            Collection.self
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
}
