//
//  AboutView.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

// The About tab: version, permissions, feature list, and links.

/// Shows whether the global shortcuts can actually fire. Because EyeBreak is
/// ad-hoc signed, macOS revokes this grant every time the app is reinstalled,
/// so there needs to be a visible way to notice and restore it.
struct KeyboardShortcutsCard: View {
    @ObservedObject var permission: AccessibilityPermission

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: permission.isTrusted ? "keyboard.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(permission.isTrusted ? .blue : .orange)
                Text("Keyboard Shortcuts")
                    .font(.system(size: 14, weight: .semibold))

                Spacer()

                Text(permission.isTrusted ? "Enabled" : "Needs permission")
                    .font(.system(size: 11))
                    .foregroundColor(permission.isTrusted ? .secondary : .orange)
            }

            if !permission.isTrusted {
                Text("""
                macOS resets this permission whenever EyeBreak is reinstalled, which stops \u{2318}\u{21E7}B \
                and the other shortcuts from working, and stops breaks from holding the keyboard. \
                Timers and break reminders are unaffected.
                """)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Open Accessibility Settings") {
                    permission.openAccessibilitySettings()
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill((permission.isTrusted ? Color.blue : Color.orange).opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke((permission.isTrusted ? Color.blue : Color.orange).opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
    }
}

struct AboutView: View {
    @EnvironmentObject var settings: AppSettings
    @StateObject private var accessibility = AccessibilityPermission.shared
    @State private var isHoveringGithub = false
    @State private var isHoveringIssue = false

    /// Read from the bundle so this never drifts from the shipped version.
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                // App Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.2), Color.cyan.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: "eye.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: .blue.opacity(0.2), radius: 15)
                .padding(.top, 24)

                VStack(spacing: 6) {
                    Text("EyeBreak")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Version \(appVersion)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }

                KeyboardShortcutsCard(permission: accessibility)

                // Description Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                        Text("About")
                            .font(.system(size: 14, weight: .semibold))
                    }

                    Text("""
                        EyeBreak helps you reduce digital eye strain by following the 20-20-20 rule: \
                        Every 20 minutes, look at something 20 feet away for 20 seconds. \
                        Built with privacy in mind—all your data stays on your Mac.
                        """)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineSpacing(3)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: .black.opacity(0.05), radius: 8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                )

                // Features Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.orange)
                        Text("Key Features")
                            .font(.system(size: 14, weight: .semibold))
                    }

                    VStack(spacing: 8) {
                        FeatureRow(icon: "eye.fill", title: "20-20-20 Rule", description: "Scientifically-backed eye care")
                        FeatureRow(icon: "timer", title: "Smart Timer", description: "Automatic break reminders")
                        FeatureRow(icon: "drop.fill", title: "Water Reminders", description: "Stay hydrated")
                        FeatureRow(icon: "sparkles", title: "Ambient Reminders", description: "Gentle exercise prompts")
                        FeatureRow(icon: "calendar", title: "Smart Schedule", description: "Respects your work hours")
                        FeatureRow(icon: "lock.fill", title: "Privacy First", description: "All data stays local")
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: .black.opacity(0.05), radius: 8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.orange.opacity(0.1), lineWidth: 1)
                )

                // Links
                HStack(spacing: 16) {
                    Link(destination: URL(string: "https://github.com/gsong/eyebreak")!) {
                        HStack {
                            Image(systemName: "link")
                            Text("GitHub")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue.opacity(isHoveringGithub ? 0.15 : 0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                        .scaleEffect(isHoveringGithub ? 1.02 : 1.0)
                    }
                    .onHover { isHoveringGithub = $0 }
                    .animation(.easeOut(duration: 0.15), value: isHoveringGithub)

                    Link(destination: URL(string: "https://github.com/gsong/eyebreak/issues")!) {
                        HStack {
                            Image(systemName: "exclamationmark.bubble")
                            Text("Report Issue")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.orange.opacity(isHoveringIssue ? 0.15 : 0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                        )
                        .scaleEffect(isHoveringIssue ? 1.02 : 1.0)
                    }
                    .onHover { isHoveringIssue = $0 }
                    .animation(.easeOut(duration: 0.15), value: isHoveringIssue)
                }

                // Copyright
                Text("© 2025 EyeBreak. All rights reserved.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 32)
            .frame(maxWidth: 550)
        }
    }
}
