//
//  FloatingBreakWindow.swift
//  EyeBreak
//
//  Created on October 14, 2025.
//

import SwiftUI
import AppKit

/// A small, elegant floating window that appears during "Notification Only" breaks
class FloatingBreakWindow: NSWindow {

    static var shared: FloatingBreakWindow?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 320),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.hasShadow = true
        self.isMovableByWindowBackground = true

        // Position in bottom-right corner with padding
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.maxX - 360  // 20px padding (340 + 20)
            let y = screenFrame.minY + 40   // 40px from bottom for better visibility
            self.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    /// - Parameters:
    ///   - awaitsDismissal: Whether the panel holds a completion state at zero
    ///     instead of closing. `onDismiss` is reached only when it does.
    func show(
        duration: Int,
        awaitsDismissal: Bool = false,
        onSkip: @escaping () -> Void,
        onComplete: @escaping () -> Void,
        onDismiss: @escaping () -> Void = {}
    ) {
        let contentView = FloatingBreakContentView(
            duration: duration,
            awaitsDismissal: awaitsDismissal,
            onSkip: onSkip,
            onComplete: onComplete,
            onDismiss: onDismiss,
            window: self
        )

        self.contentView = NSHostingView(rootView: contentView)
        self.makeKeyAndOrderFront(nil)

        // Play notification sound
        NSSound.beep()

        // Animate in
        self.alphaValue = 0
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            self.animator().alphaValue = 1
        })

        FloatingBreakWindow.shared = self
    }

    func hide() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            self.animator().alphaValue = 0
        }, completionHandler: {
            self.orderOut(nil)
            FloatingBreakWindow.shared = nil
        })
    }

    // Prevent window from becoming key (so it doesn't steal focus)
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

// MARK: - Content View

struct FloatingBreakContentView: View {
    let duration: Int
    /// Whether zero swaps this panel to a completion state instead of closing it.
    let awaitsDismissal: Bool
    let onSkip: () -> Void
    let onComplete: () -> Void
    let onDismiss: () -> Void
    weak var window: FloatingBreakWindow?

    @State var remainingSeconds: Int
    @State private var timer: Timer?
    @State var progress: Double = 1.0
    @State private var isHovered: Bool = false
    @State private var isAwaitingDismissal: Bool = false

    init(
        duration: Int,
        awaitsDismissal: Bool,
        onSkip: @escaping () -> Void,
        onComplete: @escaping () -> Void,
        onDismiss: @escaping () -> Void,
        window: FloatingBreakWindow?
    ) {
        self.duration = duration
        self.awaitsDismissal = awaitsDismissal
        self.onSkip = onSkip
        self.onComplete = onComplete
        self.onDismiss = onDismiss
        self.window = window
        self._remainingSeconds = State(initialValue: duration)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with close button
            HStack {
                // App indicator with gradient icon
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.35), Color.cyan.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: .blue.opacity(0.2), radius: 4)

                        Image(systemName: "eye.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    Text("EyeBreak")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                }

                Spacer()

                // Enhanced close button with better visibility. It goes away
                // once the break is served: the completion state offers one
                // control, and a close button next to "Back to Work" would ask
                // the user which of two buttons ends the same wait.
                if !isAwaitingDismissal {
                    Button(action: handleSkip) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary.opacity(0.8))
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(Color.secondary.opacity(isHovered ? 0.2 : 0.12))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Close (or press ESC)")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 10)

            Divider()
                .opacity(0.4)

            // Main content with better spacing
            Group {
                if isAwaitingDismissal {
                    completionContent
                } else {
                    breakContent
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .frame(width: 340, height: 320)
        .background(
            ZStack {
                // Background with blur effect
                VisualEffectView()

                // Subtle border for definition
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .onAppear(perform: startTimer)
        .onDisappear(perform: stopTimer)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    // MARK: - Break Content

    // MARK: - Completion Content

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
                progress = Double(remainingSeconds) / Double(duration)
            } else {
                stopTimer()

                // `onComplete` is what announces the break, at zero, whether or
                // not the panel then waits. Only the closing differs.
                if awaitsDismissal {
                    isAwaitingDismissal = true
                } else {
                    window?.hide()
                }
                onComplete()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func handleSkip() {
        stopTimer()
        window?.hide()
        onSkip()
    }

    /// Ends the wait. `BreakTimerManager` closes the panel on its way through, so
    /// a dismissal from the popover instead of from here reaches the same place.
    func handleDismiss() {
        stopTimer()
        onDismiss()
    }
}

// MARK: - Floating Window Blur View (for macOS blur)
