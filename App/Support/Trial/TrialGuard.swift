import Foundation
import AppKit

/// The 24-hour trial, checked in the background. Nothing is shown on screen.
///
/// - The first launch is recorded as soon as the app starts: in Google time (time.google.com)
///   when the internet is reachable, otherwise in the Mac's own clock time.
/// - A main run-loop timer checks every second whether the trial has ended. It fires reliably
///   while the app runs, so the app closes on time even if it is busy or idle.
/// - When online, the current time comes from Google (fetched at launch and every minute, then
///   carried forward on the monotonic clock between fetches). When offline, it comes from the
///   Mac's own clock.
/// - Without internet the app keeps running. Once the internet is back, Google time is used again.
/// - 24 hours after the first launch the app closes at once, even while running and even offline.
/// - A later launch after expiry shows the expiry message and closes.
enum TrialGuard {
    /// Set to false to build a version without the trial.
    static let isEnabled = true
    static let duration: TimeInterval = 24 * 60 * 60
    static let expiredMessage = "The trial token has expired. Please contact the developer."

    private static let recheckInterval: TimeInterval = 60

    /// Last time fetched from Google, with the monotonic reading taken at that moment.
    @MainActor private static var anchorGoogle: Date?
    @MainActor private static var anchorMono: TimeInterval = 0
    /// True while the last Google fetch succeeded; false when offline.
    @MainActor private static var online = false
    @MainActor private static var started = false

    /// Call at launch, before any window opens: an already-expired trial shows the message and quits.
    @MainActor
    static func checkAtLaunchAndQuitIfExpired() {
        guard isEnabled else { return }
        if TrialStore.load()?.expired == true { showExpiredMessageAndQuit() }
    }

    @MainActor
    static func start() {
        guard isEnabled, !started else { return }
        started = true

        // Record the first launch now, so the trial starts even with no internet (OS time then).
        if TrialStore.load() == nil {
            TrialStore.save(TrialRecord(firstLaunch: currentTime(), expired: false))
        }

        // A main run-loop timer is the dependable part: it fires every second while the app
        // runs (common mode keeps it firing during menu tracking and window drags).
        let timer = Timer(timeInterval: 1, repeats: true) { _ in
            MainActor.assumeIsolated { checkExpiry() }
        }
        RunLoop.main.add(timer, forMode: .common)

        // Fetch Google time now and every minute, off the main thread.
        Task.detached(priority: .utility) { await fetchLoop() }
    }

    /// Current time: Google's when online, otherwise the Mac's own clock.
    @MainActor
    private static func currentTime() -> Date {
        if online, let anchorGoogle {
            return anchorGoogle.addingTimeInterval(GoogleTime.monotonicSeconds() - anchorMono)
        }
        return Date()
    }

    /// Closes the app if 24 hours have passed since the first launch.
    @MainActor
    private static func checkExpiry() {
        guard let record = TrialStore.load() else { return }
        if record.expired || currentTime().timeIntervalSince(record.firstLaunch) >= duration {
            var expired = record
            expired.expired = true
            TrialStore.save(expired)
            exit(0)
        }
    }

    private static func fetchLoop() async {
        while true {
            if let googleNow = try? GoogleTime.now() {
                let mono = GoogleTime.monotonicSeconds()
                await MainActor.run {
                    anchorGoogle = googleNow
                    anchorMono = mono
                    online = true
                    checkExpiry()
                }
            } else {
                await MainActor.run { online = false }
            }
            try? await Task.sleep(nanoseconds: UInt64(recheckInterval * 1_000_000_000))
        }
    }

    /// The expiry message, then the app quits. Used only on a launch after the trial expired.
    @MainActor
    static func showExpiredMessageAndQuit() -> Never {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = expiredMessage
        alert.addButton(withTitle: "OK")
        NSApplication.shared.activate(ignoringOtherApps: true)
        alert.runModal()
        exit(0)
    }
}
