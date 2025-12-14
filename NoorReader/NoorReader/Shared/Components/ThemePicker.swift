// ThemePicker.swift
// NoorReader
//
// Theme selection component

import SwiftUI

struct ThemePicker: View {
    @State private var themeService = ThemeService.shared

    var body: some View {
        Menu {
            ForEach(ReadingTheme.allCases) { theme in
                Button(action: { themeService.setTheme(theme) }) {
                    HStack {
                        Image(systemName: theme.icon)
                        Text(theme.displayName)
                        if themeService.currentTheme == theme {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: themeService.currentTheme.icon)
        }
        .help("Reading Theme")
    }
}

// Preview with all themes
struct ThemePreviewCard: View {
    let theme: ReadingTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sample Text")
                .font(.headline)
                .foregroundStyle(theme.textColor)

            Text("This is how text will appear in \(theme.displayName) mode.")
                .font(.body)
                .foregroundStyle(theme.secondaryTextColor)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    VStack(spacing: 16) {
        ForEach(ReadingTheme.allCases) { theme in
            ThemePreviewCard(theme: theme)
        }
    }
    .padding()
    .frame(width: 300)
}
