import SwiftUI

/// Banker / Player / Tie entry, or entry from the cards (the original's Player / Banker cards).
/// The B, P and T keys are handled by `SessionDetailView`.
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
                cardEntry

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

    private var cardEntry: some View {
        @Bindable var game = game
        let cards = game.pendingCards

        return DisclosureGroup("Cards (optional)") {
            VStack(alignment: .leading, spacing: 8) {
                Picker("Add cards to", selection: $game.cardsForPlayer) {
                    Text("Player").tag(true)
                    Text("Banker").tag(false)
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 34), spacing: 4)], spacing: 4) {
                    ForEach(CardRank.allCases, id: \.self) { rank in
                        Button(rank.rawValue) { game.addCard(rank) }
                            .frame(maxWidth: .infinity)
                    }
                }

                cardLine("Player", cards.player, total: cards.playerTotal, color: Outcome.player.color)
                cardLine("Banker", cards.banker, total: cards.bankerTotal, color: Outcome.banker.color)

                HStack {
                    Button("Remove", systemImage: "delete.left") { game.removeLastCard() }
                    Button("Clear") { game.clearCards() }
                    Spacer()
                    Button(cards.outcome.map { "Enter: \($0.title) wins" } ?? "Enter from cards") {
                        game.enterFromCards()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(cards.outcome == nil || game.session == nil)
                    .help("Needs at least two cards on each side. The winner and pairs come from the cards.")
                }
            }
            .padding(.top, 4)
        }
    }

    private func cardLine(_ title: String, _ ranks: [CardRank], total: Int, color: Color) -> some View {
        HStack {
            Text(title).foregroundStyle(color).frame(width: 52, alignment: .leading)
            Text(ranks.isEmpty ? "—" : ranks.map(\.rawValue).joined(separator: "  "))
                .font(.body.monospaced())
            Spacer()
            if !ranks.isEmpty {
                Text("\(total)").font(.headline).monospacedDigit()
            }
        }
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
