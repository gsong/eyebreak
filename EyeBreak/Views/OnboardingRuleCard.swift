//
//  OnboardingRuleCard.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI
import UserNotifications

// The three cards explaining 20 minutes, 20 feet, 20 seconds.

struct RuleCard: View {
    let number: String
    let unit: String
    let description: String
    let icon: String
    let color: Color

    @State private var animate = false

    var body: some View {
        HStack(spacing: 20) {
            // Enhanced icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: color.opacity(0.2), radius: 8)

                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(animate ? 1.0 : 0.8)
            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2), value: animate)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(number)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text(unit)
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                }

                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 4)
        .onAppear {
            animate = true
        }
    }
}
