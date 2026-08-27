//
//  ColorThemeSettingsView.swift
//  EyeBreak
//
//  Created on October 8, 2025.
//  UI for customizing color themes for ambient reminders and break overlays
//

import SwiftUI

// MARK: - Theme Settings Card

struct ThemeSettingsCard: View {
    let title: String
    let icon: String
    @Binding var selectedThemeType: ColorThemeType
    @Binding var customTheme: ColorTheme
    let onThemeChange: () -> Void

    @State private var showingCustomEditor = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerView

            // Theme Type Picker - Custom Button Style for Better Visual Feedback
            themePickerView

            // Description with visual indicator
            descriptionView

            // Preview
            ThemePreviewCard(theme: selectedThemeType == .custom ? customTheme : ColorTheme.theme(for: selectedThemeType))

            // Custom theme editor
            if selectedThemeType == .custom {
                customEditorSection
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }

    private var headerView: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(title)
                .font(.headline)
            Spacer()
        }
    }

    private var themePickerView: some View {
        HStack(spacing: 12) {
            ForEach(ColorThemeType.allCases) { type in
                ThemeTypeButton(
                    type: type,
                    isSelected: selectedThemeType == type,
                    onSelect: {
                        selectedThemeType = type
                        onThemeChange()
                    }
                )
            }
        }
    }

    private var descriptionView: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)

            Text(selectedThemeType.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 4)
    }

    private var customEditorSection: some View {
        VStack(spacing: 0) {
            Button {
                showingCustomEditor.toggle()
            } label: {
                HStack {
                    Image(systemName: "paintbrush.fill")
                    Text(showingCustomEditor ? "Hide Customization" : "Customize Colors")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: showingCustomEditor ? "chevron.up" : "chevron.down")
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            if showingCustomEditor {
                CustomThemeEditor(theme: $customTheme, onThemeChange: onThemeChange)
                    .padding(.top, 12)
            }
        }
    }
}

// MARK: - Theme Preview Card

struct ThemePreviewCard: View {
    let theme: ColorTheme

    var body: some View {
        HStack(spacing: 16) {
            // Icon preview
            ZStack {
                Circle()
                    .fill(theme.backgroundGradient())
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(theme.borderGradient(), lineWidth: 1)
                    )

                Image(systemName: "eye")
                    .foregroundStyle(theme.textGradient())
                    .font(.title3)
            }

            // Text preview
            VStack(alignment: .leading, spacing: 4) {
                Text("Preview")
                    .font(.headline)
                    .foregroundColor(theme.textColor.opacity(theme.textOpacity))

                Text("This is how it will look")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor.opacity(theme.secondaryTextOpacity))
            }

            Spacer()

            // Accent color indicator
            Circle()
                .fill(theme.accentColor.opacity(theme.accentOpacity))
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
        }
        .padding()
        .background(theme.backgroundColor.opacity(theme.backgroundOpacity * 0.3))
        .cornerRadius(10)
    }
}

// MARK: - Custom Theme Editor

struct CustomThemeEditor: View {
    @Binding var theme: ColorTheme
    let onThemeChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Background Color
            ColorPickerRow(
                title: "Background Color",
                color: Binding(
                    get: { theme.backgroundColor },
                    set: { newColor in
                        if let hex = newColor.toHex() {
                            theme.backgroundColorHex = hex
                            onThemeChange()
                        }
                    }
                ),
                opacity: $theme.backgroundOpacity,
                onOpacityChange: onThemeChange
            )

            Divider()

            // Text Color
            ColorPickerRow(
                title: "Text Color",
                color: Binding(
                    get: { theme.textColor },
                    set: { newColor in
                        if let hex = newColor.toHex() {
                            theme.textColorHex = hex
                            onThemeChange()
                        }
                    }
                ),
                opacity: $theme.textOpacity,
                onOpacityChange: onThemeChange
            )

            Divider()

            // Secondary Text Color
            ColorPickerRow(
                title: "Secondary Text",
                color: Binding(
                    get: { theme.secondaryTextColor },
                    set: { newColor in
                        if let hex = newColor.toHex() {
                            theme.secondaryTextColorHex = hex
                            onThemeChange()
                        }
                    }
                ),
                opacity: $theme.secondaryTextOpacity,
                onOpacityChange: onThemeChange
            )

            Divider()

            // Accent Color
            ColorPickerRow(
                title: "Accent Color",
                color: Binding(
                    get: { theme.accentColor },
                    set: { newColor in
                        if let hex = newColor.toHex() {
                            theme.accentColorHex = hex
                            onThemeChange()
                        }
                    }
                ),
                opacity: $theme.accentOpacity,
                onOpacityChange: onThemeChange
            )

            Divider()

            // Glass Effect Settings
            VStack(alignment: .leading, spacing: 12) {
                Text("Glass Effect")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    Text("Blur Radius")
                        .frame(width: 120, alignment: .leading)
                    Slider(value: $theme.glassBlurRadius, in: 0...20) {
                        Text("Blur")
                    } onEditingChanged: { _ in
                        onThemeChange()
                    }
                    Text(String(format: "%.1f", theme.glassBlurRadius))
                        .frame(width: 40)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Highlight")
                        .frame(width: 120, alignment: .leading)
                    Slider(value: $theme.glassHighlightOpacity, in: 0...1) {
                        Text("Highlight")
                    } onEditingChanged: { _ in
                        onThemeChange()
                    }
                    Text(String(format: "%.0f%%", theme.glassHighlightOpacity * 100))
                        .frame(width: 40)
                        .foregroundColor(.secondary)
                }
            }

            // Reset button
            HStack {
                Spacer()
                Button {
                    theme = .customTheme
                    onThemeChange()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset to Default")
                    }
                    .foregroundColor(.orange)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
}

// MARK: - Color Picker Row

// MARK: - Quick Presets

// MARK: - Theme Type Button Component
