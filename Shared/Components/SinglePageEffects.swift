// SinglePageEffects.swift
// NoorReader
//
// Visual enhancements for single-page PDF viewing mode

import SwiftUI
import AppKit

// MARK: - Single Page Container

/// A view that wraps PDF content with single-page visual effects
struct SinglePageEffectContainer: View {
    let theme: ReadingTheme
    let showCornerCurl: Bool
    let showShadow: Bool
    let showTexture: Bool

    init(
        theme: ReadingTheme,
        showCornerCurl: Bool = true,
        showShadow: Bool = true,
        showTexture: Bool = true
    ) {
        self.theme = theme
        self.showCornerCurl = showCornerCurl
        self.showShadow = showShadow
        self.showTexture = showTexture
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with subtle gradient
                pageBackground
                    .cornerRadius(6)

                // Paper texture overlay
                if showTexture {
                    SinglePageTextureLayer(theme: theme)
                        .cornerRadius(6)
                }

                // Floating page shadow
                if showShadow {
                    SinglePageShadowLayer(size: geometry.size)
                }

                // Decorative corner curl
                if showCornerCurl {
                    DecorativeCornerCurl(theme: theme)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private var pageBackground: some View {
        Group {
            switch theme {
            case .day:
                Color.white
            case .sepia:
                Color(red: 0.96, green: 0.93, blue: 0.87)
            case .night:
                Color(red: 0.12, green: 0.12, blue: 0.14)
            case .auto:
                Color.white
            }
        }
    }
}

// MARK: - Single Page Texture Layer

struct SinglePageTextureLayer: View {
    let theme: ReadingTheme

    private let noiseIntensity: Double = 0.035

    var body: some View {
        Canvas { context, size in
            guard shouldApplyTexture else { return }

            // Create subtle noise pattern
            let dotSize: CGFloat = 0.8
            let spacing: CGFloat = 2.5

            for x in stride(from: CGFloat(0), to: size.width, by: spacing) {
                for y in stride(from: CGFloat(0), to: size.height, by: spacing) {
                    // Deterministic pseudo-random based on position
                    let seed = Int(x * 17 + y * 31) % 997
                    let random = Double(seed) / 997.0

                    if random < 0.12 {
                        let opacity = random * noiseIntensity * 2.5
                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: dotSize, height: dotSize)),
                            with: .color(textureColor.opacity(opacity))
                        )
                    }
                }
            }
        }
    }

    private var shouldApplyTexture: Bool {
        theme == .day || theme == .sepia
    }

    private var textureColor: Color {
        switch theme {
        case .day:
            return Color(white: 0.25)
        case .sepia:
            return Color(red: 0.35, green: 0.30, blue: 0.25)
        default:
            return Color(white: 0.25)
        }
    }
}

// MARK: - Single Page Shadow Layer

struct SinglePageShadowLayer: View {
    let size: CGSize

    private let shadowRadius: CGFloat = 12
    private let shadowOpacity: Double = 0.12

    var body: some View {
        ZStack {
            // All-around soft shadow (simulates floating page)
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.clear)
                .shadow(
                    color: .black.opacity(shadowOpacity),
                    radius: shadowRadius,
                    x: 0,
                    y: 3
                )
                .padding(6)

            // Stronger shadow at bottom (gravity effect)
            VStack {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .black.opacity(shadowOpacity * 0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 30)
                    .blur(radius: 15)
                    .offset(y: 10)
            }
        }
    }
}

// MARK: - Decorative Corner Curl

struct DecorativeCornerCurl: View {
    let theme: ReadingTheme

    @State private var isHovered = false

    private let curlSize: CGFloat = 22

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ZStack {
                    // Shadow under the curl
                    CornerCurlShape()
                        .fill(Color.black.opacity(0.12))
                        .frame(width: curlSize + 3, height: curlSize + 3)
                        .blur(radius: 2)
                        .offset(x: 1, y: 1)

                    // The curl itself with paper gradient
                    CornerCurlShape()
                        .fill(
                            LinearGradient(
                                colors: curlGradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: curlSize, height: curlSize)

                    // Subtle edge highlight
                    CornerCurlShape()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    pageHighlightColor.opacity(0.6),
                                    pageHighlightColor.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                        .frame(width: curlSize, height: curlSize)
                }
                .scaleEffect(isHovered ? 1.15 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
                .onHover { hovering in
                    isHovered = hovering
                }
            }
        }
        .padding(8)
    }

    private var curlGradientColors: [Color] {
        switch theme {
        case .day:
            return [Color(white: 0.97), Color(white: 0.88)]
        case .sepia:
            return [
                Color(red: 0.98, green: 0.95, blue: 0.90),
                Color(red: 0.90, green: 0.85, blue: 0.78)
            ]
        case .night:
            return [Color(white: 0.22), Color(white: 0.16)]
        case .auto:
            return [Color(white: 0.97), Color(white: 0.88)]
        }
    }

    private var pageHighlightColor: Color {
        switch theme {
        case .day, .auto:
            return .white
        case .sepia:
            return Color(red: 1.0, green: 0.98, blue: 0.95)
        case .night:
            return Color(white: 0.35)
        }
    }
}

// MARK: - Corner Curl Shape

