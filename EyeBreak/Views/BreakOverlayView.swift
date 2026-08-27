//
//  BreakOverlayView.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

struct BreakOverlayView: View {
    /// The clock for the whole break, shared with the overlay on every other
    /// screen. The view owns no timer of its own; N views counting separately
    /// would drift, and rebuilding the set on a display change would restart them.
    @ObservedObject var countdown: BreakCountdown
    let style: ScreenBlurManager.OverlayStyle
    let onSkip: () -> Void
    /// Whether this copy of the overlay takes VoiceOver focus. Every screen runs
    /// one, and only the screen the user was working on should claim it.
    let claimsAccessibilityFocus: Bool

    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    @AccessibilityFocusState var isMessageFocused: Bool

    // Get the color theme from settings
    @ObservedObject private var settings = AppSettings.shared

    var currentTheme: ColorTheme {
        settings.breakOverlayTheme
    }

    init(
        countdown: BreakCountdown,
        style: ScreenBlurManager.OverlayStyle,
        onSkip: @escaping () -> Void,
        claimsAccessibilityFocus: Bool
    ) {
        self.countdown = countdown
        self.style = style
        self.onSkip = onSkip
        self.claimsAccessibilityFocus = claimsAccessibilityFocus
    }

    var body: some View {
        ZStack {
            // Theme-based background gradient
            currentTheme.backgroundGradient()
                .ignoresSafeArea()

            // Background blur
            VisualEffectView(
                material: .hudWindow,
                blendingMode: .behindWindow
            )
            .ignoresSafeArea()
            .opacity(0.8)

            // Dimming overlay with theme color
            currentTheme.backgroundColor.opacity(currentTheme.backgroundOpacity * 0.3)
                .ignoresSafeArea()

            // Optimized: Remove floating particles to reduce CPU usage

            // Content
            VStack(spacing: 40) {
                Spacer()

                // The break is either running or served. A served one shows the
                // same completion state whichever style ran it: the exercise is
                // over, so the dot and its instructions have nothing left to say.
                if countdown.isAwaitingDismissal {
                    completionContent
                } else {
                    switch style {
                    case .blur:
                        standardBreakContent
                    case .exercise:
                        eyeExerciseContent
                    }
                }

                Spacer()

                if countdown.isAwaitingDismissal {
                    dismissHint
                } else {
                    skipHint
                }
            }
            .padding(40)
            .opacity(opacity)
            .scaleEffect(scale)
        }
        .onAppear {
            startAnimation()
            if claimsAccessibilityFocus {
                isMessageFocused = true
            }
        }
        .onChange(of: countdown.isAwaitingDismissal) { _, isAwaiting in
            // The title the focus was on has just been replaced, so VoiceOver
            // needs pointing at the new one or the swap passes silently.
            if isAwaiting && claimsAccessibilityFocus {
                isMessageFocused = true
            }
        }
    }

    // MARK: - Completion Content

    // MARK: - Standard Break Content

    // MARK: - Eye Exercise Content

    // MARK: - Timer Display

    // MARK: - Dismiss Hint

    // MARK: - Skip Hint

    // MARK: - Computed Properties

    // MARK: - Methods

    /// The one way out the overlay offers, and the only thing either hint's
    /// button does. `BreakTimerManager` reads the state to decide what it means:
    /// skip a running break, dismiss a served one.
    func endBreak() {
        DispatchQueue.main.async {
            onSkip()
        }
    }

    private func startAnimation() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            opacity = 1
            scale = 1
        }
    }

}

// MARK: - Animated Eye Exercise View

// MARK: - Visual Effect View (for blur)

// MARK: - Optimized: Removed AnimatedGradientBackground and FloatingParticlesView to reduce CPU usage
// These heavy animation effects were causing performance issues
