//
//  BreakOverlayTimerDisplay.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

// The countdown ring and the two hint lines under it.

extension BreakOverlayView {
    var timerDisplay: some View {
        ZStack {
            // Outer decorative ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            currentTheme.accentColor.opacity(0.3),
                            currentTheme.backgroundColor.opacity(0.3),
                            currentTheme.accentColor.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 140, height: 140)

            // Background circle with glow
            Circle()
                .fill(currentTheme.backgroundColor.opacity(0.1))
                .frame(width: 130, height: 130)
                .overlay(
                    Circle()
                        .stroke(currentTheme.textColor.opacity(0.2), lineWidth: 8)
                )
                .shadow(color: currentTheme.accentColor.opacity(0.3), radius: 20)

            // Progress circle with beautiful animated gradient
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [
                            currentTheme.accentColor,
                            currentTheme.backgroundColor,
                            currentTheme.accentColor.opacity(0.8),
                            currentTheme.backgroundColor.opacity(0.8),
                            currentTheme.accentColor
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 130, height: 130)
                .rotationEffect(.degrees(-90))
                .shadow(color: currentTheme.accentColor.opacity(0.5), radius: 10)
                .animation(.linear(duration: 1), value: progress)

            // Countdown text with enhanced styling
            VStack(spacing: 4) {
                Text("\(countdown.remainingSeconds)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(currentTheme.textGradient())
                    .shadow(color: currentTheme.accentColor.opacity(0.5), radius: 10)
                    .contentTransition(.numericText())

                Text("seconds")
                    .font(.caption)
                    .foregroundColor(currentTheme.secondaryTextColor.opacity(currentTheme.secondaryTextOpacity))
                    .textCase(.uppercase)
                    .tracking(2)
            }

            // Rotating accent dots
            ForEach(0..<8) { index in
                Circle()
                    .fill(currentTheme.accentColor.opacity(0.6))
                    .frame(width: 4, height: 4)
                    .offset(y: -70)
                    .rotationEffect(.degrees(Double(index) * 45))
                    .rotationEffect(.degrees(Double(countdown.remainingSeconds) * 6))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: countdown.remainingSeconds)
            }
        }
        .frame(width: 140, height: 140)
    }

    /// The one control a served break offers. It ends the wait; it does not skip
    /// anything, because there is nothing left to skip.
    var dismissHint: some View {
        VStack(spacing: 12) {
            Button(action: endBreak) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12))
                    Text("Back to Work")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundColor(currentTheme.accentColor)
                .padding(.vertical, 10)
                .padding(.horizontal, 24)
                .background(
                    Capsule()
                        .fill(currentTheme.accentColor.opacity(0.12))
                )
                .overlay(
                    Capsule()
                        .stroke(currentTheme.accentColor.opacity(0.4), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
            .help("Start your next work interval")

            Text("Press ESC or click Back to Work to continue")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(currentTheme.secondaryTextColor.opacity(currentTheme.secondaryTextOpacity * 0.8))
        }
    }

    var skipHint: some View {
        VStack(spacing: 12) {
            // The overlay used to skip on a tap anywhere, which was safe only
            // because the first click was eaten by app activation. Now that the
            // first click lands, a stray one would end the break, so skipping
            // needs a deliberate target.
            Button(action: endBreak) {
                HStack(spacing: 8) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 12))
                    Text("Skip Break")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundColor(currentTheme.accentColor)
                .padding(.vertical, 10)
                .padding(.horizontal, 24)
                .background(
                    Capsule()
                        .fill(currentTheme.accentColor.opacity(0.12))
                )
                .overlay(
                    Capsule()
                        .stroke(currentTheme.accentColor.opacity(0.4), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
            .help("Skip this break")

            Text("Press ESC or click Skip Break to skip")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(currentTheme.secondaryTextColor.opacity(currentTheme.secondaryTextOpacity * 0.8))

            Text("(Not recommended—your eyes need this!)")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(currentTheme.secondaryTextColor.opacity(currentTheme.secondaryTextOpacity * 0.6))
        }
    }

    var progress: CGFloat {
        CGFloat(countdown.progress)
    }
}
