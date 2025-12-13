# NoorReader - Master Development Prompt

> "Ihsan is to worship Allah as though you see Him, and if you cannot see Him, then indeed He sees you." — Hadith Jibril

Build this app with **Ihsan** — excellence, beauty, and attention to detail in every aspect.

---

## Project Vision

**NoorReader** (نور القارئ - "Light of the Reader") is a professional PDF and EPUB study application for Apple platforms that seamlessly integrates Islamic reminders to nurture both intellectual and spiritual growth.

The app embodies the principle that seeking knowledge is an act of worship, and every study session is an opportunity for barakah (blessing).

---

## Core Philosophy

### 1. Excellence in Craft (Itqan)
The Prophet ﷺ said: "Allah loves that when one of you does something, he does it with excellence (itqan)."

- Every pixel matters
- Every interaction should feel intentional
- Performance is not optional — it's respect for the user's time
- Code should be clean, maintainable, and well-documented
- Use cutting-edge technology to deliver the best experience

### 2. Seamless Integration
Islamic reminders should feel like a natural part of the study experience, not an interruption or afterthought. They should:
- Appear at meaningful moments
- Never feel preachy or forced
- Be dismissible and configurable
- Enhance focus, not break it

### 3. User-Centered Design
- Respect the user's intelligence
- Progressive disclosure — simple by default, powerful when needed
- Fast launch, fast rendering, fast everything
- Work offline without compromise
- Privacy-first: AI runs locally by default

### 4. Multi-Platform Ready
- macOS-first development
- Architecture designed for iOS/iPadOS expansion
- Shared codebase where possible
- Platform-specific UI where necessary

---

## Target Users

1. **Muslim Students** — University students studying any subject who want to maintain spiritual connection during long study sessions
2. **Islamic Studies Students** — Those reading tafsir, fiqh, hadith collections in PDF/EPUB format
3. **Professionals** — Knowledge workers who read research papers, reports, and books
4. **Lifelong Learners** — Anyone who values deep reading and retention

---

## Technology Stack (Cutting Edge - 2025)

### Core Technologies

| Component | Technology | Why |
|-----------|------------|-----|
| **Language** | Swift 6 | Strict concurrency, data race safety |
| **UI Framework** | SwiftUI + `@Observable` | Latest patterns, declarative UI |
| **Data Persistence** | SwiftData + CloudKit | Modern ORM, automatic iCloud sync |
| **PDF Rendering** | PDFKit + VisionKit | Native + Live Text extraction |
| **EPUB Rendering** | Native (Phase 2) | Apple's built-in support |
| **AI (Local)** | MLX + Core ML | On-device summarization, flashcards, Q&A |
| **AI (Cloud)** | Claude API (optional) | Premium features, user opt-in |
| **Search** | SQLite FTS5 + Vector Embeddings | Full-text + semantic search |
| **Concurrency** | Swift Actors + async/await | Thread-safe by design |
| **Minimum Target** | macOS 15 (Sequoia) | Access to latest APIs |

### Why These Choices

**Swift 6 Strict Concurrency**
```swift
// Data race safety at compile time
@Observable
@MainActor
final class AppState: Sendable {
    var currentBook: Book?
    var isLoading = false
}
```

**MLX for Local AI**
- Built BY Apple FOR Apple Silicon (M1/M2/M3)
- Runs LLMs efficiently on your Mac
- 100% private — nothing leaves your device
- Perfect for M1 MacBook Pro

**SwiftData + CloudKit**
```swift
@Model
final class Book {
    var title: String
    var author: String
    @Relationship(deleteRule: .cascade)
    var highlights: [Highlight]

    // Automatic iCloud sync — no extra code needed
}
```

**VisionKit Live Text**
- Instant text extraction from scanned PDFs
- Better than raw Vision framework
- Works on images within documents

---

## AI Features

### On-Device AI (MLX + Core ML) — Private by Default

