//
//  FloatingBreakContent.swift
//  EyeBreak
//
//  Created on October 14, 2025.
//

import SwiftUI
import AppKit

// What the floating panel shows during a break and once it is complete.

extension FloatingBreakContentView {
    var breakContent: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Take a Break")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Look 20 feet away for 20 seconds")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            // Circular progress timer with enhanced styling
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.blue.opacity(0.1), lineWidth: 8)
                    .frame(width: 110, height: 110)

                // Progress ring with gradient
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [.blue, .cyan, .blue],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                    .shadow(color: .blue.opacity(0.3), radius: 4)

                VStack(spacing: 2) {
                    Text("\(remainingSeconds)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .contentTransition(.numericText())
                    Text("seconds")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            // Enhanced skip button with clear outline style
            Button(action: handleSkip) {
                HStack(spacing: 6) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 11))
                    Text("Skip Break")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.blue)
                .padding(.vertical, 10)
                .padding(.horizontal, 24)
                .background(
                    Capsule()
                        .fill(Color.blue.opacity(0.12))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.blue.opacity(0.4), lineWidth: 1.5)
                )
                .shadow(color: .blue.opacity(0.15), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .help("Skip this break")
        }
    }

    /// What the panel shows once the break has been served. This style installs
    /// no keyboard tap and the panel cannot become key, so a click is the only
    /// way out of it.
    var completionContent: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Break Complete")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Your next work interval starts when you dismiss this")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .blue.opacity(0.3), radius: 8)
                .frame(height: 110)

            Button(action: handleDismiss) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11))
                    Text("Back to Work")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.blue)
                .padding(.vertical, 10)
                .padding(.horizontal, 24)
                .background(
                    Capsule()
                        .fill(Color.blue.opacity(0.12))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.blue.opacity(0.4), lineWidth: 1.5)
                )
                .shadow(color: .blue.opacity(0.15), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .help("Start your next work interval")
        }
    }
}