struct CornerCurlShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Create a triangular curl with slightly curved edge
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))

        // Slight curve on the bottom edge for realism
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY),
            control: CGPoint(x: rect.midX + rect.width * 0.1, y: rect.maxY - rect.height * 0.05)
        )

        path.closeSubpath()

        return path
    }
}

// MARK: - Smooth Scroll Physics Modifier

struct SmoothScrollModifier: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content
                .scrollContentBackground(.hidden)
        } else {
            content
        }
    }
}

extension View {
    func smoothScrollPhysics(_ enabled: Bool = true) -> some View {
        modifier(SmoothScrollModifier(enabled: enabled))
    }
}

// MARK: - NSView Implementation for PDFView Integration

class SinglePageEffectsView: NSView {
    private var theme: ReadingTheme = .day
    private var showCornerCurl: Bool = true
    private var showTexture: Bool = true

    private var curlLayer: CAShapeLayer?
    private var curlShadowLayer: CALayer?
    private var textureLayer: CALayer?
    private var trackingArea: NSTrackingArea?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        setupLayers()
    }

    func configure(theme: ReadingTheme, showCornerCurl: Bool = true, showTexture: Bool = true) {
        self.theme = theme
        self.showCornerCurl = showCornerCurl
        self.showTexture = showTexture
        updateAppearance()
    }

    private func setupLayers() {
        guard let layer = self.layer else { return }

        // Shadow layer for floating effect
        layer.shadowColor = NSColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowOffset = CGSize(width: 0, height: -3)
        layer.shadowRadius = 12
        layer.cornerRadius = 6

        // Create corner curl layers
        let curlSize: CGFloat = 22
        let curlFrame = CGRect(
            x: bounds.width - curlSize - 8,
            y: 8,
            width: curlSize,
            height: curlSize
        )

        // Curl shadow
        let shadow = CALayer()
        shadow.frame = curlFrame.offsetBy(dx: 1, dy: -1)
        shadow.backgroundColor = NSColor.black.withAlphaComponent(0.12).cgColor
        shadow.cornerRadius = 2
        layer.addSublayer(shadow)
        curlShadowLayer = shadow

        // Curl shape
        let curl = CAShapeLayer()
        curl.frame = curlFrame
        let curlPath = createCurlPath(size: curlSize)
        curl.path = curlPath
        curl.fillColor = NSColor(white: 0.95, alpha: 1.0).cgColor
        layer.addSublayer(curl)
        curlLayer = curl

        updateAppearance()
    }

    private func createCurlPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: size, y: size))
        path.addLine(to: CGPoint(x: size, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: 0),
            control: CGPoint(x: size * 0.6, y: size * 0.05)
        )
        path.closeSubpath()
        return path
    }

    private func updateAppearance() {
        // Update curl visibility
        curlLayer?.isHidden = !showCornerCurl
        curlShadowLayer?.isHidden = !showCornerCurl

        // Update colors based on theme
        let curlColors: (start: NSColor, end: NSColor) = {
            switch theme {
            case .day, .auto:
                return (NSColor(white: 0.97, alpha: 1), NSColor(white: 0.88, alpha: 1))
            case .sepia:
                return (
                    NSColor(red: 0.98, green: 0.95, blue: 0.90, alpha: 1),
                    NSColor(red: 0.90, green: 0.85, blue: 0.78, alpha: 1)
                )
            case .night:
                return (NSColor(white: 0.22, alpha: 1), NSColor(white: 0.16, alpha: 1))
            }
        }()

        curlLayer?.fillColor = curlColors.start.cgColor

        needsDisplay = true
    }

    override func layout() {
        super.layout()

        let curlSize: CGFloat = 22
        let curlFrame = CGRect(
            x: bounds.width - curlSize - 8,
            y: 8,
            width: curlSize,
            height: curlSize
        )

        curlLayer?.frame = curlFrame
        curlLayer?.path = createCurlPath(size: curlSize)
        curlShadowLayer?.frame = curlFrame.offsetBy(dx: 1, dy: -1)

        layer?.shadowPath = CGPath(roundedRect: bounds, cornerWidth: 6, cornerHeight: 6, transform: nil)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let existing = trackingArea {
            removeTrackingArea(existing)
        }

        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeInKeyWindow]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        if let trackingArea = trackingArea {
            addTrackingArea(trackingArea)
        }
    }

    override func mouseEntered(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            curlLayer?.transform = CATransform3DMakeScale(1.15, 1.15, 1)
        }
    }

    override func mouseExited(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            curlLayer?.transform = CATransform3DIdentity
        }
    }
}

// MARK: - Preview

#Preview("Single Page Effects") {
    VStack(spacing: 20) {
        ZStack {
            Color(white: 0.9)
            SinglePageEffectContainer(theme: .day)
                .frame(width: 300, height: 400)
                .background(Color.white)
                .cornerRadius(6)
        }
        .frame(height: 450)

        ZStack {
            Color(white: 0.85)
            SinglePageEffectContainer(theme: .sepia)
                .frame(width: 300, height: 400)
                .background(Color(red: 0.96, green: 0.93, blue: 0.87))
                .cornerRadius(6)
        }
        .frame(height: 450)
    }
    .padding()
}