| Feature | Description | Model |
|---------|-------------|-------|
| **Smart Summarize** | Select chapter/section → get concise summary | Local LLM via MLX |
| **Auto Flashcards** | AI generates Q&A from your highlights | Local LLM |
| **Explain Selection** | Select confusing text → plain English explanation | Local LLM |
| **Semantic Search** | "Find where author discusses deep focus" | Local embeddings |
| **Arabic Enhancement** | Better diacritics, transliteration help | Core ML |
| **OCR Enhancement** | Extract text from scanned/image PDFs | VisionKit |

### Cloud AI (Claude API) — Optional Opt-In

| Feature | Description | When Used |
|---------|-------------|-----------|
| **Study Chat** | Ask questions about your book | User enables + provides API key |
| **Advanced Summarization** | Longer, more nuanced summaries | User preference |
| **Cross-Book Insights** | Connections across your library | Premium feature |

### AI Privacy Model

```
┌─────────────────────────────────────────────────────────────┐
│                        AI FEATURES                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   LOCAL (Default)              CLOUD (Opt-In)               │
│   ─────────────────            ─────────────────            │
│   ✓ Summarization              ○ Study Chat                 │
│   ✓ Flashcard Generation       ○ Advanced Analysis          │
│   ✓ Explain Selection          ○ Cross-Book Insights        │
│   ✓ Semantic Search                                         │
│   ✓ OCR                        Requires:                    │
│                                • User consent               │
│   100% on-device               • API key                    │
│   No data leaves Mac           • Per-request approval       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Architecture (Multi-Platform Ready)

```
NoorReader/
├── Shared/                          # 80% of codebase — reusable
│   │
│   ├── Models/
│   │   ├── Book.swift               # SwiftData model
│   │   ├── Highlight.swift          # Annotation model
│   │   ├── Note.swift               # Note model
│   │   ├── Flashcard.swift          # Spaced repetition card
│   │   ├── Bookmark.swift           # Page bookmark
│   │   ├── Collection.swift         # Folder/tag organization
│   │   ├── StudySession.swift       # Time tracking
│   │   └── IslamicReminder.swift    # Hadith/Dua/Ayah content
│   │
│   ├── Services/
│   │   ├── PDFService.swift         # PDF operations
│   │   ├── EPUBService.swift        # EPUB parsing (Phase 2)
│   │   ├── AIService.swift          # MLX + Core ML integration
│   │   ├── CloudAIService.swift     # Optional Claude API
│   │   ├── OCRService.swift         # VisionKit Live Text
│   │   ├── SearchService.swift      # FTS5 + semantic search
│   │   ├── SyncService.swift        # CloudKit coordination
│   │   ├── PrayerTimeService.swift  # Aladhan API
│   │   ├── ReminderService.swift    # Islamic content delivery
│   │   └── SpacedRepetitionService.swift  # SM-2 algorithm
│   │
│   ├── ViewModels/
│   │   ├── LibraryViewModel.swift   # Library state & logic
│   │   ├── ReaderViewModel.swift    # PDF/EPUB reading state
│   │   ├── AnnotationViewModel.swift # Highlights, notes
│   │   ├── StudyViewModel.swift     # Flashcards, sessions
│   │   └── SettingsViewModel.swift  # User preferences
│   │
│   ├── Components/                  # Reusable SwiftUI views
│   │   ├── BookCard.swift           # Library grid item
│   │   ├── HighlightRow.swift       # Annotation list item
│   │   ├── FlashcardView.swift      # Card display
│   │   ├── ReminderBanner.swift     # Islamic reminder display
│   │   ├── PrayerTimeIndicator.swift # Status bar widget
│   │   └── ProgressBar.swift        # Reading progress
│   │
│   ├── Extensions/
│   │   ├── Color+Theme.swift        # App color palette
│   │   ├── Font+App.swift           # Typography system
│   │   ├── View+Modifiers.swift     # Custom view modifiers
│   │   ├── String+Arabic.swift      # RTL text handling
│   │   └── Date+Formatting.swift    # Hijri date support
│   │
│   └── Resources/
│       ├── IslamicContent/
│       │   ├── hadith_knowledge.json
│       │   ├── duas_study.json
│       │   └── ayat_learning.json
│       └── MLModels/                # Core ML models
│           └── (downloaded on first use)
│
├── macOS/                           # 10% — macOS-specific
│   ├── NoorReaderApp.swift          # macOS entry point
│   ├── MacContentView.swift         # Three-panel NavigationSplitView
│   ├── Views/
│   │   ├── MacLibraryView.swift     # Sidebar + grid
│   │   ├── MacReaderView.swift      # PDF viewer with toolbar
│   │   └── MacStudyPanel.swift      # Inspector sidebar
│   ├── MacMenuCommands.swift        # Menu bar commands
│   └── MacKeyboardShortcuts.swift   # ⌘ shortcuts
│
├── iOS/                             # 10% — iOS/iPadOS-specific (Phase 5+)
│   ├── NoorReaderApp.swift          # iOS entry point
│   ├── iOSContentView.swift         # Tab-based navigation
│   ├── Views/
│   │   ├── iOSLibraryView.swift     # Grid with pull-to-refresh
│   │   ├── iOSReaderView.swift      # Full-screen reader
│   │   └── iOSStudyView.swift       # Sheet-based study tools
│   └── iOSShareExtension/           # Import from other apps
│
└── Tests/
    ├── SharedTests/                 # Unit tests for services
    ├── macOSTests/                  # macOS UI tests
    └── iOSTests/                    # iOS UI tests
