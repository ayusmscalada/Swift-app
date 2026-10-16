import SwiftUI
import AppKit

/// An expired trial closes the app before any window opens.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        if TrialGuard.isEnabled, TrialStore.load()?.expired == true {
            TrialGuard.forceQuit()
        }
    }
}

@main
struct BaccaratAssistantApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var game: GameViewModel
    @State private var trial = TrialGuard()

    init() {
        _game = State(initialValue: GameViewModel(environment: AppEnvironment.live()))
        // Needed when run as a bare executable from Package.swift; harmless inside the .app bundle.
        _ = NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup("Baccarat Assistant") {
            MainView()
                .environment(game)
                .environment(trial)
                .disabled(trial.isFrozen)
                .frame(minWidth: 720, minHeight: 520)
                .onAppear {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    trial.start()
                }
        }
        .commands {
            // Every menu action is off while Google cannot be reached.
            let locked = trial.isFrozen
            CommandGroup(replacing: .newItem) {
                Button("New Session") { game.newSession() }
                    .keyboardShortcut("n")
                    .disabled(locked)
                Button("New Shoe") { game.newShoe() }
                    .keyboardShortcut("n", modifiers: [.command, .shift])
                    .disabled(locked || game.session == nil)
                Divider()
                Button("Import Result Sequence…") { game.isImportingSequence = true }
                    .keyboardShortcut("i")
                    .disabled(locked)
                Button("Inspect Windows Data Files…") { game.isInspectingLegacyFiles = true }
                    .disabled(locked)
            }
            CommandGroup(replacing: .undoRedo) {
                Button("Undo Last Result") { game.undo() }
                    .keyboardShortcut("z")
                    .disabled(locked || !game.canUndo)
            }
            // Plain B / P / T keys are handled by SessionDetailView, not here: menu key
            // equivalents without a modifier would also fire while typing in text fields.
            CommandMenu("Game") {
                Button("Banker") { game.enter(.banker) }
                    .disabled(locked || game.session == nil)
                Button("Player") { game.enter(.player) }
                    .disabled(locked || game.session == nil)
                Button("Tie") { game.enter(.tie) }
                    .disabled(locked || game.session == nil)
                Divider()
                Button("Report…") { game.isShowingReport = true }
                    .keyboardShortcut("r")
                    .disabled(locked)
            }
        }

        Settings {
            SettingsView()
                .environment(game)
                .disabled(trial.isFrozen)
        }
    }
}
