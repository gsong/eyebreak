//
//  BreakCountdown.swift
//  EyeBreak
//

import Combine
import Foundation

/// What the break overlay draws: the seconds left, and whether the break has
/// been served and is waiting to be dismissed.
///
/// One of these drives the overlay on every screen. That is what keeps the
/// displays showing the same number, and what lets the overlay set be rebuilt
/// when a display is attached or detached without restarting the break. The
/// waiting phase rides here for the same reason: a rebuilt overlay has to come
/// back in the phase the break is actually in.
///
/// It draws and nothing more. `BreakTimerManager.tick()` is the only thing that
/// ends a break; reaching zero here ends nothing.
final class BreakCountdown: ObservableObject {

    /// The length the break was started with. The progress ring needs it.
    let totalSeconds: Int

    @Published private(set) var remainingSeconds: Int

    /// Whether the break has been served and the overlay is now waiting for the
    /// user. `BreakTimerManager` decides it; this only carries it to the views.
    @Published private(set) var isAwaitingDismissal = false

    /// How much of the break is still to run, 1 down to 0.
    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(remainingSeconds) / Double(totalSeconds)
    }

    init(totalSeconds: Int) {
        self.totalSeconds = max(0, totalSeconds)
        self.remainingSeconds = max(0, totalSeconds)
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

    /// Swaps the overlay to its completion state and parks the count.
    ///
    /// The manager's clock and this one do not share a second boundary, so the
    /// break can be served with a second or two still on display. Parking the
    /// count stops it running on behind the completion state.
    func awaitDismissal() {
        stop()
        isAwaitingDismissal = true
    }

    /// Ends the count for good.
    func stop() {
        isStopped = true
        timer?.invalidate()
        timer = nil
    }

    /// Records one elapsed second. `start` drives this; tests call it directly.
    func tick() {
        guard !isStopped, remainingSeconds > 0 else { return }

        remainingSeconds -= 1
    }

    // MARK: - Private

    private var timer: Timer?
    private var isStopped = false
}
