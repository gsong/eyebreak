//
//  ReminderType.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI
import AppKit
import Combine

// The kinds of ambient reminder, and the copy and symbol each one shows.

enum ReminderType: String {
    case blink = "Blink"
    case lookLeft = "Look Left"
    case lookRight = "Look Right"
    case lookUp = "Look Up"
    case lookDown = "Look Down"
    case lookAround = "Look Around"
    case custom = "Custom"

    var emoji: String {
        // Kept for backward compatibility but not used in new design
        switch self {
        case .blink: return "👁️"
        case .lookLeft: return "👈"
        case .lookRight: return "👉"
        case .lookUp: return "☝️"
        case .lookDown: return "👇"
        case .lookAround: return "🔄"
        case .custom:
            let emoji = AppSettings.shared.customReminderEmoji
            return emoji.isEmpty ? "💡" : emoji
        }
    }

    // Professional SF Symbol icons
    var iconName: String {
        switch self {
        case .blink: return "eye"
        case .lookLeft: return "arrow.left.circle"
        case .lookRight: return "arrow.right.circle"
        case .lookUp: return "arrow.up.circle"
        case .lookDown: return "arrow.down.circle"
        case .lookAround: return "arrow.clockwise.circle"
        case .custom:
            let customIcon = AppSettings.shared.customReminderEmoji
            return customIcon.isEmpty ? "sparkles" : customIcon
        }
    }

    var message: String {
        switch self {
        case .blink: return "Blink your eyes"
        case .lookLeft: return "Look to the left"
        case .lookRight: return "Look to the right"
        case .lookUp: return "Look up"
        case .lookDown: return "Look down"
        case .lookAround: return "Look around"
        case .custom:
            let message = AppSettings.shared.customReminderMessage
            return message.isEmpty ? "Take care of your eyes" : message
        }
    }

    var subtitle: String {
        switch self {
        case .blink: return "Rest for a moment"
        case .lookLeft: return "Shift your focus"
        case .lookRight: return "Shift your focus"
        case .lookUp: return "Change your view"
        case .lookDown: return "Relax your gaze"
        case .lookAround: return "Take a visual break"
        case .custom: return "Eye care reminder"
        }
    }

    // Professional muted color palette inspired by Apple design
    var glassColor: Color {
        switch self {
        case .blink: return Color(red: 0.35, green: 0.5, blue: 0.75)        // Soft slate blue
        case .lookLeft: return Color(red: 0.5, green: 0.4, blue: 0.7)       // Muted purple
        case .lookRight: return Color(red: 0.5, green: 0.4, blue: 0.7)      // Muted purple
        case .lookUp: return Color(red: 0.35, green: 0.65, blue: 0.55)      // Soft teal
        case .lookDown: return Color(red: 0.4, green: 0.6, blue: 0.5)       // Sage green
        case .lookAround: return Color(red: 0.7, green: 0.5, blue: 0.4)     // Warm terracotta
        case .custom: return Color(red: 0.6, green: 0.45, blue: 0.65)       // Soft mauve
        }
    }

    // Legacy color properties (kept for compatibility)
    var color: Color {
        return glassColor
    }

    var secondaryColor: Color {
        // Lighter variant of the glass color
        let glassColorValue = glassColor
        return glassColorValue.opacity(0.7)
    }
}
