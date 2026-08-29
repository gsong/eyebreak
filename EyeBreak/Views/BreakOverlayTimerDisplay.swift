//
//  BreakOverlayTimerDisplay.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

// The countdown ring and the hint under it.

extension BreakOverlayView {
    /// A plain ring around the time left. The number reads `M:SS`, the same
    /// format the status button shows, so the two surfaces never disagree about
    /// the same instant.
    var timerDisplay: some View {
        ZStack {
            Circle()
                .stroke(.primary.opacity(0.2), lineWidth: 6)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(.tint, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)

            Text(TimeFormat.compact(countdown.remainingSeconds))
                .font(.system(size: 44, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
        }
        .frame(width: 128, height: 128)
    }

    /// The one control a served break offers. It ends the wait; it does not skip
    /// anything, because there is nothing left to skip.
    var dismissHint: some View {
        VStack(spacing: 10) {
            Button("Back to Work", action: endBreak)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .help("Start your next work interval")

            Text("Press ESC to continue")
                .font(.footnote)
                .foregroundStyle(.primary.opacity(0.65))
        }
    }

    var skipHint: some View {
        VStack(spacing: 10) {
            // The overlay used to skip on a tap anywhere, which was safe only
            // because the first click was eaten by app activation. Now that the
            // first click lands, a stray one would end the break, so skipping
            // needs a deliberate target.
            Button("Skip Break", action: endBreak)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .help("Skip this break")

            Text("Press ESC to skip")
                .font(.footnote)
                .foregroundStyle(.primary.opacity(0.65))
        }
    }

    var progress: CGFloat {
        CGFloat(countdown.progress)
    }
}
