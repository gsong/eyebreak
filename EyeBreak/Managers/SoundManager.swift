//
//  SoundManager.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import AppKit
import SwiftUI

// Break sound effects. Unrelated to the blur overlay it used to share a file with.

class SoundManager {

    static let shared = SoundManager()

    enum SoundType {
        case start
        case breakStart
        case breakEnd
        case skip
    }

    private init() {}

    func playSound(_ type: SoundType) {
        let soundName: NSSound.Name

        switch type {
        case .start:
            soundName = .init("Blow")
        case .breakStart:
            soundName = .init("Glass")
        case .breakEnd:
            soundName = .init("Purr")
        case .skip:
            soundName = .init("Tink")
        }

        NSSound(named: soundName)?.play()
    }
}
