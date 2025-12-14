// SettingsView.swift
// NoorReader
//
// App settings and preferences

import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        TabView {
            GeneralSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AppearanceSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            IslamicSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Islamic", systemImage: "moon.stars")
                }
        }
        .frame(width: 450, height: 420)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                Toggle("Remember last reading position", isOn: $viewModel.rememberLastPage)

                Picker("Default view mode", selection: $viewModel.defaultDisplayMode) {
                    ForEach(PDFDisplayModeOption.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
            } header: {
                Text("Reading")
            }

            Section {
                Toggle("Book-style page effects", isOn: $viewModel.bookStyleEffectsEnabled)
                    .help("Adds realistic book styling including spine shadows, rounded corners, and page shadows")

                Toggle("Page turn animations", isOn: $viewModel.pageTurnAnimationsEnabled)
                    .disabled(!viewModel.bookStyleEffectsEnabled)
                    .help("Animate page turns in two-page view mode")

                Toggle("Paper texture", isOn: $viewModel.paperTextureEnabled)
                    .disabled(!viewModel.bookStyleEffectsEnabled)
                    .help("Adds subtle paper texture overlay for a more authentic reading experience")
            } header: {
                Text("Book Style")
            } footer: {
                Text("Book-style effects create a more immersive reading experience, especially in two-page view mode.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Appearance Settings

struct AppearanceSettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                Picker("Reading theme", selection: $viewModel.readingTheme) {
                    ForEach(ReadingTheme.allCases) { theme in
                        HStack {
                            Image(systemName: theme.icon)
                            Text(theme.displayName)
                        }
                        .tag(theme)
                    }
                }
                .pickerStyle(.radioGroup)

                VStack(spacing: 12) {
                    ForEach(ReadingTheme.allCases.filter { $0 != .auto }) { theme in
                        ThemePreviewCard(theme: theme)
                    }
                }
                .padding(.top, 8)
            } header: {
                Text("Theme")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Islamic Settings

struct IslamicSettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                Toggle("Show dua on app launch", isOn: $viewModel.showLaunchDua)

                Toggle("Show prayer times in toolbar", isOn: $viewModel.showPrayerTimes)
            } header: {
                Text("Reminders")
            }

            Section {
                Picker("Calculation method", selection: $viewModel.prayerCalculationMethod) {
                    ForEach(prayerCalculationMethods) { method in
                        Text(method.name).tag(method.id)
                    }
                }
            } header: {
                Text("Prayer Times")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    SettingsView()
}
