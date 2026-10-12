import SwiftUI

/// Strategy choice, money settings and the suggestion for the next hand.
struct StrategyPanel: View {
    @Environment(GameViewModel.self) private var game

    var body: some View {
        GroupBox("Strategy") {
            HStack(alignment: .top, spacing: 16) {
                Form {
                    Picker("Strategy", selection: Binding(get: { game.strategyID }, set: { game.setStrategy($0) })) {
                        ForEach(StrategyRegistry.all, id: \.self) { id in
                            Text(StrategyRegistry.isImplemented(id) ? id.title : "\(id.title) (pending)")
                                .tag(id)
                        }
                    }
                    TextField(
                        "Base unit",
                        value: Binding(get: { game.strategySettings.baseUnit }, set: { game.setBaseUnit($0) }),
                        format: .number
                    )
                    TextField(
                        "Starting bankroll",
                        value: Binding(get: { game.bankroll }, set: { game.setBankroll($0) }),
                        format: .number
                    )
                }
                .frame(maxWidth: 280)

                suggestionCard
            }
            .padding(4)
        }
    }

    private var suggestionCard: some View {
        let suggestion = game.nextSuggestion
        return VStack(alignment: .leading, spacing: 6) {
            Text("Next hand")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(suggestion.side == .none ? "No bet" : "\(suggestion.side.title) · \(game.nextStake.money)")
                .font(.title2.weight(.semibold))
                .foregroundStyle(suggestion.side.color)
            if suggestion.side != .none {
                Text("\(suggestion.units.money) units" + (suggestion.step.map { " · step \($0)" } ?? ""))
                    .foregroundStyle(.secondary)
            }
            if !suggestion.reason.isEmpty {
                Text(suggestion.reason)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Divider()
            HStack {
                Text("Balance")
                Spacer()
                Text(game.ledger.balance.money).monospacedDigit()
            }
            HStack {
                Text("Session P/L")
                Spacer()
                Text(game.ledger.summary.netResult.signedMoney)
                    .monospacedDigit()
                    .foregroundStyle(game.ledger.summary.netResult < 0 ? .red : .primary)
            }
        }
        .frame(minWidth: 220, maxWidth: .infinity, alignment: .leading)
    }
}
