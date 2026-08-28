//
//  VisualEffectView.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI
import AppKit

/// The frosted backing behind the break overlay, its one remaining caller.
///
/// The defaults are what it uses. They are parameters rather than constants
/// only because `NSVisualEffectView` is meaningless without them.
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
