// BookCard.swift
// NoorReader
//
// Library grid item component

import SwiftUI
import SwiftData
import AppKit

struct BookCard: View {
    let book: Book
    let onOpen: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cover Image
            ZStack(alignment: .topTrailing) {
                coverImage

                // Favorite Badge
                if book.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                        .padding(6)
                        .background(.ultraThinMaterial, in: Circle())
                        .padding(8)
                }
            }
            .aspectRatio(3/4, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            // Title
            Text(book.displayTitle)
                .font(.headline)
                .lineLimit(2)
                .foregroundStyle(.primary)

            // Author
            Text(book.displayAuthor)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            // Progress Bar
            if book.isStarted {
                ProgressView(value: book.progress)
                    .tint(Color.noorTeal)

                Text("\(book.progressPercentage)%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovering ? Color.gray.opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .onTapGesture(count: 2) {
            onOpen()
        }
        .contextMenu {
            Button("Open") { onOpen() }
            Divider()
            Button(book.isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                // Toggle favorite - handled by parent
            }
            Divider()
            Button("Show in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([book.fileURL])
            }
            Divider()
            Button("Delete from Library", role: .destructive) {
                // Delete - handled by parent
            }
        }
    }

    @ViewBuilder
    private var coverImage: some View {
        if let imageData = book.coverImageData,
           let nsImage = NSImage(data: imageData) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFill()
        } else {
            // Placeholder cover
            ZStack {
                LinearGradient(
                    colors: [Color.noorTeal.opacity(0.8), Color.noorTeal],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 8) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.8))

                    Text(book.displayTitle)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .lineLimit(3)
                }
            }
        }
    }
}
