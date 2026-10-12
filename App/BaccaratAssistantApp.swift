import SwiftUI
import AppKit
import BaccaratDomain

@main
struct BaccaratAssistantApp: App {
    @State private var game: GameViewModel

    init() {
        _game = State(initialValue: GameViewModel(environment: AppEnvironment.live()))
        // Needed when run as a bare executable from Package.swift; harmless inside the .app bundle.
        _ = NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup("Baccarat Assistant") {
            MainView()
                .environment(game)
                .frame(minWidth: 1100, minHeight: 720)
                .onAppear { NSApplication.shared.activate(ignoringOtherApps: true) }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Session") { game.newSession() }
                    .keyboardShortcut("n")
                Button("New Shoe") { game.newShoe() }
                    .keyboardShortcut("n", modifiers: [.command, .shift])
                    .disabled(game.session == nil)
                Divider()
                Button("Import Result Sequence…") { game.isImportingSequence = true }
                    .keyboardShortcut("i")
                Button("Inspect Windows Data Files…") { game.isInspectingLegacyFiles = true }
            }
            CommandGroup(replacing: .undoRedo) {
                Button("Undo Last Result") { game.undo() }
                    .keyboardShortcut("z")
                    .disabled(!game.canUndo)
            }
            // Plain B / P / T keys are handled by SessionDetailView, not here: menu key
            // equivalents without a modifier would also fire while typing in text fields.
            CommandMenu("Game") {
                Button("Banker") { game.enter(.banker) }
                    .disabled(game.session == nil)
                Button("Player") { game.enter(.player) }
                    .disabled(game.session == nil)
                Button("Tie") { game.enter(.tie) }
                    .disabled(game.session == nil)
                Divider()
                Button("Report…") { game.isShowingReport = true }
                    .keyboardShortcut("r")
            }
        }

        Settings {
            SettingsView()
                .environment(game)
        }
    }
}
