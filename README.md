# NoorReader

> **نور القارئ** - "Light of the Reader"

A professional PDF and EPUB study application for Apple platforms with seamless Islamic reminders.

![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20iOS-blue)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Vision

NoorReader embodies the principle that **seeking knowledge is an act of worship**. Every study session is an opportunity for barakah (blessing).

Build with **Ihsan** — excellence, beauty, and attention to detail.

## Features

### Core Reading
- Smooth PDF rendering with PDFKit
- Day, Sepia, and Night themes
- Keyboard-first navigation
- Table of Contents sidebar
- Bookmarks and reading progress

### Annotations
- 8 semantic highlight colors
- Rich notes attached to highlights
- Markdown export with images
- Full-text search

### AI-Powered Study (Local & Private)
- Smart summarization via MLX
- Auto flashcard generation
- Semantic search
- Explain selection
- Optional Claude API integration

### Islamic Integration
- Launch dua banner
- Prayer time indicator (Aladhan API)
- Study break reminders with hadith
- Focus mode with Islamic motivation

### Study Tools
- Spaced repetition flashcards (SM-2)
- Study session timer
- Statistics dashboard
- Focus mode

## Technology Stack

| Component | Technology |
|-----------|------------|
| Language | Swift 6 (strict concurrency) |
| UI | SwiftUI + @Observable |
| Data | SwiftData + CloudKit |
| PDF | PDFKit + VisionKit |
| AI (Local) | MLX + Core ML |
| AI (Cloud) | Claude API (optional) |
| Search | SQLite FTS5 + Vector Embeddings |

## Architecture

```
NoorReader/
├── Shared/           # 80% - Cross-platform code
│   ├── Models/
│   ├── Services/
│   ├── ViewModels/
│   ├── Components/
│   └── Resources/
├── macOS/            # 10% - macOS-specific UI
└── iOS/              # 10% - iOS-specific UI
```

## Development Phases

| Phase | Focus | Status |
|-------|-------|--------|
| 1 | Foundation (MVP) | Not Started |
| 2 | Annotations | Not Started |
| 3 | AI Integration | Not Started |
| 4 | Study Tools | Not Started |
| 5 | Advanced (EPUB, Sync) | Not Started |
| 6 | iOS & Polish | Not Started |

## Getting Started

### Requirements
- macOS 15 (Sequoia) or later
- Xcode 16+
- Apple Silicon Mac (for MLX AI features)

### Build
```bash
git clone https://github.com/Inheriting-Islam/NoorReader.git
cd NoorReader
open NoorReader.xcodeproj
```

## Privacy

- **Local-first**: All data stored on device by default
- **AI runs locally**: MLX models never send data externally
- **No telemetry**: Zero analytics
- **No accounts**: Works without sign-up
- **iCloud sync**: Optional, user-controlled

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE)

---

*"Seeking knowledge is an obligation upon every Muslim."* — Ibn Majah

بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ
