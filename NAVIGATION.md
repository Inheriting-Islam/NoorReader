# NoorReader Navigation Map

> Complete screen hierarchy and navigation flows for macOS and iOS

---

## Table of Contents

1. [macOS Navigation Structure](#macos-navigation-structure)
2. [Screen Descriptions](#screen-descriptions)
3. [Navigation Flows](#navigation-flows)
4. [Modals & Sheets](#modals--sheets)
5. [Overlays & Banners](#overlays--banners)
6. [iOS Navigation Structure](#ios-navigation-structure)
7. [Keyboard Shortcuts](#keyboard-shortcuts)
8. [State Diagram](#state-diagram)

---

## macOS Navigation Structure

NoorReader uses a **three-panel NavigationSplitView** as the primary layout pattern.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  NoorReader                                               􀊫 􀍟  🕌 Asr 45m  │
├────────────┬────────────────────────────────────────────────┬───────────────┤
│            │                                                │               │
│  SIDEBAR   │              MAIN CONTENT                      │   INSPECTOR   │
│  (240px)   │              (flexible)                        │   (280px)     │
│            │                                                │               │
│  Library   │  ┌──────────────────────────────────────────┐  │  Annotations  │
│  ─────────── │  │                                          │  │  ───────────  │
│  📚 All     │  │                                          │  │  Highlights  │
│  📖 Reading │  │         PDF / Library Grid               │  │  Notes       │
│  ⭐ Favorites│  │                                          │  │               │
│  📁 Work    │  │                                          │  │  Study       │
│  📁 Islamic │  │                                          │  │  ───────────  │
│             │  │                                          │  │  Flashcards  │
│  Contents   │  │                                          │  │  Timer       │
│  ─────────── │  │                                          │  │  Stats       │
│  Ch 1...    │  │                                          │  │               │
│  Ch 2...    │  └──────────────────────────────────────────┘  │               │
│             │  ━━━━━━━━━━━━━━━━━━░░░░░░░░ 67%              │               │
│  Bookmarks  │                                                │               │
│  ─────────── │                                                │               │
│  📑 p.45    │                                                │               │
│  📑 p.123   │                                                │               │
│             │                                                │               │
└────────────┴────────────────────────────────────────────────┴───────────────┘
```

### Complete Screen Hierarchy

```
NoorReader.app
│
├── 🪟 Main Window (NSWindow + NavigationSplitView)
│   │
│   ├── 📑 Left Sidebar (NavigationSplitView.sidebar)
│   │   │
│   │   ├── 📚 Library Section
│   │   │   ├── All Books (default selection)
│   │   │   ├── Reading Now (smart collection - recently opened)
│   │   │   ├── Favorites (smart collection - starred books)
│   │   │   ├── Recently Added (smart collection - last 30 days)
│   │   │   └── 📁 Custom Collections (user-created folders)
│   │   │       ├── [Collection Name]
│   │   │       ├── [Collection Name]
│   │   │       └── + New Collection
│   │   │
│   │   ├── 📖 Table of Contents (visible when book is open)
│   │   │   ├── [Chapter 1]
│   │   │   │   ├── [Section 1.1]
│   │   │   │   └── [Section 1.2]
│   │   │   ├── [Chapter 2]
│   │   │   └── ... (from PDF outline)
│   │   │
│   │   └── 📑 Bookmarks (visible when book is open)
│   │       ├── [Bookmark 1] - Page X - "Title/Note"
│   │       ├── [Bookmark 2] - Page Y
│   │       └── + Add Bookmark (⌘D)
│   │
│   ├── 📄 Main Content Area (NavigationSplitView.content)
│   │   │
│   │   ├── 📚 Library Grid View (when no book selected)
│   │   │   │
│   │   │   ├── 🔍 Search Bar (library search)
│   │   │   │   ├── Text search
│   │   │   │   ├── Semantic search (Phase 3)
│   │   │   │   └── Filter dropdown (by collection, tag, date)
│   │   │   │
│   │   │   ├── 📊 Sort Controls
│   │   │   │   ├── Title (A-Z, Z-A)
│   │   │   │   ├── Author (A-Z, Z-A)
│   │   │   │   ├── Date Added (newest, oldest)
│   │   │   │   ├── Last Read (recent, oldest)
│   │   │   │   └── Progress (most, least)
│   │   │   │
│   │   │   └── 📕 Book Cards Grid
│   │   │       ├── [Book Card]
│   │   │       │   ├── Cover image
│   │   │       │   ├── Title
│   │   │       │   ├── Author
│   │   │       │   ├── Progress bar
│   │   │       │   ├── ⭐ Favorite indicator
│   │   │       │   └── 🤖 AI indexed indicator
│   │   │       │
│   │   │       │   Actions (right-click context menu):
│   │   │       │   ├── Open
│   │   │       │   ├── Open in New Window
│   │   │       │   ├── Add to Favorites
│   │   │       │   ├── Add to Collection →
│   │   │       │   ├── Show in Finder
│   │   │       │   ├── Get Info
│   │   │       │   └── Delete from Library
│   │   │       │
│   │   │       └── [Book Card] ... (repeating)
│   │   │
│   │   └── 📖 Reader View (when book is open)
│   │       │
│   │       ├── 🔧 Toolbar
│   │       │   ├── ← Back to Library
│   │       │   ├── View Mode (Single / Continuous / Two-Page)
│   │       │   ├── Zoom Controls (-, %, +, Fit Width, Fit Page)
│   │       │   ├── 🔍 Search in Document (⌘F)
│   │       │   ├── 📑 Add Bookmark (⌘D)
│   │       │   ├── 🎨 Theme Picker (Day/Sepia/Night/Auto)
│   │       │   ├── 🕌 Prayer Time Indicator
│   │       │   └── ⏱️ Study Timer (start/pause)
│   │       │
│   │       ├── 📄 PDF View (PDFKit PDFView)
│   │       │   │
│   │       │   ├── Page Content
│   │       │   │   ├── Text (selectable)
│   │       │   │   ├── Images
│   │       │   │   └── Highlight Overlays (rendered annotations)
│   │       │   │
│   │       │   ├── 📝 Selection Popover (on text selection)
│   │       │   │   │
│   │       │   │   ├── Selected Text Preview (truncated)
│   │       │   │   │
│   │       │   │   ├── Primary Actions Row
│   │       │   │   │   ├── 🖍️ Highlight
│   │       │   │   │   ├── ✏️ Underline
│   │       │   │   │   ├── 📝 Add Note
│   │       │   │   │   ├── 🔗 Copy Link
│   │       │   │   │   ├── 📋 Copy Text
│   │       │   │   │   ├── 🎴 Create Flashcard
│   │       │   │   │   └── 🤖 AI Actions →
│   │       │   │   │       ├── Summarize Selection
│   │       │   │   │       ├── Explain Selection
│   │       │   │   │       ├── Generate Flashcards
│   │       │   │   │       └── Ask Question (Cloud AI)
│   │       │   │   │
│   │       │   │   └── Color Picker Row (for highlight)
│   │       │   │       ├── 🟡 Yellow (1) - General
│   │       │   │       ├── 🟢 Green (2) - Key Concept
│   │       │   │       ├── 🔵 Blue (3) - Definition
│   │       │   │       ├── 🩷 Pink (4) - Question
│   │       │   │       ├── 🟠 Orange (5) - Example
│   │       │   │       ├── 🟣 Purple (6) - Connection
│   │       │   │       ├── 🔴 Red (7) - Critical
│   │       │   │       └── ⚫ Gray (8) - Reference
│   │       │   │
│   │       │   └── 📑 Note Indicators (clickable icons on page)
│   │       │       └── Click → Opens Note Popover
│   │       │
│   │       ├── 🔍 Search Bar (⌘F, slides down from toolbar)
│   │       │   ├── Search Input Field
│   │       │   ├── Result Count ("3 of 47")
│   │       │   ├── ⬆️ Previous Match (⌘⇧G)
│   │       │   ├── ⬇️ Next Match (⌘G)
│   │       │   └── ✕ Close (Escape)
│   │       │
│   │       └── 📊 Page Scrubber (bottom)
│   │           ├── Thumbnail strip (horizontal scroll)
│   │           ├── Current page indicator
│   │           ├── Drag to navigate
│   │           └── Click thumbnail to jump
│   │
│   └── 📋 Right Sidebar / Inspector (NavigationSplitView.detail)
│       │
│       ├── 📑 Tab: Annotations
│       │   │
│       │   ├── 🔍 Search Annotations
│       │   │
│       │   ├── 🎛️ Filter Bar
│       │   │   ├── All
│       │   │   ├── Highlights Only
│       │   │   ├── Notes Only
│       │   │   └── By Color →
│       │   │
│       │   ├── 📊 Sort
│       │   │   ├── By Page (default)
│       │   │   └── By Date
│       │   │
│       │   ├── 📈 Summary Stats
│       │   │   └── "12 highlights • 5 notes"
│       │   │
│       │   └── 📜 Annotation List
│       │       ├── [Highlight Item]
│       │       │   ├── Color indicator
│       │       │   ├── Highlighted text (truncated)
│       │       │   ├── Page number
│       │       │   ├── 📝 Note indicator (if has note)
│       │       │   └── Click → Navigate to location
│       │       │
│       │       │   Actions (right-click):
│       │       │   ├── Go to Page
│       │       │   ├── Edit Note
│       │       │   ├── Change Color →
│       │       │   ├── Create Flashcard
│       │       │   ├── Copy Text
│       │       │   └── Delete
│       │       │
│       │       └── [Note Item]
│       │           ├── 📝 Icon
│       │           ├── Note preview (truncated)
│       │           ├── Page number
│       │           ├── Tags
│       │           └── Click → Navigate & expand
│       │
│       ├── 📚 Tab: Study
│       │   │
│       │   ├── 🎴 Flashcards Section
│       │   │   ├── Cards Due: [X]
│       │   │   ├── [Start Review] button
│       │   │   ├── Cards by Book breakdown
│       │   │   └── [View All Cards] → Flashcard Manager
│       │   │
│       │   ├── ⏱️ Study Timer Section
│       │   │   ├── Current Session: HH:MM:SS
│       │   │   ├── [Start] / [Pause] / [End]
│       │   │   └── Break reminder setting
│       │   │
│       │   ├── 📊 Statistics Section
│       │   │   ├── Today: X hours
│       │   │   ├── This Week: X hours
│       │   │   ├── 🔥 Streak: X days
│       │   │   └── [View Full Stats] → Statistics Dashboard
│       │   │
│       │   └── 🕌 Daily Reminder Widget
│       │       ├── Hadith/Dua of the day
│       │       ├── Arabic text
│       │       ├── Translation
│       │       ├── Source reference
│       │       ├── ❤️ Save to Favorites
│       │       └── 📤 Share
│       │
│       └── 🤖 Tab: AI (Phase 3+)
│           │
│           ├── 📝 Summary Section
│           │   ├── [Summarize Current Chapter]
│           │   ├── [Summarize Selection]
│           │   └── Recent Summaries list
│           │
│           ├── 💬 Study Chat (Cloud AI, optional)
│           │   ├── Chat history
│           │   ├── Input field
│           │   └── "Ask about this book..."
│           │
│           └── 🔒 Privacy Indicator
│               ├── "🔒 Local AI" or "☁️ Cloud AI"
│               └── [Settings] link
│
├── ⚙️ Settings Window (⌘,) - Separate NSWindow
│   │
│   ├── 🎨 General
│   │   ├── Appearance
│   │   │   ├── Theme: [Day / Sepia / Night / Auto]
│   │   │   ├── Accent Color: [Color picker]
│   │   │   └── App Icon: [Default / Alternative]
│   │   │
│   │   ├── Sidebar
│   │   │   ├── Default Left Sidebar Width: [slider]
│   │   │   ├── Default Right Sidebar Width: [slider]
│   │   │   └── Show Sidebar on Launch: [checkbox]
│   │   │
│   │   └── Toolbar
│   │       ├── Show Prayer Time: [checkbox]
│   │       └── Show Study Timer: [checkbox]
│   │
│   ├── 📖 Reading
│   │   ├── View
│   │   │   ├── Default View Mode: [Single / Continuous / Two-Page]
│   │   │   ├── Default Zoom: [Fit Width / Fit Page / 100%]
│   │   │   └── Scroll Direction: [Vertical / Horizontal]
│   │   │
│   │   ├── Behavior
│   │   │   ├── Remember Reading Position: [checkbox]
│   │   │   ├── Page Turn Animation: [checkbox]
│   │   │   └── Auto-hide Toolbar in Full Screen: [checkbox]
│   │   │
│   │   └── Text
│   │       ├── PDF Rendering Quality: [Fast / Balanced / Best]
│   │       └── Enable Text Selection: [checkbox]
│   │
│   ├── 🖍️ Annotations
│   │   ├── Highlighting
│   │   │   ├── Default Highlight Color: [color picker]
│   │   │   └── Show Color Shortcuts (1-8): [checkbox]
│   │   │
│   │   ├── Notes
│   │   │   ├── Default Note Template: [text area]
│   │   │   └── Auto-timestamp Notes: [checkbox]
│   │   │
│   │   └── Export
│   │       ├── Default Export Format: [Markdown / JSON / Plain Text]
│   │       ├── Include Images in Export: [checkbox]
│   │       ├── Group By: [Chapter / Date / Color]
│   │       └── Obsidian Vault Path: [folder picker]
│   │
│   ├── 🤖 AI Features
│   │   ├── General
│   │   │   ├── Enable AI Features: [checkbox]
│   │   │   └── AI Processing: [Local Only / Allow Cloud]
│   │   │
│   │   ├── Local AI (MLX)
│   │   │   ├── Model: [Phi-2 / Mistral 7B / Llama 2 7B]
│   │   │   ├── Quality vs Speed: [slider]
│   │   │   ├── Model Status: [Downloaded / Downloading / Not Downloaded]
│   │   │   └── [Download Model] / [Delete Model] button
│   │   │
│   │   └── Cloud AI (Optional)
│   │       ├── Enable Cloud AI: [checkbox]
│   │       ├── Claude API Key: [secure text field]
│   │       ├── [Test Connection] button
│   │       └── Ask Before Each Request: [checkbox]
│   │
│   ├── 🎴 Study Tools
│   │   ├── Flashcards
│   │   │   ├── New Card Interval: [1 day / Custom]
│   │   │   ├── Easy Bonus: [slider]
│   │   │   └── Maximum Interval: [days]
│   │   │
│   │   ├── Study Timer
│   │   │   ├── Break Reminder Interval: [30 / 45 / 60 min / Off]
│   │   │   ├── Break Duration: [5 / 10 / 15 min]
│   │   │   └── Show Islamic Content in Breaks: [checkbox]
│   │   │
│   │   └── Focus Mode
│   │       ├── Show Entry Hadith: [checkbox]
│   │       └── Hide All UI Elements: [checkbox]
│   │
│   ├── 🕌 Islamic Reminders
│   │   ├── General
│   │   │   ├── Enable Islamic Reminders: [checkbox]
│   │   │   └── Frequency: [Minimal / Moderate / Frequent]
│   │   │
│   │   ├── Content
│   │   │   ├── Language: [Arabic Only / English Only / Both]
│   │   │   ├── Show Transliteration: [checkbox]
│   │   │   ├── Show Source Reference: [checkbox]
│   │   │   └── Content Types: [Hadith ☑️] [Quran ☑️] [Dua ☑️]
│   │   │
│   │   ├── Launch Dua
│   │   │   ├── Show on App Launch: [checkbox]
│   │   │   ├── Auto-dismiss After: [3s / 5s / Manual]
│   │   │   └── Custom Dua: [text field]
│   │   │
│   │   └── Prayer Times
│   │       ├── Show Prayer Time Indicator: [checkbox]
│   │       ├── Location: [Auto-detect / Manual]
│   │       ├── City: [text field] (if manual)
│   │       ├── Calculation Method: [ISNA / MWL / Umm al-Qura / ...]
│   │       ├── Asr Calculation: [Shafi / Hanafi]
│   │       ├── Reminder Before Prayer: [Off / 5m / 10m / 15m / 30m]
│   │       └── Pause Study Session for Prayer: [checkbox]
│   │
│   └── 🔒 Data & Privacy
│       ├── Sync
│       │   ├── Enable iCloud Sync: [checkbox]
│       │   ├── Sync Status: [indicator]
│       │   ├── Last Synced: [timestamp]
│       │   └── [Sync Now] button
│       │
│       ├── Data
│       │   ├── Library Location: [path]
│       │   ├── [Export All Data] button
│       │   ├── [Import Data] button
│       │   └── [Clear Cache] button
│       │
│       └── Privacy
│           ├── Analytics: Disabled (no telemetry)
│           └── [View Stored Data] button
│
├── 📊 Statistics Dashboard (separate window or sheet)
│   │
│   ├── Overview Cards
│   │   ├── Total Study Time (all time)
│   │   ├── Books Completed
│   │   ├── Current Streak
│   │   └── Flashcard Accuracy
│   │
│   ├── Time Period Tabs
│   │   ├── Today
│   │   ├── This Week
│   │   ├── This Month
│   │   └── All Time
│   │
│   ├── Charts
│   │   ├── Study Time by Day (bar chart)
│   │   ├── Activity Heatmap (GitHub-style)
│   │   ├── Reading Progress by Book
│   │   └── Flashcard Performance Over Time
│   │
│   └── Details
│       ├── Per-Book Statistics
│       ├── Highlights Created
│       ├── Notes Written
│       └── Flashcards Reviewed
│
├── 🎴 Flashcard Manager (separate window or sheet)
│   │
│   ├── Toolbar
│   │   ├── 🔍 Search Cards
│   │   ├── Filter by Book
│   │   ├── Filter by Tag
│   │   ├── [+ New Card] button
│   │   └── [Start Review] button
│   │
│   ├── Card List
│   │   ├── [Flashcard Row]
│   │   │   ├── Front preview
│   │   │   ├── Back preview
│   │   │   ├── Source (Book, Page)
│   │   │   ├── Tags
│   │   │   ├── Next Review Date
│   │   │   └── Ease Factor indicator
│   │   └── ...
│   │
│   └── Card Editor (on selection)
│       ├── Front (Question)
│       ├── Back (Answer)
│       ├── Tags
│       ├── Source Link
│       └── [Save] [Delete] buttons
│
└── 📖 Book Info Window (Get Info)
    ├── Cover Image
    ├── Metadata
    │   ├── Title (editable)
    │   ├── Author (editable)
    │   ├── File Path
    │   ├── File Size
    │   ├── Page Count
    │   └── Date Added
    ├── Statistics
    │   ├── Reading Progress
    │   ├── Time Spent
    │   ├── Highlights Count
    │   ├── Notes Count
    │   └── Flashcards Count
    └── Actions
        ├── [Change Cover]
        ├── [Re-index for AI]
        └── [Delete from Library]
```

---

## Screen Descriptions

### Main Window

| Screen | Purpose | Entry Point |
|--------|---------|-------------|
| Library Grid | Browse and manage book collection | Default view / Back button |
| Reader View | Read PDF with annotations | Click book card |
| Left Sidebar | Navigate library and book contents | Always visible (toggleable) |
| Right Sidebar | View annotations and study tools | Always visible (toggleable) |

### Modal Sheets

| Modal | Purpose | Trigger |
|-------|---------|---------|
| Go to Page | Jump to specific page | ⌘G |
| AI Summary | Display AI-generated summary | AI Actions → Summarize |
| AI Flashcards | Review and save AI-generated cards | AI Actions → Generate Flashcards |
| Explain Selection | Show plain-English explanation | AI Actions → Explain |
| Export Options | Configure annotation export | Export button |
| Flashcard Review | Spaced repetition review session | Start Review button |
| Study Break | Break reminder with Islamic content | Auto (45min) or manual |
| Book Completion | Celebration with stats and dua | Finish reading book |
| Note Editor | Create/edit notes | Add Note or Edit Note |
| Collection Editor | Create/edit collections | New Collection or Edit |

### Separate Windows

| Window | Purpose | Trigger |
|--------|---------|---------|
| Settings | Configure all app preferences | ⌘, |
| Statistics Dashboard | View detailed study statistics | View Full Stats |
| Flashcard Manager | Manage all flashcards | View All Cards |
| Book Info | View/edit book metadata | Get Info (right-click) |
| New Window | Same book in second window | Open in New Window |

---

## Navigation Flows

### Flow 1: Import and Read a Book

```
[App Launch]
    │
    ▼
[Launch Dua Banner] ──(3s auto-dismiss)──┐
    │                                     │
    ▼                                     │
[Library Grid] ◄──────────────────────────┘
    │
    ├──(drag & drop PDF)──► [Book Added to Library]
    │                              │
    │                              ▼
    │                       [Book Card Appears]
    │                              │
    └──(click book card)───────────┘
                │
                ▼
         [Reader View]
                │
                ├──(⌘⇧L)──► [Toggle Left Sidebar]
                ├──(⌘⇧R)──► [Toggle Right Sidebar]
                ├──(click TOC item)──► [Navigate to Chapter]
                └──(← Back)──► [Library Grid]
```

### Flow 2: Highlight and Annotate

```
[Reader View]
    │
    ├──(select text)
    │       │
    │       ▼
    │  [Selection Popover]
    │       │
    │       ├──(click Highlight)──► [Text Highlighted]
    │       │       │                      │
    │       │       └──(pick color 1-8)────┘
    │       │
    │       ├──(click Add Note)──► [Note Editor Sheet]
    │       │                             │
    │       │                             ├──(type note)
    │       │                             ├──(add tags)
    │       │                             └──(Save)──► [Note Saved]
    │       │
    │       └──(click AI Actions)──► [AI Submenu]
    │               │
    │               ├──► Summarize ──► [Summary Sheet]
    │               ├──► Explain ──► [Explanation Popover]
    │               └──► Create Flashcard ──► [Flashcard Sheet]
    │
    └──(click highlight on page)
            │
            ▼
       [Highlight Popover]
            │
            ├──(Edit Note)──► [Note Editor]
            ├──(Change Color)──► [Color Picker]
            └──(Delete)──► [Confirmation]──► [Highlight Removed]
```

### Flow 3: Flashcard Review Session

```
[Right Sidebar - Study Tab]
    │
    └──(click Start Review)
            │
            ▼
    [Flashcard Review Sheet]
            │
            ▼
    ┌─────────────────────────┐
    │   [Card Front]          │
    │                         │
    │   "What is deep work?"  │
    │                         │
    │   [Tap to Reveal]       │
    └─────────────────────────┘
            │
            ▼ (tap/click)
    ┌─────────────────────────┐
    │   [Card Back]           │
    │                         │
    │   "Professional..."     │
    │                         │
    │ [Again][Hard][Good][Easy]│
    │  <1m   <10m   1d    4d  │
    └─────────────────────────┘
            │
            ├──(select rating)──► [Next Card] (loop)
            │
            └──(all cards done)──► [Session Summary]
                                        │
                                        ├── Cards Reviewed: X
                                        ├── Accuracy: X%
                                        ├── Time: X min
                                        └── [Alhamdulillah Toast]
```

### Flow 4: Study Session with Break

```
[Reader View]
    │
    └──(click Start Timer in toolbar)
            │
            ▼
    [Timer Running: 00:00:00]
            │
            ... (reading) ...
            │
            ▼ (45 minutes elapsed)
    [Study Break Modal]
    ┌─────────────────────────────────────┐
    │  ☕ Time for a Break                │
    │                                     │
    │  You've been studying for 45 min.   │
    │  MashaAllah! Take a short break.    │
    │                                     │
    │  ─────────────────────────────────  │
    │  "Your body has a right over you."  │
    │  — Sahih al-Bukhari 5199            │
    │  ─────────────────────────────────  │
    │                                     │
    │  [5 min] [15 min] [Continue]        │
    └─────────────────────────────────────┘
            │
            ├──(5 min / 15 min)──► [Timer Paused] ──► [Resume after break]
            │
            └──(Continue)──► [Timer Continues]
```

### Flow 5: Focus Mode

```
[Reader View]
    │
    └──(⌘⇧Enter)
            │
            ▼
    [Focus Mode Entry]
    ┌─────────────────────────────────────────────┐
    │                                             │
    │           Entering Focus Mode               │
    │                                             │
    │   "Take advantage of five before five:      │
    │    Your youth before your old age..."       │
    │                                             │
    │                — Ibn Abbas                  │
    │                                             │
    │              [Begin]                        │
    │                                             │
    └─────────────────────────────────────────────┘
            │
            ▼
    [Focus Mode View]
    ┌─────────────────────────────────────────────┐
    │                                             │
    │                                             │
    │              PDF Content                    │
    │           (full screen, clean)              │
    │                                             │
    │                                             │
    │                                   ━━━ 67%  │
    └─────────────────────────────────────────────┘
            │
            └──(Escape or ⌘⇧Enter)──► [Reader View]
```

---

## Modals & Sheets

### Full List of Modals

| Name | Type | Size | Dismissal |
|------|------|------|-----------|
| Go to Page | Sheet | Small (300x150) | Enter / Escape |
| AI Summary | Sheet | Large (600x500) | Close button / Escape |
| AI Flashcard Suggestions | Sheet | Large (600x600) | Close button / Escape |
| Explain Selection | Popover | Medium (400x300) | Click outside / Escape |
| Export Options | Sheet | Medium (400x350) | Export / Cancel |
| Flashcard Review | Sheet | Large (500x400) | Complete / Close |
| Study Break Reminder | Modal | Medium (450x350) | Button selection |
| Book Completion | Modal | Medium (400x450) | Close button |
| Note Editor | Sheet | Medium (400x400) | Save / Cancel |
| Collection Editor | Sheet | Small (350x200) | Save / Cancel |
| Delete Confirmation | Alert | Small | Confirm / Cancel |
| AI Cloud Consent | Alert | Small | Allow / Deny |

---

## Overlays & Banners

### Persistent UI Elements

| Element | Location | Visibility |
|---------|----------|------------|
| Launch Dua Banner | Top of window | App launch (3s) |
| Prayer Time Indicator | Toolbar | Always (if enabled) |
| Study Timer | Toolbar | When active |
| Daily Hadith Widget | Right sidebar | Study tab |
| Sync Status | Status bar | During sync |

### Toast Notifications

| Toast | Trigger | Duration |
|-------|---------|----------|
| "Highlight saved" | Create highlight | 2s |
| "Note saved" | Save note | 2s |
| "Flashcard created" | Create flashcard | 2s |
| "Alhamdulillah" | Complete flashcard session | 3s |
| "Export complete" | Finish export | 3s |
| "Dua of Musa" | Struggle detected (Phase 4+) | 5s |
| "Prayer time approaching" | 5-30 min before prayer | 5s |

---

## iOS Navigation Structure

### Tab-Based Navigation (iPhone)

```
┌─────────────────────────────────────────┐
│                                         │
│                                         │
│            [Current Tab View]           │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│  📚        📖        🎴        ⚙️       │
│ Library   Reader    Study    Settings   │
└─────────────────────────────────────────┘
```

### iPad Navigation (Sidebar + Content)

```
┌────────────┬────────────────────────────┐
│            │                            │
│  Sidebar   │       Main Content         │
│            │                            │
│  Library   │                            │
│  ────────  │                            │
│  All Books │                            │
│  Reading   │                            │
│  Favorites │                            │
│            │                            │
│  Study     │                            │
│  ────────  │                            │
│  Flashcards│                            │
│  Stats     │                            │
│            │                            │
└────────────┴────────────────────────────┘
```

### iOS Screen Hierarchy

```
NoorReader (iOS)
│
├── 📚 Library Tab
│   ├── Library Grid
│   │   ├── Search Bar
│   │   ├── Sort/Filter
│   │   └── Book Cards
│   └── Book Detail (push)
│       └── Reader View (push)
│
├── 📖 Reader Tab (contextual - shows when book open)
│   ├── PDF View
│   ├── Selection Actions (sheet)
│   ├── TOC (sheet)
│   ├── Bookmarks (sheet)
│   ├── Annotations (sheet)
│   └── Search (sheet)
│
├── 🎴 Study Tab
│   ├── Flashcards Due
│   ├── Review Session (full screen)
│   ├── Statistics
│   └── Daily Reminder
│
└── ⚙️ Settings Tab
    ├── (Same as macOS Settings)
    └── Adapted for iOS UI
```

---

## Keyboard Shortcuts

### Global (Always Active)

| Shortcut | Action |
|----------|--------|
| ⌘O | Open file |
| ⌘W | Close window |
| ⌘, | Open Settings |
| ⌘Q | Quit app |

### Library View

| Shortcut | Action |
|----------|--------|
| ⌘N | New Collection |
| ⌘⇧F | Search Library |
| Delete | Delete selected book |
| Enter | Open selected book |

### Reader View

| Shortcut | Action |
|----------|--------|
| ← / → | Previous / Next page |
| ⌘↑ / ⌘↓ | Previous / Next page |
| ⌘G | Go to page |
| ⌘F | Find in document |
| ⌘G | Find next (when search active) |
| ⌘⇧G | Find previous |
| ⌘D | Add bookmark |
| ⌘⇧N | Add note |
| ⌘⇧L | Toggle left sidebar |
| ⌘⇧R | Toggle right sidebar |
| ⌘+ | Zoom in |
| ⌘- | Zoom out |
| ⌘0 | Actual size |
| ⌘⇧Enter | Toggle Focus Mode |
| 1-8 | Highlight with color (when text selected) |
| Escape | Close search / Exit focus mode |

### Flashcard Review

| Shortcut | Action |
|----------|--------|
| Space | Reveal answer |
| 1 | Again |
| 2 | Hard |
| 3 | Good |
| 4 | Easy |
| Escape | End session |

---

## State Diagram

### App States

```
                    ┌─────────────┐
                    │   Launch    │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │ Launch Dua  │
                    │   Banner    │
                    └──────┬──────┘
                           │ (3s)
                           ▼
              ┌────────────────────────┐
              │                        │
              │     LIBRARY VIEW       │◄────────────────┐
              │                        │                 │
              └───────────┬────────────┘                 │
                          │                              │
                          │ (open book)                  │
                          ▼                              │
              ┌────────────────────────┐                 │
              │                        │                 │
              │     READER VIEW        │─────────────────┤
              │                        │    (back)       │
              └───────────┬────────────┘                 │
                          │                              │
          ┌───────────────┼───────────────┐              │
          │               │               │              │
          ▼               ▼               ▼              │
    ┌───────────┐  ┌───────────┐  ┌───────────┐         │
    │  SELECT   │  │  SEARCH   │  │  FOCUS    │         │
    │  TEXT     │  │  MODE     │  │  MODE     │         │
    └─────┬─────┘  └─────┬─────┘  └─────┬─────┘         │
          │               │               │              │
          │               │               │              │
          ▼               ▼               │              │
    ┌───────────┐  ┌───────────┐         │              │
    │ SELECTION │  │ SEARCH    │         │              │
    │ POPOVER   │  │ RESULTS   │         │              │
    └─────┬─────┘  └───────────┘         │              │
          │                               │              │
          ├─────────────────┐             │              │
          │                 │             │              │
          ▼                 ▼             │              │
    ┌───────────┐    ┌───────────┐       │              │
    │ HIGHLIGHT │    │ AI ACTION │       │              │
    │ CREATED   │    │ SHEET     │       │              │
    └───────────┘    └───────────┘       │              │
                                         │              │
                                         ▼              │
                                   ┌───────────┐        │
                                   │  EXIT     │────────┘
                                   │  FOCUS    │
                                   └───────────┘
```

### Book Reading States

```
┌─────────────────────────────────────────────────────┐
│                    BOOK STATES                       │
├─────────────────────────────────────────────────────┤
│                                                     │
│   ┌──────────┐     ┌──────────┐     ┌──────────┐   │
│   │   NOT    │────►│ READING  │────►│COMPLETED │   │
│   │  STARTED │     │    NOW   │     │          │   │
│   └──────────┘     └──────────┘     └──────────┘   │
│        │                │                 │         │
│        │                │                 │         │
│        ▼                ▼                 ▼         │
│   Progress: 0%    Progress: 1-99%   Progress: 100%  │
│                                                     │
│   "Reading Now" collection = books with 1-99%       │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## Visual Navigation Diagram

See `NAVIGATION_DIAGRAM.md` for Mermaid flowchart.
