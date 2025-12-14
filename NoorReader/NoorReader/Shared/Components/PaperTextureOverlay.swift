// PaperTextureOverlay.swift
// NoorReader
//
// Subtle paper texture and page styling for book-like appearance

import SwiftUI
import AppKit
import PDFKit

/// Overlay that adds paper texture and rounded corners to pages
struct PaperTextureOverlay: View {
    let theme: ReadingTheme
    let displayMode: PDFDisplayMode
    let intensity: Double

    init(theme: ReadingTheme, displayMode: PDFDisplayMode, intensity: Double = 0.04) {
        self.theme = theme
        self.displayMode = displayMode
        self.intensity = intensity
    }

    var body: some View {
        GeometryReader { geometry in
            if isTwoPageMode {
                // Two-page mode: rounded outer corners only
                TwoPageTextureView(
                    theme: theme,
                    intensity: intensity,
                    size: geometry.size
                )
            } else {
                // Single-page mode: floating page with shadow
                SinglePageTextureView(
                    theme: theme,
                    intensity: intensity,
                    size: geometry.size
                )
            }
        }
        .allowsHitTesting(false)
    }

    private var isTwoPageMode: Bool {
        displayMode == .twoUp || displayMode == .twoUpContinuous
    }
}

// MARK: - Two Page Texture View

struct TwoPageTextureView: View {
    let theme: ReadingTheme
    let intensity: Double
    let size: CGSize

    private let cornerRadius: CGFloat = 8

    var body: some View {
        ZStack {
            // Paper texture noise overlay
            NoiseTextureView(intensity: intensity, theme: theme)

            // Outer shadow for the entire book spread
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.clear, lineWidth: 0)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
                .padding(2)

            // Mask for rounded outer corners only
            BookSpreadMask(cornerRadius: cornerRadius)
                .stroke(lineWidth: 0)
        }
    }
}

// MARK: - Single Page Texture View

struct SinglePageTextureView: View {
    let theme: ReadingTheme
    let intensity: Double
    let size: CGSize

    private let cornerRadius: CGFloat = 6
    private let shadowRadius: CGFloat = 10
    private let shadowOpacity: Double = 0.10

    var body: some View {
        ZStack {
            // Paper texture noise overlay
            NoiseTextureView(intensity: intensity, theme: theme)

            // Floating page shadow effect (stronger at bottom for gravity)
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color.clear)
                    .shadow(color: .black.opacity(shadowOpacity * 1.2), radius: shadowRadius + 2, x: 0, y: 4)
                    .frame(height: 20)
            }

            // All-around soft shadow
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.clear, lineWidth: 0)
                .shadow(color: .black.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: 2)
                .padding(4)
        }
    }
}

// MARK: - Noise Texture View

struct NoiseTextureView: View {
    let intensity: Double
    let theme: ReadingTheme

    var body: some View {
        Canvas { context, size in
            // Only apply texture for day and sepia modes
            guard shouldApplyTexture else { return }

            // Create noise pattern using random dots
            let dotSize: CGFloat = 1
            let spacing: CGFloat = 2

            for x in stride(from: CGFloat(0), to: size.width, by: spacing) {
                for y in stride(from: CGFloat(0), to: size.height, by: spacing) {
                    // Pseudo-random based on position for consistent texture
                    let hash = (Int(x) * 73856093) ^ (Int(y) * 19349663)
                    let random = Double(abs(hash) % 1000) / 1000.0

                    if random < 0.15 { // Only draw some dots for subtle effect
                        let opacity = random * intensity * 2
                        let dotColor = textureColor.opacity(opacity)

                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: dotSize, height: dotSize)),
                            with: .color(dotColor)
                        )
                    }
                }
            }
        }
    }

    private var shouldApplyTexture: Bool {
        switch theme {
        case .day, .sepia:
            return true
        case .night:
            return false
        case .auto:
            return true
        }
    }

    private var textureColor: Color {
        switch theme {
        case .day:
            return Color(white: 0.3)
        case .sepia:
            return Color(red: 0.4, green: 0.35, blue: 0.3)
        case .night:
            return Color(white: 0.6)
        case .auto:
            return Color(white: 0.3)
        }
    }
}

