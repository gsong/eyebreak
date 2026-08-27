//
//  VisualEffectView.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI
import AppKit

/// The frosted backing behind every overlay: the break screen, the eye
/// exercise, the floating break panel, and the water reminder.
///
/// The defaults are what all four use. They are parameters rather than
/// constants only because `NSVisualEffectView` is meaningless without them.
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

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
