//
//  BreakOverlayWindow.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import AppKit
import SwiftUI

// The window and hosting view the blur overlay is presented in.

/// Hosting view that takes the click which activates EyeBreak instead of
/// swallowing it. Without this the first click on the overlay only brings the
/// app forward, and a skip needs two clicks.
final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}

/// Custom NSWindow that can become key window even when borderless
class BreakOverlayWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }
}
