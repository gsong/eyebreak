//
//  QuickPresetsView.swift
//  EyeBreak
//
//  Created on October 8, 2025.
//  UI for customizing color themes for ambient reminders and break overlays
//

import SwiftUI

// The preset theme picker, and the button one preset renders as.

struct QuickPresetsView: View {
    @Binding var customTheme: ColorTheme
    let onThemeChange: () -> Void

    let presets: [(name: String, theme: ColorTheme)] = [
        ("Ocean Blue", ColorTheme(
            themeType: .custom,
            backgroundColorHex: "#2980B9",
            backgroundOpacity: 0.7,
            textColorHex: "#FFFFFF",
            textOpacity: 0.95,
            secondaryTextColorHex: "#ECF0F1",
            secondaryTextOpacity: 0.75,
            accentColorHex: "#3498DB",
            accentOpacity: 0.8,
            glassBlurRadius: 2.0,
            glassHighlightOpacity: 0.3
        )),
        ("Forest Green", ColorTheme(
            themeType: .custom,
            backgroundColorHex: "#27AE60",
            backgroundOpacity: 0.7,
            textColorHex: "#FFFFFF",
            textOpacity: 0.95,
            secondaryTextColorHex: "#E8F8F5",
            secondaryTextOpacity: 0.75,
            accentColorHex: "#2ECC71",
            accentOpacity: 0.8,
            glassBlurRadius: 2.0,
            glassHighlightOpacity: 0.3
        )),
        ("Sunset Orange", ColorTheme(
            themeType: .custom,
            backgroundColorHex: "#E67E22",
            backgroundOpacity: 0.7,
            textColorHex: "#FFFFFF",
            textOpacity: 0.95,
            secondaryTextColorHex: "#FEF5E7",
            secondaryTextOpacity: 0.75,
            accentColorHex: "#F39C12",
            accentOpacity: 0.8,
            glassBlurRadius: 2.0,
            glassHighlightOpacity: 0.3
        )),
        ("Royal Purple", ColorTheme(
            themeType: .custom,
            backgroundColorHex: "#8E44AD",
            backgroundOpacity: 0.7,
            textColorHex: "#FFFFFF",
            textOpacity: 0.95,
            secondaryTextColorHex: "#F4ECF7",
            secondaryTextOpacity: 0.75,
            accentColorHex: "#9B59B6",
            accentOpacity: 0.8,
            glassBlurRadius: 2.0,
            glassHighlightOpacity: 0.3
        ))
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Presets")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 12) {
                ForEach(presets, id: \.name) { preset in
                    Button {
                        customTheme = preset.theme
                        onThemeChange()
                    } label: {
                        VStack(spacing: 8) {
                            Circle()
                                .fill(preset.theme.backgroundGradient())
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )

                            Text(preset.name)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(10)
    }
}

struct ThemeTypeButton: View {
    let type: ColorThemeType
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                iconCircle

                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .overlay(borderOverlay)
        }
        .buttonStyle(.plain)
    }

    private var iconCircle: some View {
        ZStack {
            Circle()
                .fill(circleFill)
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                )

            Image(systemName: type.icon)
                .font(.title3)
                .foregroundColor(isSelected ? .white : .secondary)
        }
    }

    private var circleFill: LinearGradient {
        if isSelected {
            return LinearGradient(
                colors: [.blue, .blue.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color(NSColor.controlBackgroundColor)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var backgroundColor: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isSelected ? Color.blue.opacity(0.1) : Color(NSColor.controlBackgroundColor).opacity(0.5))
    }

    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(isSelected ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
    }
}
