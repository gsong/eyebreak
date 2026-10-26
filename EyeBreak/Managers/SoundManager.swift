//
//  SoundManager.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import AppKit

// Break sound effects. Unrelated to the blur overlay it used to share a file with.

class SoundManager {

    static let shared = SoundManager { NSSound(named: $0)?.play() }

    enum SoundType {
        case start
        case breakStart
        case breakEnd
        case skip
    }

    private let play: (NSSound.Name) -> Void

    /// NSSound.play waits for the output device to start. A wedged coreaudiod
    /// held it for about 24 seconds per sound on 2026-10-26, and on the main
    /// thread that froze the break countdown and every way out of the overlay.
    /// A stuck daemon now delays only the sound.
    private let queue = DispatchQueue(label: "com.eyebreak.sound", qos: .userInitiated)

    /// A sound asked for while another is still playing is dropped, not queued.
    /// Behind a stuck play it would go off whenever audio recovered, and
    /// ADR-0009 holds that a late sound is worse than none.
    private let lock = NSLock()
    private var inFlight = false

    /// `play` is the seam tests use to stand in for a stuck audio daemon.
    init(play: @escaping (NSSound.Name) -> Void) {
        self.play = play
    }

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

        let claimed = lock.withLock {
            guard !inFlight else { return false }
            inFlight = true
            return true
        }
        guard claimed else { return }

        queue.async { [self] in
            play(soundName)
            lock.withLock { inFlight = false }
        }
    }
}