```

### Key Architecture Principles

**1. Shared First**
- All business logic in `Shared/`
- Platform-specific code only for UI shell
- Target: 80% code sharing between macOS and iOS

**2. Observable Pattern (Swift 6)**
```swift
// Modern observation — no @Published needed
@Observable
final class LibraryViewModel {
    var books: [Book] = []
    var selectedBook: Book?
    var searchQuery = ""

    var filteredBooks: [Book] {
        guard !searchQuery.isEmpty else { return books }
        return books.filter { $0.title.localizedCaseInsensitiveContains(searchQuery) }
    }
}
```

**3. Actor Isolation for Thread Safety**
```swift
// AI service runs on background actor
actor AIService {
    private let mlxModel: MLXModel

    func summarize(_ text: String) async throws -> String {
        // Safe concurrent access
    }
}
```

**4. Dependency Injection**
```swift
// Easy to test, easy to swap implementations
@Observable
final class AppDependencies {
    let pdfService: PDFServiceProtocol
    let aiService: AIServiceProtocol
    let reminderService: ReminderServiceProtocol

    init(
        pdfService: PDFServiceProtocol = PDFService(),
        aiService: AIServiceProtocol = AIService(),
        reminderService: ReminderServiceProtocol = ReminderService()
    ) {
        self.pdfService = pdfService
        self.aiService = aiService
        self.reminderService = reminderService
    }
}
```

---

## Feature Specifications

### 1. Library Management

**Supported Formats**
- PDF (Phase 1) — primary focus
- EPUB (Phase 2) — books, Islamic texts

**Import**
- Drag and drop files
- Import from Files/Finder
- Share sheet (iOS)
- Automatic metadata extraction (title, author, cover)
- OCR indexing for scanned PDFs (background)

**Organization**
- Smart collections: Reading Now, Recently Added, Favorites
- Custom collections (folders)
- Tags with colors
- Full-text search across library
- Semantic search: "books about productivity"
- Sort by: Title, Author, Date Added, Last Read, Progress

**Book Card Display**
```
┌─────────────────┐
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │  Cover (extracted or generated)
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │        ⭐ Favorite badge
├─────────────────┤
│ Book Title      │
│ Author Name     │
│ ━━━━━━━━░░░░ 67%│  Progress bar
│ 🤖 AI Ready     │  Indexed for AI features
└─────────────────┘
```

---

### 2. PDF/EPUB Viewer

**Rendering**
- Smooth, fast rendering (< 50ms page turn)
- Support documents up to 5000+ pages
- Lazy loading for performance
- Crisp text at all zoom levels

**View Modes**
- Single page (centered)
- Two page (book spread)
- Continuous scroll
- Thumbnail overview

**Navigation**
- Page scrubber with preview
- Go to page dialog (⌘G)
- Table of contents sidebar
- Bookmarks list
- Search within document (⌘F)
- Keyboard shortcuts

**Themes**
| Theme | Background | Text | Use Case |
|-------|------------|------|----------|
| Day | #FFFFFF | #1A1A1A | Bright environments |
| Sepia | #FFF8F0 | #5C4033 | Reduced eye strain |
| Night | #1E2A38 | #E8E8E8 | Dark environments |
| Auto | System | System | Follows macOS appearance |

**Zoom**
- Pinch to zoom (trackpad)
- ⌘+ / ⌘- keyboard
- Fit to width / Fit to page
- Double-click smart zoom on paragraph

---

### 3. Annotation System

**Highlight Colors (8 semantic colors)**
| Color | Hex | Meaning | Shortcut |
|-------|-----|---------|----------|
| 🟡 Yellow | #FFF3A3 | General highlight | 1 |
| 🟢 Green | #A8E6CF | Key concept | 2 |
| 🔵 Blue | #A8D8EA | Definition/term | 3 |
| 🩷 Pink | #FFAAA5 | Question/confusion | 4 |
| 🟠 Orange | #FFD3A5 | Example | 5 |
| 🟣 Purple | #D5AAFF | Connection | 6 |
| 🔴 Red | #FF8B94 | Critical | 7 |
| ⚫ Gray | #C9C9C9 | Reference | 8 |

**Selection Popover**
```
┌─────────────────────────────────────┐
│ "Selected text appears here..."     │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│ 🖍️  ✏️  📝  🔗  📋  🎴  🤖        │
│ Hi  Un  Note Link Copy Card  AI    │
├─────────────────────────────────────┤
│  🟡  🟢  🔵  🩷  🟠  🟣  🔴  ⚫   │
└─────────────────────────────────────┘
                              ↑
                         AI Actions:
                         • Summarize
                         • Explain
                         • Create flashcard
