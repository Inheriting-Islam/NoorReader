// CoverImageService.swift
// NoorReader
//
// Service for generating and managing book cover images

import Foundation
import AppKit
import PDFKit
import SwiftUI

@MainActor
final class CoverImageService {
    static let shared = CoverImageService()

    private init() {}

    // MARK: - Cover Extraction

    /// Extract a high-quality cover from a PDF document
    func extractCover(from url: URL, maxSize: CGFloat = 400) -> Data? {
        guard let document = PDFDocument(url: url),
              let firstPage = document.page(at: 0) else {
            return nil
        }

        let pageRect = firstPage.bounds(for: .mediaBox)
        let scale = maxSize / max(pageRect.width, pageRect.height)
        let scaledSize = CGSize(
            width: pageRect.width * scale,
            height: pageRect.height * scale
        )

        let image = firstPage.thumbnail(of: scaledSize, for: .mediaBox)

        // Check if the cover looks good (not mostly blank/white)
        if isBlankCover(image) {
            return nil
        }

        return image.tiffRepresentation
    }

    /// Check if an image is mostly blank/white (poor cover candidate)
    private func isBlankCover(_ image: NSImage) -> Bool {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return true
        }

        // Sample pixels to determine if image is mostly white/blank
        let width = bitmap.pixelsWide
        let height = bitmap.pixelsHigh
        var whitePixels = 0
        var totalSampled = 0

        let sampleStep = max(1, min(width, height) / 20) // Sample ~400 pixels

        for x in stride(from: 0, to: width, by: sampleStep) {
            for y in stride(from: 0, to: height, by: sampleStep) {
                if let color = bitmap.colorAt(x: x, y: y) {
                    totalSampled += 1
                    // Check if pixel is very light (white or near-white)
                    let brightness = (color.redComponent + color.greenComponent + color.blueComponent) / 3.0
                    if brightness > 0.95 {
                        whitePixels += 1
                    }
                }
            }
        }

