// MacReaderView.swift
// NoorReader
//
// PDF reader view with toolbar and navigation

import SwiftUI
import PDFKit
import SwiftData

struct MacReaderView: View {
    let book: Book
    var isFocusMode: Bool = false

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ReaderViewModel?
    @State private var showGoToPage = false
    @State private var showSearch = false
    @State private var goToPageText = ""
    @State private var settingsViewModel = SettingsViewModel()

    var body: some View {
        Group {
            if let viewModel {
                if viewModel.isLoading {
                    loadingView
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
            let vm = ReaderViewModel(book: book, modelContext: modelContext)
            vm.pageTurnAnimationsEnabled = settingsViewModel.pageTurnAnimationsEnabled && settingsViewModel.bookStyleEffectsEnabled
            viewModel = vm
        }
        .onChange(of: settingsViewModel.pageTurnAnimationsEnabled) { _, newValue in
            viewModel?.pageTurnAnimationsEnabled = newValue && settingsViewModel.bookStyleEffectsEnabled
        }
        .onChange(of: settingsViewModel.bookStyleEffectsEnabled) { _, newValue in
            viewModel?.pageTurnAnimationsEnabled = settingsViewModel.pageTurnAnimationsEnabled && newValue
        }
        .sheet(isPresented: $showGoToPage) {
            goToPageSheet
        }
        // Handle notifications
        .onReceive(NotificationCenter.default.publisher(for: .toggleSearch)) { _ in
            showSearch.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .goToPage)) { notification in
            if let page = notification.object as? Int {
                viewModel?.goToPage(page)
            } else {
                showGoToPage = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .nextPage)) { _ in
            viewModel?.nextPage()
        }
        .onReceive(NotificationCenter.default.publisher(for: .previousPage)) { _ in
            viewModel?.previousPage()
        }
        .onReceive(NotificationCenter.default.publisher(for: .firstPage)) { _ in
            viewModel?.goToFirstPage()
        }
        .onReceive(NotificationCenter.default.publisher(for: .lastPage)) { _ in
            viewModel?.goToLastPage()
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoomIn)) { _ in
            viewModel?.zoomIn()
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoomOut)) { _ in
            viewModel?.zoomOut()
        }
        .onReceive(NotificationCenter.default.publisher(for: .actualSize)) { _ in
            viewModel?.resetZoom()
        }
        .onReceive(NotificationCenter.default.publisher(for: .addBookmark)) { _ in
            viewModel?.toggleBookmark()
        }
        .onReceive(NotificationCenter.default.publisher(for: .findNext)) { _ in
            viewModel?.nextSearchResult()
        }
        .onReceive(NotificationCenter.default.publisher(for: .findPrevious)) { _ in
            viewModel?.previousSearchResult()
        }
        .navigationTitle(book.displayTitle)
        .modifier(KeyboardNavigationModifier(
            onPrevious: { viewModel?.previousPage() },
            onNext: { viewModel?.nextPage() },
            isFocusMode: isFocusMode
        ))
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Reader Content

    @ViewBuilder
    private func readerContent(document: PDFDocument, viewModel: ReaderViewModel) -> some View {
        VStack(spacing: 0) {
            // Search bar (if active)
            if showSearch {
                searchBar(viewModel: viewModel)
            }

            // PDF View with book-style effects
            ZStack {
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
                    theme: ThemeService.shared.currentTheme,
                    bookStyleEnabled: settingsViewModel.bookStyleEffectsEnabled,
                    paperTextureEnabled: settingsViewModel.paperTextureEnabled,
                    onSelectionChanged: { selection in
                        viewModel.currentSelection = selection
                    }
                )

                // Page turn animation overlay (for two-page mode)
                if case .animating(let direction, _) = viewModel.pageTurnState {
                    PageTurnOverlay(
                        direction: direction,
                        theme: ThemeService.shared.currentTheme,
                        onComplete: {
                            viewModel.completePageTurn()
                        }
                    )
                }
            }

            // Bottom bar with page scrubber (hidden in focus mode)
            if !isFocusMode {
                pageBar(viewModel: viewModel)
            }
        }
        .toolbar(isFocusMode ? .hidden : .automatic)
        .toolbar {
            readerToolbar(viewModel: viewModel)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private func readerToolbar(viewModel: ReaderViewModel) -> some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            // Back button
            Button(action: {
                AppState.shared.closeBook()
            }) {
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
            .help("Zoom Out")

            Text("\(Int(viewModel.scaleFactor * 100))%")
                .frame(width: 50)
                .font(.caption)

            Button(action: { viewModel.zoomIn() }) {
                Image(systemName: "plus.magnifyingglass")
            }
            .help("Zoom In")
        }

        ToolbarItemGroup(placement: .automatic) {
            // Search
            Button(action: { showSearch.toggle() }) {
                Image(systemName: "magnifyingglass")
            }
            .help("Find in Document")

            // Bookmark
            Button(action: { viewModel.toggleBookmark() }) {
                Image(systemName: viewModel.isCurrentPageBookmarked() ? "bookmark.fill" : "bookmark")
            }
            .help("Toggle Bookmark")

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
            .help("Go to Page")

            Spacer()

            // Progress bar
            ProgressScrubber(
                currentPage: Binding(
                    get: { viewModel.currentPage },
                    set: { viewModel.goToPage($0) }
                ),
                totalPages: viewModel.totalPages
            )
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

// MARK: - Keyboard Navigation Modifier

struct KeyboardNavigationModifier: ViewModifier {
    let onPrevious: () -> Void
    let onNext: () -> Void
    let isFocusMode: Bool

    func body(content: Content) -> some View {
        content
            .onKeyPress(.leftArrow) {
                onPrevious()
                return .handled
            }
            .onKeyPress(.rightArrow) {
                onNext()
                return .handled
            }
            .onKeyPress(.upArrow) {
                onPrevious()
                return .handled
            }
            .onKeyPress(.downArrow) {
                onNext()
                return .handled
            }
            .onKeyPress(.space) {
                onNext()
                return .handled
            }
            .onKeyPress(.escape) {
                if isFocusMode {
                    NotificationCenter.default.post(name: .toggleFocusMode, object: nil)
                    return .handled
                }
                return .ignored
            }
            .focusable()
    }
}
