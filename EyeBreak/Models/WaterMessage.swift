//
//  WaterMessage.swift
//  EyeBreak
//
//  Created on October 18, 2025.
//

import SwiftUI

// One preset hydration prompt.

struct WaterMessage {
    let icon: String  // SF Symbol name
    let title: String
    let message: String
    let theme: ColorTheme  // Theme for coloring

    var glassColor: Color {
        // Use background color from theme
        return theme.backgroundColor
    }

    var accentColor: Color {
        // Use accent color from theme
        return theme.accentColor
    }
}
