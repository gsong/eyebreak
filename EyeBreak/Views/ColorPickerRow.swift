//
//  ColorPickerRow.swift
//  EyeBreak
//
//  Created on October 8, 2025.
//  UI for customizing color themes for ambient reminders and break overlays
//

import SwiftUI

// One labelled color well in the custom theme editor.

struct ColorPickerRow: View {
    let title: String
    @Binding var color: Color
    @Binding var opacity: Double
    let onOpacityChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                ColorPicker("", selection: $color, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 50)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Opacity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.0f%%", opacity * 100))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $opacity, in: 0...1) {
                        Text("Opacity")
                    } onEditingChanged: { _ in
                        onOpacityChange()
                    }
                }
            }
        }
    }
}
