//
//  BreakOverlayContent.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

// What the overlay shows: the break itself and the completion state.
//
// System colours throughout, and no hex constant anywhere. `.secondary` is not
// used: over a veiled desktop it is the first thing to fail.

extension BreakOverlayView {
    /// What a served break looks like while it waits. No countdown, because
    /// nothing is counting, and one control, because there is one thing to do.
    var completionContent: some View {
        VStack(spacing: 28) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(.tint)

            Text("Break Complete")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.primary)
                .accessibilityFocused($isMessageFocused)

            Text("Your next work interval starts when you dismiss this")
                .font(.title3)
                .foregroundStyle(.primary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }

    var standardBreakContent: some View {
        VStack(spacing: 28) {
            Image(systemName: "eye.slash")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(.tint)

            Text("Time for a Break")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.primary)
                .accessibilityFocused($isMessageFocused)

            Text("Look at something 20 feet away")
                .font(.title3)
                .foregroundStyle(.primary.opacity(0.8))
                .multilineTextAlignment(.center)

            timerDisplay
                .padding(.top, 8)
        }
    }
}
