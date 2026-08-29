//
//  SettingsComponents.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

// The header and the slider row the settings form is assembled from.

struct SectionHeaderView: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(color)
        }
        .textCase(nil)
    }
}

/// One slider on one row: icon, title, track, value. The tall card this replaced
/// spent roughly 200pt per slider on a 24pt gradient readout of a number the
/// track already showed.
struct EnhancedSliderCard: View {
    let title: String
    let value: Int
    let unit: String
    let icon: String
    let color: Color
    let range: ClosedRange<Int>
    let step: Int
    let onChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
                .frame(width: 18)

            Text(title)
                .frame(width: 110, alignment: .leading)

            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { onChange(Int($0.rounded())) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: Double(step)
            )
            .tint(color)

            Text("\(value) \(unit)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(color)
                .frame(width: 58, alignment: .trailing)
                .contentTransition(.numericText())
        }
    }
}
