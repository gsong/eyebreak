//
//  MenuBarComponents.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

// The badge, button style, and hover modifier the menu bar popover is built from.

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.1)],
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
                    .font(.system(size: 14, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

struct HoverEffectModifier: ViewModifier {
    @State private var isHovered = false
    let cornerRadius: CGFloat

    init(cornerRadius: CGFloat = 8) {
        self.cornerRadius = cornerRadius
    }

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
            .contentShape(Rectangle())
    }
}

extension View {
    func hoverEffect(cornerRadius: CGFloat = 8) -> some View {
        self.modifier(HoverEffectModifier(cornerRadius: cornerRadius))
    }
}

struct ProfessionalButtonStyle: ButtonStyle {
    let color: Color
    let isOutlined: Bool

    init(color: Color = .blue, isOutlined: Bool = false) {
        self.color = color
        self.isOutlined = isOutlined
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func professionalButtonStyle(color: Color = .blue, isOutlined: Bool = false) -> some View {
        self.buttonStyle(ProfessionalButtonStyle(color: color, isOutlined: isOutlined))
    }
}
