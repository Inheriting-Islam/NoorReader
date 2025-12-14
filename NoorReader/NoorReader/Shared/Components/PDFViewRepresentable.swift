// PDFViewRepresentable.swift
// NoorReader
//
// SwiftUI wrapper for PDFKit's PDFView with highlight overlay support

import SwiftUI
import PDFKit
import QuartzCore

struct PDFViewRepresentable: NSViewRepresentable {
    let document: PDFDocument
    @Binding var currentPage: Int
    @Binding var scaleFactor: CGFloat
    let displayMode: PDFDisplayMode
    let highlights: [Highlight]
    let theme: ReadingTheme
    let bookStyleEnabled: Bool
    let paperTextureEnabled: Bool
    let onSelectionChanged: ((PDFSelection?) -> Void)?
    let onHighlightTap: ((Highlight) -> Void)?

    init(
        document: PDFDocument,
        currentPage: Binding<Int>,
        scaleFactor: Binding<CGFloat>,
        displayMode: PDFDisplayMode,
        highlights: [Highlight] = [],
        theme: ReadingTheme = .day,
        bookStyleEnabled: Bool = true,
        paperTextureEnabled: Bool = true,
        onSelectionChanged: ((PDFSelection?) -> Void)? = nil,
        onHighlightTap: ((Highlight) -> Void)? = nil
    ) {
        self.document = document
        self._currentPage = currentPage
        self._scaleFactor = scaleFactor
        self.displayMode = displayMode
        self.highlights = highlights
        self.theme = theme
        self.bookStyleEnabled = bookStyleEnabled
        self.paperTextureEnabled = paperTextureEnabled
        self.onSelectionChanged = onSelectionChanged
        self.onHighlightTap = onHighlightTap
    }

