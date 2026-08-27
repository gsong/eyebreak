//
//  BreakCountdown.swift
//  EyeBreak
//

import Combine
import Foundation

/// The seconds left in a break.
///
/// One countdown drives the overlay on every screen. That is what keeps the
/// displays showing the same number, and what lets the overlay set be rebuilt
/// when a display is attached or detached without restarting the break.
final class BreakCountdown: ObservableObject {

    /// The length the break was started with. The progress ring needs it.
    let totalSeconds: Int

    @Published private(set) var remainingSeconds: Int

    /// How much of the break is still to run, 1 down to 0.
    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(remainingSeconds) / Double(totalSeconds)
    }

    init(totalSeconds: Int, onFinish: @escaping () -> Void) {
        self.totalSeconds = max(0, totalSeconds)
        self.remainingSeconds = max(0, totalSeconds)
        self.onFinish = onFinish
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Public Methods

    /// Starts counting down once per second. Calling it twice is harmless.
    func start() {
        guard timer == nil, !isStopped else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    /// Ends the count for good. Nothing fires afterwards, so a break that ended
    /// early cannot also end on its own timer.
    func stop() {
        isStopped = true
        timer?.invalidate()
        timer = nil
    }

    /// Records one elapsed second. `start` drives this; tests call it directly.
    func tick() {
        guard !isStopped else { return }

        // Zero stays on screen for a second, so the break ends on the tick after
        // the count reaches zero rather than on the one that gets it there.
        guard remainingSeconds > 0 else {
            stop()
            onFinish()
            return
        }

        remainingSeconds -= 1
    }

    // MARK: - Private

    private let onFinish: () -> Void
    private var timer: Timer?
    private var isStopped = false
}
