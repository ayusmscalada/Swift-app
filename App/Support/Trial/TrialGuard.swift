import Foundation
import AppKit
import Observation

/// The 24-hour trial.
///
/// - The first launch is recorded in Google time (`TrialStore`).
/// - Every launch, and every minute while the app runs, the time is checked with Google.
///   Between checks the countdown runs on the Mac's monotonic clock, so changing the date
///   does nothing.
/// - Without internet the app is frozen (`isUnlocked` is false) and keeps retrying.
/// - 24 hours after the first launch the app is locked, even while running, and every later
///   launch shows only the expiry message.
@MainActor
@Observable
final class TrialGuard {
    enum State: Equatable {
        case checking, offline, active, expired
    }

    /// Set to false to build a version without the trial.
    static let isEnabled = true
    static let duration: TimeInterval = 24 * 60 * 60
    static let expiredMessage = "The trial token has expired. Please contact the developer."

    private static let recheckInterval: TimeInterval = 60
    private static let retryInterval: TimeInterval = 10

    private(set) var state: State = isEnabled ? .checking : .active
    /// Time left in the trial, updated every second while active.
    private(set) var remaining: TimeInterval = duration

    var isUnlocked: Bool { state == .active }

    private var task: Task<Void, Never>?

    func start() {
        guard Self.isEnabled, task == nil, state != .expired else { return }
        if TrialStore.load()?.expired == true {
            expire()
            return
        }
        task = Task { [weak self] in await self?.run() }
    }

    private func run() async {
        while !Task.isCancelled {
            let googleNow: Date
            do {
                googleNow = try await GoogleTime.now()
            } catch {
                state = .offline
                try? await Task.sleep(nanoseconds: UInt64(Self.retryInterval * 1_000_000_000))
                continue
            }

            let record: TrialRecord
            if let stored = TrialStore.load() {
                record = stored
            } else {
                record = TrialRecord(firstLaunch: googleNow, expired: false)
                TrialStore.save(record)
            }

            // Count down each second from this Google time until the next check.
            let checkedAt = GoogleTime.monotonicSeconds()
            while !Task.isCancelled {
                let elapsed = GoogleTime.monotonicSeconds() - checkedAt
                let now = googleNow.addingTimeInterval(elapsed)
                remaining = Self.duration - now.timeIntervalSince(record.firstLaunch)
                if record.expired || remaining <= 0 {
                    expire()
                    return
                }
                state = .active
                if elapsed >= Self.recheckInterval { break }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    private func expire() {
        state = .expired
        remaining = 0
        if var record = TrialStore.load() {
            record.expired = true
            TrialStore.save(record)
        }
        task?.cancel()
        Self.showExpiredAlertAndQuit()
    }

    /// The only thing an expired trial shows: the message, then the app quits.
    static func showExpiredAlertAndQuit() {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = expiredMessage
        alert.addButton(withTitle: "Quit")
        NSApplication.shared.activate(ignoringOtherApps: true)
        alert.runModal()
        NSApplication.shared.terminate(nil)
    }
}
