//
//  BreakSettingsStylePreview.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

// The Break Style and Eye Exercise sections, and the preview button behind them.

extension BreakSettingsView {
    var breakStyleSection: some View {
        Section {
            VStack(spacing: 12) {
                ForEach(BreakStyle.allCases) { style in
                    BreakStyleOptionCard(
                        style: style,
                        isSelected: settings.breakStyle == style
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            settings.breakStyle = style
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Toggle("Wait for me to dismiss the break", isOn: $settings.requireBreakDismissal)
                        .toggleStyle(.switch)

                    Text("The break is counted when it ends, but the screen stays up and your next work interval does not start until you dismiss it.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: previewBreakStyle) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Preview Break Style")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.purple, .purple.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ProfessionalButtonStyle(color: .purple))
            }
        } header: {
            SectionHeaderView(title: "Break Style", icon: "sparkles.rectangle.stack.fill", color: .purple)
        } footer: {
            // The panic chord has to be written down somewhere a user can
            // find it, because the moment they need it is the moment the
            // keyboard is doing something they did not expect. The claim is
            // gated on the grant, which is missing after every update.
            if accessibility.isTrusted {
                Text("""
                Blur Screen and Eye Exercise hold the keyboard for the length of the break, so \
                shortcuts in other apps stay quiet. Press \u{238B} to end a break early. \
                \u{2303}\u{2325}\u{2318}\u{238B} releases the keyboard and ends the break if \
                anything goes wrong. \u{2318}\u{2325}\u{238B} still reaches Force Quit, but it \
                opens behind the overlay.
                """)
                    .font(.caption)
            } else {
                Text("""
                Blur Screen and Eye Exercise cover every display, and \u{238B} ends a break \
                early. Holding the keyboard as well needs Accessibility permission, which \
                macOS resets on every update — see Keyboard Shortcuts under About. Until \
                then, shortcuts in other apps still work during a break.
                """)
                    .font(.caption)
            }
        }
    }

    var eyeExerciseSection: some View {
        Section {
            VStack(spacing: 12) {
                EnhancedSliderCard(
                    title: "Exercise Interval",
                    value: settings.exerciseIntervalSeconds,
                    unit: "sec",
                    icon: "arrow.triangle.2.circlepath",
                    color: .cyan,
                    range: 2...10
                ) { newValue in
                    settings.exerciseIntervalSeconds = Int(newValue)
                }

                EnhancedSliderCard(
                    title: "Exercise Duration",
                    value: settings.eyeExerciseDurationSeconds / 60,
                    unit: "min",
                    icon: "figure.walk",
                    color: .teal,
                    range: 1...30
                ) { newValue in
                    settings.eyeExerciseDurationSeconds = Int(newValue) * 60
                }

                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("Exercise interval controls how long to hold each eye position")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 4)
            }
        } header: {
            SectionHeaderView(title: "Eye Exercise", icon: "eye.circle.fill", color: .cyan)
        }
    }

    private func previewBreakStyle() {
        switch settings.breakStyle {
        case .blurScreen:
            // Show 5-second preview of blur with proper cleanup
            ScreenBlurManager.shared.showBreakOverlay(
                duration: 5,
                style: .blur,
                awaitsDismissal: false
            ) {
                // When user clicks skip, hide the overlay
                ScreenBlurManager.shared.hideOverlay()
            }

            // Auto-hide after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                ScreenBlurManager.shared.hideOverlay()
            }

        case .notificationOnly:
            // Show 5-second preview of floating window
            let window = FloatingBreakWindow()
            window.show(
                duration: 5,
                onSkip: {
                    window.hide()
                },
                onComplete: {
                    window.hide()
                }
            )

        case .eyeExercise:
            // Show 5-second preview of exercise with proper cleanup
            ScreenBlurManager.shared.showBreakOverlay(
                duration: 5,
                style: .exercise,
                awaitsDismissal: false
            ) {
                // When user clicks skip, hide the overlay
                ScreenBlurManager.shared.hideOverlay()
            }

            // Auto-hide after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                ScreenBlurManager.shared.hideOverlay()
            }
        }
    }
}