```

**Notes**
- Attach to highlight or standalone
- Rich text editor (bold, italic, lists)
- Link to other notes (bidirectional)
- Tags for organization
- Timestamp and page reference

**Export**
- Markdown format with page references
- Include highlighted text and notes
- Group by chapter/section or date
- **Include images** (unlike competitors)
- Export to: Clipboard, File, Obsidian vault

---

### 4. AI-Powered Study Tools

**Smart Summarization**
```
┌─────────────────────────────────────────────────────────────┐
│  🤖 AI Summary                                          ✕   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Chapter 3: Deep Work (Pages 45-78)                         │
│                                                             │
│  Key Points:                                                │
│  • Deep work is the ability to focus without distraction    │
│  • It produces high-quality output in less time             │
│  • Modern workplace trends actively harm deep work          │
│  • Deliberate practice requires deep work                   │
│                                                             │
│  Main Argument:                                             │
│  The author argues that deep work is becoming increasingly  │
│  rare at the same time it's becoming increasingly valuable, │
│  creating an opportunity for those who cultivate it.        │
│                                                             │
│  ─────────────────────────────────────────────────────────  │
│  🔒 Generated locally on your device                        │
│                                                             │
│  [Save to Notes]  [Create Flashcards]  [Regenerate]        │
└─────────────────────────────────────────────────────────────┘
```

**Auto Flashcard Generation**
```
┌─────────────────────────────────────────────────────────────┐
│  🤖 AI Flashcard Suggestions                            ✕   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  From your 5 highlights on pages 45-52:                     │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ □ Q: What is the definition of "deep work"?         │   │
│  │   A: Professional activities performed in a state   │   │
│  │      of distraction-free concentration that push    │   │
│  │      cognitive capabilities to their limit.         │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ □ Q: What are the two core abilities for thriving   │   │
│  │      in the new economy?                            │   │
│  │   A: 1) Quickly mastering hard things               │   │
│  │      2) Producing at an elite level                 │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ □ Q: Why is deep work becoming rare?                │   │
│  │   A: Network tools, open offices, and instant       │   │
│  │      messaging fragment attention constantly.       │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  [Select All]  [Create Selected (3)]                       │
└─────────────────────────────────────────────────────────────┘
```

**Semantic Search**
```
Search: "where does the author talk about social media"

