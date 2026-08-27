//
//  OnboardingFeaturesPage.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI
import UserNotifications

// The onboarding page listing what EyeBreak does, and the row it repeats.

struct FeaturesPage: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("What EyeBreak Does")
                .font(.system(size: 36, weight: .bold, design: .rounded))

            VStack(alignment: .leading, spacing: 20) {
                FeatureItem(
                    icon: "bell.badge.fill",
                    title: "Gentle Reminders",
                    description: "Get a notification 30 seconds before each break"
                )

                FeatureItem(
                    icon: "eye.slash.fill",
                    title: "Screen Blur",
                    description: "Your screen blurs during breaks to encourage rest"
                )

                FeatureItem(
                    icon: "moon.zzz.fill",
                    title: "Smart Pausing",
                    description: "Automatically pauses when you're away from your Mac"
                )

                FeatureItem(
                    icon: "chart.bar.fill",
                    title: "Track Progress",
                    description: "See how many breaks you've taken each day"
                )

                FeatureItem(
                    icon: "lock.fill",
                    title: "Privacy First",
                    description: "All data stays on your Mac—no tracking or analytics"
                )
            }
            .frame(width: 400)

            Spacer()
        }
        .padding(40)
    }
}

struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String

    @State private var animate = false

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Enhanced icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.cyan.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: .blue.opacity(0.15), radius: 6)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(animate ? 1.0 : 0.8)
            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: animate)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .onAppear {
            animate = true
        }
    }
}
