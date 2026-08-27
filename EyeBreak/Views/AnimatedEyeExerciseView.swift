//
//  AnimatedEyeExerciseView.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

// The guided eye-exercise animation, and the blur backing it sits on.

struct AnimatedEyeExerciseView: View {
    let remainingSeconds: Int
    let totalDuration: Int

    @ObservedObject private var settings = AppSettings.shared

    private var currentTheme: ColorTheme {
        settings.breakOverlayTheme
    }

    /// Where to look, worked out from the clock rather than from a timer of this
    /// view's own. Every screen runs this view, so a timer each would put the
    /// displays on different directions, and a rebuild would restart the pattern.
    private var currentDirection: ExerciseDirection {
        let interval = max(1, settings.exerciseIntervalSeconds)
        let elapsed = max(0, totalDuration - remainingSeconds)
        return exercisePattern[(elapsed / interval) % exercisePattern.count]
    }

    enum ExerciseDirection: String {
        case center = "Look at Center"
        case left = "Look Left"
        case right = "Look Right"
        case up = "Look Up"
        case down = "Look Down"
        case topLeft = "Look Top-Left"
        case topRight = "Look Top-Right"
        case bottomLeft = "Look Bottom-Left"
        case bottomRight = "Look Bottom-Right"

        var offset: (x: CGFloat, y: CGFloat) {
            switch self {
            case .center: return (0, 0)
            case .left: return (-250, 0)
            case .right: return (250, 0)
            case .up: return (0, -200)
            case .down: return (0, 200)
            case .topLeft: return (-200, -150)
            case .topRight: return (200, -150)
            case .bottomLeft: return (-200, 150)
            case .bottomRight: return (200, 150)
            }
        }

        var color: Color {
            switch self {
            case .center: return .white
            case .left, .right: return .blue
            case .up, .down: return .green
            case .topLeft, .topRight, .bottomLeft, .bottomRight: return .purple
            }
        }

        var iconName: String {
            switch self {
            case .center: return "circle.fill"
            case .left: return "arrow.left.circle.fill"
            case .right: return "arrow.right.circle.fill"
            case .up: return "arrow.up.circle.fill"
            case .down: return "arrow.down.circle.fill"
            case .topLeft: return "arrow.up.left.circle.fill"
            case .topRight: return "arrow.up.right.circle.fill"
            case .bottomLeft: return "arrow.down.left.circle.fill"
            case .bottomRight: return "arrow.down.right.circle.fill"
            }
        }
    }

    let exercisePattern: [ExerciseDirection] = [
        .center, .left, .center, .right,
        .center, .up, .center, .down,
        .center, .topLeft, .center, .topRight,
        .center, .bottomLeft, .center, .bottomRight
    ]

    var body: some View {
        VStack(spacing: 40) {
            // Title
            Text("Eye Exercise")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(currentTheme.textGradient())
                .shadow(color: Color.black.opacity(0.3), radius: 10)

            // Optimized: Reduced exercise area size to reduce rendering load
            ZStack {
                // Background guide
                Circle()
                    .strokeBorder(currentTheme.textColor.opacity(0.2), lineWidth: 2)
                    .frame(width: 400, height: 400)

                // Horizontal guide line
                Rectangle()
                    .fill(currentTheme.textColor.opacity(0.1))
                    .frame(width: 400, height: 2)

                // Vertical guide line
                Rectangle()
                    .fill(currentTheme.textColor.opacity(0.1))
                    .frame(width: 2, height: 400)

                // Center reference point
                Circle()
                    .fill(currentTheme.textColor.opacity(0.3))
                    .frame(width: 20, height: 20)

                // Optimized: Simplified animated moving dot
                ZStack {
                    // Main dot (removed glow effect to improve performance)
                    Circle()
                        .fill(currentDirection.color)
                        .frame(width: 50, height: 50)
                        .shadow(color: currentDirection.color.opacity(0.5), radius: 10)

                    // Icon indicator
                    Image(systemName: currentDirection.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(currentTheme.textColor)
                }
                .offset(x: currentDirection.offset.x * 0.65, y: currentDirection.offset.y * 0.65)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: currentDirection)
            }
            .frame(height: 400)

            // Direction instruction
            VStack(spacing: 12) {
                Text(currentDirection.rawValue)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(currentDirection.color)
                    .shadow(color: Color.black.opacity(0.3), radius: 10)
                    .animation(.easeInOut(duration: 0.3), value: currentDirection)

                Text("Follow the moving dot with your eyes")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(currentTheme.textColor.opacity(currentTheme.textOpacity * 0.9))
            }
            .padding(20)
            .background(currentTheme.backgroundColor.opacity(0.2))
            .cornerRadius(16)

            // Timer countdown
            Text("Break ends in: \(remainingSeconds)s")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(currentTheme.textColor.opacity(currentTheme.textOpacity))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(currentTheme.backgroundColor.opacity(0.25))
                .cornerRadius(12)
        }
    }
}
