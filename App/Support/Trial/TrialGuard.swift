import Foundation
import AppKit
import Observation

/// The 24-hour trial, checked in the background with nothing shown on screen.
///
/// - The first launch is recorded in Google time (`TrialStore`).
/// - Every launch, and every minute while the app runs, the time is checked with Google.
///   Between checks the countdown runs on the Mac's monotonic clock, so changing the date
///   does nothing.
/// - Without internet the app's controls are frozen (`isFrozen`) until Google answers again.
/// - 24 hours after the first launch the app closes at once, and every later launch closes
///   it straight away.
@MainActor
@Observable
final class TrialGuard {
    /// Set to false to build a version without the trial.
    static let isEnabled = true
    static let duration: TimeInterval = 24 * 60 * 60

    private static let recheckInterval: TimeInterval = 60
    private static let retryInterval: TimeInterval = 10

    /// True while Google cannot be reached: the window's controls are disabled.
    private(set) var isFrozen = false

    private var task: Task<Void, Never>?

    func start() {
        guard Self.isEnabled, task == nil else { return }
        if TrialStore.load()?.expired == true { Self.forceQuit() }
        task = Task { [weak self] in await self?.run() }
    }

    private func run() async {
        while !Task.isCancelled {
            let googleNow: Date
            do {
                googleNow = try await GoogleTime.now()
            } catch {
                isFrozen = true
                try? await Task.sleep(nanoseconds: UInt64(Self.retryInterval * 1_000_000_000))
                continue
            }
            isFrozen = false

            let record: TrialRecord
            if let stored = TrialStore.load() {
                record = stored
            } else {
                record = TrialRecord(firstLaunch: googleNow, expired: false)
                TrialStore.save(record)
            }

            // Count down from this Google time until the next check.
            let checkedAt = GoogleTime.monotonicSeconds()
            while !Task.isCancelled {
                let elapsed = GoogleTime.monotonicSeconds() - checkedAt
                let now = googleNow.addingTimeInterval(elapsed)
                if record.expired || now.timeIntervalSince(record.firstLaunch) >= Self.duration {
                    expire(record)
                    return
                }
                if elapsed >= Self.recheckInterval { break }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    private func expire(_ record: TrialRecord) {
        var expired = record
        expired.expired = true
        TrialStore.save(expired)
        Self.forceQuit()
    }

    /// Closes the app immediately, with no message.
    static func forceQuit() -> Never {
        UserDefaults.standard.synchronize()
        exit(0)
    }
}
