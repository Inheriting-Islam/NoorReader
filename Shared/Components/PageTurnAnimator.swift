// PageTurnAnimator.swift
// NoorReader
//
// Realistic page turn animations for book-style viewing

import SwiftUI
import AppKit
import QuartzCore

// MARK: - Page Turn Direction

enum PageTurnDirection {
    case forward  // Right page flips left
    case backward // Left page flips right
}

// MARK: - Page Turn State

enum PageTurnState: Equatable {
    case idle
    case animating(direction: PageTurnDirection, progress: Double)
    case completed
}

// MARK: - Page Turn Animation View (SwiftUI)

struct PageTurnAnimationView: View {
    let direction: PageTurnDirection
    let pageImage: NSImage?
    let theme: ReadingTheme
    @Binding var isAnimating: Bool
    let onComplete: () -> Void

    @State private var progress: Double = 0
    @State private var hasCompleted = false

    private let duration: Double = 0.45

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // The page being turned
                if let image = pageImage {
                    PageTurnLayer(
                        image: image,
                        progress: progress,
                        direction: direction,
                        size: geometry.size,
                        theme: theme
                    )
                }
            }
        }
        .onChange(of: isAnimating) { _, newValue in
            if newValue && !hasCompleted {
                startAnimation()
            }
        }
        .onAppear {
            if isAnimating && !hasCompleted {
                startAnimation()
            }
        }
    }

    private func startAnimation() {
        progress = 0
        hasCompleted = false

        withAnimation(.easeInOut(duration: duration)) {
            progress = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            hasCompleted = true
            isAnimating = false
            onComplete()
        }
    }
}

// MARK: - Page Turn Layer

struct PageTurnLayer: View {
    let image: NSImage
    let progress: Double
    let direction: PageTurnDirection
    let size: CGSize
    let theme: ReadingTheme

    private var rotationAngle: Double {
        // Rotate from 0 to 180 degrees (or -180 for backward)
        let baseAngle = progress * 180
        return direction == .forward ? -baseAngle : baseAngle
    }

    private var perspectiveAmount: Double {
        // Add slight perspective curve during the flip
        let midProgress = 1.0 - abs(progress - 0.5) * 2
        return midProgress * 0.3
    }

    private var shadowOpacity: Double {
        // Shadow is strongest in the middle of the animation
        let midProgress = 1.0 - abs(progress - 0.5) * 2
        return midProgress * 0.4
    }

    var body: some View {
        ZStack {
            // Shadow under the turning page
            Rectangle()
                .fill(Color.black.opacity(shadowOpacity * 0.5))
                .blur(radius: 20)
                .offset(x: direction == .forward ? -20 : 20, y: 10)

            // The page itself with 3D rotation
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size.width / 2)
                .rotation3DEffect(
                    .degrees(rotationAngle),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: direction == .forward ? .leading : .trailing,
                    anchorZ: 0,
                    perspective: 0.5
                )
                .shadow(color: .black.opacity(shadowOpacity), radius: 15, x: 0, y: 5)
                .position(
                    x: direction == .forward ? size.width * 0.75 : size.width * 0.25,
                    y: size.height / 2
                )
        }
    }
}

// MARK: - Page Turn Animator Class (for NSView integration)

class PageTurnAnimator {
    private weak var containerView: NSView?
    private var animationLayer: CALayer?
    private var isAnimating = false

    var animationDuration: CFTimeInterval = 0.45
    var onAnimationComplete: (() -> Void)?

    init(containerView: NSView) {
        self.containerView = containerView
    }

    func animatePageTurn(
        direction: PageTurnDirection,
        pageSnapshot: CGImage,
        theme: ReadingTheme
    ) {
        guard !isAnimating, let containerView = containerView else { return }

        isAnimating = true

        // Create the animation layer
        let pageLayer = CALayer()
        pageLayer.contents = pageSnapshot
        pageLayer.contentsGravity = .resizeAspect

        let containerBounds = containerView.bounds
        let pageWidth = containerBounds.width / 2
        let pageHeight = containerBounds.height

        // Position based on direction
        if direction == .forward {
            // Right page flips left
            pageLayer.frame = CGRect(
                x: containerBounds.width / 2,
                y: 0,
                width: pageWidth,
                height: pageHeight
            )
            pageLayer.anchorPoint = CGPoint(x: 0, y: 0.5) // Anchor on left edge
        } else {
            // Left page flips right
            pageLayer.frame = CGRect(
                x: 0,
                y: 0,
                width: pageWidth,
                height: pageHeight
            )
            pageLayer.anchorPoint = CGPoint(x: 1, y: 0.5) // Anchor on right edge
        }

        // Add perspective transform to container
        var perspective = CATransform3DIdentity
        perspective.m34 = -1.0 / 1000.0 // Perspective depth

        pageLayer.transform = perspective

        containerView.layer?.addSublayer(pageLayer)
        self.animationLayer = pageLayer

        // Create shadow layer
        let shadowLayer = CALayer()
        shadowLayer.backgroundColor = NSColor.black.cgColor
        shadowLayer.opacity = 0
        shadowLayer.frame = pageLayer.frame
        containerView.layer?.insertSublayer(shadowLayer, below: pageLayer)

        // Animate the page flip
        CATransaction.begin()
        CATransaction.setAnimationDuration(animationDuration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        CATransaction.setCompletionBlock { [weak self] in
            pageLayer.removeFromSuperlayer()
            shadowLayer.removeFromSuperlayer()
            self?.animationLayer = nil
            self?.isAnimating = false
            self?.onAnimationComplete?()
        }

        // Rotation animation
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.y")
        rotationAnimation.fromValue = 0
        rotationAnimation.toValue = direction == .forward ? -Double.pi : Double.pi
        pageLayer.add(rotationAnimation, forKey: "rotation")

        // Apply final transform
        let finalRotation = direction == .forward ? -Double.pi : Double.pi
        pageLayer.transform = CATransform3DRotate(perspective, finalRotation, 0, 1, 0)

        // Shadow animation (fade in then out)
        let shadowAnimation = CAKeyframeAnimation(keyPath: "opacity")
        shadowAnimation.values = [0, 0.3, 0]
        shadowAnimation.keyTimes = [0, 0.5, 1.0]
        shadowLayer.add(shadowAnimation, forKey: "shadow")

        CATransaction.commit()
    }

    func cancelAnimation() {
        animationLayer?.removeAllAnimations()
        animationLayer?.removeFromSuperlayer()
        animationLayer = nil
        isAnimating = false
    }
}

// MARK: - Page Snapshot Helper

extension NSView {
    func takeSnapshot() -> CGImage? {
        guard let bitmapRep = bitmapImageRepForCachingDisplay(in: bounds) else {
            return nil
        }
        cacheDisplay(in: bounds, to: bitmapRep)
        return bitmapRep.cgImage
    }
}

// MARK: - SwiftUI Page Turn Modifier

struct PageTurnModifier: ViewModifier {
    @Binding var pageTurnState: PageTurnState
    let theme: ReadingTheme
    let onTurnComplete: () -> Void

