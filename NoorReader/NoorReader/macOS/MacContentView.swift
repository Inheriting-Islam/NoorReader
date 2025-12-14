// MacContentView.swift
// NoorReader
//
// Main window layout with three-panel navigation including annotations sidebar

import SwiftUI
import SwiftData

struct MacContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var appState = AppState.shared
    @State private var showLaunchDua: Bool = true
    @State private var showLeftSidebar: Bool = true
    @State private var showAnnotationsSidebar: Bool = true
    @State private var isFocusMode: Bool = false
    @State private var showFocusModeHint: Bool = false

    // Store previous states for restoring after focus mode
    @State private var previousLeftSidebar: Bool = true
    @State private var previousAnnotationsSidebar: Bool = true

    var body: some View {
        ZStack {
            // Main three-panel layout using HStack for symmetrical sidebars
            HStack(spacing: 0) {
                // Left Sidebar
                if showLeftSidebar && !isFocusMode {
                    SidebarPanel {
                        MacSidebarView(
                            selectedCollection: $appState.selectedCollection,
                            selectedBook: $appState.selectedBook
                        )
                    }
                    .frame(width: 280)
                }

                // Main Content
                mainContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Right Sidebar (Annotations) - only show when a book is open
                if showAnnotationsSidebar && !isFocusMode, let book = appState.selectedBook {
                    SidebarPanel {
                        AnnotationsSidebar(
                            book: book,
                            onNavigateToPage: { page in
                                NotificationCenter.default.post(
                                    name: .goToPage,
                                    object: page
                                )
                            }
                        )
                    }
                    .frame(width: 280)
                }
            }
            .toolbar(isFocusMode ? .hidden : .automatic)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showLeftSidebar.toggle()
                        }
                    } label: {
                        Image(systemName: "sidebar.left")
                            .symbolVariant(showLeftSidebar ? .none : .slash)
                    }
                    .help("Toggle Sidebar (⌘⇧L)")
                    .keyboardShortcut("l", modifiers: [.command, .shift])
                }

                ToolbarItem(placement: .automatic) {
                    if appState.selectedBook != nil {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showAnnotationsSidebar.toggle()
                            }
                        } label: {
                            Image(systemName: "sidebar.right")
                                .symbolVariant(showAnnotationsSidebar ? .none : .slash)
                        }
                        .help("Toggle Annotations Sidebar (⌘⇧A)")
                        .keyboardShortcut("a", modifiers: [.command, .shift])
                    }
                }

                ToolbarItem(placement: .automatic) {
                    if appState.selectedBook != nil {
                        Button {
                            toggleFocusMode()
                        } label: {
                            Image(systemName: isFocusMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        }
                        .help("Focus Mode (⌘⇧F)")
                        .keyboardShortcut("f", modifiers: [.command, .shift])
                    }
                }
            }

            // Launch Dua Banner (overlay)
            if showLaunchDua && appState.showLaunchDua {
                LaunchDuaBanner(isPresented: $showLaunchDua)
            }

            // Focus Mode hint overlay
            if showFocusModeHint {
                FocusModeHint()
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            // Focus Mode exit button (appears on hover at top)
            if isFocusMode {
                FocusModeExitOverlay(onExit: toggleFocusMode)
            }
        }
        .frame(minWidth: isFocusMode ? 600 : 900, minHeight: isFocusMode ? 400 : 600)
        .onAppear {
            // Auto-dismiss launch dua after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showLaunchDua = false
                }
            }
        }
        // Handle notifications for keyboard shortcuts
        .onReceive(NotificationCenter.default.publisher(for: .toggleLeftSidebar)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                showLeftSidebar.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleRightSidebar)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                showAnnotationsSidebar.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleFocusMode)) { _ in
            toggleFocusMode()
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        if let book = appState.selectedBook {
            MacReaderView(book: book, isFocusMode: isFocusMode)
        } else {
            MacLibraryView(
                collection: appState.selectedCollection,
                selectedBook: $appState.selectedBook
            )
        }
    }

    // MARK: - Focus Mode

    private func toggleFocusMode() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if isFocusMode {
                // Exit focus mode - restore previous state
                showLeftSidebar = previousLeftSidebar
                showAnnotationsSidebar = previousAnnotationsSidebar
                isFocusMode = false
            } else {
                // Enter focus mode - save current state and hide everything
                previousLeftSidebar = showLeftSidebar
                previousAnnotationsSidebar = showAnnotationsSidebar
                showLeftSidebar = false
                showAnnotationsSidebar = false
                isFocusMode = true

                // Show hint briefly
                showFocusModeHint = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showFocusModeHint = false
                    }
                }
            }
        }
    }
}

// MARK: - Sidebar Panel

/// A panel container that matches the inspector styling - solid background color
struct SidebarPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxHeight: .infinity)
            .background(
                Color(nsColor: .windowBackgroundColor)
                    .ignoresSafeArea()
            )
    }
}

// MARK: - Focus Mode Hint

struct FocusModeHint: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "eye")
                .font(.system(size: 24))
                .foregroundStyle(.white)

            Text("Focus Mode")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Press ⌘⇧F or Esc to exit")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(24)
        .background(.black.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Focus Mode Exit Overlay

struct FocusModeExitOverlay: View {
    let onExit: () -> Void
    @State private var isHovering = false
    @State private var showButton = false

    var body: some View {
        VStack {
            // Invisible hover detection area at top
            Rectangle()
                .fill(Color.clear)
                .frame(height: 60)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showButton = hovering
                    }
                }
                .overlay(alignment: .top) {
                    if showButton {
                        exitButton
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }

            Spacer()
        }
        .onReceive(NotificationCenter.default.publisher(for: .exitFocusMode)) { _ in
            onExit()
        }
    }

    private var exitButton: some View {
        Button(action: onExit) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.right.and.arrow.up.left")
                Text("Exit Focus Mode")
                    .font(.caption)
                Text("⌘⇧F")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.black.opacity(0.6))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

#Preview {
    MacContentView()
        .modelContainer(for: [Book.self, Highlight.self, Bookmark.self, Collection.self, Note.self], inMemory: true)
}