Results:
┌─────────────────────────────────────────────────────────────┐
│ 📖 Page 67 — 92% relevant                                   │
│ "Social media, with its constant stream of notifications,   │
│  is particularly destructive to deep work..."               │
│                                                    [Go →]   │
├─────────────────────────────────────────────────────────────┤
│ 📖 Page 134 — 85% relevant                                  │
│ "The craftsman approach to tool selection requires          │
│  evaluating social media against your core values..."       │
│                                                    [Go →]   │
├─────────────────────────────────────────────────────────────┤
│ 📖 Page 201 — 71% relevant                                  │
│ "Consider a 30-day social media detox to reset your         │
│  attention capabilities..."                                 │
│                                                    [Go →]   │
└─────────────────────────────────────────────────────────────┘
```

**Flashcard Review (Spaced Repetition)**
- SM-2 algorithm implementation
- Quality ratings: Again, Hard, Good, Easy
- Interval calculation with ease factor
- Statistics: streak, accuracy, cards due
- Review reminders

---

### 5. Islamic Reminders

**Content Sources**
- Curated hadith about knowledge/learning (with full chains)
- Quranic verses about knowledge
- Duas for studying (Arabic + transliteration + English)
- All content verified from authentic sources (Bukhari, Muslim, etc.)

**Trigger Points**
| Trigger | Content Type | Display | Dismissal |
|---------|--------------|---------|-----------|
| App launch | Dua (Rabbi zidni ilma) | Top banner | Auto 3s |
| Study session start | Hadith about knowledge | Small modal | Button |
| 45 min study | Break + hadith | Modal | Choose action |
| Book completion | Gratitude dua + stats | Celebration | Button |
| Struggle detected | Dua of Musa for ease | Toast | Auto 5s |
| Focus mode | Hadith about time | Center screen | — |
| Flashcard complete | Alhamdulillah | Toast | Auto 3s |

**Prayer Time Integration**
- Fetch from Aladhan API (cached locally)
- Show next prayer in status bar
- Configurable reminder (5/10/15/30 min before)
- Optional: Pause study session prompt
- Offline calculation fallback

**Prayer Time Settings**
| Setting | Options |
|---------|---------|
| Calculation Method | ISNA, MWL, Umm al-Qura, Egyptian, Karachi, Tehran, etc. |
| School (Asr) | Shafi (standard) / Hanafi (later) |
| Location | Auto-detect / Manual city entry |
| Reminder Timing | 5 / 10 / 15 / 30 minutes before |

**User Preferences**
- Enable/disable reminders entirely
- Frequency: Minimal / Moderate / Frequent
- Language: Arabic only / English only / Both
- Show/hide transliteration
- Show/hide source reference
- Save favorites
- Custom reminder scheduling

---

### 6. Search

**Within Document**
- Instant search as you type
- Highlight all matches in scroll bar
- Navigate between matches (⌘G / ⌘⇧G)
- Show context snippet
- Search history

**Across Library**
- Full-text search (SQLite FTS5)
- Semantic search (vector embeddings)
- Search annotations and notes
- Filter by: book, date, tag, color
- Search suggestions

---

### 7. Settings

**Appearance**
- Theme: Day / Sepia / Night / System
- Accent color customization
- Font size for PDF rendering
- Sidebar width preferences
- Toolbar customization

**Reading**
- Default view mode
- Scroll direction
- Page turn animation
- Auto-save position
- Reading speed tracking

**AI Features**
- Enable/disable AI features
- Local-only vs. allow cloud
- Claude API key (optional)
- Model quality vs. speed preference

**Annotations**
- Default highlight color
- Default note template
- Export format preferences
- Auto-backup annotations

**Islamic Reminders**
- All settings from section 5
- Prayer time configuration
- Saved reminders management

**Data & Privacy**
- iCloud sync toggle
- Export all data
- Import from other apps
- Clear cache
- View what data is stored

---

## Design System

### Colors

```swift
// Primary palette
extension Color {
    // Brand
    static let noorTeal = Color(hex: "#0D7377")       // Primary actions
    static let noorGold = Color(hex: "#D4AF37")       // Islamic accent

