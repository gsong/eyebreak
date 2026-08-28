//
//  MenuBarComponents.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

// The button style the break-style preview is built from.

struct ProfessionalButtonStyle: ButtonStyle {
    let color: Color
    let isOutlined: Bool

    init(color: Color = .blue, isOutlined: Bool = false) {
        self.color = color
        self.isOutlined = isOutlined
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
