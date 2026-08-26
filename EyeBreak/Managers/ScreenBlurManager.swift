//
//  ScreenBlurManager.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import AppKit
import SwiftUI

/// Manages full-screen blur overlay during breaks
class ScreenBlurManager {
    
    static let shared = ScreenBlurManager()
    
    private var overlayWindows: [NSWindow] = []
    private var hostingViews: [NSHostingView<BreakOverlayView>] = []
    /// The app that was frontmost when the break started. The overlay activates
    /// EyeBreak to take keyboard focus, so it has to hand focus back on the way out.
    private var previousFrontmostApp: NSRunningApplication?
    private let windowQueue = DispatchQueue(label: "com.eyebreak.window", qos: .userInteractive)
    
    enum OverlayStyle {
        case blur
        case exercise
    }
    
    private init() {}
    
    // MARK: - Public Methods
    
    func showBreakOverlay(duration: Int, style: OverlayStyle, onSkip: @escaping () -> Void) {
        
        // Optimize: Execute on main thread directly if already on main thread
        if Thread.isMainThread {
            self.showOverlayOnMainThread(duration: duration, style: style, onSkip: onSkip)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.showOverlayOnMainThread(duration: duration, style: style, onSkip: onSkip)
            }
        }
    }
    
    private func showOverlayOnMainThread(duration: Int, style: OverlayStyle, onSkip: @escaping () -> Void) {
        // Generate a new random color theme for this break overlay (if using random color theme)
        AppSettings.shared.regenerateBreakOverlayRandomTheme()
        
        // Close existing windows
        for window in self.overlayWindows {
            window.orderOut(nil)
        }
        self.overlayWindows.removeAll()
        self.hostingViews.removeAll()
        
        
        // Get the screen with mouse cursor (the active screen user is on)
        let mouseLocation = NSEvent.mouseLocation
        let activeScreen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) ?? NSScreen.main ?? NSScreen.screens[0]
        
        
        // Create overlay ONLY for the active screen where user is working
        let window = self.createOverlayWindow(for: activeScreen)
        
        // CRITICAL: Force window frame to the active screen
        window.setFrame(activeScreen.frame, display: true, animate: false)
        
        // Create the beautiful SwiftUI overlay view
        let overlayView = BreakOverlayView(
            duration: duration,
            style: style,
            onSkip: {
                // Ensure onSkip is called on main thread safely
                if Thread.isMainThread {
                    onSkip()
                } else {
                    DispatchQueue.main.async {
                        onSkip()
                    }
                }
            }
        )
        
        let hostingView = FirstMouseHostingView(rootView: overlayView)
        hostingView.frame = activeScreen.frame
        
        window.contentView = hostingView
        
        // Remember who had focus so the break can hand it back. Ignore EyeBreak
        // itself, or a preview started from Settings would make us the app we
        // return to.
        let frontmost = NSWorkspace.shared.frontmostApplication
        if frontmost?.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            self.previousFrontmostApp = frontmost
        }
        
        // The overlay has to be modal. ESC runs off a local event monitor, which
        // only sees events macOS already routed to EyeBreak, and macOS routes
        // keys to the frontmost app. So the app activates and the window takes
        // key status. The window joins all Spaces, so EyeBreak always has a
        // window on the current one, which is what keeps activation from
        // switching Spaces.
        NSApp.activate()
        window.orderFrontRegardless()
        window.makeKey()
        
        
        self.overlayWindows.append(window)
        self.hostingViews.append(hostingView)
        
    }
    
    func hideOverlay() {
        
        // Optimize: Execute on main thread directly if already on main thread
        if Thread.isMainThread {
            self.hideOverlayOnMainThread()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.hideOverlayOnMainThread()
            }
        }
    }
    
    private func hideOverlayOnMainThread() {
        
        // First, remove content views to break retain cycles
        for window in self.overlayWindows {
            window.contentView = nil
            window.orderOut(nil)
        }
        
        // Then close windows
        for window in self.overlayWindows {
            window.close()
        }
        
        // Clear arrays
        self.overlayWindows.removeAll()
        self.hostingViews.removeAll()
        
        // Give focus back to whatever the break interrupted. Every way out of a
        // break — timer expiry, ESC, the Skip button, and Stop or Pause from the
        // menu — ends up here.
        //
        // `from: .current` tells macOS that EyeBreak is yielding, which is what
        // lets the other app take focus under cooperative activation.
        if let previous = self.previousFrontmostApp {
            self.previousFrontmostApp = nil
            _ = previous.activate(from: .current)
        }
    }
    
    // MARK: - Private Methods
    
    private func createOverlayWindow(for screen: NSScreen) -> NSWindow {
        let window = BreakOverlayWindow(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))  // Highest possible level - above everything
        window.backgroundColor = .clear  // Clear background for blur effect
        window.isOpaque = false  // Allow transparency
        window.hasShadow = false
        window.ignoresMouseEvents = false
        // CRITICAL: Use .canJoinAllSpaces to show on ALL desktops simultaneously
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .transient]
        window.acceptsMouseMovedEvents = true
        window.isReleasedWhenClosed = false
        window.animationBehavior = .none
        window.alphaValue = 1.0  // Full opacity
        window.hidesOnDeactivate = false
        window.canHide = false
        
        return window
    }
}

// MARK: - Custom Content View

/// Hosting view that takes the click which activates EyeBreak instead of
/// swallowing it. Without this the first click on the overlay only brings the
/// app forward, and a skip needs two clicks.
private final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}

// MARK: - Custom Window Class

/// Custom NSWindow that can become key window even when borderless
class BreakOverlayWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}

// MARK: - Sound Manager

class SoundManager {
    
    static let shared = SoundManager()
    
    enum SoundType {
        case start
        case breakStart
        case breakEnd
        case skip
    }
    
    private init() {}
    
    func playSound(_ type: SoundType) {
        let soundName: NSSound.Name
        
        switch type {
        case .start:
            soundName = .init("Blow")
        case .breakStart:
            soundName = .init("Glass")
        case .breakEnd:
            soundName = .init("Purr")
        case .skip:
            soundName = .init("Tink")
        }
        
        NSSound(named: soundName)?.play()
    }
}
