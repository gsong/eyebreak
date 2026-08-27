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
    @AccessibilityFocusState private var isMessageFocused: Bool
    
    // Get the color theme from settings
    @ObservedObject private var settings = AppSettings.shared
    
    private var currentTheme: ColorTheme {
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
    
    /// What a served break looks like while it waits. No countdown, because
    /// nothing is counting, and one control, because there is one thing to do.
    private var completionContent: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                currentTheme.accentColor.opacity(0.3),
                                currentTheme.accentColor.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 140, height: 140)
                    .opacity(0.4)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                currentTheme.accentColor,
                                currentTheme.accentColor.opacity(0.8),
                                currentTheme.backgroundColor
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: currentTheme.accentColor.opacity(0.5), radius: 20)
            }
            
            Text("Break Complete")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(currentTheme.textGradient())
                .shadow(color: currentTheme.accentColor.opacity(0.3), radius: 10)
                .shadow(color: Color.black.opacity(0.3), radius: 10)
                .accessibilityFocused($isMessageFocused)
            
            Text("Your next work interval starts when you dismiss this")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(currentTheme.textColor.opacity(currentTheme.textOpacity))
                .multilineTextAlignment(.center)
                .shadow(color: Color.black.opacity(0.3), radius: 5)
        }
    }
    
    // MARK: - Standard Break Content
    
    private var standardBreakContent: some View {
        VStack(spacing: 32) {
            // Optimized: Simplified icon with minimal animation
            ZStack {
                // Single outer glow ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                currentTheme.accentColor.opacity(0.3),
                                currentTheme.accentColor.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 140, height: 140)
                    .opacity(0.4)
                
                // Main icon with gradient (no animation)
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                currentTheme.accentColor,
                                currentTheme.accentColor.opacity(0.8),
                                currentTheme.backgroundColor
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: currentTheme.accentColor.opacity(0.5), radius: 20)
            }
            
            // Title with gradient
            Text("Time for a Break")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(currentTheme.textGradient())
                .shadow(color: currentTheme.accentColor.opacity(0.3), radius: 10)
                .shadow(color: Color.black.opacity(0.3), radius: 10)
                .accessibilityFocused($isMessageFocused)
            
            // Instruction with subtle animation
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.left.and.right")
                        .font(.title2)
                        .foregroundColor(currentTheme.accentColor)
                    
                    Text("Look at something 20 feet away")
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundColor(currentTheme.textColor.opacity(currentTheme.textOpacity))
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundColor(currentTheme.accentColor.opacity(0.8))
                    Text("Give your eyes a rest")
                        .font(.callout)
                        .foregroundColor(currentTheme.secondaryTextColor.opacity(currentTheme.secondaryTextOpacity))
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundColor(currentTheme.accentColor.opacity(0.8))
                }
            }
            .multilineTextAlignment(.center)
            .shadow(color: Color.black.opacity(0.3), radius: 5)
            
            // Enhanced timer display
            timerDisplay
        }
    }
    
    // MARK: - Eye Exercise Content
    
    private var eyeExerciseContent: some View {
        AnimatedEyeExerciseView(
            remainingSeconds: countdown.remainingSeconds,
            totalDuration: countdown.totalSeconds
        )
    }
    
    // MARK: - Timer Display
    
    private var timerDisplay: some View {
        ZStack {
            // Outer decorative ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            currentTheme.accentColor.opacity(0.3),
                            currentTheme.backgroundColor.opacity(0.3),
                            currentTheme.accentColor.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 140, height: 140)
            
            // Background circle with glow
            Circle()
                .fill(currentTheme.backgroundColor.opacity(0.1))
                .frame(width: 130, height: 130)
                .overlay(
                    Circle()
                        .stroke(currentTheme.textColor.opacity(0.2), lineWidth: 8)
                )
                .shadow(color: currentTheme.accentColor.opacity(0.3), radius: 20)
            
            // Progress circle with beautiful animated gradient
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [
                            currentTheme.accentColor,
                            currentTheme.backgroundColor,
                            currentTheme.accentColor.opacity(0.8),
                            currentTheme.backgroundColor.opacity(0.8),
                            currentTheme.accentColor
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 130, height: 130)
                .rotationEffect(.degrees(-90))
                .shadow(color: currentTheme.accentColor.opacity(0.5), radius: 10)
                .animation(.linear(duration: 1), value: progress)
            
            // Countdown text with enhanced styling
            VStack(spacing: 4) {
                Text("\(countdown.remainingSeconds)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(currentTheme.textGradient())
                    .shadow(color: currentTheme.accentColor.opacity(0.5), radius: 10)
                    .contentTransition(.numericText())
                
                Text("seconds")
                    .font(.caption)
                    .foregroundColor(currentTheme.secondaryTextColor.opacity(currentTheme.secondaryTextOpacity))
                    .textCase(.uppercase)
                    .tracking(2)
            }
            
            // Rotating accent dots
            ForEach(0..<8) { index in
                Circle()
                    .fill(currentTheme.accentColor.opacity(0.6))
                    .frame(width: 4, height: 4)
                    .offset(y: -70)
                    .rotationEffect(.degrees(Double(index) * 45))
                    .rotationEffect(.degrees(Double(countdown.remainingSeconds) * 6))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: countdown.remainingSeconds)
            }
        }
        .frame(width: 140, height: 140)
    }
    
    // MARK: - Dismiss Hint
    
    /// The one control a served break offers. It ends the wait; it does not skip
    /// anything, because there is nothing left to skip.
    private var dismissHint: some View {
        VStack(spacing: 12) {
            Button(action: endBreak) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12))
                    Text("Back to Work")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundColor(currentTheme.accentColor)
                .padding(.vertical, 10)
                .padding(.horizontal, 24)
                .background(
                    Capsule()
                        .fill(currentTheme.accentColor.opacity(0.12))
                )
                .overlay(
                    Capsule()
                        .stroke(currentTheme.accentColor.opacity(0.4), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
            .help("Start your next work interval")
            
            Text("Press ESC or click Back to Work to continue")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(currentTheme.secondaryTextColor.opacity(currentTheme.secondaryTextOpacity * 0.8))
        }
    }
    
    // MARK: - Skip Hint
    
    private var skipHint: some View {
        VStack(spacing: 12) {
            // The overlay used to skip on a tap anywhere, which was safe only
            // because the first click was eaten by app activation. Now that the
            // first click lands, a stray one would end the break, so skipping
            // needs a deliberate target.
            Button(action: endBreak) {
                HStack(spacing: 8) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 12))
                    Text("Skip Break")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundColor(currentTheme.accentColor)
                .padding(.vertical, 10)
                .padding(.horizontal, 24)
                .background(
                    Capsule()
                        .fill(currentTheme.accentColor.opacity(0.12))
                )
                .overlay(
                    Capsule()
                        .stroke(currentTheme.accentColor.opacity(0.4), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
            .help("Skip this break")
            
            Text("Press ESC or click Skip Break to skip")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(currentTheme.secondaryTextColor.opacity(currentTheme.secondaryTextOpacity * 0.8))
            
            Text("(Not recommended—your eyes need this!)")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(currentTheme.secondaryTextColor.opacity(currentTheme.secondaryTextOpacity * 0.6))
        }
    }
    
    // MARK: - Computed Properties
    
    private var progress: CGFloat {
        CGFloat(countdown.progress)
    }
    
    // MARK: - Methods
    
    /// The one way out the overlay offers, and the only thing either hint's
    /// button does. `BreakTimerManager` reads the state to decide what it means:
    /// skip a running break, dismiss a served one.
    private func endBreak() {
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

// MARK: - Visual Effect View (for blur)

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Optimized: Removed AnimatedGradientBackground and FloatingParticlesView to reduce CPU usage
// These heavy animation effects were causing performance issues
