//
//  SettingsIconPickers.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

// The SF Symbol pickers for the ambient and water reminders.

struct CustomIconPickerView: View {
    @Binding var selectedIcon: String

    // Curated professional SF Symbols for eye care reminders
    let iconOptions: [(name: String, symbol: String)] = [
        ("Eye", "eye"),
        ("Eye Fill", "eye.fill"),
        ("Sparkle", "sparkles"),
        ("Star", "star.fill"),
        ("Heart", "heart.fill"),
        ("Drop", "drop.fill"),
        ("Leaf", "leaf.fill"),
        ("Moon", "moon.stars.fill"),
        ("Sun", "sun.max.fill"),
        ("Clock", "clock.fill"),
        ("Bell", "bell.fill"),
        ("Hand Raised", "hand.raised.fill"),
        ("Figure Walk", "figure.walk"),
        ("Lungs", "lungs.fill"),
        ("Headphones", "headphones"),
        ("Cup", "cup.and.saucer.fill")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 60, maximum: 70), spacing: 12)
            ], spacing: 12) {
                ForEach(iconOptions, id: \.symbol) { option in
                    IconOptionButton(
                        symbol: option.symbol,
                        isSelected: selectedIcon == option.symbol,
                        onSelect: {
                            selectedIcon = option.symbol
                        }
                    )
                }
            }

            if selectedIcon.isEmpty {
                Text("Select an icon for your custom reminder")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
    }
}

struct IconOptionButton: View {
    let symbol: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ?
                          LinearGradient(colors: [.purple, .purple.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                          LinearGradient(colors: [Color(NSColor.controlBackgroundColor)], startPoint: .top, endPoint: .bottom))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.purple : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    )
                    .shadow(color: isSelected ? Color.purple.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 2)

                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .frame(height: 60)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

struct CustomWaterIconPickerView: View {
    @Binding var selectedIcon: String

    // Curated water-related SF Symbols
    let iconOptions: [(name: String, symbol: String)] = [
        ("Drop", "drop.fill"),
        ("Water Bottle", "waterbottle.fill"),
        ("Drop Circle", "drop.circle.fill"),
        ("Drop Triangle", "drop.triangle.fill"),
        ("Cup", "cup.and.saucer.fill"),
        ("Mug", "mug.fill"),
        ("Figure Water", "figure.water.fitness"),
        ("Sparkles", "sparkles"),
        ("Leaf", "leaf.fill"),
        ("Heart", "heart.fill"),
        ("Hands", "hands.and.sparkles.fill"),
        ("Sun", "sun.max.fill"),
        ("Moon", "moon.stars.fill"),
        ("Clock", "clock.fill"),
        ("Bell", "bell.fill"),
        ("Hand Raised", "hand.raised.fill")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 60, maximum: 70), spacing: 12)
            ], spacing: 12) {
                ForEach(iconOptions, id: \.symbol) { option in
                    WaterIconOptionButton(
                        symbol: option.symbol,
                        isSelected: selectedIcon == option.symbol,
                        onSelect: {
                            selectedIcon = option.symbol
                        }
                    )
                }
            }

            if selectedIcon.isEmpty {
                Text("Select an icon for your water reminder")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
    }
}

struct WaterIconOptionButton: View {
    let symbol: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ?
                          LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing) :
                          LinearGradient(colors: [Color(NSColor.controlBackgroundColor)], startPoint: .top, endPoint: .bottom))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    )
                    .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 2)

                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .white : .secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            .frame(width: 60, height: 60)
        }
        .buttonStyle(.plain)
        .help(symbol)
    }
}