        // If more than 90% is white, consider it blank
        guard totalSampled > 0 else { return true }
        return Double(whitePixels) / Double(totalSampled) > 0.90
    }

    // MARK: - Placeholder Generation

    /// Generate a decorative placeholder cover for a book
    func generatePlaceholderCover(
        title: String,
        author: String,
        category: BookCategory?,
        size: CGSize = CGSize(width: 300, height: 400)
    ) -> Data? {
        let image = NSImage(size: size)

        image.lockFocus()

        // Get category color or default
        let categoryColor = category?.color ?? .blue
        let nsColor = NSColor(categoryColor)

        // Draw gradient background
        drawGradientBackground(in: NSRect(origin: .zero, size: size), color: nsColor)

        // Draw Islamic geometric pattern overlay
        drawIslamicPattern(in: NSRect(origin: .zero, size: size), color: nsColor)

        // Draw decorative border
        drawBorder(in: NSRect(origin: .zero, size: size), color: nsColor)

        // Draw title
        drawTitle(title, in: NSRect(origin: .zero, size: size))

        // Draw author
        drawAuthor(author, in: NSRect(origin: .zero, size: size))

        // Draw category icon
        if let category = category {
            drawCategoryIcon(category.icon, in: NSRect(origin: .zero, size: size), color: nsColor)
        }

        image.unlockFocus()

        return image.tiffRepresentation
    }

    // MARK: - Drawing Helpers

    private func drawGradientBackground(in rect: NSRect, color: NSColor) {
        // Create a darker and lighter variant
        let darkerColor = color.blended(withFraction: 0.4, of: .black) ?? color
        let lighterColor = color.blended(withFraction: 0.2, of: .white) ?? color

        let gradient = NSGradient(
            starting: lighterColor,
            ending: darkerColor
        )

        gradient?.draw(in: rect, angle: 135)
    }

    private func drawIslamicPattern(in rect: NSRect, color: NSColor) {
        let patternColor = color.blended(withFraction: 0.3, of: .white)?.withAlphaComponent(0.1) ?? color.withAlphaComponent(0.1)
        patternColor.setStroke()

        let path = NSBezierPath()
        path.lineWidth = 1.0

        // Draw 8-pointed star pattern (simplified)
        let cellSize: CGFloat = 40
        let starRadius: CGFloat = 15

        for x in stride(from: cellSize/2, to: rect.width, by: cellSize) {
            for y in stride(from: cellSize/2, to: rect.height, by: cellSize) {
                drawEightPointStar(at: CGPoint(x: x, y: y), radius: starRadius, path: path)
            }
        }

        path.stroke()
    }

    private func drawEightPointStar(at center: CGPoint, radius: CGFloat, path: NSBezierPath) {
        let points = 8
        let innerRadius = radius * 0.4

        for i in 0..<points {
            let outerAngle = (Double(i) / Double(points)) * 2 * .pi - .pi / 2
            let innerAngle = outerAngle + .pi / Double(points)

            let outerPoint = CGPoint(
                x: center.x + CGFloat(cos(outerAngle)) * radius,
                y: center.y + CGFloat(sin(outerAngle)) * radius
            )
            let innerPoint = CGPoint(
                x: center.x + CGFloat(cos(innerAngle)) * innerRadius,
                y: center.y + CGFloat(sin(innerAngle)) * innerRadius
            )

            if i == 0 {
                path.move(to: outerPoint)
            } else {
                path.line(to: outerPoint)
            }
            path.line(to: innerPoint)
        }
        path.close()
    }

    private func drawBorder(in rect: NSRect, color: NSColor) {
        let borderColor = color.blended(withFraction: 0.5, of: .white)?.withAlphaComponent(0.3) ?? color.withAlphaComponent(0.3)
        borderColor.setStroke()

        let borderInset: CGFloat = 15
        let borderRect = rect.insetBy(dx: borderInset, dy: borderInset)

        // Outer border
        let outerPath = NSBezierPath(roundedRect: borderRect, xRadius: 8, yRadius: 8)
        outerPath.lineWidth = 2
        outerPath.stroke()

        // Inner decorative border
        let innerRect = borderRect.insetBy(dx: 8, dy: 8)
        let innerPath = NSBezierPath(roundedRect: innerRect, xRadius: 4, yRadius: 4)
        innerPath.lineWidth = 0.5
        innerPath.stroke()
    }

    private func drawTitle(_ title: String, in rect: NSRect) {
        let titleFont = NSFont.systemFont(ofSize: 24, weight: .bold)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraphStyle
        ]

        // Calculate title area
        let titleRect = NSRect(
            x: 30,
            y: rect.height * 0.4,
            width: rect.width - 60,
            height: rect.height * 0.4
        )

        // Truncate if too long
        let displayTitle = title.count > 60 ? String(title.prefix(57)) + "..." : title

        displayTitle.draw(in: titleRect, withAttributes: attributes)
    }

    private func drawAuthor(_ author: String, in rect: NSRect) {
        guard !author.isEmpty else { return }

        let authorFont = NSFont.systemFont(ofSize: 14, weight: .medium)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: authorFont,
            .foregroundColor: NSColor.white.withAlphaComponent(0.8),
            .paragraphStyle: paragraphStyle
        ]

        let authorRect = NSRect(
            x: 30,
            y: rect.height * 0.25,
            width: rect.width - 60,
            height: 30
        )

        author.draw(in: authorRect, withAttributes: attributes)
    }

    private func drawCategoryIcon(_ iconName: String, in rect: NSRect, color: NSColor) {
        let iconConfig = NSImage.SymbolConfiguration(pointSize: 32, weight: .light)
        guard let iconImage = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)?
            .withSymbolConfiguration(iconConfig) else {
            return
        }

        let iconColor = color.blended(withFraction: 0.6, of: .white) ?? .white
        let tintedIcon = iconImage.tinted(with: iconColor)

        let iconSize: CGFloat = 40
        let iconRect = NSRect(
            x: (rect.width - iconSize) / 2,
            y: rect.height * 0.08,
            width: iconSize,
            height: iconSize
        )

        tintedIcon.draw(in: iconRect)
    }

    // MARK: - Get or Generate Cover

    /// Get cover image for a book - extract from PDF or generate placeholder
    func getCover(for book: Book) -> Data? {
        // First try to use existing cover
        if let existingCover = book.coverImageData, !existingCover.isEmpty {
            return existingCover
        }

        // Try to extract from PDF
        if let extracted = extractCover(from: book.fileURL) {
            return extracted
        }

        // Generate placeholder
        return generatePlaceholderCover(
            title: book.title,
            author: book.author,
            category: book.category
        )
    }

    /// Update book cover - extract or generate if needed
    func updateBookCover(_ book: Book) {
        book.coverImageData = getCover(for: book)
    }
}

// MARK: - NSImage Tinting Extension

private extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        let image = self.copy() as! NSImage
        image.lockFocus()

        color.set()

        let imageRect = NSRect(origin: .zero, size: image.size)
        imageRect.fill(using: .sourceAtop)

        image.unlockFocus()
        return image
    }
}
