// AISettingsView.swift
// NoorReader
//
// AI configuration and privacy settings

import SwiftUI

struct AISettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var aiService = AIService.shared
    @State private var isValidatingKey = false
    @State private var keyValidationResult: Bool?
    @State private var validationError: AIError?
    @State private var showAPIKeyField = false
    @State private var debugMessage: String = ""

    var body: some View {
        Form {
            // AI Enable/Disable
            Section {
                Toggle("Enable AI Features", isOn: $viewModel.aiEnabled)
                    .help("Enable or disable all AI features")
            } header: {
                Label("AI Features", systemImage: "sparkles")
            } footer: {
                Text("AI features help you summarize text, explain concepts, and generate flashcards.")
            }

            if viewModel.aiEnabled {
                // Provider Selection
                Section {
                    providerPicker

                    if viewModel.aiProvider == .cloud {
                        cloudSettings
                    } else {
                        localAIInfo
                    }
                } header: {
                    Label("Provider", systemImage: "cpu")
                } footer: {
                    if viewModel.aiProvider == .local {
                        Text("Local AI runs entirely on your Mac. Your data never leaves your device.")
                    } else {
                        Text("Cloud AI sends text to Anthropic's Claude API. Only use for non-sensitive content.")
                    }
                }

                // Feature Toggles
                Section {
                    featureToggles
                } header: {
                    Label("Features", systemImage: "list.bullet")
                }

                // Privacy Information
                Section {
                    privacyInfo
                } header: {
                    Label("Privacy", systemImage: "lock.shield")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onChange(of: viewModel.claudeAPIKey) { _, newValue in
            // Configure AI service when key changes
            Task {
                if !newValue.isEmpty {
                    await aiService.configureCloudAPI(key: newValue)
                } else {
                    await aiService.clearCloudAPI()
                }
            }
            keyValidationResult = nil
            validationError = nil
        }
        .onAppear {
            // Sync settings to AI service
            aiService.syncSettings(from: viewModel)
        }
    }

    // MARK: - Provider Picker

    private var providerPicker: some View {
        Picker("AI Provider", selection: $viewModel.aiProvider) {
            Text("Cloud").tag(AIProvider.cloud)
            Text("Local").tag(AIProvider.local)
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Cloud Settings

    private var cloudSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            // API Key field
            HStack {
                if showAPIKeyField {
                    TextField("sk-ant-...", text: $viewModel.claudeAPIKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                } else {
                    SecureField("Claude API Key", text: $viewModel.claudeAPIKey)
                        .textFieldStyle(.roundedBorder)
                }

                Button {
                    showAPIKeyField.toggle()
                } label: {
                    Image(systemName: showAPIKeyField ? "eye.slash" : "eye")
                }
                .buttonStyle(.plain)
            }

            // Key status
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    if viewModel.claudeAPIKey.isEmpty {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("API key required for cloud AI features")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if isValidatingKey {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Validating...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if let error = validationError {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else if let result = keyValidationResult {
                        if result {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("API key is valid")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                            Text("Invalid API key")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    } else if !viewModel.claudeAPIKey.isEmpty {
                        Button("Validate Key") {
                            validateAPIKey()
                        }
                        .font(.caption)
                    }
                }

                // Show credits link if insufficient credits error
                if case .insufficientCredits = validationError {
                    Link(destination: URL(string: "https://console.anthropic.com/settings/billing")!) {
                        Label("Add credits at Anthropic Console", systemImage: "creditcard")
                            .font(.caption)
                    }
                }

                // Debug info
                if !debugMessage.isEmpty {
                    Text(debugMessage)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                        .textSelection(.enabled)
                }
            }

            // Get API key link
            Link(destination: URL(string: "https://console.anthropic.com/settings/keys")!) {
                Label("Get an API key from Anthropic", systemImage: "arrow.up.right.square")
                    .font(.caption)
            }
        }
    }

    // MARK: - Local AI Info

    private var localAIInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "desktopcomputer")
                    .foregroundStyle(.green)
                Text("On-Device Processing")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Text("Local AI uses Apple's NaturalLanguage framework for semantic search. Full LLM capabilities require the cloud provider or MLX setup.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Label("Private", systemImage: "lock.fill")
                Label("Offline", systemImage: "wifi.slash")
                Label("Fast", systemImage: "bolt.fill")
            }
            .font(.caption)
            .foregroundStyle(.green)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Feature Toggles

    private var featureToggles: some View {
        Group {
            Toggle(isOn: $viewModel.aiSummarizationEnabled) {
                Label("Summarization", systemImage: "text.alignleft")
            }
            .help("Generate concise summaries of selected text")

            Toggle(isOn: $viewModel.aiExplainEnabled) {
                Label("Explain Selection", systemImage: "questionmark.circle")
            }
            .help("Get plain-language explanations of complex text")

            Toggle(isOn: $viewModel.aiFlashcardsEnabled) {
                Label("Flashcard Generation", systemImage: "rectangle.on.rectangle")
            }
            .help("Automatically create study flashcards from highlights")

            Toggle(isOn: $viewModel.aiSemanticSearchEnabled) {
                Label("Semantic Search", systemImage: "sparkle.magnifyingglass")
            }
            .help("Search by meaning, not just keywords")
        }
    }

    // MARK: - Privacy Info

    private var privacyInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: viewModel.aiProvider == .local ? "lock.shield.fill" : "network")
                    .font(.title2)
                    .foregroundStyle(viewModel.aiProvider == .local ? .green : .orange)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.aiProvider == .local ? "Maximum Privacy" : "Cloud Processing")
                        .font(.headline)

                    if viewModel.aiProvider == .local {
                        Text("All AI processing happens on your Mac using Apple's frameworks. No data is sent to any external server.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Text is sent to Anthropic's Claude API for processing. Anthropic does not train on API data. Use only for non-sensitive content.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if viewModel.aiProvider == .local {
                HStack(spacing: 16) {
                    PrivacyBadge(icon: "desktopcomputer", text: "On-device")
                    PrivacyBadge(icon: "wifi.slash", text: "No internet")
                    PrivacyBadge(icon: "hand.raised.fill", text: "Private")
                }
            } else {
                HStack(spacing: 16) {
                    PrivacyBadge(icon: "cloud", text: "Cloud", color: .orange)
                    PrivacyBadge(icon: "lock.fill", text: "Encrypted", color: .orange)
                    PrivacyBadge(icon: "nosign", text: "No training", color: .orange)
                }
            }
        }
    }

    // MARK: - Actions

    private func validateAPIKey() {
        isValidatingKey = true
        keyValidationResult = nil
        validationError = nil
        debugMessage = "Key length: \(viewModel.claudeAPIKey.count), prefix: \(String(viewModel.claudeAPIKey.prefix(25)))..."

        Task {
            do {
                await aiService.configureCloudAPI(key: viewModel.claudeAPIKey)
                let isValid = try await aiService.validateCloudAPIKey()
                keyValidationResult = isValid
                debugMessage = isValid ? "Validation succeeded!" : "Key returned invalid"
            } catch let error as AIError {
                validationError = error
                keyValidationResult = nil
                debugMessage = "AIError: \(error)"
            } catch {
                keyValidationResult = false
                debugMessage = "Other error: \(error.localizedDescription)"
            }
            isValidatingKey = false
        }
    }
}

// MARK: - Privacy Badge

struct PrivacyBadge: View {
    let icon: String
    let text: String
    var color: Color = .green

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

#Preview {
    AISettingsView(viewModel: SettingsViewModel())
        .frame(width: 500, height: 700)
}
