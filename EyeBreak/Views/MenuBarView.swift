//
//  MenuBarView.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var timerManager: BreakTimerManager
    @EnvironmentObject var settings: AppSettings
    @Environment(\.openWindow) var openWindow

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()

            // Status
            statusSection
                .padding()

            Divider()

            // Controls
            controlsSection
                .padding()

            Divider()

            // Quick Stats
            quickStatsSection
                .padding()

            Divider()

            // Bottom Actions
            bottomActionsSection
        }
        .frame(width: 300)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            ZStack {
                // Optimized: Simplified background circle without animation
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.cyan.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                // Eye icon - removed heavy animation
                Image(systemName: timerManager.state.isActive ? "eye.fill" : "eye")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("EyeBreak")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .transition(.opacity.combined(with: .scale))
            }

            Spacer()

            statusIndicator
        }
        .padding()
    }

    private var statusText: String {
        switch timerManager.state {
        case .idle: return "Ready to start"
        case .working: return "Working"
        case .preBreak: return "Break soon"
        case .breaking: return "On break"
        case .paused: return "Paused"
        case .awaitingDismissal: return "Break complete"
        }
    }

    private var statusIndicator: some View {
        ZStack {
            // Optimized: Simplified pulse rings - reduced animation complexity
            Circle()
                .fill(timerManager.state.isActive ? Color.green.opacity(0.3) : Color.clear)
                .frame(width: 16, height: 16)

            // Core indicator with gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: timerManager.state.isActive ?
                            [Color.green, Color.green.opacity(0.8)] :
                            [Color.gray, Color.gray.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 8, height: 8)
                .shadow(color: timerManager.state.isActive ? .green.opacity(0.5) : .clear, radius: 4)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: timerManager.state.isActive)
    }

    // MARK: - Status Section

    // MARK: - Controls Section

    // MARK: - Quick Stats Section

    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Progress")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                StatBadge(
                    icon: "checkmark.circle.fill",
                    value: "\(settings.getTodayStats().breaksCompleted)",
                    label: "Breaks",
                    color: .green
                )

                StatBadge(
                    icon: "flame.fill",
                    value: "\(settings.getTodayStats().breaksCompleted)/\(settings.dailyBreakGoal)",
                    label: "Goal",
                    color: .orange
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Bottom Actions Section

    private var bottomActionsSection: some View {
        VStack(spacing: 0) {
            Button { openWindow(id: "settings") } label: {
                HStack {
                    Label("Settings", systemImage: "gear")
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .hoverEffect()

            Divider()

            Button { NSApplication.shared.terminate(nil) } label: {
                HStack {
                    Label("Quit EyeBreak", systemImage: "xmark.circle")
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .hoverEffect()
        }
    }

    // MARK: - Helper Methods

}

// MARK: - Stat Badge Component

// MARK: - Enhanced Hover Effect

// MARK: - Professional Button Style
