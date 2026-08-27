//
//  AppSettings+Themes.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import Foundation
import SwiftUI

// The three themable surfaces and the cached random palette each one holds.

extension AppSettings {
    /// Theme type for ambient reminders
    var ambientReminderThemeType: ColorThemeType {
        get { ColorThemeType(rawValue: ambientReminderThemeTypeRaw) ?? .defaultTheme }
        set { ambientReminderThemeTypeRaw = newValue.rawValue }
    }

    /// Get the active theme for ambient reminders
    var ambientReminderTheme: ColorTheme {
        get {
            switch ambientReminderThemeType {
            case .defaultTheme:
                return .defaultTheme
            case .randomColor:
                // Return cached theme if available, otherwise generate new one
                if let cached = cachedAmbientReminderRandomTheme {
                    return cached
                }
                let newTheme = ColorTheme.randomColorTheme()
                cachedAmbientReminderRandomTheme = newTheme
                return newTheme
            case .custom:
                if let data = ambientReminderCustomThemeData,
                   let theme = try? JSONDecoder().decode(ColorTheme.self, from: data) {
                    return theme
                }
                return .customTheme
            }
        }
        set {
            if newValue.themeType == .custom,
               let data = try? JSONEncoder().encode(newValue) {
                ambientReminderCustomThemeData = data
            }
        }
    }

    /// Generate a new random theme for ambient reminders
    func regenerateAmbientReminderRandomTheme() {
        if ambientReminderThemeType == .randomColor {
            cachedAmbientReminderRandomTheme = ColorTheme.randomColorTheme()
            objectWillChange.send()
        }
    }

    /// Theme type for break overlay
    var breakOverlayThemeType: ColorThemeType {
        get { ColorThemeType(rawValue: breakOverlayThemeTypeRaw) ?? .defaultTheme }
        set { breakOverlayThemeTypeRaw = newValue.rawValue }
    }

    /// Get the active theme for break overlay
    var breakOverlayTheme: ColorTheme {
        get {
            switch breakOverlayThemeType {
            case .defaultTheme:
                return .defaultTheme
            case .randomColor:
                // Return cached theme if available, otherwise generate new one
                if let cached = cachedBreakOverlayRandomTheme {
                    return cached
                }
                let newTheme = ColorTheme.randomColorTheme()
                cachedBreakOverlayRandomTheme = newTheme
                return newTheme
            case .custom:
                if let data = breakOverlayCustomThemeData,
                   let theme = try? JSONDecoder().decode(ColorTheme.self, from: data) {
                    return theme
                }
                return .customTheme
            }
        }
        set {
            if newValue.themeType == .custom,
               let data = try? JSONEncoder().encode(newValue) {
                breakOverlayCustomThemeData = data
            }
        }
    }

    /// Generate a new random theme for break overlay
    func regenerateBreakOverlayRandomTheme() {
        if breakOverlayThemeType == .randomColor {
            cachedBreakOverlayRandomTheme = ColorTheme.randomColorTheme()
            objectWillChange.send()
        }
    }

    /// Theme type for water reminders
    var waterReminderThemeType: ColorThemeType {
        get { ColorThemeType(rawValue: waterReminderThemeTypeRaw) ?? .defaultTheme }
        set { waterReminderThemeTypeRaw = newValue.rawValue }
    }

    /// Get the active theme for water reminders
    var waterReminderTheme: ColorTheme {
        get {
            switch waterReminderThemeType {
            case .defaultTheme:
                // Water-themed blue/cyan gradient
                return ColorTheme(
                    themeType: .defaultTheme,
                    backgroundColorHex: "#4D99CC",  // Ocean blue
                    backgroundOpacity: 0.75,
                    textColorHex: "#FFFFFF",
                    textOpacity: 0.95,
                    secondaryTextColorHex: "#FFFFFF",
                    secondaryTextOpacity: 0.75,
                    accentColorHex: "#66CCFF",  // Light cyan
                    accentOpacity: 0.85,
                    glassBlurRadius: 1.0,
                    glassHighlightOpacity: 0.25
                )
            case .randomColor:
                // Return cached theme if available, otherwise generate new one
                if let cached = cachedWaterReminderRandomTheme {
                    return cached
                }
                let newTheme = ColorTheme.randomColorTheme()
                cachedWaterReminderRandomTheme = newTheme
                return newTheme
            case .custom:
                if let data = waterReminderCustomThemeData,
                   let theme = try? JSONDecoder().decode(ColorTheme.self, from: data) {
                    return theme
                }
                return .customTheme
            }
        }
        set {
            if newValue.themeType == .custom,
               let data = try? JSONEncoder().encode(newValue) {
                waterReminderCustomThemeData = data
            }
        }
    }

    /// Generate a new random theme for water reminders
    func regenerateWaterReminderRandomTheme() {
        if waterReminderThemeType == .randomColor {
            cachedWaterReminderRandomTheme = ColorTheme.randomColorTheme()
            objectWillChange.send()
        }
    }
}
