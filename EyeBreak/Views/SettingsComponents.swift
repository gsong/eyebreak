//
//  SettingsComponents.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

// The cards, headers, and rows the settings tabs are assembled from.

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 30, height: 30)

                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

struct SectionHeaderView: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(color)
        }
        .textCase(nil)
    }
}

struct SettingsSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.2), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }

            // Content
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.1), lineWidth: 1)
        )
    }
}

struct BreakStyleOptionCard: View {
    let style: BreakStyle
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.purple.opacity(0.15) : Color.secondary.opacity(0.08))
                        .frame(width: 44, height: 44)

                    Image(systemName: style.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isSelected ? .purple : .secondary)
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(style.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isSelected ? .primary : .secondary)

                    Text(style.description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.purple)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.purple.opacity(0.08) : Color.secondary.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct EnhancedSliderCard: View {
    let title: String
    let value: Int
    let unit: String
    let icon: String
    let color: Color
    let range: ClosedRange<Int>
    let step: Int
    let onChange: (Int) -> Void

    @State private var animateValue = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .font(.system(size: 14))
                }

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Spacer()

                // Value display with animation
                HStack(spacing: 4) {
                    Text("\(value)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .contentTransition(.numericText())

                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                }
                .scaleEffect(animateValue ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: animateValue)
            }

            // Custom styled slider
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { newValue in
                        onChange(Int(newValue.rounded()))
                        animateValue = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            animateValue = false
                        }
                    }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: Double(step)
            )
            .tint(color)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [color.opacity(0.2), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}