    func makeNSView(context: Context) -> ThemedPDFView {
        let pdfView = ThemedPDFView()
        pdfView.document = document
        pdfView.autoScales = false
        pdfView.displayMode = displayMode
        pdfView.displayDirection = .vertical
        pdfView.delegate = context.coordinator

        // Apply initial theme
        pdfView.applyTheme(theme)

        // Configure book style effects
        pdfView.configureBookStyle(enabled: bookStyleEnabled, paperTexture: paperTextureEnabled)

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

        // Set up notification for scale changes
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.scaleChanged),
            name: .PDFViewScaleChanged,
            object: pdfView
        )

        return pdfView
    }

    func updateNSView(_ pdfView: ThemedPDFView, context: Context) {
        // Update display mode
        if pdfView.displayMode != displayMode {
            pdfView.displayMode = displayMode
            // Reconfigure book style when display mode changes
            pdfView.configureBookStyle(enabled: bookStyleEnabled, paperTexture: paperTextureEnabled)
        }

        // Update scale factor
        if abs(pdfView.scaleFactor - scaleFactor) > 0.01 {
            pdfView.scaleFactor = scaleFactor
        }

        // Navigate to page if changed externally
        if let page = document.page(at: currentPage),
           pdfView.currentPage != page {
            pdfView.go(to: page)
        }

        // Update theme
        pdfView.applyTheme(theme)

        // Update book style configuration
        pdfView.configureBookStyle(enabled: bookStyleEnabled, paperTexture: paperTextureEnabled)

        // Update highlights overlay
        context.coordinator.updateHighlights(highlights, in: pdfView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PDFViewDelegate {
        var parent: PDFViewRepresentable
        private var highlightOverlays: [NSView] = []

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
                if self.parent.currentPage != pageIndex {
                    self.parent.currentPage = pageIndex
                }
            }
        }

        @objc func selectionChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView else { return }

            DispatchQueue.main.async {
                self.parent.onSelectionChanged?(pdfView.currentSelection)
            }
        }

        @objc func scaleChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView else { return }

            DispatchQueue.main.async {
                // Sync scale factor back to the binding so zoom persists
                let newScale = pdfView.scaleFactor
                if abs(self.parent.scaleFactor - newScale) > 0.01 {
                    self.parent.scaleFactor = newScale
                }

                // Re-render highlights when scale changes
                self.updateHighlights(self.parent.highlights, in: pdfView)
            }
        }

        func updateHighlights(_ highlights: [Highlight], in pdfView: PDFView) {
            // Remove existing overlays
            highlightOverlays.forEach { $0.removeFromSuperview() }
            highlightOverlays.removeAll()

            // Add new overlays for highlights
            guard let document = pdfView.document,
                  let documentView = pdfView.documentView else { return }

            for highlight in highlights {
                guard highlight.pageNumber < document.pageCount,
                      let page = document.page(at: highlight.pageNumber) else { continue }

                for rect in highlight.selectionBounds {
                    // Convert PDF coordinates to view coordinates
                    let viewRect = pdfView.convert(rect, from: page)

                    // Create overlay view
                    let overlay = HighlightOverlayView(
                        frame: viewRect,
                        color: NSColor(highlight.color.color),
                        hasNote: highlight.hasNote
                    )
                    overlay.highlight = highlight
                    overlay.onTap = { [weak self] in
                        self?.parent.onHighlightTap?(highlight)
                    }

                    documentView.addSubview(overlay)
                    highlightOverlays.append(overlay)
                }
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

// MARK: - Selection Bounds Extraction

extension PDFSelection {
    /// Extract bounds for all pages in the selection (for multi-line highlights)
    func allBounds() -> [(page: PDFPage, bounds: CGRect)] {
        var result: [(page: PDFPage, bounds: CGRect)] = []

        for page in pages {
            let bounds = self.bounds(for: page)
            result.append((page: page, bounds: bounds))
        }

        return result
    }

    /// Get all selection bounds for a specific page
    func boundsForPage(_ page: PDFPage) -> [CGRect] {
        // PDFKit returns selection as a series of line selections
        // We need to get the bounds for each line
        var bounds: [CGRect] = []

        // Get the selection bounds for this page
        let pageBounds = self.bounds(for: page)
        if !pageBounds.isEmpty {
            bounds.append(pageBounds)
        }

        return bounds
    }
}

// MARK: - Themed PDF View

/// Custom PDFView subclass that supports reading themes via Core Image filters
class ThemedPDFView: PDFView {
    private var currentTheme: ReadingTheme = .day
    private var bookStyleEnabled: Bool = true
    private var spineOverlay: BookSpineOverlayView?
    private var textureOverlay: PaperTextureOverlayView?
    private var roundedCornerMask: CAShapeLayer?

    func applyTheme(_ theme: ReadingTheme) {
        guard theme != currentTheme else { return }
        currentTheme = theme

        // Apply theme using page background color and optional color inversion
        switch theme {
        case .day:
            // Default white background - remove any filters
            self.pageBreakMargins = NSEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
            self.backgroundColor = NSColor.white
            removeFilters()

        case .sepia:
            // Warm sepia tone
            self.backgroundColor = NSColor(red: 0.96, green: 0.93, blue: 0.87, alpha: 1.0)
            applySepiaFilter()

        case .night:
            // Dark mode - invert colors
            self.backgroundColor = NSColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0)
            applyNightFilter()

        case .auto:
            // Follow system appearance
            let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            if isDark {
                self.backgroundColor = NSColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0)
                applyNightFilter()
            } else {
                self.backgroundColor = NSColor.white
                removeFilters()
            }
        }

        // Update book style overlays
        spineOverlay?.updateTheme(theme)
        textureOverlay?.configure(theme: theme, displayMode: displayMode)

        // Force redraw
        needsDisplay = true
        documentView?.needsDisplay = true
    }

    func configureBookStyle(enabled: Bool, paperTexture: Bool) {
        self.bookStyleEnabled = enabled

        if enabled {
            setupBookStyleOverlays(paperTexture: paperTexture)
        } else {
            removeBookStyleOverlays()
        }
    }

    private func setupBookStyleOverlays(paperTexture: Bool) {
        wantsLayer = true

        // Add spine overlay for two-page modes
        if displayMode == .twoUp || displayMode == .twoUpContinuous {
            if spineOverlay == nil {
                let overlay = BookSpineOverlayView(frame: bounds)
                overlay.translatesAutoresizingMaskIntoConstraints = false
                overlay.updateTheme(currentTheme)
                // Add as topmost subview so it renders over the PDF content
                addSubview(overlay, positioned: .above, relativeTo: nil)

                // Pin to all edges
                NSLayoutConstraint.activate([
                    overlay.leadingAnchor.constraint(equalTo: leadingAnchor),
                    overlay.trailingAnchor.constraint(equalTo: trailingAnchor),
                    overlay.topAnchor.constraint(equalTo: topAnchor),
                    overlay.bottomAnchor.constraint(equalTo: bottomAnchor)
                ])

                spineOverlay = overlay
            } else {
                // Ensure spine overlay is always on top
                spineOverlay?.removeFromSuperview()
                addSubview(spineOverlay!, positioned: .above, relativeTo: nil)

                // Re-apply constraints
                if let overlay = spineOverlay {
                    NSLayoutConstraint.activate([
                        overlay.leadingAnchor.constraint(equalTo: leadingAnchor),
                        overlay.trailingAnchor.constraint(equalTo: trailingAnchor),
                        overlay.topAnchor.constraint(equalTo: topAnchor),
                        overlay.bottomAnchor.constraint(equalTo: bottomAnchor)
                    ])
                }
            }
        } else {
            spineOverlay?.removeFromSuperview()
            spineOverlay = nil
        }

        // Add paper texture overlay (below spine but above PDF content)
        if paperTexture && textureOverlay == nil {
            let texture = PaperTextureOverlayView(frame: bounds)
            texture.translatesAutoresizingMaskIntoConstraints = false
            texture.configure(theme: currentTheme, displayMode: displayMode)
            addSubview(texture, positioned: .below, relativeTo: spineOverlay)

            // Pin to all edges
            NSLayoutConstraint.activate([
                texture.leadingAnchor.constraint(equalTo: leadingAnchor),
                texture.trailingAnchor.constraint(equalTo: trailingAnchor),
                texture.topAnchor.constraint(equalTo: topAnchor),
                texture.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])

            textureOverlay = texture
        } else if !paperTexture {
            textureOverlay?.removeFromSuperview()
            textureOverlay = nil
        }

        // Apply rounded corners mask for two-page mode
        applyRoundedCornersMask()

        // Apply outer shadow
        applyOuterShadow()
    }

    private func removeBookStyleOverlays() {
        spineOverlay?.removeFromSuperview()
        spineOverlay = nil

        textureOverlay?.removeFromSuperview()
        textureOverlay = nil

        layer?.mask = nil
        roundedCornerMask = nil

        layer?.shadowOpacity = 0
    }

    private func applyRoundedCornersMask() {
        guard bookStyleEnabled else { return }

        let cornerRadius: CGFloat = 8
        let isTwoPage = displayMode == .twoUp || displayMode == .twoUpContinuous

        if isTwoPage {
            // Create custom mask with only outer corners rounded
            let mask = CAShapeLayer()
            mask.path = createBookSpreadPath(bounds: bounds, cornerRadius: cornerRadius)
            layer?.mask = mask
            roundedCornerMask = mask
        } else {
            // Single page: round all corners
            layer?.cornerRadius = 6
            layer?.masksToBounds = true
            layer?.mask = nil
            roundedCornerMask = nil
        }
    }

    private func createBookSpreadPath(bounds: NSRect, cornerRadius: CGFloat) -> CGPath {
        let path = CGMutablePath()

        let halfWidth = bounds.width / 2

        // Start at top-left rounded corner
        path.move(to: CGPoint(x: cornerRadius, y: bounds.height))

        // Top-left corner (rounded)
        path.addArc(
            center: CGPoint(x: cornerRadius, y: bounds.height - cornerRadius),
            radius: cornerRadius,
            startAngle: .pi / 2,
            endAngle: .pi,
            clockwise: false
        )

        // Left edge down to bottom-left corner
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))

        // Bottom-left corner (rounded)
        path.addArc(
            center: CGPoint(x: cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: .pi,
            endAngle: .pi * 1.5,
            clockwise: false
        )

        // Bottom edge to center (straight - no rounding at spine)
        path.addLine(to: CGPoint(x: halfWidth, y: 0))

        // Bottom edge from center to right (straight at spine)
        path.addLine(to: CGPoint(x: bounds.width - cornerRadius, y: 0))

        // Bottom-right corner (rounded)
        path.addArc(
            center: CGPoint(x: bounds.width - cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: .pi * 1.5,
            endAngle: 0,
            clockwise: false
        )

        // Right edge up to top-right corner
        path.addLine(to: CGPoint(x: bounds.width, y: bounds.height - cornerRadius))

        // Top-right corner (rounded)
        path.addArc(
            center: CGPoint(x: bounds.width - cornerRadius, y: bounds.height - cornerRadius),
            radius: cornerRadius,
            startAngle: 0,
            endAngle: .pi / 2,
            clockwise: false
        )

        // Top edge back to center (straight at spine)
        path.addLine(to: CGPoint(x: halfWidth, y: bounds.height))

        // Top edge from center to start
        path.addLine(to: CGPoint(x: cornerRadius, y: bounds.height))

        path.closeSubpath()

        return path
    }

    private func applyOuterShadow() {
        guard bookStyleEnabled, let layer = self.layer else { return }

        layer.masksToBounds = false
        layer.shadowColor = NSColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowOffset = CGSize(width: 0, height: -4)
        layer.shadowRadius = 12

        // Create shadow path for performance
        if displayMode == .twoUp || displayMode == .twoUpContinuous {
            layer.shadowPath = createBookSpreadPath(bounds: bounds, cornerRadius: 8)
        } else {
            layer.shadowPath = CGPath(
                roundedRect: bounds,
                cornerWidth: 6,
                cornerHeight: 6,
                transform: nil
            )
        }
    }

    override func layout() {
        super.layout()

        // Update rounded corners mask on layout
        if bookStyleEnabled {
            if let mask = roundedCornerMask {
                mask.path = createBookSpreadPath(bounds: bounds, cornerRadius: 8)
            }
            applyOuterShadow()
        }
    }

    private func removeFilters() {
        self.layer?.filters = nil
        self.documentView?.layer?.filters = nil
    }

    private func applySepiaFilter() {
        guard let documentView = self.documentView else { return }

        documentView.wantsLayer = true

        // Create sepia tone filter
        if let sepiaFilter = CIFilter(name: "CISepiaTone") {
            sepiaFilter.setValue(0.3, forKey: kCIInputIntensityKey)
            documentView.layer?.filters = [sepiaFilter]
        }
    }

    private func applyNightFilter() {
        guard let documentView = self.documentView else { return }

        documentView.wantsLayer = true

        // Create color invert filter for night mode
        if let invertFilter = CIFilter(name: "CIColorInvert") {
            documentView.layer?.filters = [invertFilter]
        }
    }
}
