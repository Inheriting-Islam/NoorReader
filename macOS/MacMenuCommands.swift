// MacMenuCommands.swift
// NoorReader
//
// Menu bar commands and keyboard shortcuts

import SwiftUI

struct MacMenuCommands: Commands {
    var body: some Commands {
        // File Menu
        CommandGroup(replacing: .newItem) {
            Button("Open...") {
                NotificationCenter.default.post(name: .openFile, object: nil)
            }
            .keyboardShortcut("o")

            Divider()

            Button("Export Annotations...") {
                NotificationCenter.default.post(name: .exportAnnotations, object: nil)
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])

            Divider()

            Button("Close Window") {
                NSApp.keyWindow?.close()
            }
            .keyboardShortcut("w")
        }

        // Edit Menu additions
        CommandGroup(after: .pasteboard) {
            Divider()

            Button("Find...") {
                NotificationCenter.default.post(name: .toggleSearch, object: nil)
            }
            .keyboardShortcut("f")

            Button("Find Next") {
                NotificationCenter.default.post(name: .findNext, object: nil)
            }
            .keyboardShortcut("g")

            Button("Find Previous") {
                NotificationCenter.default.post(name: .findPrevious, object: nil)
            }
            .keyboardShortcut("g", modifiers: [.command, .shift])
        }

        // View Menu
        CommandMenu("View") {
            Button("Toggle Left Sidebar") {
                NotificationCenter.default.post(name: .toggleLeftSidebar, object: nil)
            }
            .keyboardShortcut("l", modifiers: [.command, .shift])

            Button("Toggle Annotations Sidebar") {
                NotificationCenter.default.post(name: .toggleRightSidebar, object: nil)
            }
            .keyboardShortcut("a", modifiers: [.command, .shift])

            Divider()

            Button("Zoom In") {
                NotificationCenter.default.post(name: .zoomIn, object: nil)
            }
            .keyboardShortcut("+", modifiers: .command)

            Button("Zoom Out") {
                NotificationCenter.default.post(name: .zoomOut, object: nil)
            }
            .keyboardShortcut("-", modifiers: .command)

            Button("Actual Size") {
                NotificationCenter.default.post(name: .actualSize, object: nil)
            }
            .keyboardShortcut("0")

            Divider()

            Button("Cycle Theme") {
                ThemeService.shared.cycleTheme()
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])

            Divider()

            Button("Focus Mode") {
                NotificationCenter.default.post(name: .toggleFocusMode, object: nil)
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])
        }

        // Go Menu
        CommandMenu("Go") {
            Button("Go to Page...") {
                NotificationCenter.default.post(name: .goToPage, object: nil)
            }
            .keyboardShortcut("g", modifiers: [.command, .option])

            Divider()

            Button("Previous Page") {
                NotificationCenter.default.post(name: .previousPage, object: nil)
            }
            .keyboardShortcut(.leftArrow)

            Button("Next Page") {
                NotificationCenter.default.post(name: .nextPage, object: nil)
            }
            .keyboardShortcut(.rightArrow)

            Divider()

            Button("First Page") {
                NotificationCenter.default.post(name: .firstPage, object: nil)
            }
            .keyboardShortcut(.home)

            Button("Last Page") {
                NotificationCenter.default.post(name: .lastPage, object: nil)
            }
            .keyboardShortcut(.end)
        }

        // Annotations Menu
        CommandMenu("Annotations") {
            // Highlight colors
            Menu("Highlight Selection") {
                ForEach(HighlightColor.allCases) { color in
                    Button("\(color.displayName) (\(color.shortcut))") {
                        NotificationCenter.default.post(name: .highlightWithColor, object: color)
                    }
                    .keyboardShortcut(KeyEquivalent(Character(color.shortcut)), modifiers: [])
                }
            }

            Button("Add Note") {
                NotificationCenter.default.post(name: .addNote, object: nil)
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])

            Divider()

            Button("Add Bookmark") {
                NotificationCenter.default.post(name: .addBookmark, object: nil)
            }
            .keyboardShortcut("d")

            Divider()

            Button("Export Annotations...") {
                NotificationCenter.default.post(name: .exportAnnotations, object: nil)
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
        }

        // Remove the old Bookmarks menu as we've moved it to Annotations
        CommandGroup(replacing: .help) {
            Button("NoorReader Help") {
                // Open documentation
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    // File
    static let openFile = Notification.Name("openFile")
    static let exportAnnotations = Notification.Name("exportAnnotations")

    // Search
    static let toggleSearch = Notification.Name("toggleSearch")
    static let findNext = Notification.Name("findNext")
    static let findPrevious = Notification.Name("findPrevious")

    // View
    static let toggleLeftSidebar = Notification.Name("toggleLeftSidebar")
    static let toggleRightSidebar = Notification.Name("toggleRightSidebar")
    static let zoomIn = Notification.Name("zoomIn")
    static let zoomOut = Notification.Name("zoomOut")
    static let actualSize = Notification.Name("actualSize")
    static let toggleFocusMode = Notification.Name("toggleFocusMode")

    // Navigation
    static let goToPage = Notification.Name("goToPage")
    static let previousPage = Notification.Name("previousPage")
    static let nextPage = Notification.Name("nextPage")
    static let firstPage = Notification.Name("firstPage")
    static let lastPage = Notification.Name("lastPage")

    // Annotations
    static let addBookmark = Notification.Name("addBookmark")
    static let addNote = Notification.Name("addNote")
    static let highlightWithColor = Notification.Name("highlightWithColor")

    // Focus Mode
    static let exitFocusMode = Notification.Name("exitFocusMode")
}
