# Phase 1: Foundation (MVP) - Development Prompt

بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ

**In the name of Allah, the Most Gracious, the Most Merciful.**

---

> "Allah loves that when one of you does something, he does it with excellence (itqan)."
> — Prophet Muhammad ﷺ

This prompt guides the development of NoorReader Phase 1 with **Ihsan** — excellence, beauty, and attention to every detail. We build this app as if presenting it to Allah, with sincerity and craftsmanship in every line of code.

---

## Table of Contents

1. [Phase 1 Overview](#phase-1-overview)
2. [Guiding Principles](#guiding-principles)
3. [Development Environment](#development-environment)
4. [Project Structure](#project-structure)
5. [Implementation Tasks](#implementation-tasks)
   - [Task 1: Project Setup](#task-1-project-setup)
   - [Task 2: macOS App Shell](#task-2-macos-app-shell)
   - [Task 3: Library Management](#task-3-library-management)
   - [Task 4: PDF Viewer](#task-4-pdf-viewer)
   - [Task 5: Theme System](#task-5-theme-system)
   - [Task 6: Navigation](#task-6-navigation)
   - [Task 7: Basic Highlights](#task-7-basic-highlights)
   - [Task 8: Islamic Launch Dua](#task-8-islamic-launch-dua)
   - [Task 9: Prayer Time Indicator](#task-9-prayer-time-indicator)
6. [Quality Standards](#quality-standards)
7. [Testing Requirements](#testing-requirements)
8. [Phase 1 Completion Criteria](#phase-1-completion-criteria)

---

## Phase 1 Overview

**Objective:** Build a functional, beautiful PDF reader for macOS with the foundational architecture that will support all future features.

**Duration:** Build with care, not with haste. Ihsan over speed.

**Deliverable:** A macOS app that can:
- Import and organize PDF books in a library
- Read PDFs with smooth rendering and navigation
- Apply reading themes (Day, Sepia, Night)
- Create basic highlights on text
- Display Islamic reminders (launch dua, prayer times)

---

## Guiding Principles

### 1. Bismillah - Begin with Allah's Name
Start every coding session with Bismillah. This is not just software — it is a tool to help Muslims seek knowledge, which is an act of worship. Code with that intention.

### 2. Itqan - Excellence in Craft
```
Do not rush. Do not take shortcuts.
Every function should be clear.
Every variable should be named with purpose.
Every UI element should be intentional.
If something feels "good enough," make it better.
```

### 3. Amanah - Trust and Responsibility
Users will trust this app with their books, notes, and study time. Honor that trust:
- Never lose user data
- Never compromise privacy
- Never waste their time with slow performance
- Never frustrate them with confusing UI

### 4. Ihsan - Beauty and Perfection
```
"Allah is Beautiful and loves beauty." — Sahih Muslim

The code should be beautiful.
The architecture should be elegant.
The UI should bring joy.
The animations should be smooth.
```

### 5. Sabr - Patience
When facing bugs or difficult problems:
- Take a break and make dua
- Return with fresh eyes
- The solution will come, insha'Allah

---

## Development Environment

### Required Software

| Software | Version | Purpose |
|----------|---------|---------|
| macOS | 15.0+ (Sequoia) | Development & target platform |
| Xcode | 16.0+ | IDE and build tools |
| Swift | 6.0 | Programming language |
| Git | Latest | Version control |

### Xcode Configuration

```
Project Settings:
├── Deployment Target: macOS 15.0
├── Swift Language Version: Swift 6
├── Strict Concurrency Checking: Complete
└── Build Settings:
    ├── SWIFT_STRICT_CONCURRENCY = complete
    └── ENABLE_USER_SCRIPT_SANDBOXING = YES
```

### Required Frameworks

| Framework | Purpose | Apple Documentation |
|-----------|---------|---------------------|
| SwiftUI | User interface | [SwiftUI](https://developer.apple.com/documentation/swiftui) |
| SwiftData | Data persistence | [SwiftData](https://developer.apple.com/documentation/swiftdata) |
| PDFKit | PDF rendering | [PDFKit](https://developer.apple.com/documentation/pdfkit) |
| CoreLocation | Prayer time location | [CoreLocation](https://developer.apple.com/documentation/corelocation) |

### Hybrid VSCode + Xcode Workflow

Use **VSCode** for fast editing and **Xcode** when Apple-specific tooling is needed.

#### VSCode Setup

**Required Extensions:**
| Extension | Publisher | Purpose |
|-----------|-----------|---------|
| Swift | Swift Server Work Group | Syntax highlighting, code completion, IntelliSense |
| CodeLLDB | Vadim Chugunov | Debugger support |

**Optional Extensions:**
| Extension | Purpose |
|-----------|---------|
| SwiftLint | Code style enforcement |
| GitLens | Enhanced Git integration |

**Verify Swift is installed:**
```bash
swift --version
# Should show Swift 6.0 or later
```

#### Initial Project Creation (One-Time in Xcode)

You must create the project in Xcode first, then edit in VSCode:

```bash
# 1. Clone the NoorReader repo
git clone https://github.com/Inheriting-Islam/NoorReader.git
cd NoorReader

# 2. Open Xcode
open -a Xcode
```

**In Xcode:**
1. File → New → Project
2. Select: **macOS** → **App**
3. Configure:
   - **Product Name:** `NoorReader`
   - **Team:** Your Apple ID (or "None" for local development)
   - **Organization Identifier:** `com.inheritingislam`
   - **Interface:** `SwiftUI`
   - **Storage:** `SwiftData`
   - **Language:** `Swift`
4. Save in the cloned `NoorReader/` directory
5. Close Xcode

#### Daily Development Workflow

**Open project in VSCode:**
```bash
cd NoorReader
code .
```

**Build from terminal:**
```bash
# Debug build
xcodebuild -scheme NoorReader -configuration Debug build

# Release build
xcodebuild -scheme NoorReader -configuration Release build
```

**Run the app:**
```bash
# Find and run the built app
open $(find ~/Library/Developer/Xcode/DerivedData -name "NoorReader.app" -path "*/Debug/*" | head -1)
```

**Quick build + run script** (save as `run.sh` in project root):
```bash
#!/bin/bash
# run.sh - Build and run NoorReader
set -e
echo "بِسْمِ اللَّهِ - Building NoorReader..."
xcodebuild -scheme NoorReader -configuration Debug build -quiet
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "NoorReader.app" -path "*/Debug/*" | head -1)
echo "Running NoorReader..."
open "$APP_PATH"
```

Make it executable:
```bash
chmod +x run.sh
./run.sh
```

#### When to Use Each Tool

| Task | Tool | Why |
|------|------|-----|
| Writing/editing code | VSCode | Faster, familiar keybindings |
| Building project | Terminal (`xcodebuild`) | Scriptable, VSCode integrated terminal |
| SwiftUI Previews | Xcode | Only available in Xcode Canvas |
| Debugging UI issues | Xcode | Better SwiftUI debugging tools |
| Adding new files | Either | VSCode is faster, but update Xcode project |
| Adding frameworks | Xcode | Manages dependencies properly |
| Code signing & archives | Xcode | Required for distribution |
| Git operations | VSCode or terminal | VSCode has great Git integration |

#### Adding New Files

When you create new `.swift` files in VSCode, you need to add them to the Xcode project:

**Option A: Quick add via Xcode (recommended)**
1. Open `NoorReader.xcodeproj` in Xcode
2. Right-click the target folder → "Add Files to NoorReader"
3. Select your new files
4. Close Xcode, continue in VSCode

**Option B: Let Xcode discover on next build**
- Files in the project folder are often auto-discovered
- If not, use Option A

#### Terminal Aliases (Optional)

Add to your `~/.zshrc` or `~/.bashrc`:
```bash
# NoorReader development shortcuts
alias nr-build="cd ~/path/to/NoorReader && xcodebuild -scheme NoorReader -configuration Debug build -quiet"
alias nr-run="open \$(find ~/Library/Developer/Xcode/DerivedData -name 'NoorReader.app' -path '*/Debug/*' | head -1)"
alias nr-dev="nr-build && nr-run"
alias nr-xcode="open NoorReader.xcodeproj"
```

Then just type:
```bash
nr-dev    # Build and run
nr-xcode  # Open in Xcode for previews
```

---

## Project Structure

Create this exact folder structure. Every file has its place, like a well-organized masjid.

```
NoorReader/
│
├── NoorReader.xcodeproj
│
├── Shared/                              # 80% of codebase — cross-platform
│   │
│   ├── Models/                          # SwiftData models
│   │   ├── Book.swift                   # PDF book model
│   │   ├── Highlight.swift              # Text highlight model
│   │   ├── Bookmark.swift               # Page bookmark model
│   │   ├── Collection.swift             # Book collection/folder model
│   │   └── IslamicReminder.swift        # Dua/Hadith content model
│   │
│   ├── Services/                        # Business logic
│   │   ├── PDFService.swift             # PDF operations
│   │   ├── LibraryService.swift         # Library management
│   │   ├── ThemeService.swift           # Theme management
│   │   ├── PrayerTimeService.swift      # Aladhan API integration
│   │   └── ReminderService.swift        # Islamic content delivery
│   │
│   ├── ViewModels/                      # State management
│   │   ├── AppState.swift               # Global app state
│   │   ├── LibraryViewModel.swift       # Library view state
│   │   ├── ReaderViewModel.swift        # PDF reader state
│   │   └── SettingsViewModel.swift      # User preferences
│   │
│   ├── Components/                      # Reusable SwiftUI views
│   │   ├── BookCard.swift               # Library grid item
│   │   ├── PDFViewRepresentable.swift   # PDFKit wrapper
│   │   ├── SelectionPopover.swift       # Text selection actions
│   │   ├── ReminderBanner.swift         # Islamic reminder display
│   │   ├── PrayerTimeIndicator.swift    # Prayer time widget
│   │   ├── ProgressBar.swift            # Reading progress
│   │   └── ThemePicker.swift            # Theme selection
│   │
│   ├── Extensions/                      # Swift extensions
│   │   ├── Color+Theme.swift            # App color palette
│   │   ├── Font+App.swift               # Typography system
│   │   ├── View+Modifiers.swift         # Custom view modifiers
│   │   ├── String+Arabic.swift          # RTL text handling
│   │   └── Date+Formatting.swift        # Date formatting
│   │
│   └── Resources/                       # Static assets
│       ├── IslamicContent/
│       │   ├── duas_study.json          # Study duas
│       │   └── hadith_knowledge.json    # Knowledge hadith
│       └── Assets.xcassets/
│           ├── AppIcon.appiconset/      # App icons
│           └── Colors/                  # Color assets
│
├── macOS/                               # macOS-specific code
│   ├── NoorReaderApp.swift              # App entry point
│   ├── MacContentView.swift             # Main window layout
│   ├── Views/
│   │   ├── MacLibraryView.swift         # Library sidebar + grid
│   │   ├── MacReaderView.swift          # PDF reader view
│   │   └── MacSidebarView.swift         # Left sidebar
│   ├── MacMenuCommands.swift            # Menu bar commands
│   └── MacKeyboardShortcuts.swift       # Keyboard shortcuts
│
├── Tests/
│   ├── SharedTests/                     # Unit tests
│   │   ├── ModelTests/
│   │   ├── ServiceTests/
│   │   └── ViewModelTests/
│   └── macOSTests/                      # UI tests
│
└── Documentation/
    ├── MASTER_PROMPT.md
    ├── NAVIGATION.md
    ├── NAVIGATION_DIAGRAM.md
    └── PHASE_1_PROMPT.md
```

---

## Implementation Tasks

### Task 1: Project Setup

**GitHub Issue:** #1 - Project Setup: Swift 6, SwiftUI, SwiftData

**Objective:** Create the Xcode project with proper configuration for Swift 6 strict concurrency.

#### Steps

1. **Create New Xcode Project**
   ```
   File → New → Project
   ├── Platform: macOS
   ├── Template: App
   ├── Product Name: NoorReader
   ├── Team: [Your Team]
   ├── Organization Identifier: com.inheritingislam
   ├── Bundle Identifier: com.inheritingislam.noorreader
   ├── Interface: SwiftUI
   ├── Language: Swift
   └── Storage: SwiftData ✓
   ```

2. **Configure Swift 6 Strict Concurrency**

   In `NoorReader.xcodeproj`, set Build Settings:
   ```
   SWIFT_VERSION = 6.0
   SWIFT_STRICT_CONCURRENCY = complete
   ```

3. **Create Folder Structure**

   Create all folders as specified in Project Structure above.

4. **Configure SwiftData Container**

   ```swift
   // Shared/Models/Book.swift
   import SwiftData

   @Model
   final class Book {
       var id: UUID
       var title: String
       var author: String
       var fileURL: URL
       var coverImageData: Data?
       var dateAdded: Date
       var lastRead: Date?
       var currentPage: Int
       var totalPages: Int
       var isFavorite: Bool

       @Relationship(deleteRule: .cascade)
       var highlights: [Highlight]

       @Relationship(deleteRule: .cascade)
       var bookmarks: [Bookmark]

       var progress: Double {
           guard totalPages > 0 else { return 0 }
           return Double(currentPage) / Double(totalPages)
       }

       init(
           title: String,
           author: String = "Unknown",
           fileURL: URL,
           totalPages: Int = 0
       ) {
           self.id = UUID()
           self.title = title
           self.author = author
           self.fileURL = fileURL
           self.dateAdded = Date()
           self.currentPage = 0
           self.totalPages = totalPages
           self.isFavorite = false
           self.highlights = []
           self.bookmarks = []
       }
   }
   ```

5. **Create App Entry Point**

   ```swift
   // macOS/NoorReaderApp.swift
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
           .commands {
               MacMenuCommands()
           }
       }

       Settings {
           SettingsView()
       }
   }
   ```

6. **Configure SwiftLint**

   Create `.swiftlint.yml` in project root:
   ```yaml
   disabled_rules:
     - trailing_whitespace
     - line_length

   opt_in_rules:
     - empty_count
     - closure_spacing
     - overridden_super_call
     - redundant_nil_coalescing
     - private_outlet
     - nimble_operator
     - attributes
     - operator_usage_whitespace
     - closure_end_indentation
     - first_where
     - sorted_first_last
     - object_literal
     - number_separator
     - prohibited_super_call
     - fatal_error_message

   included:
     - Shared
     - macOS

   excluded:
     - Tests

   line_length:
     warning: 120
     error: 200

   type_body_length:
     warning: 300
     error: 500

   file_length:
     warning: 500
     error: 1000

   identifier_name:
     min_length:
       warning: 2
     excluded:
       - id
       - x
       - y
   ```

#### Acceptance Criteria
- [ ] Project builds without errors
- [ ] Swift 6 strict concurrency enabled (no warnings)
- [ ] SwiftData container initializes correctly
- [ ] Folder structure matches specification
- [ ] SwiftLint runs and passes

---

### Task 2: macOS App Shell

**GitHub Issue:** #9 - macOS App Shell: Three-Panel NavigationSplitView

**Objective:** Build the main window layout with three-panel navigation.

#### Layout Specification

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  NoorReader                                               🎨  🕌 Asr 45m    │
├────────────┬────────────────────────────────────────────────┬───────────────┤
│            │                                                │               │
│  SIDEBAR   │              MAIN CONTENT                      │   INSPECTOR   │
│  (240px)   │              (flexible)                        │   (280px)     │
│            │                                                │               │
│  Library   │                                                │  Annotations  │
│  ───────── │                                                │  ──────────── │
│  📚 All    │         Library Grid / PDF Reader              │  (Phase 2)    │
│  📖 Reading│                                                │               │
│  ⭐ Favs   │                                                │  Study        │
│            │                                                │  ──────────── │
│  Contents  │                                                │  (Phase 4)    │
│  ───────── │                                                │               │
│  (when     │                                                │               │
│   reading) │                                                │               │
│            │                                                │               │
└────────────┴────────────────────────────────────────────────┴───────────────┘
```

#### Implementation

```swift
// macOS/MacContentView.swift
import SwiftUI
import SwiftData

struct MacContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedCollection: LibraryCollection = .all
    @State private var selectedBook: Book?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showLaunchDua: Bool = true

    var body: some View {
        ZStack {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                // Left Sidebar (240px)
                MacSidebarView(
                    selectedCollection: $selectedCollection,
                    selectedBook: $selectedBook
                )
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
            } content: {
                // Main Content (flexible)
                if let book = selectedBook {
                    MacReaderView(book: book)
                } else {
                    MacLibraryView(
                        collection: selectedCollection,
                        selectedBook: $selectedBook
                    )
                }
            } detail: {
                // Right Sidebar - Inspector (280px)
                // Phase 2: Annotations
                // Phase 4: Study Tools
                Text("Inspector Panel")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(nsColor: .windowBackgroundColor))
                    .navigationSplitViewColumnWidth(min: 250, ideal: 280, max: 350)
            }
            .navigationSplitViewStyle(.balanced)

            // Launch Dua Banner (overlay)
            if showLaunchDua {
                LaunchDuaBanner(isPresented: $showLaunchDua)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .onAppear {
            // Auto-dismiss launch dua after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showLaunchDua = false
                }
            }
        }
    }
}

// Library collection types
enum LibraryCollection: Hashable {
    case all
    case readingNow
    case favorites
    case recentlyAdded
    case custom(Collection)
}
```

```swift
// macOS/Views/MacSidebarView.swift
import SwiftUI
import SwiftData

struct MacSidebarView: View {
    @Binding var selectedCollection: LibraryCollection
    @Binding var selectedBook: Book?
    @Query private var collections: [Collection]

    var body: some View {
        List(selection: $selectedCollection) {
            // Library Section
            Section("Library") {
                Label("All Books", systemImage: "books.vertical")
                    .tag(LibraryCollection.all)

                Label("Reading Now", systemImage: "book")
                    .tag(LibraryCollection.readingNow)

                Label("Favorites", systemImage: "star")
                    .tag(LibraryCollection.favorites)

                Label("Recently Added", systemImage: "clock")
                    .tag(LibraryCollection.recentlyAdded)
            }

            // Custom Collections
            if !collections.isEmpty {
                Section("Collections") {
                    ForEach(collections) { collection in
                        Label(collection.name, systemImage: "folder")
                            .tag(LibraryCollection.custom(collection))
                    }
                }
            }

            // Table of Contents (when book is open)
            if let book = selectedBook {
                Section("Contents") {
                    // Will be populated from PDF outline
                    Text("Table of Contents")
                        .foregroundStyle(.secondary)
                }

                Section("Bookmarks") {
                    ForEach(book.bookmarks) { bookmark in
                        Label("Page \(bookmark.pageNumber)", systemImage: "bookmark")
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .toolbar {
            ToolbarItem {
                Button(action: { /* Add collection */ }) {
                    Image(systemName: "folder.badge.plus")
                }
            }
        }
    }
}
```

#### Keyboard Shortcuts

```swift
// macOS/MacKeyboardShortcuts.swift
import SwiftUI

struct MacKeyboardShortcuts: Commands {
    @FocusedBinding(\.selectedBook) var selectedBook

    var body: some Commands {
        // File Menu
        CommandGroup(replacing: .newItem) {
            Button("Open...") {
                // Open file dialog
            }
            .keyboardShortcut("o")
        }

        // View Menu
        CommandMenu("View") {
            Button("Toggle Left Sidebar") {
                // Toggle sidebar
            }
            .keyboardShortcut("l", modifiers: [.command, .shift])

            Button("Toggle Right Sidebar") {
                // Toggle inspector
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])

            Divider()

            Button("Zoom In") {
                // Zoom in
            }
            .keyboardShortcut("+")

            Button("Zoom Out") {
                // Zoom out
            }
            .keyboardShortcut("-")

            Button("Actual Size") {
                // Reset zoom
            }
            .keyboardShortcut("0")
        }

        // Go Menu
        CommandMenu("Go") {
            Button("Go to Page...") {
                // Show go to page dialog
            }
            .keyboardShortcut("g")

            Divider()

            Button("Previous Page") {
                // Previous page
            }
            .keyboardShortcut(.upArrow)

            Button("Next Page") {
                // Next page
            }
            .keyboardShortcut(.downArrow)
        }
    }
}
```

#### Acceptance Criteria
- [ ] Three-panel NavigationSplitView displays correctly
- [ ] Sidebars toggle with ⌘⇧L and ⌘⇧R
- [ ] Window has minimum size of 900x600
- [ ] Sidebar widths are appropriate (240px left, 280px right)
- [ ] Window state persists across launches
- [ ] Menu commands are functional

---

### Task 3: Library Management

**GitHub Issue:** #3 - Library Management: Import, List, Organize

**Objective:** Enable users to import PDFs, view them in a grid, and organize into collections.

#### Book Model (Complete)

```swift
// Shared/Models/Book.swift
import SwiftData
import Foundation

@Model
final class Book {
    // MARK: - Properties

    @Attribute(.unique) var id: UUID
    var title: String
    var author: String
    var fileURL: URL
    @Attribute(.externalStorage) var coverImageData: Data?
    var dateAdded: Date
    var lastRead: Date?
    var currentPage: Int
    var totalPages: Int
    var isFavorite: Bool

    // MARK: - Relationships

    @Relationship(deleteRule: .cascade, inverse: \Highlight.book)
    var highlights: [Highlight] = []

    @Relationship(deleteRule: .cascade, inverse: \Bookmark.book)
    var bookmarks: [Bookmark] = []

    @Relationship(inverse: \Collection.books)
    var collections: [Collection] = []

    // MARK: - Computed Properties

    var progress: Double {
        guard totalPages > 0 else { return 0 }
        return Double(currentPage) / Double(totalPages)
    }

    var progressPercentage: Int {
        Int(progress * 100)
    }

    var isStarted: Bool {
        currentPage > 0
    }

    var isCompleted: Bool {
        currentPage >= totalPages && totalPages > 0
    }

    var displayTitle: String {
        title.isEmpty ? "Untitled" : title
    }

    var displayAuthor: String {
        author.isEmpty ? "Unknown Author" : author
    }

    // MARK: - Initialization

    init(
        title: String,
        author: String = "",
        fileURL: URL,
        totalPages: Int = 0
    ) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.fileURL = fileURL
        self.dateAdded = Date()
        self.currentPage = 0
        self.totalPages = totalPages
        self.isFavorite = false
    }
}
```

#### Library Service

```swift
// Shared/Services/LibraryService.swift
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

        // Create bookmark for persistent access
        let bookmarkData = try finalURL.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

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
```

#### Book Card Component

```swift
// Shared/Components/BookCard.swift
import SwiftUI
import SwiftData

struct BookCard: View {
    let book: Book
    let onOpen: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cover Image
            ZStack(alignment: .topTrailing) {
                coverImage

                // Favorite Badge
                if book.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                        .padding(6)
                        .background(.ultraThinMaterial, in: Circle())
                        .padding(8)
                }
            }
            .aspectRatio(3/4, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            // Title
            Text(book.displayTitle)
                .font(.headline)
                .lineLimit(2)
                .foregroundStyle(.primary)

            // Author
            Text(book.displayAuthor)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            // Progress Bar
            if book.isStarted {
                ProgressView(value: book.progress)
                    .tint(Color.noorTeal)

                Text("\(book.progressPercentage)%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovering ? Color.gray.opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .onTapGesture(count: 2) {
            onOpen()
        }
        .contextMenu {
            Button("Open") { onOpen() }
            Button("Open in New Window") { /* TODO */ }
            Divider()
            Button(book.isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                // Toggle favorite
            }
            Menu("Add to Collection") {
                // Collection options
            }
            Divider()
            Button("Show in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([book.fileURL])
            }
            Button("Get Info") { /* TODO */ }
            Divider()
            Button("Delete from Library", role: .destructive) {
                // Delete confirmation
            }
        }
    }

    @ViewBuilder
    private var coverImage: some View {
        if let imageData = book.coverImageData,
           let nsImage = NSImage(data: imageData) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFill()
        } else {
            // Placeholder cover
            ZStack {
                LinearGradient(
                    colors: [Color.noorTeal.opacity(0.8), Color.noorTeal],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 8) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.8))

                    Text(book.displayTitle)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .lineLimit(3)
                }
            }
        }
    }
}
```

#### Library Grid View

```swift
// macOS/Views/MacLibraryView.swift
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct MacLibraryView: View {
    let collection: LibraryCollection
    @Binding var selectedBook: Book?

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.dateAdded, order: .reverse) private var allBooks: [Book]

    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .dateAdded
    @State private var isImporting = false
    @State private var importError: LibraryError?
    @State private var showingError = false

    private var filteredBooks: [Book] {
        var books = allBooks

        // Filter by collection
        switch collection {
        case .all:
            break
        case .readingNow:
            books = books.filter { $0.isStarted && !$0.isCompleted }
        case .favorites:
            books = books.filter { $0.isFavorite }
        case .recentlyAdded:
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            books = books.filter { $0.dateAdded >= thirtyDaysAgo }
        case .custom(let collection):
            books = books.filter { $0.collections.contains(collection) }
        }

        // Filter by search
        if !searchText.isEmpty {
            books = books.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.author.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Sort
        switch sortOrder {
        case .title:
            books.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .author:
            books.sort { $0.author.localizedCompare($1.author) == .orderedAscending }
        case .dateAdded:
            books.sort { $0.dateAdded > $1.dateAdded }
        case .lastRead:
            books.sort { ($0.lastRead ?? .distantPast) > ($1.lastRead ?? .distantPast) }
        case .progress:
            books.sort { $0.progress > $1.progress }
        }

        return books
    }

    var body: some View {
        Group {
            if filteredBooks.isEmpty {
                emptyState
            } else {
                bookGrid
            }
        }
        .searchable(text: $searchText, prompt: "Search library...")
        .toolbar {
            ToolbarItemGroup {
                sortMenu

                Button(action: { isImporting = true }) {
                    Image(systemName: "plus")
                }
                .help("Import PDF")
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [UTType.pdf],
            allowsMultipleSelection: true
        ) { result in
            handleImport(result)
        }
        .alert("Import Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importError?.localizedDescription ?? "Unknown error")
        }
        .onDrop(of: [UTType.pdf], isTargeted: nil) { providers in
            handleDrop(providers)
            return true
        }
    }

    // MARK: - Views

    private var bookGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 160, maximum: 200))],
                spacing: 24
            ) {
                ForEach(filteredBooks) { book in
                    BookCard(book: book) {
                        selectedBook = book
                    }
                }
            }
            .padding(24)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Books Yet")
                .font(.title2)
                .fontWeight(.medium)

            Text("Drag and drop PDF files here, or click + to import.")
                .foregroundStyle(.secondary)

            Button("Import PDF") {
                isImporting = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.noorTeal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort By", selection: $sortOrder) {
                ForEach(SortOrder.allCases) { order in
                    Text(order.displayName).tag(order)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .help("Sort Order")
    }

    // MARK: - Import Handling

    private func handleImport(_ result: Result<[URL], Error>) {
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

    private func handleDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.pdf.identifier, options: nil) { item, error in
                guard let url = item as? URL else { return }

                Task { @MainActor in
                    let service = LibraryService(modelContext: modelContext)
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
```

#### Acceptance Criteria
- [ ] Can import PDFs via drag-drop and menu
- [ ] Metadata extracted automatically (title, author, cover)
- [ ] Library displays as responsive grid
- [ ] Sorting works correctly (5 options)
- [ ] Books persist across app launches
- [ ] Search filters books in real-time
- [ ] Smart collections filter correctly
- [ ] Context menu works on book cards

---

### Task 4: PDF Viewer

**GitHub Issue:** #2 - Basic PDF Viewer with PDFKit

**Objective:** Implement smooth, performant PDF rendering.

#### PDF View Wrapper

```swift
// Shared/Components/PDFViewRepresentable.swift
import SwiftUI
import PDFKit

struct PDFViewRepresentable: NSViewRepresentable {
    let document: PDFDocument
    @Binding var currentPage: Int
    @Binding var scaleFactor: CGFloat
    let displayMode: PDFDisplayMode
    let onSelectionChanged: ((PDFSelection?) -> Void)?

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = displayMode
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .clear
        pdfView.delegate = context.coordinator

        // Enable text selection
        pdfView.acceptsFirstMouse(for: nil)

        // Set up notification for page changes
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged),
            name: .PDFViewPageChanged,
            object: pdfView
        )

        // Set up notification for selection changes
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.selectionChanged),
            name: .PDFViewSelectionChanged,
            object: pdfView
        )

        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        // Update display mode
        if pdfView.displayMode != displayMode {
            pdfView.displayMode = displayMode
        }

        // Update scale factor
        if pdfView.scaleFactor != scaleFactor {
            pdfView.scaleFactor = scaleFactor
        }

        // Navigate to page if changed externally
        if let page = document.page(at: currentPage),
           pdfView.currentPage != page {
            pdfView.go(to: page)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PDFViewDelegate {
        var parent: PDFViewRepresentable

        init(_ parent: PDFViewRepresentable) {
            self.parent = parent
        }

        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let currentPage = pdfView.currentPage,
                  let pageIndex = pdfView.document?.index(for: currentPage) else {
                return
            }

            DispatchQueue.main.async {
                self.parent.currentPage = pageIndex
            }
        }

        @objc func selectionChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView else { return }

            DispatchQueue.main.async {
                self.parent.onSelectionChanged?(pdfView.currentSelection)
            }
        }
    }
}

// MARK: - PDF Display Mode Extension

extension PDFDisplayMode {
    var displayName: String {
        switch self {
        case .singlePage: return "Single Page"
        case .singlePageContinuous: return "Continuous"
        case .twoUp: return "Two Pages"
        case .twoUpContinuous: return "Two Pages Continuous"
        @unknown default: return "Unknown"
        }
    }

    var icon: String {
        switch self {
        case .singlePage: return "doc"
        case .singlePageContinuous: return "doc.text"
        case .twoUp: return "book"
        case .twoUpContinuous: return "book.pages"
        @unknown default: return "doc"
        }
    }
}
```

#### Reader View Model

```swift
// Shared/ViewModels/ReaderViewModel.swift
import Foundation
import PDFKit
import SwiftData
import Combine

@MainActor
@Observable
final class ReaderViewModel {
    // MARK: - Properties

    let book: Book
    private(set) var document: PDFDocument?
    private(set) var isLoading = true
    private(set) var error: Error?

    var currentPage: Int {
        didSet {
            saveProgress()
        }
    }
    var scaleFactor: CGFloat = 1.0
    var displayMode: PDFDisplayMode = .singlePageContinuous
    var currentSelection: PDFSelection?

    // Search
    var searchText = ""
    var searchResults: [PDFSelection] = []
    var currentSearchIndex = 0
    var isSearching = false

    private let modelContext: ModelContext
    private var saveTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var totalPages: Int {
        document?.pageCount ?? 0
    }

    var progress: Double {
        guard totalPages > 0 else { return 0 }
        return Double(currentPage + 1) / Double(totalPages)
    }

    var pageLabel: String {
        "Page \(currentPage + 1) of \(totalPages)"
    }

    var currentSearchResult: PDFSelection? {
        guard !searchResults.isEmpty, currentSearchIndex < searchResults.count else { return nil }
        return searchResults[currentSearchIndex]
    }

    var searchResultsLabel: String {
        guard !searchResults.isEmpty else { return "No results" }
        return "\(currentSearchIndex + 1) of \(searchResults.count)"
    }

    // MARK: - Initialization

    init(book: Book, modelContext: ModelContext) {
        self.book = book
        self.modelContext = modelContext
        self.currentPage = book.currentPage

        Task {
            await loadDocument()
        }
    }

    // MARK: - Document Loading

    private func loadDocument() async {
        isLoading = true
        error = nil

        do {
            // Access security-scoped resource
            guard book.fileURL.startAccessingSecurityScopedResource() else {
                throw ReaderError.accessDenied
            }
            defer { book.fileURL.stopAccessingSecurityScopedResource() }

            guard let doc = PDFDocument(url: book.fileURL) else {
                throw ReaderError.cannotOpenDocument
            }

            self.document = doc

            // Update total pages if needed
            if book.totalPages != doc.pageCount {
                book.totalPages = doc.pageCount
                try? modelContext.save()
            }

            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    // MARK: - Navigation

    func goToPage(_ page: Int) {
        guard page >= 0, page < totalPages else { return }
        currentPage = page
    }

    func nextPage() {
        goToPage(currentPage + 1)
    }

    func previousPage() {
        goToPage(currentPage - 1)
    }

    func goToFirstPage() {
        goToPage(0)
    }

    func goToLastPage() {
        goToPage(totalPages - 1)
    }

    // MARK: - Zoom

    func zoomIn() {
        scaleFactor = min(scaleFactor * 1.25, 5.0)
    }

    func zoomOut() {
        scaleFactor = max(scaleFactor / 1.25, 0.25)
    }

    func resetZoom() {
        scaleFactor = 1.0
    }

    func fitToWidth() {
        // Will be calculated by PDFView
        scaleFactor = 1.0
    }

    // MARK: - Search

    func search() {
        guard !searchText.isEmpty, let document else {
            searchResults = []
            return
        }

        isSearching = true
        searchResults = []
        currentSearchIndex = 0

        Task {
            let results = document.findString(searchText, withOptions: .caseInsensitive)

            await MainActor.run {
                self.searchResults = results
                self.isSearching = false
            }
        }
    }

    func nextSearchResult() {
        guard !searchResults.isEmpty else { return }
        currentSearchIndex = (currentSearchIndex + 1) % searchResults.count
        navigateToCurrentSearchResult()
    }

    func previousSearchResult() {
        guard !searchResults.isEmpty else { return }
        currentSearchIndex = (currentSearchIndex - 1 + searchResults.count) % searchResults.count
        navigateToCurrentSearchResult()
    }

    private func navigateToCurrentSearchResult() {
        guard let selection = currentSearchResult,
              let page = selection.pages.first,
              let pageIndex = document?.index(for: page) else { return }

        currentPage = pageIndex
    }

    func clearSearch() {
        searchText = ""
        searchResults = []
        currentSearchIndex = 0
    }

    // MARK: - Progress Saving

    private func saveProgress() {
        // Debounce saves
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            guard !Task.isCancelled else { return }

            book.currentPage = currentPage
            book.lastRead = Date()
            try? modelContext.save()
        }
    }
}

// MARK: - Errors

enum ReaderError: LocalizedError {
    case accessDenied
    case cannotOpenDocument

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Cannot access the document. Please re-import the file."
        case .cannotOpenDocument:
            return "Cannot open the document. The file may be corrupted."
        }
    }
}
```

#### Reader View

```swift
// macOS/Views/MacReaderView.swift
import SwiftUI
import PDFKit
import SwiftData

struct MacReaderView: View {
    let book: Book

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ReaderViewModel?
    @State private var showGoToPage = false
    @State private var showSearch = false
    @State private var goToPageText = ""

    var body: some View {
        Group {
            if let viewModel {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                } else if let error = viewModel.error {
                    errorView(error)
                } else if let document = viewModel.document {
                    readerContent(document: document, viewModel: viewModel)
                }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            viewModel = ReaderViewModel(book: book, modelContext: modelContext)
        }
        .sheet(isPresented: $showGoToPage) {
            goToPageSheet
        }
    }

    // MARK: - Reader Content

    @ViewBuilder
    private func readerContent(document: PDFDocument, viewModel: ReaderViewModel) -> some View {
        VStack(spacing: 0) {
            // Search bar (if active)
            if showSearch {
                searchBar(viewModel: viewModel)
            }

            // PDF View
            PDFViewRepresentable(
                document: document,
                currentPage: Binding(
                    get: { viewModel.currentPage },
                    set: { viewModel.goToPage($0) }
                ),
                scaleFactor: Binding(
                    get: { viewModel.scaleFactor },
                    set: { viewModel.scaleFactor = $0 }
                ),
                displayMode: viewModel.displayMode,
                onSelectionChanged: { selection in
                    viewModel.currentSelection = selection
                }
            )
            .background(Color.readerBackground)

            // Bottom bar with page scrubber
            pageBar(viewModel: viewModel)
        }
        .toolbar {
            readerToolbar(viewModel: viewModel)
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleSearch)) { _ in
            showSearch.toggle()
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private func readerToolbar(viewModel: ReaderViewModel) -> some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            // Back button
            Button(action: { /* Go back to library */ }) {
                Image(systemName: "chevron.left")
            }
            .help("Back to Library")
        }

        ToolbarItemGroup(placement: .principal) {
            // View mode picker
            Picker("View Mode", selection: Binding(
                get: { viewModel.displayMode },
                set: { viewModel.displayMode = $0 }
            )) {
                Image(systemName: "doc").tag(PDFDisplayMode.singlePage)
                Image(systemName: "doc.text").tag(PDFDisplayMode.singlePageContinuous)
                Image(systemName: "book").tag(PDFDisplayMode.twoUp)
            }
            .pickerStyle(.segmented)
            .frame(width: 120)

            Divider()

            // Zoom controls
            Button(action: { viewModel.zoomOut() }) {
                Image(systemName: "minus.magnifyingglass")
            }
            .help("Zoom Out (⌘-)")

            Text("\(Int(viewModel.scaleFactor * 100))%")
                .frame(width: 50)
                .font(.caption)

            Button(action: { viewModel.zoomIn() }) {
                Image(systemName: "plus.magnifyingglass")
            }
            .help("Zoom In (⌘+)")
        }

        ToolbarItemGroup(placement: .automatic) {
            // Search
            Button(action: { showSearch.toggle() }) {
                Image(systemName: "magnifyingglass")
            }
            .help("Find in Document (⌘F)")

            // Bookmark
            Button(action: { /* Add bookmark */ }) {
                Image(systemName: "bookmark")
            }
            .help("Add Bookmark (⌘D)")

            // Theme picker
            ThemePicker()
        }
    }

    // MARK: - Search Bar

    @ViewBuilder
    private func searchBar(viewModel: ReaderViewModel) -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search in document...", text: Binding(
                get: { viewModel.searchText },
                set: { viewModel.searchText = $0 }
            ))
            .textFieldStyle(.plain)
            .onSubmit {
                viewModel.search()
            }

            if viewModel.isSearching {
                ProgressView()
                    .scaleEffect(0.7)
            } else if !viewModel.searchResults.isEmpty {
                Text(viewModel.searchResultsLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button(action: { viewModel.previousSearchResult() }) {
                    Image(systemName: "chevron.up")
                }
                .buttonStyle(.borderless)

                Button(action: { viewModel.nextSearchResult() }) {
                    Image(systemName: "chevron.down")
                }
                .buttonStyle(.borderless)
            }

            Button(action: {
                viewModel.clearSearch()
                showSearch = false
            }) {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Page Bar

    @ViewBuilder
    private func pageBar(viewModel: ReaderViewModel) -> some View {
        HStack {
            // Page indicator
            Button(action: { showGoToPage = true }) {
                Text(viewModel.pageLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Go to Page (⌘G)")

            Spacer()

            // Progress bar
            ProgressView(value: viewModel.progress)
                .frame(maxWidth: 300)

            Spacer()

            // Navigation buttons
            Button(action: { viewModel.previousPage() }) {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.borderless)
            .disabled(viewModel.currentPage == 0)

            Button(action: { viewModel.nextPage() }) {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.borderless)
            .disabled(viewModel.currentPage >= viewModel.totalPages - 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Go to Page Sheet

    private var goToPageSheet: some View {
        VStack(spacing: 16) {
            Text("Go to Page")
                .font(.headline)

            TextField("Page number", text: $goToPageText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
                .onSubmit {
                    if let page = Int(goToPageText) {
                        viewModel?.goToPage(page - 1)
                    }
                    showGoToPage = false
                    goToPageText = ""
                }

            if let viewModel {
                Text("1 - \(viewModel.totalPages)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("Cancel") {
                    showGoToPage = false
                    goToPageText = ""
                }
                .keyboardShortcut(.cancelAction)

                Button("Go") {
                    if let page = Int(goToPageText) {
                        viewModel?.goToPage(page - 1)
                    }
                    showGoToPage = false
                    goToPageText = ""
                }
                .keyboardShortcut(.defaultAction)
                .disabled(Int(goToPageText) == nil)
            }
        }
        .padding(24)
        .frame(width: 200)
    }

    // MARK: - Error View

    @ViewBuilder
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Cannot Open Document")
                .font(.title2)

            Text(error.localizedDescription)
                .foregroundStyle(.secondary)

            Button("Try Again") {
                viewModel = ReaderViewModel(book: book, modelContext: modelContext)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let toggleSearch = Notification.Name("toggleSearch")
}
```

#### Performance Targets

| Metric | Target | How to Achieve |
|--------|--------|----------------|
| Open 500-page PDF | < 2 seconds | Lazy loading, async loading |
| Page turn | < 50ms | Use PDFKit native rendering |
| Memory (large PDF) | < 500MB | Don't cache all pages |
| Zoom | Instant | Use PDFView.scaleFactor |

#### Acceptance Criteria
- [ ] Can open and display any standard PDF
- [ ] Page turns are smooth (< 50ms)
- [ ] Large documents (1000+ pages) load quickly
- [ ] Zoom works via trackpad and keyboard
- [ ] Text selection works
- [ ] Search finds text and highlights results
- [ ] Go to page dialog works
- [ ] Reading position saved on exit

---

### Task 5: Theme System

**GitHub Issue:** #4 - Theme System: Day, Night, Sepia, Auto

**Objective:** Implement reading themes that are beautiful and reduce eye strain.

#### Color Extension

```swift
// Shared/Extensions/Color+Theme.swift
import SwiftUI

extension Color {
    // MARK: - Brand Colors

    /// Primary brand color - Deep teal
    static let noorTeal = Color(hex: "#0D7377")

    /// Secondary brand color - Warm gold
    static let noorGold = Color(hex: "#D4AF37")

    // MARK: - Theme Colors

    /// Day theme background
    static let dayBackground = Color(hex: "#FFFFFF")
    static let dayText = Color(hex: "#1A1A1A")
    static let daySecondary = Color(hex: "#666666")

    /// Sepia theme background
    static let sepiaBackground = Color(hex: "#FFF8F0")
    static let sepiaText = Color(hex: "#5C4033")
    static let sepiaSecondary = Color(hex: "#8B7355")

    /// Night theme background
    static let nightBackground = Color(hex: "#1E2A38")
    static let nightText = Color(hex: "#E8E8E8")
    static let nightSecondary = Color(hex: "#A0A0A0")

    // MARK: - Semantic Colors

    static let noorSuccess = Color(hex: "#2E8B57")
    static let noorWarning = Color(hex: "#E8A838")
    static let noorError = Color(hex: "#DC3545")

    // MARK: - Highlight Colors

    static let highlightYellow = Color(hex: "#FFF3A3")
    static let highlightGreen = Color(hex: "#A8E6CF")
    static let highlightBlue = Color(hex: "#A8D8EA")
    static let highlightPink = Color(hex: "#FFAAA5")
    static let highlightOrange = Color(hex: "#FFD3A5")
    static let highlightPurple = Color(hex: "#D5AAFF")
    static let highlightRed = Color(hex: "#FF8B94")
    static let highlightGray = Color(hex: "#C9C9C9")

    // MARK: - Dynamic Colors (based on current theme)

    @MainActor
    static var readerBackground: Color {
        ThemeService.shared.currentTheme.backgroundColor
    }

    @MainActor
    static var readerText: Color {
        ThemeService.shared.currentTheme.textColor
    }

    // MARK: - Hex Initializer

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

#### Theme Model

```swift
// Shared/Services/ThemeService.swift
import SwiftUI
import Combine

// MARK: - Theme Enum

enum ReadingTheme: String, CaseIterable, Identifiable, Codable {
    case day
    case sepia
    case night
    case auto

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .day: return "Day"
        case .sepia: return "Sepia"
        case .night: return "Night"
        case .auto: return "Auto"
        }
    }

    var icon: String {
        switch self {
        case .day: return "sun.max"
        case .sepia: return "book"
        case .night: return "moon"
        case .auto: return "circle.lefthalf.filled"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .day: return .dayBackground
        case .sepia: return .sepiaBackground
        case .night: return .nightBackground
        case .auto: return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? .nightBackground : .dayBackground
        }
    }

    var textColor: Color {
        switch self {
        case .day: return .dayText
        case .sepia: return .sepiaText
        case .night: return .nightText
        case .auto: return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? .nightText : .dayText
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .day: return .daySecondary
        case .sepia: return .sepiaSecondary
        case .night: return .nightSecondary
        case .auto: return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? .nightSecondary : .daySecondary
        }
    }
}

// MARK: - Theme Service

@MainActor
@Observable
final class ThemeService {
    static let shared = ThemeService()

    private(set) var currentTheme: ReadingTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "readingTheme")
        }
    }

    private init() {
        if let savedTheme = UserDefaults.standard.string(forKey: "readingTheme"),
           let theme = ReadingTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .auto
        }
    }

    func setTheme(_ theme: ReadingTheme) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = theme
        }
    }

    func cycleTheme() {
        let themes = ReadingTheme.allCases
        guard let currentIndex = themes.firstIndex(of: currentTheme) else { return }
        let nextIndex = (currentIndex + 1) % themes.count
        setTheme(themes[nextIndex])
    }
}
```

#### Theme Picker Component

```swift
// Shared/Components/ThemePicker.swift
import SwiftUI

struct ThemePicker: View {
    @State private var themeService = ThemeService.shared

    var body: some View {
        Menu {
            ForEach(ReadingTheme.allCases) { theme in
                Button(action: { themeService.setTheme(theme) }) {
                    HStack {
                        Image(systemName: theme.icon)
                        Text(theme.displayName)
                        if themeService.currentTheme == theme {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: themeService.currentTheme.icon)
        }
        .help("Reading Theme")
    }
}

// Preview with all themes
struct ThemePreviewCard: View {
    let theme: ReadingTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sample Text")
                .font(.headline)
                .foregroundStyle(theme.textColor)

            Text("This is how text will appear in \(theme.displayName) mode.")
                .font(.body)
                .foregroundStyle(theme.secondaryTextColor)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
```

#### Acceptance Criteria
- [ ] All 4 themes render correctly
- [ ] Theme persists across app launches
- [ ] Auto mode follows macOS light/dark setting
- [ ] Smooth transition between themes (0.3s animation)
- [ ] PDF content remains readable in all themes
- [ ] Theme picker in toolbar works

---

### Task 6: Navigation

**GitHub Issue:** #5 - Navigation: TOC Sidebar, Bookmarks, Keyboard Shortcuts

**Objective:** Enable efficient document navigation.

#### Bookmark Model

```swift
// Shared/Models/Bookmark.swift
import SwiftData
import Foundation

@Model
final class Bookmark {
    var id: UUID
    var pageNumber: Int
    var title: String
    var dateCreated: Date

    var book: Book?

    init(pageNumber: Int, title: String = "") {
        self.id = UUID()
        self.pageNumber = pageNumber
        self.title = title.isEmpty ? "Page \(pageNumber + 1)" : title
        self.dateCreated = Date()
    }
}
```

#### Table of Contents Extraction

```swift
// Extension for ReaderViewModel
extension ReaderViewModel {

    struct TOCItem: Identifiable {
        let id = UUID()
        let title: String
        let pageNumber: Int
        let level: Int
        var children: [TOCItem]
    }

    /// Extract table of contents from PDF outline
    func extractTableOfContents() -> [TOCItem] {
        guard let document,
              let outline = document.outlineRoot else {
            return []
        }

        return extractOutlineItems(from: outline, level: 0)
    }

    private func extractOutlineItems(from outline: PDFOutline, level: Int) -> [TOCItem] {
        var items: [TOCItem] = []

        for i in 0..<outline.numberOfChildren {
            guard let child = outline.child(at: i) else { continue }

            let title = child.label ?? "Untitled"
            var pageNumber = 0

            if let destination = child.destination,
               let page = destination.page,
               let index = document?.index(for: page) {
                pageNumber = index
            }

            let children = extractOutlineItems(from: child, level: level + 1)

            items.append(TOCItem(
                title: title,
                pageNumber: pageNumber,
                level: level,
                children: children
            ))
        }

        return items
    }
}
```

#### Keyboard Shortcuts Handler

```swift
// macOS/MacMenuCommands.swift
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

            Button("Toggle Right Sidebar") {
                NotificationCenter.default.post(name: .toggleRightSidebar, object: nil)
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])

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

            Button("Enter Focus Mode") {
                NotificationCenter.default.post(name: .toggleFocusMode, object: nil)
            }
            .keyboardShortcut(.return, modifiers: [.command, .shift])
        }

        // Go Menu
        CommandMenu("Go") {
            Button("Go to Page...") {
                NotificationCenter.default.post(name: .goToPage, object: nil)
            }
            .keyboardShortcut("g")

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

        // Bookmarks Menu
        CommandMenu("Bookmarks") {
            Button("Add Bookmark") {
                NotificationCenter.default.post(name: .addBookmark, object: nil)
            }
            .keyboardShortcut("d")
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openFile = Notification.Name("openFile")
    static let toggleSearch = Notification.Name("toggleSearch")
    static let findNext = Notification.Name("findNext")
    static let findPrevious = Notification.Name("findPrevious")
    static let toggleLeftSidebar = Notification.Name("toggleLeftSidebar")
    static let toggleRightSidebar = Notification.Name("toggleRightSidebar")
    static let zoomIn = Notification.Name("zoomIn")
    static let zoomOut = Notification.Name("zoomOut")
    static let actualSize = Notification.Name("actualSize")
    static let toggleFocusMode = Notification.Name("toggleFocusMode")
    static let goToPage = Notification.Name("goToPage")
    static let previousPage = Notification.Name("previousPage")
    static let nextPage = Notification.Name("nextPage")
    static let firstPage = Notification.Name("firstPage")
    static let lastPage = Notification.Name("lastPage")
    static let addBookmark = Notification.Name("addBookmark")
}
```

#### Acceptance Criteria
- [ ] TOC displays hierarchically when available
- [ ] Clicking TOC item navigates to correct page
- [ ] Bookmarks can be added with ⌘D
- [ ] Bookmarks persist and appear in sidebar
- [ ] All keyboard shortcuts work
- [ ] Last position restored when reopening book

---

### Task 7: Basic Highlights

**GitHub Issue:** #6 - Basic Highlights: Select Text and Highlight

**Objective:** Enable users to highlight text in PDFs.

#### Highlight Model

```swift
// Shared/Models/Highlight.swift
import SwiftData
import Foundation
import PDFKit

@Model
final class Highlight {
    var id: UUID
    var text: String
    var pageNumber: Int
    var color: HighlightColor
    var dateCreated: Date

    // Store selection bounds for rendering
    var boundsData: Data?

    var book: Book?

    var bounds: CGRect? {
        get {
            guard let data = boundsData else { return nil }
            return try? JSONDecoder().decode(CGRect.self, from: data)
        }
        set {
            boundsData = try? JSONEncoder().encode(newValue)
        }
    }

    init(
        text: String,
        pageNumber: Int,
        bounds: CGRect? = nil,
        color: HighlightColor = .yellow
    ) {
        self.id = UUID()
        self.text = text
        self.pageNumber = pageNumber
        self.color = color
        self.dateCreated = Date()

        if let bounds {
            self.boundsData = try? JSONEncoder().encode(bounds)
        }
    }
}

// MARK: - Highlight Color

enum HighlightColor: String, Codable, CaseIterable, Identifiable {
    case yellow
    case green
    case blue
    case pink
    case orange
    case purple
    case red
    case gray

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .yellow: return .highlightYellow
        case .green: return .highlightGreen
        case .blue: return .highlightBlue
        case .pink: return .highlightPink
        case .orange: return .highlightOrange
        case .purple: return .highlightPurple
        case .red: return .highlightRed
        case .gray: return .highlightGray
        }
    }

    var displayName: String {
        switch self {
        case .yellow: return "General"
        case .green: return "Key Concept"
        case .blue: return "Definition"
        case .pink: return "Question"
        case .orange: return "Example"
        case .purple: return "Connection"
        case .red: return "Critical"
        case .gray: return "Reference"
        }
    }

    var shortcut: String {
        switch self {
        case .yellow: return "1"
        case .green: return "2"
        case .blue: return "3"
        case .pink: return "4"
        case .orange: return "5"
        case .purple: return "6"
        case .red: return "7"
        case .gray: return "8"
        }
    }
}

// CGRect Codable conformance
extension CGRect: Codable {
    enum CodingKeys: String, CodingKey {
        case x, y, width, height
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        let width = try container.decode(CGFloat.self, forKey: .width)
        let height = try container.decode(CGFloat.self, forKey: .height)
        self.init(x: x, y: y, width: width, height: height)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(origin.x, forKey: .x)
        try container.encode(origin.y, forKey: .y)
        try container.encode(size.width, forKey: .width)
        try container.encode(size.height, forKey: .height)
    }
}
```

#### Selection Popover

```swift
// Shared/Components/SelectionPopover.swift
import SwiftUI
import PDFKit

struct SelectionPopover: View {
    let selection: PDFSelection
    let onHighlight: (HighlightColor) -> Void
    let onCopy: () -> Void
    let onDismiss: () -> Void

    @State private var showColorPicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Selected text preview
            if let text = selection.string, !text.isEmpty {
                Text(text.prefix(100) + (text.count > 100 ? "..." : ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .controlBackgroundColor))
            }

            Divider()

            // Action buttons
            HStack(spacing: 16) {
                Button(action: { showColorPicker.toggle() }) {
                    VStack(spacing: 4) {
                        Image(systemName: "highlighter")
                            .font(.title3)
                        Text("Highlight")
                            .font(.caption2)
                    }
                }
                .buttonStyle(.plain)

                Button(action: onCopy) {
                    VStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.title3)
                        Text("Copy")
                            .font(.caption2)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(12)

            // Color picker (Phase 1: just yellow, expandable in Phase 2)
            if showColorPicker {
                Divider()

                HStack(spacing: 8) {
                    ForEach(HighlightColor.allCases) { color in
                        Button(action: { onHighlight(color) }) {
                            Circle()
                                .fill(color.color)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .help("\(color.displayName) (\(color.shortcut))")
                    }
                }
                .padding(12)
            }
        }
        .frame(width: 280)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}
```

#### Acceptance Criteria
- [ ] Can select text in PDF
- [ ] Popover appears on selection
- [ ] Clicking highlight saves the annotation
- [ ] Highlights render correctly on page
- [ ] Highlights persist across sessions
- [ ] Highlights visible at all zoom levels
- [ ] Keyboard shortcuts 1-8 work for colors

---

### Task 8: Islamic Launch Dua

**GitHub Issue:** #7 - Islamic Launch Dua Banner

**Objective:** Display a beautiful dua banner when the app launches.

#### Islamic Reminder Model

```swift
// Shared/Models/IslamicReminder.swift
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
}
```

#### Launch Dua Banner Component

```swift
// Shared/Components/ReminderBanner.swift
import SwiftUI

struct LaunchDuaBanner: View {
    @Binding var isPresented: Bool

    private let dua = IslamicReminder.launchDua

    var body: some View {
        VStack(spacing: 0) {
            banner
            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.easeOut(duration: 0.5), value: isPresented)
    }

    private var banner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                // Arabic text
                Text(dua.arabic)
                    .font(.system(size: 24, weight: .medium, design: .serif))
                    .foregroundStyle(Color.noorGold)

                // Transliteration
                Text(dua.transliteration)
                    .font(.subheadline)
                    .italic()
                    .foregroundStyle(.white.opacity(0.8))

                // English translation
                Text("\"\(dua.english)\"")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))

                // Source
                Text("— \(dua.source)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            // Dismiss button
            Button(action: {
                withAnimation {
                    isPresented = false
                }
            }) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(8)
                    .background(Circle().fill(.white.opacity(0.1)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            LinearGradient(
                colors: [Color.noorTeal, Color.noorTeal.opacity(0.9)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

// MARK: - Daily Reminder Widget (for sidebar)

struct DailyReminderWidget: View {
    @State private var reminder: IslamicReminder = .sampleHadith
    @State private var isFavorite = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "book.closed")
                    .foregroundStyle(Color.noorGold)
                Text("Daily Reminder")
                    .font(.headline)
                Spacer()
            }

            Divider()

            // Arabic (if available and not too long)
            if !reminder.arabic.isEmpty && reminder.arabic.count < 100 {
                Text(reminder.arabic)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // English translation
            Text(reminder.english)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Source
            HStack {
                Text("— \(reminder.source)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer()

                // Favorite button
                Button(action: { isFavorite.toggle() }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? .red : .secondary)
                }
                .buttonStyle(.plain)

                // Share button
                Button(action: { /* Share */ }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

#### Islamic Content JSON

```json
// Shared/Resources/IslamicContent/duas_study.json
{
  "reminders": [
    {
      "id": "dua-001",
      "type": "dua",
      "arabic": "رَبِّ زِدْنِي عِلْمًا",
      "transliteration": "Rabbi zidni ilma",
      "english": "My Lord, increase me in knowledge.",
      "source": "Quran 20:114",
      "category": "seeking_knowledge"
    },
    {
      "id": "dua-002",
      "type": "dua",
      "arabic": "اللَّهُمَّ انْفَعْنِي بِمَا عَلَّمْتَنِي وَعَلِّمْنِي مَا يَنْفَعُنِي وَزِدْنِي عِلْمًا",
      "transliteration": "Allahumma infa'ni bima 'allamtani, wa 'allimni ma yanfa'uni, wa zidni 'ilma",
      "english": "O Allah, benefit me with what You have taught me, teach me what will benefit me, and increase me in knowledge.",
      "source": "Sunan Ibn Majah 251",
      "category": "seeking_knowledge"
    },
    {
      "id": "dua-003",
      "type": "dua",
      "arabic": "رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي وَاحْلُلْ عُقْدَةً مِنْ لِسَانِي يَفْقَهُوا قَوْلِي",
      "transliteration": "Rabbi-shrah li sadri, wa yassir li amri, wahlul 'uqdatan min lisani, yafqahu qawli",
      "english": "My Lord, expand for me my chest, ease for me my task, and untie the knot from my tongue that they may understand my speech.",
      "source": "Quran 20:25-28",
      "category": "ease_in_learning"
    }
  ]
}
```

#### Acceptance Criteria
- [ ] Banner displays on app launch
- [ ] Arabic text renders correctly (RTL, diacritics)
- [ ] Auto-dismisses after 3 seconds
- [ ] Can be manually dismissed
- [ ] Smooth fade-in/fade-out animation
- [ ] Preference can disable (in Settings)

---

### Task 9: Prayer Time Indicator

**GitHub Issue:** #8 - Prayer Time Indicator (Aladhan API)

**Objective:** Show the next prayer time in the toolbar.

#### Prayer Time Service

```swift
// Shared/Services/PrayerTimeService.swift
import Foundation
import CoreLocation

@MainActor
@Observable
final class PrayerTimeService: NSObject {
    static let shared = PrayerTimeService()

    private(set) var prayerTimes: PrayerTimes?
    private(set) var nextPrayer: Prayer?
    private(set) var timeUntilNextPrayer: String = ""
    private(set) var isLoading = false
    private(set) var error: Error?

    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    private var updateTimer: Timer?

    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    // MARK: - Public Methods

    func startUpdating() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        // Update time remaining every minute
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateNextPrayer()
            }
        }
    }

    func stopUpdating() {
        locationManager.stopUpdatingLocation()
        updateTimer?.invalidate()
        updateTimer = nil
    }

    func refresh() async {
        guard let location = currentLocation else { return }
        await fetchPrayerTimes(for: location)
    }

    // MARK: - Private Methods

    private func fetchPrayerTimes(for location: CLLocation) async {
        isLoading = true
        error = nil

        do {
            let times = try await fetchFromAladhan(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            self.prayerTimes = times
            self.updateNextPrayer()
            self.isLoading = false
        } catch {
            self.error = error
            self.isLoading = false
        }
    }

    private func fetchFromAladhan(latitude: Double, longitude: Double) async throws -> PrayerTimes {
        // Get calculation method from settings (default: ISNA)
        let method = UserDefaults.standard.integer(forKey: "prayerCalculationMethod")
        let methodParam = method > 0 ? method : 2 // ISNA = 2

        let urlString = "https://api.aladhan.com/v1/timings/\(Int(Date().timeIntervalSince1970))?latitude=\(latitude)&longitude=\(longitude)&method=\(methodParam)"

        guard let url = URL(string: urlString) else {
            throw PrayerTimeError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PrayerTimeError.serverError
        }

        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(AladhanResponse.self, from: data)

        return apiResponse.data.timings.toPrayerTimes()
    }

    private func updateNextPrayer() {
        guard let times = prayerTimes else { return }

        let now = Date()
        let calendar = Calendar.current

        let prayers: [(Prayer, Date?)] = [
            (.fajr, times.fajr),
            (.dhuhr, times.dhuhr),
            (.asr, times.asr),
            (.maghrib, times.maghrib),
            (.isha, times.isha)
        ]

        // Find next prayer
        for (prayer, time) in prayers {
            guard let prayerTime = time, prayerTime > now else { continue }

            nextPrayer = prayer

            // Calculate time remaining
            let components = calendar.dateComponents([.hour, .minute], from: now, to: prayerTime)
            if let hours = components.hour, let minutes = components.minute {
                if hours > 0 {
                    timeUntilNextPrayer = "\(hours)h \(minutes)m"
                } else {
                    timeUntilNextPrayer = "\(minutes)m"
                }
            }
            return
        }

        // If no prayer found today, next is tomorrow's Fajr
        nextPrayer = .fajr
        timeUntilNextPrayer = "tomorrow"
    }
}

// MARK: - CLLocationManagerDelegate

extension PrayerTimeService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            self.currentLocation = location
            await self.fetchPrayerTimes(for: location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.error = error
        }
    }
}

// MARK: - Models

struct PrayerTimes {
    let fajr: Date?
    let sunrise: Date?
    let dhuhr: Date?
    let asr: Date?
    let maghrib: Date?
    let isha: Date?
}

enum Prayer: String, CaseIterable {
    case fajr = "Fajr"
    case sunrise = "Sunrise"
    case dhuhr = "Dhuhr"
    case asr = "Asr"
    case maghrib = "Maghrib"
    case isha = "Isha"

    var icon: String {
        switch self {
        case .fajr: return "sunrise"
        case .sunrise: return "sun.horizon"
        case .dhuhr: return "sun.max"
        case .asr: return "sun.min"
        case .maghrib: return "sunset"
        case .isha: return "moon.stars"
        }
    }
}

enum PrayerTimeError: LocalizedError {
    case invalidURL
    case serverError
    case locationUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .serverError: return "Could not fetch prayer times"
        case .locationUnavailable: return "Location not available"
        }
    }
}

// MARK: - Aladhan API Response

struct AladhanResponse: Codable {
    let data: AladhanData
}

struct AladhanData: Codable {
    let timings: AladhanTimings
}

struct AladhanTimings: Codable {
    let Fajr: String
    let Sunrise: String
    let Dhuhr: String
    let Asr: String
    let Maghrib: String
    let Isha: String

    func toPrayerTimes() -> PrayerTimes {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        let calendar = Calendar.current
        let today = Date()

        func parseTime(_ timeString: String) -> Date? {
            guard let time = formatter.date(from: timeString) else { return nil }

            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: today)
            dateComponents.hour = timeComponents.hour
            dateComponents.minute = timeComponents.minute

            return calendar.date(from: dateComponents)
        }

        return PrayerTimes(
            fajr: parseTime(Fajr),
            sunrise: parseTime(Sunrise),
            dhuhr: parseTime(Dhuhr),
            asr: parseTime(Asr),
            maghrib: parseTime(Maghrib),
            isha: parseTime(Isha)
        )
    }
}
```

#### Prayer Time Indicator Component

```swift
// Shared/Components/PrayerTimeIndicator.swift
import SwiftUI

struct PrayerTimeIndicator: View {
    @State private var service = PrayerTimeService.shared

    var body: some View {
        Group {
            if service.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            } else if let prayer = service.nextPrayer {
                HStack(spacing: 4) {
                    Image(systemName: "mosque")
                        .font(.caption)
                        .foregroundStyle(Color.noorGold)

                    Text("\(prayer.rawValue)")
                        .font(.caption)
                        .fontWeight(.medium)

                    Text(service.timeUntilNextPrayer)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .help("Next prayer: \(prayer.rawValue) in \(service.timeUntilNextPrayer)")
            } else {
                Image(systemName: "mosque")
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            service.startUpdating()
        }
        .onDisappear {
            service.stopUpdating()
        }
    }
}

// Expanded view for settings or popover
struct PrayerTimesView: View {
    @State private var service = PrayerTimeService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "mosque.fill")
                    .foregroundStyle(Color.noorGold)
                Text("Prayer Times")
                    .font(.headline)
                Spacer()

                Button(action: {
                    Task { await service.refresh() }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
            }

            Divider()

            if let times = service.prayerTimes {
                prayerRow(.fajr, time: times.fajr)
                prayerRow(.dhuhr, time: times.dhuhr)
                prayerRow(.asr, time: times.asr)
                prayerRow(.maghrib, time: times.maghrib)
                prayerRow(.isha, time: times.isha)
            } else if service.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Text("Unable to load prayer times")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(width: 200)
    }

    @ViewBuilder
    private func prayerRow(_ prayer: Prayer, time: Date?) -> some View {
        HStack {
            Image(systemName: prayer.icon)
                .frame(width: 20)
                .foregroundStyle(service.nextPrayer == prayer ? Color.noorGold : .secondary)

            Text(prayer.rawValue)
                .fontWeight(service.nextPrayer == prayer ? .semibold : .regular)

            Spacer()

            if let time {
                Text(time, style: .time)
                    .foregroundStyle(service.nextPrayer == prayer ? .primary : .secondary)
            } else {
                Text("--:--")
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
        .background(service.nextPrayer == prayer ? Color.noorGold.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
```

#### Acceptance Criteria
- [ ] Shows next prayer name and time remaining
- [ ] Updates automatically as time passes
- [ ] Works offline with cached data
- [ ] Location auto-detected or manually set
- [ ] Calculation method configurable in settings
- [ ] Minimal UI footprint (not distracting)

---

## Quality Standards

### Code Quality Checklist

Before marking any task complete, verify:

- [ ] **No compiler warnings** - Zero warnings, zero errors
- [ ] **Swift 6 concurrency** - No data race warnings
- [ ] **Meaningful names** - Variables, functions, types all have clear names
- [ ] **Documentation** - Public APIs have doc comments
- [ ] **Error handling** - All errors caught and handled gracefully
- [ ] **No force unwraps** - Unless explicitly justified with comment
- [ ] **SwiftLint passes** - No violations
- [ ] **Accessibility** - Labels on interactive elements

### Performance Checklist

- [ ] **App launch** - Under 1 second to interactive
- [ ] **PDF opening** - Under 2 seconds for 500-page document
- [ ] **Page turns** - Under 50ms
- [ ] **Memory** - Under 150MB idle, under 500MB with large PDF
- [ ] **No main thread blocking** - Heavy work on background threads

### Design Checklist

- [ ] **Consistent spacing** - Using 8pt grid
- [ ] **Correct colors** - Using defined color palette
- [ ] **Smooth animations** - 60fps, appropriate durations
- [ ] **Responsive layout** - Works at all window sizes
- [ ] **Dark mode** - Fully supported via theme system

---

## Testing Requirements

### Unit Tests Required

```swift
// Tests/SharedTests/ServiceTests/LibraryServiceTests.swift
final class LibraryServiceTests: XCTestCase {

    func testImportPDF() async throws {
        // Test PDF import creates Book with correct metadata
    }

    func testDeleteBook() throws {
        // Test book deletion removes from database
    }

    func testToggleFavorite() throws {
        // Test favorite toggle persists
    }
}

// Tests/SharedTests/ServiceTests/PrayerTimeServiceTests.swift
final class PrayerTimeServiceTests: XCTestCase {

    func testParseAladhanResponse() {
        // Test API response parsing
    }

    func testNextPrayerCalculation() {
        // Test next prayer logic
    }
}

// Tests/SharedTests/ViewModelTests/ReaderViewModelTests.swift
final class ReaderViewModelTests: XCTestCase {

    func testPageNavigation() {
        // Test page navigation bounds
    }

    func testProgressCalculation() {
        // Test progress calculation
    }

    func testSearch() async {
        // Test search functionality
    }
}
```

### Manual Testing Checklist

Before completing Phase 1:

- [ ] Import 5 different PDF files (small, large, with images, scanned)
- [ ] Open a 1000+ page document
- [ ] Test all keyboard shortcuts
- [ ] Test all three themes
- [ ] Test bookmark creation and navigation
- [ ] Test highlight creation
- [ ] Verify prayer times are accurate for your location
- [ ] Test with VoiceOver briefly
- [ ] Test window resizing at various sizes
- [ ] Test sidebar toggling
- [ ] Kill and restart app, verify data persists

---

## Phase 1 Completion Criteria

Phase 1 is complete when ALL of the following are true:

### Functionality
- [ ] Can import PDFs via drag-drop and menu
- [ ] Library displays books in a grid with covers
- [ ] Can open and read any PDF smoothly
- [ ] Page navigation works (arrows, ⌘G, TOC, scrubber)
- [ ] Three themes work and persist
- [ ] Can create and view bookmarks
- [ ] Can create highlights (yellow minimum, all 8 colors ideal)
- [ ] Launch dua displays on startup
- [ ] Prayer time indicator shows in toolbar

### Quality
- [ ] Zero compiler warnings
- [ ] SwiftLint passes
- [ ] All unit tests pass
- [ ] Manual testing checklist complete
- [ ] Performance targets met

### Polish
- [ ] Animations are smooth
- [ ] No visual glitches
- [ ] Error states handled gracefully
- [ ] Loading states shown appropriately

---

## Dua for Success

اللَّهُمَّ لَا سَهْلَ إِلَّا مَا جَعَلْتَهُ سَهْلًا، وَأَنْتَ تَجْعَلُ الْحَزْنَ إِذَا شِئْتَ سَهْلًا

*Allahumma la sahla illa ma ja'altahu sahla, wa Anta taj'alul-hazna idha shi'ta sahla.*

**O Allah, there is no ease except what You make easy, and You make difficulty easy if You wish.**

---

بِسْمِ اللَّهِ، تَوَكَّلْتُ عَلَى اللَّهِ

**In the name of Allah, I place my trust in Allah.**

Begin.
