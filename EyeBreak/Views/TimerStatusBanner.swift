//
//  TimerStatusBanner.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

// The live timer strip pinned above the settings form.

struct TimerStatusBanner: View {
    @EnvironmentObject var timerManager: BreakTimerManager

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(timerManager.state.hasBreakOnScreen ? Color.green : Color.blue)
                .frame(width: 9, height: 9)

            Text(timerManager.state.displayText)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .contentTransition(.numericText())

            Spacer()

            // Two branches, not five. A break covers the screen above the menu
            // bar, and `.paused` resumes on the movement that reaches the
            // window, so idle and working are the only states anyone sees here.
            if case .idle = timerManager.state {
                Button("Start") { timerManager.start() }
            } else {
                Button("Stop") { timerManager.stop() }
                Button("Break Now") { timerManager.takeBreakNow() }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
    }
}