    // Backgrounds
    static let noorCream = Color(hex: "#FFF8F0")      // Sepia mode
    static let noorSlate = Color(hex: "#1E2A38")      // Night mode

    // Semantic
    static let noorSuccess = Color(hex: "#2E8B57")    // Progress, success
    static let noorWarning = Color(hex: "#E8A838")    // Upcoming prayer
    static let noorError = Color(hex: "#DC3545")      // Errors

    // Highlights
    static let highlightYellow = Color(hex: "#FFF3A3")
    static let highlightGreen = Color(hex: "#A8E6CF")
    static let highlightBlue = Color(hex: "#A8D8EA")
    static let highlightPink = Color(hex: "#FFAAA5")
    static let highlightOrange = Color(hex: "#FFD3A5")
    static let highlightPurple = Color(hex: "#D5AAFF")
    static let highlightRed = Color(hex: "#FF8B94")
    static let highlightGray = Color(hex: "#C9C9C9")
}
```

### Typography

```swift
extension Font {
    // App UI
    static let noorHeading = Font.system(.title, design: .default, weight: .semibold)
    static let noorBody = Font.system(.body, design: .default)
    static let noorCaption = Font.system(.caption, design: .default)

    // Arabic text — use system Arabic fonts
    static let noorArabic = Font.system(.body, design: .serif)
    static let noorArabicLarge = Font.system(.title2, design: .serif)

