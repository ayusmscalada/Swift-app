import SwiftUI

/// Covers the window while the trial is not active, so nothing in it can be clicked.
/// The window's close, minimize and zoom buttons stay usable.
struct TrialLockView: View {
    @Environment(TrialGuard.self) private var trial

    var body: some View {
        if !trial.isUnlocked {
            ZStack {
                Color.black.opacity(0.6)
                    .contentShape(Rectangle())
                    .onTapGesture {}
                VStack(spacing: 12) {
                    switch trial.state {
                    case .checking, .active:
                        ProgressView()
                        Text("Verifying the trial time with Google…")
                            .font(.headline)
                    case .offline:
                        Image(systemName: "wifi.slash").font(.largeTitle)
                        Text("No internet connection")
                            .font(.headline)
                        Text("The app is locked until it can check the time with Google.\nIt retries automatically.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    case .expired:
                        Image(systemName: "lock.fill").font(.largeTitle)
                        Text(TrialGuard.expiredMessage)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(28)
                .frame(maxWidth: 420)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .ignoresSafeArea()
        }
    }
}

/// "Trial: 23:12:05 left", shown in the window toolbar.
struct TrialBadge: View {
    @Environment(TrialGuard.self) private var trial

    var body: some View {
        if TrialGuard.isEnabled, trial.isUnlocked {
            Text("Trial: \(SessionInfoPanel.clock(trial.remaining)) left")
                .font(.callout.monospacedDigit())
                .foregroundStyle(trial.remaining < 3600 ? .red : .secondary)
                .help("The trial ends 24 hours after the first launch.")
        }
    }
}
