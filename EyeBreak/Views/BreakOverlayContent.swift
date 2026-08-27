//
//  BreakOverlayContent.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

// What the overlay shows: the break itself, the eye exercise, and the completion state.

extension BreakOverlayView {
    /// What a served break looks like while it waits. No countdown, because
    /// nothing is counting, and one control, because there is one thing to do.
    var completionContent: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                currentTheme.accentColor.opacity(0.3),
                                currentTheme.accentColor.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 140, height: 140)
                    .opacity(0.4)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                currentTheme.accentColor,
                                currentTheme.accentColor.opacity(0.8),
                                currentTheme.backgroundColor
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: currentTheme.accentColor.opacity(0.5), radius: 20)
            }

            Text("Break Complete")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(currentTheme.textGradient())
                .shadow(color: currentTheme.accentColor.opacity(0.3), radius: 10)
                .shadow(color: Color.black.opacity(0.3), radius: 10)
                .accessibilityFocused($isMessageFocused)

            Text("Your next work interval starts when you dismiss this")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(currentTheme.textColor.opacity(currentTheme.textOpacity))
                .multilineTextAlignment(.center)
                .shadow(color: Color.black.opacity(0.3), radius: 5)
        }
    }

    var standardBreakContent: some View {
        VStack(spacing: 32) {
            // Optimized: Simplified icon with minimal animation
            ZStack {
                // Single outer glow ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                currentTheme.accentColor.opacity(0.3),
                                currentTheme.accentColor.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 140, height: 140)
                    .opacity(0.4)

                // Main icon with gradient (no animation)
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                currentTheme.accentColor,
                                currentTheme.accentColor.opacity(0.8),
                                currentTheme.backgroundColor
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: currentTheme.accentColor.opacity(0.5), radius: 20)
            }

            // Title with gradient
            Text("Time for a Break")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(currentTheme.textGradient())
                .shadow(color: currentTheme.accentColor.opacity(0.3), radius: 10)
                .shadow(color: Color.black.opacity(0.3), radius: 10)
                .accessibilityFocused($isMessageFocused)

            // Instruction with subtle animation
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.left.and.right")
                        .font(.title2)
                        .foregroundColor(currentTheme.accentColor)

                    Text("Look at something 20 feet away")
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundColor(currentTheme.textColor.opacity(currentTheme.textOpacity))
                }

                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundColor(currentTheme.accentColor.opacity(0.8))
                    Text("Give your eyes a rest")
                        .font(.callout)
                        .foregroundColor(currentTheme.secondaryTextColor.opacity(currentTheme.secondaryTextOpacity))
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundColor(currentTheme.accentColor.opacity(0.8))
                }
            }
            .multilineTextAlignment(.center)
            .shadow(color: Color.black.opacity(0.3), radius: 5)

            // Enhanced timer display
            timerDisplay
        }
    }

    var eyeExerciseContent: some View {
        AnimatedEyeExerciseView(
            remainingSeconds: countdown.remainingSeconds,
            totalDuration: countdown.totalSeconds
        )
    }
}
