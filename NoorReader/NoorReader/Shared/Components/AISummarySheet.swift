// AISummarySheet.swift
// NoorReader
//
// AI-powered text summarization sheet

import SwiftUI

struct AISummarySheet: View {
    let selectedText: String
    let pageRange: ClosedRange<Int>?

    @Environment(\.dismiss) private var dismiss
    @State private var aiService = AIService.shared
    @State private var summary: String?
    @State private var isLoading = false
    @State private var error: Error?
    @State private var style: SummarizationStyle = .concise
    @State private var processingTime: TimeInterval?

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    sourcePreview
                    stylePicker

                    Divider()

                    if isLoading {
                        loadingView
                    } else if let error {
                        errorView(error)
                    } else if let summary {
                        summaryView(summary)
                    } else {
                        promptView
                    }
                }
                .padding()
            }

            Divider()

            footer
        }
        .frame(width: 500, height: 600)
        .background(.background)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundStyle(.purple)

            Text("AI Summary")
                .font(.headline)

            Spacer()

            // Provider indicator
            HStack(spacing: 4) {
                Image(systemName: "cloud")
                    .font(.caption)
                Text("Claude")
                    .font(.caption)
            }
            .foregroundStyle(.blue)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .clipShape(Capsule())

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    // MARK: - Source Preview

    private var sourcePreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Source Text")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let range = pageRange {
                    Text("Pages \(range.lowerBound + 1)-\(range.upperBound + 1)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Text("\(selectedText.count) characters")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Text(selectedText)
                .font(.callout)
                .lineLimit(6)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Style Picker

    private var stylePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary Style")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("Style", selection: $style) {
                ForEach(SummarizationStyle.allCases) { s in
                    Label(s.displayName, systemImage: s.icon)
                        .tag(s)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Generating summary...")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Using Claude AI")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Error View

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)

            Text("Something went wrong")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Try Again") {
                generateSummary()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Summary View

    private func summaryView(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundStyle(.purple)

                Text("Summary")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if let time = processingTime {
                    Text(String(format: "%.1fs", time))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Text(summary)
                .font(.body)
                .textSelection(.enabled)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.purple.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Prompt View

    private var promptView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(.purple.opacity(0.5))

            Text("Ready to summarize")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Click 'Generate' to create an AI summary of the selected text.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            if summary != nil {
                Button {
                    copyToClipboard(summary!)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }

                Button {
                    // TODO: Save to notes
                } label: {
                    Label("Save to Notes", systemImage: "square.and.pencil")
                }
            }

            Spacer()

            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.escape, modifiers: [])

            Button("Generate") {
                generateSummary()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding()
    }

    // MARK: - Actions

    private func generateSummary() {
        isLoading = true
        error = nil

        Task {
            do {
                let response = try await aiService.summarize(text: selectedText, style: style)
                summary = response.content
                processingTime = response.processingTime
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

#Preview {
    AISummarySheet(
        selectedText: "This is some sample text that would be summarized by the AI. It contains multiple sentences and ideas that need to be condensed into a brief summary. The AI will analyze the content and extract the key points.",
        pageRange: 1...3
    )
}
