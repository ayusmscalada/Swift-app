import SwiftUI
import BaccaratDomain

/// Banker / Player / Tie entry. The B, P and T keys are handled by `SessionDetailView`.
struct GameInputView: View {
    @Environment(GameViewModel.self) private var game

    var body: some View {
        @Bindable var game = game

        GroupBox("Enter result") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    outcomeButton(.banker, key: "B")
                    outcomeButton(.player, key: "P")
                    outcomeButton(.tie, key: "T")
                }
                HStack(spacing: 16) {
                    Toggle("Banker pair", isOn: $game.nextBankerPair)
                    Toggle("Player pair", isOn: $game.nextPlayerPair)
                }
                .toggleStyle(.checkbox)
                HStack {
                    Button("Undo", systemImage: "arrow.uturn.backward") { game.undo() }
                        .disabled(!game.canUndo)
                    Button("New Shoe", systemImage: "rectangle.stack.badge.plus") { game.newShoe() }
                    Spacer()
                    Text("Shoe \(game.currentShoeNumber) · \(game.currentHistory.count) hands")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .padding(4)
        }
        .frame(maxWidth: 420)
    }

    private func outcomeButton(_ outcome: Outcome, key: String) -> some View {
        Button {
            game.enter(outcome)
        } label: {
            VStack(spacing: 2) {
                Text(outcome.title).font(.headline)
                Text(key).font(.caption).opacity(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.borderedProminent)
        .tint(outcome.color)
        .help("\(outcome.title) (\(key))")
    }
}
