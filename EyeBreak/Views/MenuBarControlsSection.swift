//
//  MenuBarControlsSection.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

// The start, stop, and break-now buttons.

extension MenuBarView {
    var controlsSection: some View {
        VStack(spacing: 12) {
            if timerManager.state == .idle {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        timerManager.start()
                    }
                } label: {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                        Text("Start Timer")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .professionalButtonStyle(color: .blue)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: timerManager.state)

            } else if timerManager.state.isActive {
                HStack(spacing: 8) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            timerManager.stop()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "stop.circle.fill")
                            Text("Stop")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .professionalButtonStyle(color: .red, isOutlined: true)

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            timerManager.takeBreakNow()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "eye.slash.circle.fill")
                            Text("Break Now")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(color: .green.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    .professionalButtonStyle(color: .green)
                }
            } else if case .awaitingDismissal = timerManager.state {
                // The overlay sits in front of this in normal use, so the button
                // is here as a way back if the overlay never appeared.
                Button(action: timerManager.dismissBreak) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        Text("Back to Work")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .professionalButtonStyle(color: .green)

            } else if case .paused = timerManager.state {
                Button(action: timerManager.resume) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                        Text("Resume Timer")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        LinearGradient(
                            colors: [.orange, .orange.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .professionalButtonStyle(color: .orange)
            }
        }
    }
}
