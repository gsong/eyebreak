//
//  WaterReminderViews.swift
//  EyeBreak
//
//  Created on October 18, 2025.
//

import SwiftUI
import AppKit
import UserNotifications
import Combine

// The SwiftUI surfaces a water reminder appears in, and the window hosting the full-screen one.

struct WaterReminderView: View {
    let message: WaterMessage
    let onDismiss: () -> Void

    @State private var isVisible = false

    var body: some View {
        ZStack {
            // Glass morphism background with theme colors - using backgroundGradient() for proper opacity
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(message.theme.backgroundGradient())
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            message.theme.borderGradient(),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 5)
                .shadow(color: message.theme.accentColor.opacity(0.25), radius: 20, x: 0, y: 8)

            HStack(spacing: 16) {
                // Water icon - using SF Symbol with theme colors
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    message.theme.backgroundColor.opacity(message.theme.backgroundOpacity * 0.4),
                                    message.theme.accentColor.opacity(message.theme.accentOpacity * 0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: message.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    message.theme.backgroundColor,
                                    message.theme.accentColor
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolRenderingMode(.hierarchical)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(message.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(message.theme.textColor.opacity(message.theme.textOpacity))

                    Text(message.message)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(message.theme.secondaryTextColor.opacity(message.theme.secondaryTextOpacity))
                        .lineLimit(2)
                }

                Spacer()

                // Dismiss button
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                        .opacity(0.6)
                }
                .buttonStyle(.plain)
                .help("Dismiss")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(width: 420, height: 110)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -20)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
}

/// Full screen blur overlay for water reminder (similar to break overlay)
struct WaterBlurOverlayView: View {
    let message: WaterMessage
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // Blur background
            VisualEffectBlur()
                .ignoresSafeArea()

            // Gradient overlay with theme colors
            LinearGradient(
                colors: [
                    message.theme.backgroundColor.opacity(message.theme.backgroundOpacity * 0.6),
                    message.theme.backgroundColor.opacity(message.theme.backgroundOpacity * 0.4),
                    message.theme.accentColor.opacity(message.theme.accentOpacity * 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                // Water icon with animation
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    message.theme.accentColor.opacity(message.theme.accentOpacity * 0.4),
                                    message.theme.accentColor.opacity(0)
                                ],
                                center: .center,
                                startRadius: 40,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)

                    // Icon background circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    message.theme.backgroundColor.opacity(message.theme.backgroundOpacity * 0.8),
                                    message.theme.accentColor.opacity(message.theme.accentOpacity * 0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(
                                    message.theme.borderGradient(),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)

                    // Water icon
                    Image(systemName: message.icon)
                        .font(.system(size: 56, weight: .light, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    message.theme.textColor.opacity(message.theme.textOpacity)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolRenderingMode(.hierarchical)
                }
                .scaleEffect(scale)

                // Message content
                VStack(spacing: 16) {
                    Text(message.title)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(message.theme.textColor.opacity(message.theme.textOpacity))
                        .multilineTextAlignment(.center)

                    Text(message.message)
                        .font(.system(size: 20, weight: .regular, design: .rounded))
                        .foregroundColor(message.theme.secondaryTextColor.opacity(message.theme.secondaryTextOpacity))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 60)

                // Gentle dismiss button - no countdown, user chooses when to dismiss
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        scale = 0.5
                        opacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onDismiss()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 18))
                        Text("Thanks, I'll drink water now")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        message.theme.backgroundColor,
                                        message.theme.accentColor
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: message.theme.accentColor.opacity(0.4), radius: 15, x: 0, y: 8)
                }
                .buttonStyle(.plain)
                .padding(.top, 16)
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

/// Custom window class for water reminder overlay with proper key/main window handling
class WaterReminderWindow: NSWindow {
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }
}

/// Helper view for creating blur effect background
struct VisualEffectBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .hudWindow
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