    func body(content: Content) -> some View {
        content
            .overlay {
                if case .animating(let direction, _) = pageTurnState {
                    // Capture and animate
                    PageTurnOverlay(
                        direction: direction,
                        theme: theme,
                        onComplete: {
                            pageTurnState = .idle
                            onTurnComplete()
                        }
                    )
                }
            }
    }
}

struct PageTurnOverlay: View {
    let direction: PageTurnDirection
    let theme: ReadingTheme
    let onComplete: () -> Void

    @State private var progress: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated page curl effect using gradient
                PageCurlEffect(
                    direction: direction,
                    progress: progress,
                    size: geometry.size,
                    theme: theme
                )
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.45)) {
                progress = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                onComplete()
            }
        }
    }
}

struct PageCurlEffect: View {
    let direction: PageTurnDirection
    let progress: Double
    let size: CGSize
    let theme: ReadingTheme

    private var curlOffset: CGFloat {
        let maxOffset = size.width / 2
        return CGFloat(progress) * maxOffset * (direction == .forward ? -1 : 1)
    }

    private var curlRotation: Double {
        progress * 90 * (direction == .forward ? -1 : 1)
    }

    var body: some View {
        ZStack {
            // Shadow layer
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .black.opacity(0.3 * (1 - abs(progress - 0.5) * 2)),
                            .clear
                        ],
                        startPoint: direction == .forward ? .trailing : .leading,
                        endPoint: direction == .forward ? .leading : .trailing
                    )
                )
                .frame(width: 60)
                .position(
                    x: size.width / 2 + curlOffset,
                    y: size.height / 2
                )

            // Curl highlight
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            pageColor.opacity(0.9),
                            pageColor.opacity(0.6),
                            .clear
                        ],
                        startPoint: direction == .forward ? .leading : .trailing,
                        endPoint: direction == .forward ? .trailing : .leading
                    )
                )
                .frame(width: 30)
                .position(
                    x: size.width / 2 + curlOffset + (direction == .forward ? 15 : -15),
                    y: size.height / 2
                )
        }
        .mask(
            Rectangle()
                .frame(width: size.width, height: size.height)
        )
    }

    private var pageColor: Color {
        switch theme {
        case .day:
            return .white
        case .sepia:
            return Color(red: 0.96, green: 0.93, blue: 0.87)
        case .night:
            return Color(red: 0.15, green: 0.15, blue: 0.17)
        case .auto:
            return .white
        }
    }
}

// MARK: - View Extension

extension View {
    func pageTurnAnimation(
        state: Binding<PageTurnState>,
        theme: ReadingTheme,
        onComplete: @escaping () -> Void
    ) -> some View {
        modifier(PageTurnModifier(
            pageTurnState: state,
            theme: theme,
            onTurnComplete: onComplete
        ))
    }
}

// MARK: - Preview

#Preview {
    struct PreviewContainer: View {
        @State private var isAnimating = false
        @State private var direction: PageTurnDirection = .forward

        var body: some View {
            ZStack {
                // Simulated two-page spread
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(red: 0.96, green: 0.93, blue: 0.87))
                        .overlay {
                            Text("Left Page")
                                .font(.title)
                        }

                    Rectangle()
                        .fill(Color(red: 0.96, green: 0.93, blue: 0.87))
                        .overlay {
                            Text("Right Page")
                                .font(.title)
                        }
                }

                // Page turn effect
                if isAnimating {
                    PageTurnOverlay(
                        direction: direction,
                        theme: .sepia,
                        onComplete: {
                            isAnimating = false
                        }
                    )
                }
            }
            .frame(width: 600, height: 400)
            .overlay(alignment: .bottom) {
                HStack {
                    Button("< Previous") {
                        direction = .backward
                        isAnimating = true
                    }
                    Button("Next >") {
                        direction = .forward
                        isAnimating = true
                    }
                }
                .padding()
            }
        }
    }

    return PreviewContainer()
}
