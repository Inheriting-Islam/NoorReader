// AIExplainPopover.swift
// NoorReader
//
// AI-powered text explanation popover

import SwiftUI

struct AIExplainPopover: View {
    let selectedText: String
    let context: String?
    let onDismiss: () -> Void

    @State private var aiService = AIService.shared
    @State private var explanation: String?
    @State private var isLoading = false
    @State private var error: Error?
    @State private var processingTime: TimeInterval?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            selectedTextPreview

            Divider()

            contentArea

            if explanation != nil {
                Divider()
                actionButtons
            }
        }
        .padding()
        .frame(width: 380)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        .onAppear {
            explain()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "questionmark.circle.fill")
                .foregroundStyle(.orange)

            Text("Explain")
                .font(.headline)

            Spacer()

            // Provider badge
            HStack(spacing: 4) {
                Image(systemName: "cloud")
                    .font(.caption2)
                Text("Claude")
                    .font(.caption2)
            }
            .foregroundStyle(.blue)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.1))
            .clipShape(Capsule())

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Selected Text Preview

    private var selectedTextPreview: some View {
        Text(selectedText)
            .font(.callout)
            .foregroundStyle(.secondary)
            .lineLimit(3)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        if isLoading {
            loadingView
        } else if let error {
            errorView(error)
        } else if let explanation {
            explanationView(explanation)
        }
    }

    private var loadingView: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("Thinking...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.orange)

            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                explain()
            }
            .font(.caption)
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    private func explanationView(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Explanation")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if let time = processingTime {
                    Text(String(format: "%.1fs", time))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Text(text)
                .font(.body)
                .textSelection(.enabled)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack {
            Button {
                copyToClipboard(explanation!)
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
                    .font(.caption)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                explanation = nil
                explain()
            } label: {
                Label("Regenerate", systemImage: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Actions

    private func explain() {
        isLoading = true
        error = nil

        Task {
            do {
                let response = try await aiService.explain(text: selectedText, context: context)
                explanation = response.content
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

// MARK: - Standalone Explain View (for sheet presentation)

struct AIExplainSheet: View {
    let selectedText: String
    let context: String?

    @Environment(\.dismiss) private var dismiss
    @State private var aiService = AIService.shared
    @State private var explanation: String?
    @State private var isLoading = false
    @State private var error: Error?
    @State private var processingTime: TimeInterval?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundStyle(.orange)

                Text("AI Explanation")
                    .font(.headline)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Source text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected Text")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(selectedText)
                            .font(.callout)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Divider()

                    // Explanation
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Generating explanation...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if let error {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundStyle(.orange)

                            Text(error.localizedDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            Button("Try Again") {
                                generateExplanation()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if let explanation {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Explanation")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                if let time = processingTime {
                                    Text(String(format: "%.1fs", time))
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }

                            Text(explanation)
                                .font(.body)
                                .textSelection(.enabled)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.orange.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding()
            }

            Divider()

            // Footer
            HStack {
                if explanation != nil {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(explanation!, forType: .string)
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }

                    Button {
                        explanation = nil
                        generateExplanation()
                    } label: {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                    }
                }

                Spacer()

                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()
        }
        .frame(width: 500, height: 500)
        .background(.background)
        .onAppear {
            generateExplanation()
        }
    }

    private func generateExplanation() {
        isLoading = true
        error = nil

        Task {
            do {
                let response = try await aiService.explain(text: selectedText, context: context)
                explanation = response.content
                processingTime = response.processingTime
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
}

#Preview("Popover") {
    AIExplainPopover(
        selectedText: "Quantum entanglement is a phenomenon where particles become interconnected.",
        context: nil,
        onDismiss: {}
    )
    .padding()
}

#Preview("Sheet") {
    AIExplainSheet(
        selectedText: "Quantum entanglement is a phenomenon where particles become interconnected and the quantum state of one particle cannot be described independently.",
        context: "Chapter 5: Quantum Mechanics"
    )
}
