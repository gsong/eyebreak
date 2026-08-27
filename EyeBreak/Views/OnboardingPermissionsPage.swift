//
//  OnboardingPermissionsPage.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI
import UserNotifications

// The onboarding page asking for Notifications and Screen Recording.

struct PermissionsPage: View {
    @State private var notificationGranted = false
    @State private var screenRecordingGranted = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Permissions Needed")
                .font(.system(size: 36, weight: .bold, design: .rounded))

            Text("EyeBreak needs a few permissions to work properly")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 16) {
                PermissionCard(
                    icon: "bell.badge.fill",
                    title: "Notifications",
                    description: "To remind you when it's time for a break",
                    required: true,
                    granted: notificationGranted
                ) {
                    requestNotifications()
                }

                PermissionCard(
                    icon: "eye.slash.fill",
                    title: "Screen Recording",
                    description: "To blur your screen during breaks",
                    required: false,
                    granted: screenRecordingGranted
                ) {
                    openScreenRecordingSettings()
                }
            }
            .frame(width: 450)

            Text("You can change these permissions anytime in System Settings.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(40)
    }

    private func requestNotifications() {
        NotificationManager.shared.requestAuthorization()
        // Give it a moment then check status
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            checkNotificationStatus()
        }
    }

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationGranted = settings.authorizationStatus == .authorized
            }
        }
    }

    private func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let required: Bool
    let granted: Bool
    let action: () -> Void

    @State private var animate = false
    @State private var isHovered = false

    private var cardColor: Color {
        granted ? .green : (required ? .orange : .blue)
    }

    var body: some View {
        HStack(spacing: 20) {
            // Enhanced icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [cardColor.opacity(0.2), cardColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: cardColor.opacity(0.2), radius: 8)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [cardColor, cardColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(animate ? 1.0 : 0.8)
            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: animate)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    if required && !granted {
                        Text("Required")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.red.opacity(0.15))
                            )
                            .foregroundColor(.red)
                    }
                }

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if granted {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                Button(action: action) {
                    Text("Grant")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [cardColor, cardColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: cardColor.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(.plain)
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .animation(.easeOut(duration: 0.15), value: isHovered)
                .onHover { isHovered = $0 }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardColor.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [cardColor.opacity(0.3), cardColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: cardColor.opacity(0.1), radius: 8, x: 0, y: 4)
        .onAppear {
            animate = true
        }
    }
}
