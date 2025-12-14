// BookSpineOverlay.swift
// NoorReader
//
// Center spine shadow overlay for two-page book mode

import SwiftUI

/// Overlay that creates a realistic book spine shadow effect in two-page mode
struct BookSpineOverlay: View {
    let theme: ReadingTheme

    /// Total width of the spine shadow effect (20-30px each side)
    private let spineWidth: CGFloat = 50

    /// Maximum shadow opacity at the center
    private let maxOpacity: Double = 0.12

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left half - shadow fades from center to left
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: spineShadowColor.opacity(maxOpacity * 0.3), location: 0.4),
                        .init(color: spineShadowColor.opacity(maxOpacity * 0.7), location: 0.7),
                        .init(color: spineShadowColor.opacity(maxOpacity), location: 1.0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: spineWidth / 2)

                // Center highlight line - subtle paper edge catching light
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                spineHighlightColor.opacity(0.08),
                                spineHighlightColor.opacity(0.15),
                                spineHighlightColor.opacity(0.08)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 1)

                // Right half - shadow fades from center to right
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: spineShadowColor.opacity(maxOpacity), location: 0),
                        .init(color: spineShadowColor.opacity(maxOpacity * 0.7), location: 0.3),
                        .init(color: spineShadowColor.opacity(maxOpacity * 0.3), location: 0.6),
                        .init(color: .clear, location: 1.0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: spineWidth / 2)
            }
            .frame(maxHeight: .infinity)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .allowsHitTesting(false)
    }

    private var spineShadowColor: Color {
        switch theme {
        case .day, .sepia:
            return .black
        case .night:
            return .black
        case .auto:
            return .black
        }
    }

    private var spineHighlightColor: Color {
        switch theme {
        case .day:
            return .white
        case .sepia:
            return Color(red: 1.0, green: 0.98, blue: 0.94)
        case .night:
            return Color(white: 0.3)
        case .auto:
            return .white
        }
    }
}

/// NSView version of the spine overlay for use with PDFView
/// This overlay is designed to sit on top of PDFView and pass through all mouse events
class BookSpineOverlayView: NSView {
    private var theme: ReadingTheme = .day
    private let spineWidth: CGFloat = 50
    private let maxOpacity: CGFloat = 0.12

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        wantsLayer = true
        // Critical: Allow mouse events to pass through to PDFView underneath
        layer?.isOpaque = false
        setupLayers()
    }

    // Pass all mouse events through to views underneath
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }

    override var acceptsFirstResponder: Bool { false }

    func updateTheme(_ theme: ReadingTheme) {
        self.theme = theme
        updateColors()
    }

    private func setupLayers() {
        guard let layer = self.layer else { return }

        // Left shadow gradient
        let leftShadow = CAGradientLayer()
        leftShadow.name = "leftShadow"
        leftShadow.startPoint = CGPoint(x: 0, y: 0.5)
        leftShadow.endPoint = CGPoint(x: 1, y: 0.5)
        layer.addSublayer(leftShadow)

        // Center highlight
        let centerLine = CALayer()
        centerLine.name = "centerLine"
        layer.addSublayer(centerLine)

        // Right shadow gradient
        let rightShadow = CAGradientLayer()
        rightShadow.name = "rightShadow"
        rightShadow.startPoint = CGPoint(x: 0, y: 0.5)
        rightShadow.endPoint = CGPoint(x: 1, y: 0.5)
        layer.addSublayer(rightShadow)

        updateColors()
    }

    private func updateColors() {
        guard let layer = self.layer else { return }

        let shadowColor = NSColor.black
        let highlightColor: NSColor = {
            switch theme {
            case .day:
                return .white
            case .sepia:
                return NSColor(red: 1.0, green: 0.98, blue: 0.94, alpha: 1.0)
            case .night:
                return NSColor(white: 0.3, alpha: 1.0)
            case .auto:
                return .white
            }
        }()

        // Update left shadow colors
        if let leftShadow = layer.sublayers?.first(where: { $0.name == "leftShadow" }) as? CAGradientLayer {
            leftShadow.colors = [
                NSColor.clear.cgColor,
                shadowColor.withAlphaComponent(maxOpacity * 0.3).cgColor,
                shadowColor.withAlphaComponent(maxOpacity * 0.7).cgColor,
                shadowColor.withAlphaComponent(maxOpacity).cgColor
            ]
            leftShadow.locations = [0, 0.4, 0.7, 1.0]
        }

        // Update center highlight
        if let centerLine = layer.sublayers?.first(where: { $0.name == "centerLine" }) {
            centerLine.backgroundColor = highlightColor.withAlphaComponent(0.15).cgColor
        }

        // Update right shadow colors
        if let rightShadow = layer.sublayers?.first(where: { $0.name == "rightShadow" }) as? CAGradientLayer {
            rightShadow.colors = [
                shadowColor.withAlphaComponent(maxOpacity).cgColor,
                shadowColor.withAlphaComponent(maxOpacity * 0.7).cgColor,
                shadowColor.withAlphaComponent(maxOpacity * 0.3).cgColor,
                NSColor.clear.cgColor
            ]
            rightShadow.locations = [0, 0.3, 0.6, 1.0]
        }
    }

    override func layout() {
        super.layout()
        updateSpinePosition()
    }

    func updateSpinePosition() {
        guard let layer = self.layer else { return }

        let centerX = bounds.width / 2
        let halfSpine = spineWidth / 2

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // Position left shadow
        if let leftShadow = layer.sublayers?.first(where: { $0.name == "leftShadow" }) {
            leftShadow.frame = CGRect(
                x: centerX - halfSpine,
                y: 0,
                width: halfSpine,
                height: bounds.height
            )
        }

        // Position center line
        if let centerLine = layer.sublayers?.first(where: { $0.name == "centerLine" }) {
            centerLine.frame = CGRect(
                x: centerX - 0.5,
                y: 0,
                width: 1,
                height: bounds.height
            )
        }

        // Position right shadow
        if let rightShadow = layer.sublayers?.first(where: { $0.name == "rightShadow" }) {
            rightShadow.frame = CGRect(
                x: centerX + 0.5,
                y: 0,
                width: halfSpine,
                height: bounds.height
            )
        }

        CATransaction.commit()
    }
}

#Preview {
    VStack {
        ZStack {
            HStack(spacing: 0) {
                Color(red: 0.96, green: 0.93, blue: 0.87)
                Color(red: 0.96, green: 0.93, blue: 0.87)
            }
            BookSpineOverlay(theme: .sepia)
        }
        .frame(height: 300)

        ZStack {
            HStack(spacing: 0) {
                Color.white
                Color.white
            }
            BookSpineOverlay(theme: .day)
        }
        .frame(height: 300)
    }
    .frame(width: 600)
}
