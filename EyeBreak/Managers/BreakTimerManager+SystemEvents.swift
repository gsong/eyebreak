//
//  BreakTimerManager+SystemEvents.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import Foundation
import Combine
import AppKit

// Everything outside the app that moves the timer: going idle, the screen locking, and sleep.

extension BreakTimerManager {
    func setupIdleDetection() {
        idleDetector = IdleDetector(threshold: TimeInterval(settings.idleThresholdSeconds))

        idleDetector?.onIdleStateChanged = { [weak self] isIdle in
            guard let self = self else { return }

            if isIdle && self.state.isActive {
                // User went idle, pause timer
                self.pause()
            } else if !isIdle, case .paused = self.state {
                // User returned, resume timer
                self.resume()
            }
        }
    }

    /// Sets up system notifications to automatically pause/resume timer during sleep and screen lock
    func setupWorkspaceNotifications() {
        // Mac sleep events
        NotificationCenter.default.publisher(for: NSWorkspace.willSleepNotification)
            .sink { [weak self] _ in
                self?.pause()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in
                if case .paused = self?.state {
                    self?.resume()
                }
            }
            .store(in: &cancellables)

        // Screen lock events
        let notificationCenter = DistributedNotificationCenter.default()

        notificationCenter.addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pause()
        }

        notificationCenter.addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            if case .paused = self?.state {
                self?.resume()
            }
        }

        // Screen saver events (treated same as screen lock)
        notificationCenter.addObserver(
            forName: NSNotification.Name("com.apple.screensaver.didstart"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pause()
        }

        notificationCenter.addObserver(
            forName: NSNotification.Name("com.apple.screensaver.didstop"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            if case .paused = self?.state {
                self?.resume()
            }
        }
    }
}
