import Foundation
import AppKit

/// The 24-hour trial, checked in the background. Nothing is shown on screen.
///
/// - The first launch is recorded in Google time (time.google.com) the first time the internet
///   is reached (`TrialStore`).
/// - Every launch, and every minute while running, the time is checked with Google. Between
///   checks, and while offline, the estimate moves forward on the Mac's monotonic clock, so
///   changing the Mac's date does nothing.
/// - Without internet the app keeps running. Once the internet is back, the time is checked again.
/// - 24 hours after the first launch the app closes at once, even while running and even offline.
/// - A later launch after expiry shows the expiry message and closes.
enum TrialGuard {
    /// Set to false to build a version without the trial.
    static let isEnabled = true
    static let duration: TimeInterval = 24 * 60 * 60
    static let expiredMessage = "The trial token has expired. Please contact the developer."

    private static let recheckInterval: TimeInterval = 60
    private static let retryInterval: TimeInterval = 10

    /// Call at launch, before any window opens: an already-expired trial shows the message and quits.
    static func checkAtLaunchAndQuitIfExpired() {
        guard isEnabled else { return }
        if TrialStore.load()?.expired == true { showExpiredMessageAndQuit() }
    }

    /// Starts the background loop. Returns at once; the work runs on a detached task.
    static func start() {
        guard isEnabled else { return }
        Task.detached(priority: .background) { await run() }
    }

    private static func run() async {
        // The last trustworthy time, with the monotonic reading taken at that moment.
        var anchorGoogle: Date?
        var anchorMono: TimeInterval = 0

        while true {
            if let googleNow = try? GoogleTime.now() {
                anchorGoogle = googleNow
                anchorMono = GoogleTime.monotonicSeconds()

                var record = TrialStore.load() ?? TrialRecord(firstLaunch: googleNow, expired: false)
                if TrialStore.load() == nil { TrialStore.save(record) }
                if record.expired || googleNow.timeIntervalSince(record.firstLaunch) >= duration {
                    await expire(&record)
                }
            }

            // Count forward until the next check. Works offline once we have an anchor, so the
            // trial can still end while the internet is down.
            let startedMono = GoogleTime.monotonicSeconds()
            while GoogleTime.monotonicSeconds() - startedMono < recheckInterval {
                if let anchorGoogle, let record = TrialStore.load() {
                    let now = anchorGoogle.addingTimeInterval(GoogleTime.monotonicSeconds() - anchorMono)
                    if record.expired || now.timeIntervalSince(record.firstLaunch) >= duration {
                        var expiring = record
                        await expire(&expiring)
                    }
                }
                let idle = anchorGoogle == nil ? retryInterval : 1
                try? await Task.sleep(nanoseconds: UInt64(idle * 1_000_000_000))
                if anchorGoogle == nil { break }  // offline with no anchor yet: retry sooner
            }
        }
    }

    private static func expire(_ record: inout TrialRecord) async {
        record.expired = true
        TrialStore.save(record)
        await MainActor.run { forceQuit() }
    }

    /// Closes the app immediately, with no message.
    @MainActor
    static func forceQuit() -> Never {
        exit(0)
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
