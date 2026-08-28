//
//  SettingsView.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var timerManager: BreakTimerManager
    @EnvironmentObject var settings: AppSettings
    @Environment(\.openWindow) var openWindow

    @State private var selectedTab: Tab = .general

    enum Tab: String, CaseIterable {
        case general = "General"
        case breaks = "Breaks"
        case about = "About"

        var icon: String {
            switch self {
            case .general: return "gearshape.fill"
            case .breaks: return "timer"
            case .about: return "info.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .general: return .gray
            case .breaks: return .blue
            case .about: return .purple
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(Tab.allCases, id: \.self, selection: $selectedTab) { tab in
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(selectedTab == tab ? tab.color.opacity(0.15) : Color.clear)
                            .frame(width: 28, height: 28)

                        Image(systemName: tab.icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(selectedTab == tab ? tab.color : .secondary)
                    }

                    Text(tab.rawValue)
                        .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                        .foregroundColor(selectedTab == tab ? .primary : .secondary)
                }
                .padding(.vertical, 4)
                .tag(tab)
            }
            .navigationSplitViewColumnWidth(160)
            .listStyle(.sidebar)
        } detail: {
            VStack(spacing: 0) {
                // Large Countdown Timer Display at the top
                TimerStatusBanner()
                    .environmentObject(timerManager)
                    .environmentObject(settings)

                Divider()

                // Main content with smooth transition
                Group {
                    switch selectedTab {
                    case .general:
                        GeneralSettingsView()
                    case .breaks:
                        BreakSettingsView()
                    case .about:
                        AboutView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
                .id(selectedTab) // Force view recreation for animation
            }
        }
        .navigationTitle("EyeBreak Settings")
    }
}

// MARK: - Unified Countdown Display Component

// MARK: - Countdown Row Component

// MARK: - General Settings

// MARK: - Break Settings

// MARK: - Keyboard Shortcuts Permission Card

// MARK: - About View

// MARK: - Timer Status Banner

// MARK: - Section Header View

// MARK: - Settings Section Card

// MARK: - Enhanced Slider Card Component

// MARK: - Custom Icon Picker View

// MARK: - Icon Option Button

// MARK: - Custom Water Icon Picker View

// MARK: - Water Icon Option Button

// MARK: - Smart Schedule View

// MARK: - Day Button Component
