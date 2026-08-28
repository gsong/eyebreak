//
//  ScreenBlurManager+Windows.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import AppKit
import SwiftUI

// The overlay windows: building them, closing them, and rebuilding when the displays change.

extension ScreenBlurManager {
    /// Covers every attached screen. A break that covers one of three displays
    /// is not modal: the other two stay visible and stay clickable.
    func buildOverlayWindows() {
        guard let countdown = self.countdown, let onSkip = self.skipHandler else { return }

        let screens = NSScreen.screens

        // The screen holding the pointer is the one the user was working on. It
        // takes key status, and its overlay is the one VoiceOver should land on.
        // Both are single-window jobs, so the other screens must not claim them.
        let mouseLocation = NSEvent.mouseLocation
        let pointerScreen = screens.first { NSMouseInRect(mouseLocation, $0.frame, false) } ?? screens.first

        for screen in screens {
            let window = self.createOverlayWindow(for: screen)

            // CRITICAL: Force window frame to this screen
            window.setFrame(screen.frame, display: true, animate: false)

            // Every screen shows the full break. The user may be looking at any
            // of them, and "the active screen" stops meaning anything once the
            // overlay holds focus.
            let overlayView = BreakOverlayView(
                countdown: countdown,
                onSkip: onSkip,
                claimsAccessibilityFocus: screen == pointerScreen
            )

            let hostingView = FirstMouseHostingView(rootView: overlayView)
            hostingView.frame = CGRect(origin: .zero, size: screen.frame.size)

            window.contentView = hostingView
            window.orderFrontRegardless()

            self.overlayWindows.append(window)
            self.hostingViews.append(hostingView)

            if screen == pointerScreen {
                self.keyOverlayWindow = window
            }
        }

        self.coveredFrames = Self.sortedFrames(of: screens)
    }

    func closeOverlayWindows() {
        self.close(self.overlayWindows)

        // Clear arrays
        self.overlayWindows.removeAll()
        self.hostingViews.removeAll()
        self.coveredFrames.removeAll()
        self.keyOverlayWindow = nil
    }

    private func close(_ windows: [NSWindow]) {
        // First, remove content views to break retain cycles
        for window in windows {
            window.contentView = nil
            window.orderOut(nil)
        }

        // Then close windows
        for window in windows {
            window.close()
        }
    }

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

    func startObservingScreenChanges() {
        guard self.screenChangeObserver == nil else { return }

        self.screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.rebuildOverlayWindowsIfScreensChanged()
        }
    }

    func stopObservingScreenChanges() {
        guard let observer = self.screenChangeObserver else { return }
        NotificationCenter.default.removeObserver(observer)
        self.screenChangeObserver = nil
    }

    /// Rebuilds the overlay for the screens attached right now. A display added
    /// mid-break must not stay an uncovered hole, and removing one must not end
    /// the break. The countdown is left alone, so the remaining time carries over.
    private func rebuildOverlayWindowsIfScreensChanged() {
        guard self.countdown != nil else { return }
        guard Self.sortedFrames(of: NSScreen.screens) != self.coveredFrames else { return }

        // Build the replacements before dropping the old windows. An overlay
        // that goes to zero windows, even for an instant, hands focus back to
        // whatever is underneath and stops being modal.
        let stale = self.overlayWindows
        self.overlayWindows.removeAll()
        self.hostingViews.removeAll()
        self.keyOverlayWindow = nil

        self.buildOverlayWindows()
        self.keyOverlayWindow?.makeKey()

        self.close(stale)
    }

    /// Screen frames in a fixed order. `NSScreen.screens` puts the main screen
    /// first, so choosing a different main display reorders it without moving a
    /// single pixel. Sorting keeps that out of the rebuild test.
    private static func sortedFrames(of screens: [NSScreen]) -> [CGRect] {
        screens.map(\.frame).sorted { lhs, rhs in
            (lhs.origin.x, lhs.origin.y, lhs.width, lhs.height)
                < (rhs.origin.x, rhs.origin.y, rhs.width, rhs.height)
        }
    }
}