    // Monospace for code/references
    static let noorMono = Font.system(.body, design: .monospaced)
}
```

### Spacing
- Use 8pt grid system
- Consistent padding: 8, 16, 24, 32
- Sidebar width: 240px (left), 280px (right)
- Minimum touch target: 44pt (iOS), 24pt (macOS)

### Icons
- SF Symbols throughout
- Consistent weight (regular, medium for emphasis)
- Custom symbols for Islamic elements if needed

---

## Keyboard Shortcuts (macOS)

| Action | Shortcut |
|--------|----------|
| Open file | ⌘O |
| Close tab | ⌘W |
| Go to page | ⌘G |
| Find in document | ⌘F |
| Find next | ⌘G |
| Find previous | ⌘⇧G |
| Find in library | ⌘⇧F |
| Toggle left sidebar | ⌘⇧L |
| Toggle right sidebar | ⌘⇧R |
| Add bookmark | ⌘D |
| Add note | ⌘⇧N |
| Previous page | ← or ⌘↑ |
| Next page | → or ⌘↓ |
| Zoom in | ⌘+ |
| Zoom out | ⌘- |
| Actual size | ⌘0 |
| Focus mode | ⌘⇧Enter |
| Start flashcard review | ⌘⇧R |
| AI summarize selection | ⌘⇧S |
| Settings | ⌘, |
| Highlight colors | 1-8 |

---

## Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| App launch (cold) | < 1 second | Time to interactive |
| App launch (warm) | < 0.5 second | Time to interactive |
| Open 500-page PDF | < 2 seconds | First page visible |
| Page turn | < 50ms | Frame to frame |
| Search (in document) | < 100ms | Results displayed |
| Search (library, 100 books) | < 500ms | Results displayed |
| AI summarize (local) | < 5 seconds | For 1 chapter |
| Memory (idle) | < 150MB | Activity Monitor |
| Memory (large PDF) | < 500MB | 1000+ page document |
| Battery | Minimal drain | No background CPU |

---

## Privacy & Security

### Data Storage
- **Local-first**: All data stored on device by default
- **iCloud sync**: Optional, user-controlled, encrypted
- **No telemetry**: Zero analytics sent to any server
- **No accounts**: Works without any sign-up

### AI Privacy
- **Local AI default**: MLX models run entirely on-device
- **Cloud AI opt-in**: Only if user explicitly enables + provides API key
- **No training**: Your data is never used to train models
- **Transparent**: Clear indicators when AI is used

### Network Requests
| Request | Purpose | Frequency |
|---------|---------|-----------|
| Aladhan API | Prayer times | Daily (cached) |
| Claude API | Cloud AI (optional) | Per user action |
| Apple CloudKit | iCloud sync (optional) | On changes |

---

## Development Phases

### Phase 1: Foundation (MVP) — 4-6 weeks
- [ ] Project setup with Swift 6, SwiftUI, SwiftData
- [ ] Basic PDF viewing with PDFKit
- [ ] Library management (import, list, delete)
- [ ] Single/continuous view modes
- [ ] Day/Night/Sepia themes
- [ ] Page navigation (scrubber, go-to, TOC)
- [ ] Basic highlights (select → highlight)
- [ ] Bookmarks
- [ ] Islamic launch dua banner
- [ ] Prayer time indicator (Aladhan API)

### Phase 2: Annotations — 3-4 weeks
- [ ] Full highlight system with 8 colors
- [ ] Notes attached to highlights
- [ ] Standalone notes
- [ ] Annotations sidebar/list
- [ ] Markdown export (with images)
- [ ] Search within document
- [ ] Daily reminder widget

### Phase 3: AI Integration — 4-5 weeks
- [ ] MLX model integration
- [ ] Local summarization
- [ ] Auto flashcard generation
- [ ] Semantic search with embeddings
- [ ] Explain selection feature
- [ ] Optional Claude API integration

### Phase 4: Study Tools — 3-4 weeks
- [ ] Manual flashcard creation
- [ ] Spaced repetition review (SM-2)
- [ ] Study session timer
- [ ] Break reminders with Islamic content
- [ ] Statistics and insights
- [ ] Focus mode

### Phase 5: Advanced — 4-5 weeks
- [ ] EPUB support
- [ ] Full-text search across library
- [ ] iCloud sync (SwiftData + CloudKit)
- [ ] OCR for scanned PDFs (VisionKit)
- [ ] Mind map visualization
- [ ] Import/export from other apps

### Phase 6: iOS & Polish — 4-6 weeks
- [ ] iOS/iPadOS app target
- [ ] Adaptive layouts for iPhone/iPad
- [ ] Share extension for import
- [ ] Widget for prayer times
- [ ] Performance optimization
- [ ] Accessibility (VoiceOver, Dynamic Type)
- [ ] Localization (Arabic UI)
- [ ] App Store preparation

---

## Quality Standards

### Code Quality
- Swift 6 strict concurrency — no data races
- SwiftLint for consistent style
- Comprehensive documentation (DocC)
- Unit tests for all services (>80% coverage)
- UI tests for critical user flows
- No force unwraps without explicit justification
- Meaningful error handling with user-friendly messages

### Design Quality
- Consistent with Apple Human Interface Guidelines
- Pixel-perfect alignment
- Smooth animations (60fps minimum)
- Responsive to window resizing
- Full dark mode support
- Accessibility from day one

### Content Quality
- All Islamic content from verified authentic sources
- Proper Arabic typography (RTL, diacritics)
- Correct transliteration following standard conventions
- Accurate translations
- Full source citations (book, hadith number, grade)

---

## Testing Strategy

### Unit Tests
```swift
// Test all services
func testSpacedRepetitionInterval() async {
    let service = SpacedRepetitionService()
    let card = Flashcard(front: "Q", back: "A", easeFactor: 2.5)

    // Test "Good" response
    let updated = service.processReview(card, quality: .good)
    XCTAssertEqual(updated.interval, 1) // First review = 1 day
}
```

### UI Tests
```swift
// Test critical flows
func testHighlightCreation() {
    let app = XCUIApplication()
    app.launch()

    // Open a book
    app.collectionViews.cells.firstMatch.tap()

    // Select text and highlight
    // ...verify highlight appears in sidebar
}
```

### Manual Testing Checklist
- [ ] PDF rendering with various documents (text, images, scanned)
- [ ] Large documents (1000+ pages)
- [ ] Arabic/RTL text handling
- [ ] Memory usage over extended sessions
- [ ] Battery drain during reading
- [ ] iCloud sync conflict resolution
- [ ] Offline functionality
- [ ] VoiceOver navigation

---

## App Store Preparation

### App Name
**NoorReader - PDF Study App**

### Subtitle
*Read with purpose. Study with barakah.*

### Description
NoorReader is a professional PDF reader designed for deep study sessions, featuring seamless Islamic reminders to keep your intentions aligned while you learn.

**Powerful Study Features:**
• Beautiful library to organize your books
• Smooth PDF rendering with Day, Sepia, and Night modes
• Highlight and annotate with 8 color-coded options
• Take rich notes linked to your highlights
• AI-powered summarization and flashcard generation
• Spaced repetition for long-term retention

**Islamic Integration:**
• Prayer time awareness so you never miss salah
• Gentle reminders with authentic hadith and duas
• Study break prompts with beneficial knowledge
• Completion duas when you finish a book

**Privacy First:**
• AI runs locally on your Mac — your data never leaves
• No accounts required
• No analytics or tracking
• Optional iCloud sync for your convenience

*"Seeking knowledge is an obligation upon every Muslim."* — Ibn Majah

### Keywords
PDF reader, study app, Islamic, Muslim, annotations, highlights, flashcards, spaced repetition, prayer times, hadith, Quran, focus, productivity, note-taking, EPUB

### Category
Primary: Education
Secondary: Productivity

### Screenshots Needed
1. Library view with book grid
2. PDF reading with night mode
3. Highlight with color selection
4. AI summarization feature
5. Flashcard review
6. Prayer time reminder
7. Study break with hadith

---

## Resources & References

### Apple Documentation
- [SwiftUI](https://developer.apple.com/documentation/swiftui)
- [SwiftData](https://developer.apple.com/documentation/swiftdata)
- [PDFKit](https://developer.apple.com/documentation/pdfkit)
- [VisionKit](https://developer.apple.com/documentation/visionkit)
- [Core ML](https://developer.apple.com/documentation/coreml)

### MLX Resources
- [MLX GitHub](https://github.com/ml-explore/mlx)
- [MLX Swift](https://github.com/ml-explore/mlx-swift)
- [MLX Examples](https://github.com/ml-explore/mlx-examples)

### Islamic Content Sources
- [Sunnah.com](https://sunnah.com) — Hadith collections
- [Quran.com](https://quran.com) — Quranic verses
- [Aladhan API](https://aladhan.com/prayer-times-api) — Prayer times

### Inspiration Apps
- PDF Expert — Clean UI, fast performance
- MarginNote — Mind maps, flashcards
- LiquidText — Excerpt workspace
- Highlights — Markdown export
- Obsidian — Linked notes

---

## Final Note

Build this app as if you were presenting it to Allah — with sincerity, excellence, and attention to every detail. Let every line of code, every pixel, and every interaction reflect the beauty of ihsan.

The goal is not just to build a PDF reader, but to create a tool that helps Muslims maintain their spiritual connection while pursuing knowledge in any field.

This is an act of worship disguised as software engineering.

بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ

Begin with the name of Allah, the Most Gracious, the Most Merciful.

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Dec 2024 | Initial prompt |
| 2.0 | Dec 2024 | Added cutting-edge tech (Swift 6, MLX, AI features), multi-platform architecture, EPUB support |