// MARK: - Book Spread Mask Shape

struct BookSpreadMask: Shape {
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let halfWidth = rect.width / 2

        // Left page - rounded on outer corners only
        path.move(to: CGPoint(x: cornerRadius, y: 0))
        path.addLine(to: CGPoint(x: halfWidth, y: 0))
        path.addLine(to: CGPoint(x: halfWidth, y: rect.height))
        path.addLine(to: CGPoint(x: cornerRadius, y: rect.height))
        path.addArc(
            center: CGPoint(x: cornerRadius, y: rect.height - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        path.addArc(
            center: CGPoint(x: cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )

        // Right page - rounded on outer corners only
        path.move(to: CGPoint(x: halfWidth, y: 0))
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))
        path.addArc(
            center: CGPoint(x: rect.width - cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(270),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius))
        path.addArc(
            center: CGPoint(x: rect.width - cornerRadius, y: rect.height - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: halfWidth, y: rect.height))
        path.closeSubpath()

        return path
    }
}

// MARK: - Corner Curl View (Decorative for single page mode)

struct CornerCurlView: View {
    let size: CGFloat
    @State private var isHovered = false

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ZStack {
                    // Curl shadow
                    Triangle()
                        .fill(Color.black.opacity(0.08))
                        .frame(width: size + 2, height: size + 2)
                        .offset(x: 1, y: 1)

                    // Paper curl gradient
                    Triangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(white: 0.95),
                                    Color(white: 0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size, height: size)

                    // Curl highlight
                    Triangle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
                        .frame(width: size, height: size)
                }
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
                .onHover { hovering in
                    isHovered = hovering
                }
            }
        }
        .padding(4)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - NSView Version for PDFView Integration

class PaperTextureOverlayView: NSView {
    private var theme: ReadingTheme = .day
    private var displayMode: PDFDisplayMode = .singlePageContinuous
    private let intensity: CGFloat = 0.04

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = false
        layer?.isOpaque = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.masksToBounds = false
        layer?.isOpaque = false
    }

    // Pass all mouse events through to views underneath
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }

    override var acceptsFirstResponder: Bool { false }

    func configure(theme: ReadingTheme, displayMode: PDFDisplayMode) {
        self.theme = theme
        self.displayMode = displayMode
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Only draw texture for day and sepia modes
        guard theme == .day || theme == .sepia else { return }

        // Draw noise texture
        let dotSize: CGFloat = 1
        let spacing: CGFloat = 3

        let textureColor: NSColor = {
            switch theme {
            case .day:
                return NSColor(white: 0.3, alpha: 1.0)
            case .sepia:
                return NSColor(red: 0.4, green: 0.35, blue: 0.3, alpha: 1.0)
            default:
                return NSColor(white: 0.3, alpha: 1.0)
            }
        }()

        for x in stride(from: CGFloat(0), to: bounds.width, by: spacing) {
            for y in stride(from: CGFloat(0), to: bounds.height, by: spacing) {
                let hash = (Int(x) * 73856093) ^ (Int(y) * 19349663)
                let random = Double(abs(hash) % 1000) / 1000.0

                if random < 0.15 {
                    let opacity = random * Double(intensity) * 2
                    textureColor.withAlphaComponent(opacity).setFill()
                    let dotRect = NSRect(x: x, y: y, width: dotSize, height: dotSize)
                    NSBezierPath(ovalIn: dotRect).fill()
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Two Page Mode") {
    ZStack {
        HStack(spacing: 0) {
            Color(red: 0.96, green: 0.93, blue: 0.87)
            Color(red: 0.96, green: 0.93, blue: 0.87)
        }
        PaperTextureOverlay(theme: .sepia, displayMode: .twoUp)
        BookSpineOverlay(theme: .sepia)
    }
    .frame(width: 600, height: 400)
}

#Preview("Single Page Mode") {
    ZStack {
        Color(white: 0.9)
        VStack {
            ZStack {
                Color.white
                    .cornerRadius(6)
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
                PaperTextureOverlay(theme: .day, displayMode: .singlePage)
                CornerCurlView(size: 20)
            }
            .frame(width: 400, height: 500)
            .padding()
        }
    }
}
