//
//  OnboardingView.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss

    @State private var currentPage = 0
    private let totalPages = 4

    var body: some View {
        VStack(spacing: 0) {
            // Content
            TabView(selection: $currentPage) {
                WelcomePage()
                    .tag(0)

                RulePage()
                    .tag(1)

                FeaturesPage()
                    .tag(2)

                PermissionsPage()
                    .tag(3)
            }
            .tabViewStyle(.automatic)

            // Navigation
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .keyboardShortcut(.cancelAction)
                }

                Spacer()

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }

                Spacer()

                if currentPage < totalPages - 1 {
                    Button("Continue") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                } else {
                    Button("Get Started") {
                        completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding()
        }
        .frame(width: 600, height: 500)
    }

    private func completeOnboarding() {
        settings.completeOnboarding()
        isPresented = false
        dismiss()
    }
}

// MARK: - Welcome Page

struct WelcomePage: View {
    @State private var animateIcon = false
    @State private var animateGlow = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                // Animated glow rings
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .cyan.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: CGFloat(120 + index * 40), height: CGFloat(120 + index * 40))
                        .scaleEffect(animateGlow ? 1.2 : 1.0)
                        .opacity(0.5 - Double(index) * 0.15)
                        .animation(
                            .easeInOut(duration: 2.0 + Double(index) * 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.3),
                            value: animateGlow
                        )
                }

                // Main icon with gradient
                Image(systemName: "eye.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 20)
                    .scaleEffect(animateIcon ? 1.0 : 0.8)
                    .rotationEffect(.degrees(animateIcon ? 0 : -10))
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    animateIcon = true
                }
                animateGlow = true
            }

            VStack(spacing: 12) {
                Text("Welcome to EyeBreak")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                    Text("Your eyes deserve a break")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                }
            }

            Text("""
            Spending hours in front of a screen can cause eye strain, headaches, \
            and fatigue. EyeBreak helps you take regular breaks to keep your eyes healthy.
            """)
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 400)
            .padding(.horizontal)

            Spacer()
        }
        .padding(40)
    }
}

// MARK: - Rule Page

struct RulePage: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("The 20-20-20 Rule")
                .font(.system(size: 36, weight: .bold, design: .rounded))

            VStack(spacing: 24) {
                RuleCard(
                    number: "20",
                    unit: "minutes",
                    description: "Work for 20 minutes",
                    icon: "desktopcomputer",
                    color: .blue
                )

                RuleCard(
                    number: "20",
                    unit: "feet",
                    description: "Look 20 feet away",
                    icon: "eye",
                    color: .green
                )

                RuleCard(
                    number: "20",
                    unit: "seconds",
                    description: "Rest for 20 seconds",
                    icon: "timer",
                    color: .orange
                )
            }

            Text("This simple technique reduces eye strain and keeps you productive.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Spacer()
        }
        .padding(40)
    }
}

// MARK: - Features Page

// MARK: - Permissions Page
